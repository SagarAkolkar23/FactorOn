import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/operator/providers/downtimeProvider.dart';
import 'package:frontend/operator/providers/machineProvider.dart';
import 'package:frontend/widgets/operator/startDowntime.dart';
import 'package:frontend/widgets/operator/editMachineDialog.dart';
import 'package:intl/intl.dart';
import 'package:frontend/operator/models/machineModel.dart';
import 'dart:async';

class MachineDetailScreen extends ConsumerWidget {
  final MachineModel machine;

  const MachineDetailScreen({super.key, required this.machine});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final downtimeAsync = ref.watch(downtimeNotifierProvider);
    final machinesAsync = ref.watch(machineNotifierProvider);

    // Get the latest machine data from the provider if available
    final currentMachine = machinesAsync.value?.firstWhere(
          (m) => m.id == machine.id,
          orElse: () => machine,
        ) ?? machine;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(currentMachine.name),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.grey.shade900,
        centerTitle: true,
      ),
      body: downtimeAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(e.toString())),
        data: (downtime) {
          final bool hasActiveDowntime = downtime != null;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _HeaderCard(machine: currentMachine),
                const SizedBox(height: 16),

                /// 🔴 ACTIVE DOWNTIME
                if (hasActiveDowntime)
                  _DowntimeTimerCard(
                    startTime: DateTime.parse(downtime["startTime"]),
                    downtimeId: downtime["_id"],
                    onStop: () async {
                      try {
                        await ref
                            .read(downtimeNotifierProvider.notifier)
                            .stopDowntime(
                              downtimeId: downtime["_id"],
                              endTime: DateTime.now(),
                            );

                        // ✅ Refresh machine status immediately
                        await ref
                            .read(machineNotifierProvider.notifier)
                            .refresh();
                      } catch (e) {
                        // Error handling is done in the provider
                        // The UI will automatically update when state changes
                      }
                    },
                  )
                /// 🟢 NO ACTIVE DOWNTIME
                else
                  _StartDowntimeCard(
                    machine: currentMachine,
                    onStartDowntime: () async {
                      await showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (_) =>
                            StartDowntimeDialog(machineId: currentMachine.id),
                      );
                      await ref
                          .read(machineNotifierProvider.notifier)
                          .refresh();
                    },
                  ),

                const SizedBox(height: 16),
                _InfoSection(machine: currentMachine),
                const SizedBox(height: 16),
                _EditMachineButton(
                  machine: currentMachine,
                  onEdit: () async {
                    await showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (_) => EditMachineDialog(machine: currentMachine),
                    );
                    // Refresh machine data after editing
                    await ref
                        .read(machineNotifierProvider.notifier)
                        .refresh();
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  final MachineModel machine;

  const _HeaderCard({required this.machine});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.primary.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                _MachineIcon(type: machine.type),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        machine.name,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "ID: ${machine.machineId}",
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ),
                _StatusChip(status: machine.status),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DowntimeTimerCard extends StatefulWidget {
  final DateTime startTime;
  final String downtimeId;
  final VoidCallback onStop;

  const _DowntimeTimerCard({
    required this.startTime,
    required this.downtimeId,
    required this.onStop,
  });

  @override
  State<_DowntimeTimerCard> createState() => _DowntimeTimerCardState();
}

class _DowntimeTimerCardState extends State<_DowntimeTimerCard> {
  late Timer _timer;
  late Duration _elapsed;
  bool _isStopped = false;

  @override
  void initState() {
    super.initState();
    _elapsed = DateTime.now().difference(widget.startTime);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && !_isStopped) {
        setState(() {
          _elapsed = DateTime.now().difference(widget.startTime);
        });
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  void _handleStop() {
    if (_isStopped) return;
    setState(() {
      _isStopped = true;
    });
    _timer.cancel();
    widget.onStop();
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$hours:$minutes:$seconds";
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF6B6B), Color(0xFFEE5A6F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF6B6B).withOpacity(0.4),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Text(
                    "Downtime Active",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                _formatDuration(_elapsed),
                style: const TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 2,
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.stop_circle_outlined, size: 24),
                label: const Text(
                  "Stop Downtime",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFFFF6B6B),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: _handleStop,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StartDowntimeCard extends StatelessWidget {
  final MachineModel machine;
  final VoidCallback onStartDowntime;

  const _StartDowntimeCard({
    required this.machine,
    required this.onStartDowntime,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                Icons.timer_outlined,
                size: 48,
                color: Colors.orange.shade700,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              "Ready to Track Downtime",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Start tracking when the machine goes offline",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.play_arrow_rounded, size: 24),
                label: const Text(
                  "Start Downtime",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange.shade600,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: onStartDowntime,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoSection extends StatelessWidget {
  final MachineModel machine;

  const _InfoSection({required this.machine});

  @override
  Widget build(BuildContext context) {
    final maintenanceDate = machine.nextMaintenance;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Machine Details",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 16),
            _InfoRow(
              icon: Icons.category_outlined,
              label: "Type",
              value: machine.type,
            ),
            const SizedBox(height: 12),
            _InfoRow(
              icon: Icons.build_circle_outlined,
              label: "Last Maintenance",
              value: maintenanceDate != null
                  ? DateFormat("dd MMM yyyy").format(maintenanceDate)
                  : "Not scheduled",
            ),
          ],
        ),
      ),
    );
  }
}

class _EditMachineButton extends StatelessWidget {
  final MachineModel machine;
  final VoidCallback onEdit;

  const _EditMachineButton({
    required this.machine,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton.icon(
        icon: const Icon(Icons.edit_outlined, size: 20),
        label: const Text(
          "Edit Machine",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: Theme.of(context).colorScheme.primary,
          side: BorderSide(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
            width: 1.5,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        onPressed: onEdit,
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    Color textColor;

    switch (status) {
      case "RUN":
        backgroundColor = const Color(0xFF10B981);
        textColor = Colors.white;
        break;
      case "IDLE":
        backgroundColor = const Color(0xFFF59E0B);
        textColor = Colors.white;
        break;
      case "OFF":
        backgroundColor = const Color(0xFFEF4444);
        textColor = Colors.white;
        break;
      default:
        backgroundColor = Colors.grey.shade400;
        textColor = Colors.white;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: backgroundColor.withOpacity(0.4),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        status,
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.bold,
          fontSize: 13,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _MachineIcon extends StatelessWidget {
  final String type;

  const _MachineIcon({required this.type});

  @override
  Widget build(BuildContext context) {
    IconData icon;

    switch (type.toLowerCase()) {
      case "electrical":
        icon = Icons.electrical_services;
        break;
      case "mechanical":
        icon = Icons.precision_manufacturing;
        break;
      default:
        icon = Icons.settings;
    }

    return Container(
      height: 56,
      width: 56,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Icon(icon, color: Colors.white, size: 28),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            size: 20,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey.shade800,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
