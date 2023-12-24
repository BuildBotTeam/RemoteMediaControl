import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:keypress_simulator/keypress_simulator.dart';
import 'package:launch_at_startup/launch_at_startup.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:system_tray/system_tray.dart';
import 'package:window_manager/window_manager.dart';

const int PORT = 35911;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());

  WidgetsFlutterBinding.ensureInitialized();
  // Must add this line.
  await windowManager.ensureInitialized();

  WindowOptions windowOptions = const WindowOptions(
    size: Size(300, 300),
    center: true,
    backgroundColor: Colors.transparent,
    titleBarStyle: TitleBarStyle.normal,
  );
  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RMC',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.orange),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Remote media control'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with WindowListener {
  HttpServer? server;
  bool isOnStartUp = false;
  final Menu menu = Menu();
  final SystemTray systemTray = SystemTray();
  final info = NetworkInfo();

  String? wifiIP;

  @override
  void initState() {
    super.initState();
    startServer();
    initSystemTray();
    windowManager.addListener(this);
    _init();
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    super.dispose();
  }

  void _init() async {
    await windowManager.setPreventClose(true);
    setState(() {});
  }

  void launchOnStartUp() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();

    launchAtStartup.setup(
      appName: packageInfo.appName,
      appPath: Platform.resolvedExecutable,
    );

    if (isOnStartUp) {
      await launchAtStartup.disable();
      isOnStartUp = false;
    } else {
      await launchAtStartup.enable();
      isOnStartUp = true;
    }

    await menu.buildFrom([
      MenuItemLabel(label: isOnStartUp ? 'Remove from stat up' : 'Add to start up', onClicked: (menuItem) => launchOnStartUp()),
      MenuItemLabel(label: 'Exit', onClicked: (menuItem) => windowManager.destroy()),
    ]);

    await systemTray.setContextMenu(menu);

    setState(() {});
  }

  void startServer() async {
    server = await HttpServer.bind(InternetAddress.anyIPv4, PORT);
    wifiIP = await info.getWifiIP();
    await for (var request in server!) {
      Map<String, String> qp = request.requestedUri.queryParameters;
      if (qp.containsKey('up')) {
        pressKey(LogicalKeyboardKey.audioVolumeUp);
      }
      if (qp.containsKey('down')) {
        pressKey(LogicalKeyboardKey.audioVolumeDown);
      }
      if (qp.containsKey('mute')) {
        pressKey(LogicalKeyboardKey.audioVolumeMute);
      }
      if (qp.containsKey('next')) {
        pressKey(LogicalKeyboardKey.mediaTrackNext);
      }
      if (qp.containsKey('prev')) {
        pressKey(LogicalKeyboardKey.mediaTrackPrevious);
      }
      if (qp.containsKey('play')) {
        pressKey(LogicalKeyboardKey.mediaPlay);
      }
      if (qp.containsKey('connect')) {
        request.response
          ..headers.contentType = ContentType("application", "json", charset: "utf-8")
          ..write(jsonEncode({'connect': true}))
          ..close();
      } else {
        request.response
          ..headers.contentType = ContentType("text", "plain", charset: "utf-8")
          ..close();
      }
    }
    setState(() {});
  }

  void initSystemTray() async {
    String path = Platform.isWindows ? 'assets/play.ico' : 'assets/play.png';

    final AppWindow appWindow = AppWindow();

    PackageInfo packageInfo = await PackageInfo.fromPlatform();

    launchAtStartup.setup(
      appName: packageInfo.appName,
      appPath: Platform.resolvedExecutable,
    );

    isOnStartUp = await launchAtStartup.isEnabled();

    await systemTray.initSystemTray(
      title: "Remote media control",
      iconPath: path,
    );

    await menu.buildFrom([
      MenuItemLabel(label: isOnStartUp ? 'Remove from stat up' : 'Add to start up', onClicked: (menuItem) => launchOnStartUp()),
      MenuItemLabel(label: 'Exit', onClicked: (menuItem) => windowManager.destroy()),
    ]);

    await systemTray.setContextMenu(menu);

    systemTray.registerSystemTrayEventHandler((eventName) {
      if (eventName == kSystemTrayEventClick) {
        Platform.isWindows ? appWindow.show() : systemTray.popUpContextMenu();
      } else if (eventName == kSystemTrayEventRightClick) {
        Platform.isWindows ? systemTray.popUpContextMenu() : appWindow.show();
      }
    });
    setState(() {});
  }

  void pressKey(LogicalKeyboardKey key) async {
    await keyPressSimulator.simulateKeyPress(
      key: key,
    );
    setState(() {});
  }

  @override
  void onWindowClose() async {
    bool isPreventClose = await windowManager.isPreventClose();
    if (isPreventClose) {
      await windowManager.hide();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            const Text(
              'Your Server address:',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 5),
            TextButton(
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: 'http://$wifiIP:$PORT'));
              },
              child: Text('http://$wifiIP:$PORT'),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(onPressed: () => pressKey(LogicalKeyboardKey.audioVolumeUp), icon: const Icon(Icons.volume_up)),
                IconButton(onPressed: () => pressKey(LogicalKeyboardKey.audioVolumeDown), icon: const Icon(Icons.volume_down)),
                IconButton(onPressed: () => pressKey(LogicalKeyboardKey.audioVolumeMute), icon: const Icon(Icons.volume_mute)),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(onPressed: () => pressKey(LogicalKeyboardKey.mediaTrackPrevious), icon: const Icon(Icons.skip_previous)),
                IconButton(onPressed: () => pressKey(LogicalKeyboardKey.mediaPlay), icon: const Icon(Icons.play_circle)),
                IconButton(onPressed: () => pressKey(LogicalKeyboardKey.mediaTrackNext), icon: const Icon(Icons.skip_next)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
