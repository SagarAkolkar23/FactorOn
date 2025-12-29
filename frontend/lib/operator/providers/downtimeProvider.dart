import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/operator/providers/machineProvider.dart';
import 'package:frontend/operator/services/downtimeService.dart';

final downtimeServiceProvider = Provider<DowntimeService>((ref) {
  return DowntimeService();
});


final downtimeNotifierProvider =
    AsyncNotifierProvider<DowntimeNotifier, Map<String, dynamic>?>(
      DowntimeNotifier.new,
    );



class DowntimeNotifier extends AsyncNotifier<Map<String, dynamic>?> {
  late final DowntimeService _service;

  @override
  Future<Map<String, dynamic>?> build() async {
    _service = ref.read(downtimeServiceProvider);

    final machineId = ref.read(currentMachineIdProvider);
    if (machineId == null) return null;
    
    try {
      return await _service.getActiveDowntime(machineId);
    } catch (e) {
      // If error, return null to prevent app crash
      // The UI should handle showing offline message
      return null;
    }
  }

  Future<void> startDowntime({
    required String machineId,
    required DateTime startTime,
    required String categoryCode,
    required String subReasonCode,
    File? photo,
  }) async {
    state = const AsyncLoading();

    try {
      final downtime = await _service.startDowntime(
        machineId: machineId,
        startTime: startTime,
        categoryCode: categoryCode,
        subReasonCode: subReasonCode,
        photo: photo,
      );

      state = AsyncData(downtime);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  Future<void> stopDowntime({
    required String downtimeId,
    required DateTime endTime,
  }) async {
    state = const AsyncLoading();

    try {
      await _service.stopDowntime(
        downtimeId: downtimeId,
        endTime: endTime,
      );

      // After stopping downtime, refresh to get the latest state from server
      final machineId = ref.read(currentMachineIdProvider);
      if (machineId != null) {
        final updatedDowntime = await _service.getActiveDowntime(machineId);
        state = AsyncData(updatedDowntime);
      } else {
        // No active downtime after stopping
        state = const AsyncData(null);
      }
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  void clear() {
    state = const AsyncData(null);
  }
}
