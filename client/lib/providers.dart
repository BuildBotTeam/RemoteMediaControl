import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:riverpod/riverpod.dart';

const int PORT = 35911;

final serversListProvider = StateProvider<List<String>>((ref) => []);

final selectServersListProvider = StateProvider<List<String>>((_) => []);

final loading = StateProvider<bool>((_) => true);

void getServer(String serverUrl, WidgetRef ref, bool last) async {
  final Dio dio = Dio();
  try {
    Response resp = await dio.get(
      serverUrl,
      queryParameters: {'connect': true},
      options: Options(receiveTimeout: const Duration(milliseconds: 500)),
    );
    if (resp.data['connect'] != null) {
      ref.read(serversListProvider.notifier).update((state) => [...state, serverUrl]);
      ref.read(selectServersListProvider.notifier).update((state) => [...state, serverUrl]);
    }

  } catch (e) {}
  if (last) ref.read(loading.notifier).update((state) => false);
}

void getServers(WidgetRef ref) async {
  ref.read(serversListProvider.notifier).update((state) => []);
  ref.read(selectServersListProvider.notifier).update((state) => []);
  ref.read(loading.notifier).update((state) => true);
  final String? wifiIp = await NetworkInfo().getWifiIP();
  if (wifiIp != null) {
    int search = 1;
    while (search < 255) {
      String serverUrl = 'http://${wifiIp.split('.').sublist(0, 3).join('.')}.$search:$PORT';
      getServer(serverUrl, ref, search == 254);
      search++;
    }
  }
}

void sendData(List<String> servers, String data) async {
  final Dio dio = Dio();
  Future.forEach(servers, (serverUrl) async => await dio.get(
    serverUrl,
    queryParameters: {data: true},
    options: Options(receiveTimeout: const Duration(milliseconds: 500)),
  ));
}
