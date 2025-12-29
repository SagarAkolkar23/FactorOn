import 'package:frontend/supervisor/models/downtimeModel.dart';

class DashboardStatsModel {
  final int totalMachines;
  final int activeDowntimesCount;
  final int todayDowntimes;
  final Map<String, int> machinesByStatus;
  final int totalDowntimeMinutesToday;
  final List<DowntimeModel> activeDowntimes;
  final List<DowntimeModel> recentDowntimes;

  DashboardStatsModel({
    required this.totalMachines,
    required this.activeDowntimesCount,
    required this.todayDowntimes,
    required this.machinesByStatus,
    required this.totalDowntimeMinutesToday,
    required this.activeDowntimes,
    required this.recentDowntimes,
  });

  factory DashboardStatsModel.fromJson(Map<String, dynamic> json) {
    return DashboardStatsModel(
      totalMachines: json["stats"]["totalMachines"] ?? 0,
      activeDowntimesCount: json["stats"]["activeDowntimes"] ?? 0,
      todayDowntimes: json["stats"]["todayDowntimes"] ?? 0,
      machinesByStatus: Map<String, int>.from(
        json["stats"]["machinesByStatus"] ?? {},
      ),
      totalDowntimeMinutesToday:
          json["stats"]["totalDowntimeMinutesToday"] ?? 0,
      activeDowntimes: (json["activeDowntimes"] as List<dynamic>?)
              ?.map((e) => DowntimeModel.fromJson(e))
              .toList() ??
          [],
      recentDowntimes: (json["recentDowntimes"] as List<dynamic>?)
              ?.map((e) => DowntimeModel.fromJson(e))
              .toList() ??
          [],
    );
  }
}

