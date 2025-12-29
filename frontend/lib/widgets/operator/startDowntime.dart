import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:frontend/operator/providers/downtimeProvider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final List<Map<String, dynamic>> downtimeReasons = [
  {
    "code": "POWER",
    "label": "Power",
    "children": [
      {"code": "GRID", "label": "Grid"},
      {"code": "INTERNAL", "label": "Internal"},
    ],
  },
  {
    "code": "NO-ORDER",
    "label": "No Order",
    "children": [
      {"code": "PLANNED", "label": "Planned"},
      {"code": "UNPLANNED", "label": "Unplanned"},
    ],
  },
];

class StartDowntimeDialog extends ConsumerStatefulWidget {
  final String machineId;

  const StartDowntimeDialog({super.key, required this.machineId});

  @override
  ConsumerState<StartDowntimeDialog> createState() =>
      _StartDowntimeDialogState();
}

class _StartDowntimeDialogState extends ConsumerState<StartDowntimeDialog> {
  String? categoryCode;
  String? subReasonCode;
  File? image;
  bool loading = false;

  Future<void> pickAndCompressImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.camera);
    if (picked == null) return;

    final compressed = await FlutterImageCompress.compressAndGetFile(
      picked.path,
      "${picked.path}_compressed.jpg",
      quality: 60,
    );

    if (compressed != null) {
      setState(() => image = File(compressed.path));
    }
  }

  Future<void> startDowntime() async {
    if (categoryCode == null || subReasonCode == null || image == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.white),
              SizedBox(width: 12),
              Text("Please complete all fields"),
            ],
          ),
          backgroundColor: Colors.orange.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      return;
    }

    setState(() => loading = true);

    try {
      await ref
          .read(downtimeNotifierProvider.notifier)
          .startDowntime(
            machineId: widget.machineId,
            startTime: DateTime.now(),
            categoryCode: categoryCode!,
            subReasonCode: subReasonCode!,
            photo: image,
          );

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text(e.toString())),
              ],
            ),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.timer_outlined,
                        color: Colors.orange.shade700,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Text(
                        "Start Downtime",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: loading ? null : () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                _buildDropdown(
                  label: "Downtime Reason",
                  hint: "Select primary reason",
                  value: categoryCode,
                  items: downtimeReasons
                      .map<DropdownMenuItem<String>>(
                        (r) => DropdownMenuItem<String>(
                          value: r["code"] as String,
                          child: Text(r["label"] as String),
                        ),
                      )
                      .toList(),
                  onChanged: loading
                      ? null
                      : (v) {
                          setState(() {
                            categoryCode = v;
                            subReasonCode = null;
                          });
                        },
                  icon: Icons.list_alt,
                ),

                const SizedBox(height: 16),

                if (categoryCode != null) ...[
                  _buildDropdown(
                    label: "Sub Reason",
                    hint: "Select detailed reason",
                    value: subReasonCode,
                    items: (() {
                      final reason = downtimeReasons.firstWhere(
                        (r) => r["code"] == categoryCode,
                      );
                      final List children = reason["children"] as List;
                      return children
                          .map<DropdownMenuItem<String>>(
                            (c) => DropdownMenuItem<String>(
                              value: c["code"] as String,
                              child: Text(c["label"] as String),
                            ),
                          )
                          .toList();
                    })(),
                    onChanged: loading
                        ? null
                        : (v) => setState(() => subReasonCode = v),
                    icon: Icons.subdirectory_arrow_right,
                  ),
                  const SizedBox(height: 16),
                ],

                _buildImagePicker(),

                const SizedBox(height: 24),

                SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: loading ? null : startDowntime,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange.shade600,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      disabledBackgroundColor: Colors.grey.shade300,
                    ),
                    child: loading
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.play_arrow_rounded),
                              SizedBox(width: 8),
                              Text(
                                "Start Downtime",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String hint,
    required String? value,
    required List<DropdownMenuItem<String>> items,
    required ValueChanged<String?>? onChanged,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: Colors.grey.shade700),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: value,
          hint: Text(hint),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.grey.shade50,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.orange.shade600, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
          items: items,
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildImagePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.camera_alt, size: 18, color: Colors.grey.shade700),
            const SizedBox(width: 8),
            Text(
              "Photo Evidence",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: loading ? null : pickAndCompressImage,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: image == null ? Colors.grey.shade50 : Colors.green.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: image == null
                    ? Colors.grey.shade300
                    : Colors.green.shade300,
                width: 2,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: image == null
                        ? Colors.grey.shade200
                        : Colors.green.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    image == null
                        ? Icons.add_a_photo_outlined
                        : Icons.check_circle_outline,
                    color: image == null
                        ? Colors.grey.shade600
                        : Colors.green.shade700,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        image == null ? "Capture Photo" : "Photo Captured",
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: image == null
                              ? Colors.grey.shade700
                              : Colors.green.shade700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        image == null
                            ? "Take a photo of the issue"
                            : "Tap to retake photo",
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: Colors.grey.shade400),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
