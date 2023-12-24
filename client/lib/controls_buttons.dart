import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_rmc/providers.dart';

class ControlsButtons extends ConsumerWidget {
  const ControlsButtons({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    var selectedServers = ref.watch(selectServersListProvider);
    bool isDisabled = selectedServers.isEmpty;
    return Padding(
      padding: MediaQuery.of(context).viewInsets,
      child: GridView.count(
        crossAxisCount: 3,
        children: [
          const SizedBox(width: 100),
          IconButton(onPressed: isDisabled ? null : () => sendData(selectedServers, 'up'), icon: const Icon(Icons.volume_up), iconSize: 100),
          const SizedBox(width: 100),
          IconButton(onPressed: isDisabled ? null : () => sendData(selectedServers, 'prev'), icon: const Icon(Icons.skip_previous), iconSize: 100),
          IconButton(onPressed: isDisabled ? null : () => sendData(selectedServers, 'play'), icon: const Icon(Icons.play_circle), iconSize: 100),
          IconButton(onPressed: isDisabled ? null : () => sendData(selectedServers, 'next'), icon: const Icon(Icons.skip_next), iconSize: 100),
          IconButton(onPressed: isDisabled ? null : () => sendData(selectedServers, 'mute'), icon: const Icon(Icons.volume_off), iconSize: 100),
          IconButton(onPressed: isDisabled ? null : () => sendData(selectedServers, 'down'), icon: const Icon(Icons.volume_down), iconSize: 100),
          const SizedBox(width: 100),
        ],
      ),
    );
  }
}
