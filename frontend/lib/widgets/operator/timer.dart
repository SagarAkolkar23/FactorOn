import 'dart:async';
import 'package:flutter/material.dart';

class DowntimeTimer extends StatefulWidget {
  final DateTime startTime;
  final VoidCallback onStop;

  const DowntimeTimer({
    super.key,
    required this.startTime,
    required this.onStop,
  });

  @override
  State<DowntimeTimer> createState() => _DowntimeTimerState();
}

class _DowntimeTimerState extends State<DowntimeTimer> {
  late Timer timer;
  late Duration elapsed;

  @override
  void initState() {
    super.initState();
    elapsed = DateTime.now().difference(widget.startTime);

    timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        elapsed = DateTime.now().difference(widget.startTime);
      });
    });
  }

  @override
  void dispose() {
    timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String two(int n) => n.toString().padLeft(2, "0");

    final h = two(elapsed.inHours);
    final m = two(elapsed.inMinutes % 60);
    final s = two(elapsed.inSeconds % 60);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              "Downtime Running",
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              "$h:$m:$s",
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              icon: const Icon(Icons.stop),
              label: const Text("Stop Downtime"),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: widget.onStop,
            ),
          ],
        ),
      ),
    );
  }
}
