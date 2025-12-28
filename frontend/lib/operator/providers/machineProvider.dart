import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/operator/models/machineModel.dart';
import 'package:frontend/operator/services/machineService.dart';

final machineServiceProvider = Provider<MachineService>((ref) {
  return MachineService();
});

final machineNotifierProvider =
    AsyncNotifierProvider<MachineNotifier, List<MachineModel>>(
      MachineNotifier.new,
    );

class MachineNotifier extends AsyncNotifier<List<MachineModel>> {
  late final MachineService _service;

  @override
  Future<List<MachineModel>> build() async {
    _service = ref.read(machineServiceProvider);
    return _service.getMachines();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    try {
      final machines = await _service.getMachines();
      state = AsyncData(machines);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> addMachine({
    required String machineId,
    required String name,
    required String type,
    Map<String, dynamic>? details,
    DateTime? nextMaintenance,
    String? maintenanceNotes,
  }) async {
    try {
      await _service.addMachine(
        machineId: machineId,
        name: name,
        type: type,
        details: details,
        lastMaintenance: nextMaintenance,
        maintenanceNotes: maintenanceNotes,
      );

      await refresh();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateMachine({
    required String id,
    String? name,
    String? type,
    String? status,
    Map<String, dynamic>? details,
    DateTime? nextMaintenance,
    String? maintenanceNotes,
  }) async {
    try {
      await _service.updateMachine(
        id: id,
        name: name,
        type: type,
        status: status,
        details: details,
        nextMaintenance: nextMaintenance,
        maintenanceNotes: maintenanceNotes,
      );

      await refresh();
    } catch (e) {
      rethrow;
    }
  }

  /// ---------------- DELETE MACHINE (OPTIMISTIC) ----------------
  Future<void> deleteMachine(String id) async {
    final previous = state.value;
    if (previous == null) return;

    // Optimistic update
    state = AsyncData(previous.where((m) => m.id != id).toList());

    try {
      await _service.deleteMachine(id);
    } catch (e, st) {
      // Rollback on failure
      state = AsyncError(e, st);
      state = AsyncData(previous);
    }
  }
}
