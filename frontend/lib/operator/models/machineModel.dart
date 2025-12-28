class MachineModel {
  final String id;
  final String machineId;
  final String name;
  final String type;
  final Map<String, dynamic>? details;
  final Map<String, dynamic>? maintenance;
  final DateTime? createdAt;

  MachineModel({
    required this.id,
    required this.machineId,
    required this.name,
    required this.type,
    this.details,
    this.maintenance,
    this.createdAt,
  });

  factory MachineModel.fromJson(Map<String, dynamic> json) {
    return MachineModel(
      id: json["_id"],
      machineId: json["machineId"],
      name: json["name"],
      type: json["type"],
      details: json["details"],
      maintenance: json["maintenance"],
      createdAt: json["createdAt"] != null
          ? DateTime.parse(json["createdAt"])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "machineId": machineId,
      "name": name,
      "type": type,
      "details": details,
      "maintenance": maintenance,
    };
  }
}
