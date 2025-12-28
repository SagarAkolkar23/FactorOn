import 'package:flutter/material.dart';
import 'package:frontend/operator/models/machineModel.dart';

class MachineCard extends StatelessWidget {
  final MachineModel machine;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const MachineCard({
    super.key,
    required this.machine,
    this.onTap,
    this.onDelete,
  });

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
              machineIcon(context, machine.type),
              const SizedBox(width: 16),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      machine.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),

                    Text(
                      "ID: ${machine.machineId}",
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 6),

                    typeChip(context, machine.type),
                  ],
                ),
              ),

              if (onDelete != null)
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  color: Colors.redAccent,
                  onPressed: onDelete,
                  tooltip: "Delete machine",
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget machineIcon(BuildContext context, String type) {
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

  Widget typeChip(BuildContext context, String type) {
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
}
