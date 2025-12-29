import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:frontend/operator/models/machineModel.dart';
import 'package:frontend/operator/providers/machineProvider.dart';
import 'package:frontend/widgets/mainButton.dart';
import 'package:frontend/widgets/textField.dart';
import 'package:frontend/widgets/operator/addMachineDialog.dart';

class EditMachineDialog extends ConsumerStatefulWidget {
  final MachineModel machine;

  const EditMachineDialog({super.key, required this.machine});

  @override
  ConsumerState<EditMachineDialog> createState() => _EditMachineDialogState();
}

class _EditMachineDialogState extends ConsumerState<EditMachineDialog> {
  late TextEditingController _nameController;
  late TextEditingController _detailsController;

  String? _selectedType;
  String? _selectedStatus;
  DateTime? _lastMaintenanceDate;
  String? _maintenanceNotes;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.machine.name);
    _detailsController = TextEditingController(
      text: widget.machine.details?['description'] ?? '',
    );
    _selectedType = widget.machine.type;
    _selectedStatus = widget.machine.status;
    _lastMaintenanceDate = widget.machine.nextMaintenance;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _detailsController.dispose();
    super.dispose();
  }

  Future<void> _pickMaintenanceDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _lastMaintenanceDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() => _lastMaintenanceDate = picked);
    }
  }

  Future<void> _submit() async {
    if (_nameController.text.trim().isEmpty || _selectedType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all required fields")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await ref.read(machineNotifierProvider.notifier).updateMachine(
            id: widget.machine.id,
            name: _nameController.text.trim(),
            type: _selectedType!,
            status: _selectedStatus,
            details: _detailsController.text.trim().isNotEmpty
                ? {"description": _detailsController.text.trim()}
                : null,
            nextMaintenance: _lastMaintenanceDate,
            maintenanceNotes: _maintenanceNotes,
          );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Machine updated successfully"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Edit Machine",
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 20),

              // Machine ID (read-only)
              TextField(
                controller: TextEditingController(text: widget.machine.machineId),
                enabled: false,
                decoration: InputDecoration(
                  labelText: "Machine ID",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade200,
                ),
              ),
              const SizedBox(height: 12),

              AppTextField(
                label: "Machine Name",
                controller: _nameController,
              ),
              const SizedBox(height: 12),

              // Machine Type Dropdown
              DropdownButtonFormField<String>(
                value: _selectedType,
                decoration: InputDecoration(
                  labelText: "Machine Type",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                items: machineTypes
                    .map(
                      (type) => DropdownMenuItem<String>(
                        value: type,
                        child: Text(type),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  setState(() => _selectedType = value);
                },
              ),
              const SizedBox(height: 12),

              // Status Dropdown
              DropdownButtonFormField<String>(
                value: _selectedStatus,
                decoration: InputDecoration(
                  labelText: "Status",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                items: const [
                  DropdownMenuItem<String>(
                    value: "RUN",
                    child: Text("RUN"),
                  ),
                  DropdownMenuItem<String>(
                    value: "IDLE",
                    child: Text("IDLE"),
                  ),
                  DropdownMenuItem<String>(
                    value: "OFF",
                    child: Text("OFF"),
                  ),
                ],
                onChanged: (value) {
                  setState(() => _selectedStatus = value);
                },
              ),
              const SizedBox(height: 12),

              AppTextField(
                label: "Machine Details (optional)",
                controller: _detailsController,
              ),
              const SizedBox(height: 12),

              // Maintenance Date Picker
              InkWell(
                onTap: _pickMaintenanceDate,
                borderRadius: BorderRadius.circular(8),
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: "Last Maintenance Date (optional)",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    _lastMaintenanceDate == null
                        ? "Select date"
                        : DateFormat("dd MMM yyyy").format(_lastMaintenanceDate!),
                    style: TextStyle(
                      color: _lastMaintenanceDate == null
                          ? Colors.grey
                          : Colors.black,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              AppButton(
                text: "Update Machine",
                isLoading: _isLoading,
                onPressed: _submit,
                backgroundColor: Colors.orange.shade600,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

