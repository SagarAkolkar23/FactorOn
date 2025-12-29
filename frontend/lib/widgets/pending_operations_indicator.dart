import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/offline_storage.dart';
import 'package:frontend/widgets/offline_indicator.dart';

final pendingOperationsProvider = FutureProvider<int>((ref) async {
  final storage = OfflineStorage();
  final operations = await storage.getPendingOperations();
  return operations.length;
});

class PendingOperationsIndicator extends ConsumerWidget {
  const PendingOperationsIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingCountAsync = ref.watch(pendingOperationsProvider);
    final connectivityAsync = ref.watch(connectivityProvider);
    
    return pendingCountAsync.when(
      data: (count) {
        if (count == 0) {
          return const SizedBox.shrink();
        }
        
        final isOnline = connectivityAsync.value ?? false;
        
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          color: isOnline ? Colors.blue.shade700 : Colors.orange.shade700,
          child: Row(
            children: [
              Icon(
                isOnline ? Icons.sync : Icons.cloud_upload,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  isOnline
                      ? "Syncing $count pending operation${count > 1 ? 's' : ''}..."
                      : "$count operation${count > 1 ? 's' : ''} pending sync",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (isOnline)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

