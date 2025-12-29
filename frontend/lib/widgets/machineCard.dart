import 'package:flutter/material.dart';
import 'package:frontend/operator/models/machineModel.dart';

class MachineCard extends StatelessWidget {
  final MachineModel machine;
  final VoidCallback? onTap;

  const MachineCard({super.key, required this.machine, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.grey.shade300),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _machineIcon(context, machine.type),
              const SizedBox(width: 16),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    /// Name + Status
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            machine.name,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                        ),
                        _statusChip(machine.status),
                      ],
                    ),

                    const SizedBox(height: 6),

                    Text(
                      "ID: ${machine.machineId}",
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                    ),

                    const SizedBox(height: 8),

                    _typeChip(context, machine.type),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------- ICON ----------------
  Widget _machineIcon(BuildContext context, String type) {
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
      height: 44,
      width: 44,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: Theme.of(context).colorScheme.primary, size: 24),
    );
  }

  // ---------------- TYPE CHIP ----------------
  Widget _typeChip(BuildContext context, String type) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.blueGrey.shade50,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        type,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          fontWeight: FontWeight.w500,
          color: Colors.blueGrey.shade700,
        ),
      ),
    );
  }

  // ---------------- STATUS CHIP ----------------
  Widget _statusChip(String status) {
    Color color;

    switch (status) {
      case "RUN":
        color = Colors.green;
        break;
      case "IDLE":
        color = Colors.orange;
        break;
      case "OFF":
        color = Colors.red;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
