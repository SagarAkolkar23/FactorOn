class DowntimeModel {
  final String id;
  final String machineId;
  final String machineName;
  final String? machineType;
  final DateTime startTime;
  final DateTime? endTime;
  final Map<String, dynamic> reason;
  final String? photoUrl;
  final bool isActive;
  final String? createdByEmail;
  final DateTime createdAt;

  DowntimeModel({
    required this.id,
    required this.machineId,
    required this.machineName,
    this.machineType,
    required this.startTime,
    this.endTime,
    required this.reason,
    this.photoUrl,
    required this.isActive,
    this.createdByEmail,
    required this.createdAt,
  });

  factory DowntimeModel.fromJson(Map<String, dynamic> json) {
    return DowntimeModel(
      id: json["_id"],
      machineId: json["machine"]?["_id"] ?? json["machine"]?.toString() ?? "",
      machineName: json["machine"]?["name"] ?? json["machineName"] ?? "Unknown",
      machineType: json["machine"]?["type"],
      startTime: DateTime.parse(json["startTime"]),
      endTime: json["endTime"] != null ? DateTime.parse(json["endTime"]) : null,
      reason: json["reason"] ?? {},
      photoUrl: json["photo"]?["url"],
      isActive: json["isActive"] ?? false,
      createdByEmail: json["createdBy"]?["email"],
      createdAt: json["createdAt"] != null
          ? DateTime.parse(json["createdAt"])
          : DateTime.now(),
    );
  }

  Duration get duration {
    if (endTime != null) {
      return endTime!.difference(startTime);
    }
    return DateTime.now().difference(startTime);
  }

  String get durationFormatted {
    final d = duration;
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60);
    if (hours > 0) {
      return "${hours}h ${minutes}m";
    }
    return "${minutes}m";
  }
}

