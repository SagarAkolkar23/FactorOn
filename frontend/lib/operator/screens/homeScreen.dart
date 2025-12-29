import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/operator/models/machineModel.dart';
import 'package:frontend/operator/providers/machineProvider.dart';
import 'package:frontend/widgets/machineCard.dart';
import 'package:frontend/widgets/operator/addMachineDialog.dart';
import 'package:frontend/widgets/offline_indicator.dart';
import 'package:frontend/widgets/pending_operations_indicator.dart';
import 'package:go_router/go_router.dart';

class OperatorHomeScreen extends ConsumerWidget {
  const OperatorHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final machinesState = ref.watch(machineNotifierProvider);

    return Scaffold(
      backgroundColor: Colors.grey.shade100,

      appBar: AppBar(
        title: const Text("Machines"),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),

      body: Column(
        children: [
          const OfflineIndicator(),
          const PendingOperationsIndicator(),
          Expanded(
            child: machinesState.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => _ErrorState(
                message: e.toString(),
                onRetry: () {
                  ref.invalidate(machineNotifierProvider);
                },
              ),
              data: (machines) {
                if (machines.isEmpty) {
                  return const _EmptyState();
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(machineNotifierProvider);
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.only(bottom: 100),
                    itemCount: machines.length,
                    itemBuilder: (context, index) {
                      final MachineModel machine = machines[index];

                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: MachineCard(
                          machine: machine,
                          onTap: () {
                            ref.read(currentMachineIdProvider.notifier).state =
                                machine.id;

                            context.push(
                              "/machineDetail",
                              extra: machine,
                            );
                          },
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),

 floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (_) => const AddMachineDialog(),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text("Add Machine"),
      ),

    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.precision_manufacturing_outlined,
            size: 72,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            "No machines found",
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            "Tap on 'Add Machine' to get started",
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});
          


  @override
  Widget build(BuildContext context) {
    print(message);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: onRetry, child: const Text("Retry")),
          ],
        ),
      ),
    );
  }
}
