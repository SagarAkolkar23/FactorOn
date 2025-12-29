class MachineModel {
  final String id;
  final String machineId;
  final String name;
  final String type;
  final String status;

  final Map<String, dynamic>? details;

  final DateTime? nextMaintenance;

  final DateTime? createdAt;

  MachineModel({
    required this.id,
    required this.machineId,
    required this.name,
    required this.type,
    required this.status,
    this.details,
    this.nextMaintenance,
    this.createdAt,
  });

  factory MachineModel.fromJson(Map<String, dynamic> json) {
    return MachineModel(
      id: json["_id"],
      machineId: json["machineId"],
      name: json["name"],
      type: json["type"],
      status: json["status"],
      details: json["details"],

      nextMaintenance:
          json["maintenance"] != null &&
              json["maintenance"]["nextMaintenance"] != null
          ? DateTime.parse(json["maintenance"]["nextMaintenance"])
          : null,

      createdAt: json["createdAt"] != null
          ? DateTime.parse(json["createdAt"])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "_id": id,
      "machineId": machineId,
      "name": name,
      "type": type,
      "status": status,
      "details": details,
      "maintenance": nextMaintenance != null
          ? {"nextMaintenance": nextMaintenance!.toIso8601String()}
          : null,
      if (createdAt != null) "createdAt": createdAt!.toIso8601String(),
    };
  }
}
