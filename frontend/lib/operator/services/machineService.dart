import 'package:dio/dio.dart';
import 'package:frontend/core/api.dart';
import 'package:frontend/operator/models/machineModel.dart';

class MachineService {
  final Dio _dio = DioClient.dio;

  Future<MachineModel> addMachine({
    required String machineId,
    required String name,
    required String type,
    Map<String, dynamic>? details,
    DateTime? lastMaintenance,
    String? maintenanceNotes,
  }) async {
    try {
      final response = await _dio.post(
        "/machines/add",
        data: {
          "machineId": machineId,
          "name": name,
          "type": type,
          "details": details,
          "maintenance": lastMaintenance != null
              ? {
                  "lastMaintenance": lastMaintenance.toIso8601String(), // ✅ ISO
                  "notes": maintenanceNotes,
                }
              : null,
        },
      );

      return MachineModel.fromJson(response.data["machine"]);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<MachineModel>> getMachines() async {
    try {
      final response = await _dio.get("/machines/get");

      final List machinesJson = response.data["machines"];

      return machinesJson.map((json) => MachineModel.fromJson(json)).toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<MachineModel> updateMachine({
    required String id,
    String? name,
    String? type,
    String? status,
    Map<String, dynamic>? details,
    DateTime? nextMaintenance,
    String? maintenanceNotes,
  }) async {
    try {
      final response = await _dio.put(
        "/machines/update/$id",
        data: {
          if (name != null) "name": name,
          if (type != null) "type": type,
          if (status != null) "status": status,
          if (details != null) "details": details,
          if (nextMaintenance != null)
            "maintenance": {
              "lastMaintenance": nextMaintenance.toIso8601String(),
              "notes": maintenanceNotes,
            },
        },
      );

      return MachineModel.fromJson(response.data["machine"]);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> deleteMachine(String id) async {
    try {
      await _dio.delete("/machines/delete/$id");
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  String _handleError(DioException e) {
    if (e.response != null) {
      return e.response?.data["message"] ?? "Server error";
    } else {
      return "Network error. Check your internet connection.";
    }
  }
}
