import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/supervisor/models/dashboardStatsModel.dart';
import 'package:frontend/supervisor/models/downtimeModel.dart';
import 'package:frontend/supervisor/services/supervisorService.dart';

final supervisorServiceProvider = Provider<SupervisorService>((ref) {
  return SupervisorService();
});

final dashboardStatsProvider =
    AsyncNotifierProvider<DashboardStatsNotifier, DashboardStatsModel?>(
      DashboardStatsNotifier.new,
    );

final allDowntimesProvider =
    AsyncNotifierProvider<AllDowntimesNotifier, List<DowntimeModel>>(
      AllDowntimesNotifier.new,
    );

class DashboardStatsNotifier
    extends AsyncNotifier<DashboardStatsModel?> {
  late final SupervisorService _service;

  @override
  Future<DashboardStatsModel?> build() async {
    _service = ref.read(supervisorServiceProvider);
    try {
      return await _service.getDashboardStats();
    } catch (e) {
      return null;
    }
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    try {
      final stats = await _service.getDashboardStats();
      state = AsyncData(stats);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}

class AllDowntimesNotifier extends AsyncNotifier<List<DowntimeModel>> {
  late final SupervisorService _service;

  @override
  Future<List<DowntimeModel>> build() async {
    _service = ref.read(supervisorServiceProvider);
    try {
      return await _service.getAllDowntimes();
    } catch (e) {
      return [];
    }
  }

  Future<void> refresh({
    int page = 1,
    int limit = 20,
    String? machineId,
    bool? isActive,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    state = const AsyncLoading();
    try {
      final downtimes = await _service.getAllDowntimes(
        page: page,
        limit: limit,
        machineId: machineId,
        isActive: isActive,
        startDate: startDate,
        endDate: endDate,
      );
      state = AsyncData(downtimes);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}

