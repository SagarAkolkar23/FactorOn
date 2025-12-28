import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:frontend/operator/providers/machineProvider.dart';
import 'package:frontend/widgets/mainButton.dart';
import 'package:frontend/widgets/textField.dart';

class AddMachineDialog extends ConsumerStatefulWidget {
  const AddMachineDialog({super.key});

  @override
  ConsumerState<AddMachineDialog> createState() => _AddMachineDialogState();
}

class _AddMachineDialogState extends ConsumerState<AddMachineDialog> {
  final TextEditingController _machineIdController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _detailsController = TextEditingController();

  String? _selectedType;
  DateTime? _lastMaintenanceDate;

  bool _isLoading = false;

  @override
  void dispose() {
    _machineIdController.dispose();
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
    if (_machineIdController.text.trim().isEmpty ||
        _nameController.text.trim().isEmpty ||
        _selectedType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all required fields")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await ref
          .read(machineNotifierProvider.notifier)
          .addMachine(
            machineId: _machineIdController.text.trim(),
            name: _nameController.text.trim(),
            type: _selectedType!,
            details: _detailsController.text.trim().isNotEmpty
                ? {"description": _detailsController.text.trim()}
                : null,
            nextMaintenance: _lastMaintenanceDate, // ✅ DateTime
            maintenanceNotes: null,
          );

      if (mounted) Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
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
                "Add Machine",
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 20),

              AppTextField(
                label: "Machine ID",
                controller: _machineIdController,
              ),
              const SizedBox(height: 12),

              AppTextField(label: "Machine Name", controller: _nameController),
              const SizedBox(height: 12),

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

              AppTextField(
                label: "Machine Details (optional)",
                controller: _detailsController,
              ),
              const SizedBox(height: 12),

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
                        : DateFormat(
                            "dd MMM yyyy",
                          ).format(_lastMaintenanceDate!),
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
                text: "Add Machine",
                isLoading: _isLoading,
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

const List<String> machineTypes = [
  "Electrical",
  "Mechanical",
  "Hydraulic",
  "Pneumatic",
  "CNC",
  "Other",
];