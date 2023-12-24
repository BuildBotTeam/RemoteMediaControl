import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mobile_rmc/providers.dart';

class ServersView extends ConsumerWidget {
  const ServersView({super.key});

  void handleSelected(WidgetRef ref, String select) {
    ref.read(selectServersListProvider.notifier).update((state) {
      if (state.contains(select)) {
        state.remove(select);
      } else {
        state.add(select);
      }
      return state.toList();
    });
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final servers = ref.watch(serversListProvider);
    final selected = ref.watch(selectServersListProvider);
    final isLoading = ref.watch(loading);
    return Container(
      decoration: BoxDecoration(color: Colors.black.withOpacity(0.05), borderRadius: const BorderRadius.vertical(top: Radius.circular(20))),
      child: DraggableScrollableSheet(
        minChildSize: 0.2,
        maxChildSize: 0.4,
        initialChildSize: 0.2,
        expand: false,
        builder: (BuildContext context, ScrollController scrollController) => Container(
          padding: const EdgeInsets.only(top: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  height: 4,
                  width: 70,
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), color: Colors.black),
                ),
              ),
              Expanded(
                child: SizedBox(
                  height: 300,
                  child: isLoading
                      ? const Center(
                          child: CircularProgressIndicator(),
                        )
                      : servers.isEmpty
                          ? const Center(child: Text('Нет не одного сервера...'))
                          : ListView.builder(
                              shrinkWrap: true,
                              controller: scrollController,
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: servers.length,
                              itemBuilder: (context, index) {
                                return Card(
                                  color: selected.contains(servers[index]) ? Colors.yellow : Colors.grey,
                                  child: ListTile(
                                    onTap: () => handleSelected(ref, servers[index]),
                                    title: Text(servers[index]),
                                  ),
                                );
                              },
                            ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: ElevatedButton.icon(onPressed: () => getServers(ref), icon: const Icon(Icons.refresh), label: const Text('ОБНОВИТЬ')),
              )
            ],
          ),
        ),
      ),
    );
  }
}
