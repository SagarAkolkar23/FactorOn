import 'package:dio/dio.dart';
import 'package:frontend/core/api.dart';
import 'package:frontend/core/connectivity_service.dart';
import 'package:frontend/core/offline_storage.dart';
import 'package:frontend/operator/models/machineModel.dart';

class MachineService {
  final Dio _dio = DioClient.dio;
  final ConnectivityService _connectivity = ConnectivityService();
  final OfflineStorage _storage = OfflineStorage();

  Future<MachineModel> addMachine({
    required String machineId,
    required String name,
    required String type,
    Map<String, dynamic>? details,
    DateTime? lastMaintenance,
    String? maintenanceNotes,
  }) async {
    final isOnline = await _connectivity.checkConnectivity();
    final machineData = {
      "machineId": machineId,
      "name": name,
      "type": type,
      "details": details,
      "maintenance": lastMaintenance != null
          ? {
              "lastMaintenance": lastMaintenance.toIso8601String(),
              "notes": maintenanceNotes,
            }
          : null,
    };

    if (isOnline) {
      try {
        final response = await _dio.post("/machines/add", data: machineData);
        final machine = MachineModel.fromJson(response.data["machine"]);
        
        // Refresh cache after adding
        await getMachines();
        
        return machine;
      } on DioException catch (e) {
        throw _handleError(e);
      }
    } else {
      // Offline mode - queue the operation
      await _storage.addPendingOperation({
        "type": "addMachine",
        "data": machineData,
      });
      
      // Create a temporary machine object for optimistic UI update
      // Note: This won't have a real ID, but it allows the UI to show the machine
      throw "Machine will be added when connection is restored. Operation queued.";
    }
  }

  Future<List<MachineModel>> getMachines() async {
    final isOnline = await _connectivity.checkConnectivity();
    
    if (isOnline) {
      try {
        final response = await _dio.get("/machines/get");
        final List machinesJson = response.data["machines"];
        final machines = machinesJson.map((json) => MachineModel.fromJson(json)).toList();
        
        // Cache the data for offline use
        await _storage.cacheMachines(machinesJson.cast<Map<String, dynamic>>());
        
        return machines;
      } on DioException catch (e) {
        // If network error, try to return cached data
        if (e.type == DioExceptionType.connectionTimeout ||
            e.type == DioExceptionType.connectionError) {
          return await _getCachedMachines();
        }
        throw _handleError(e);
      }
    } else {
      // Offline mode - return cached data
      return await _getCachedMachines();
    }
  }

  Future<List<MachineModel>> _getCachedMachines() async {
    final cached = await _storage.getCachedMachines();
    if (cached != null && cached.isNotEmpty) {
      return cached.map((json) => MachineModel.fromJson(json)).toList();
    }
    throw "No cached data available. Please connect to the internet.";
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
    final isOnline = await _connectivity.checkConnectivity();
    final updateData = {
      if (name != null) "name": name,
      if (type != null) "type": type,
      if (status != null) "status": status,
      if (details != null) "details": details,
      if (nextMaintenance != null)
        "maintenance": {
          "lastMaintenance": nextMaintenance.toIso8601String(),
          "notes": maintenanceNotes,
        },
    };

    if (isOnline) {
      try {
        final response = await _dio.put("/machines/update/$id", data: updateData);
        final machine = MachineModel.fromJson(response.data["machine"]);
        
        // Refresh cache after updating
        await getMachines();
        
        return machine;
      } on DioException catch (e) {
        throw _handleError(e);
      }
    } else {
      // Offline mode - queue the operation
      await _storage.addPendingOperation({
        "type": "updateMachine",
        "id": id,
        "data": updateData,
      });
      
      throw "Machine will be updated when connection is restored. Operation queued.";
    }
  }

  Future<void> deleteMachine(String id) async {
    final isOnline = await _connectivity.checkConnectivity();
    
    if (isOnline) {
      try {
        await _dio.delete("/machines/delete/$id");
        // Refresh cache after deleting
        await getMachines();
      } on DioException catch (e) {
        throw _handleError(e);
      }
    } else {
      // Offline mode - queue the operation
      await _storage.addPendingOperation({
        "type": "deleteMachine",
        "id": id,
      });
      
      throw "Machine will be deleted when connection is restored. Operation queued.";
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
