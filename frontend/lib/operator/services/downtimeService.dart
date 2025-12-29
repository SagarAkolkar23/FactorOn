import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import 'package:frontend/core/api.dart';
import 'package:frontend/core/connectivity_service.dart';
import 'package:frontend/core/offline_storage.dart';

class DowntimeService {
  final Dio _dio = DioClient.dio;
  final ConnectivityService _connectivity = ConnectivityService();
  final OfflineStorage _storage = OfflineStorage();

  Future<Map<String, dynamic>> startDowntime({
    required String machineId,
    required DateTime startTime,
    required String categoryCode,
    required String subReasonCode,
    File? photo, 
  }) async {
    final isOnline = await _connectivity.checkConnectivity();
    
    if (isOnline) {
      try {
        final formData = FormData.fromMap({
          "machineId": machineId,
          "startTime": startTime.toIso8601String(),
          "reason[categoryCode]": categoryCode,
          "reason[subReasonCode]": subReasonCode,

          if (photo != null)
            "photo": await MultipartFile.fromFile(
              photo.path,
              filename: path.basename(photo.path),
            ),
        });

        final response = await _dio.post(
          "/downtime/start",
          data: formData,
          options: Options(contentType: "multipart/form-data"),
        );

        final downtime = response.data["downtime"];
        
        // Cache the active downtime
        await _storage.cacheActiveDowntime(machineId, downtime);
        
        return downtime;
      } on DioException catch (e) {
        throw _handleError(e);
      }
    } else {
      // Offline mode - queue the operation
      // Note: Photo cannot be queued, so we'll skip it for offline operations
      
      // Create a temporary downtime object for optimistic UI
      final tempId = "temp_${DateTime.now().millisecondsSinceEpoch}";
      final tempDowntime = {
        "_id": tempId,
        "machine": machineId,
        "startTime": startTime.toIso8601String(),
        "reason": {
          "categoryCode": categoryCode,
          "subReasonCode": subReasonCode,
        },
        "isActive": true,
        "isPending": true, // Mark as pending sync
      };
      
      // Store the temp ID in the operation for later reference
      final operationData = {
        "type": "startDowntime",
        "machineId": machineId,
        "startTime": startTime.toIso8601String(),
        "categoryCode": categoryCode,
        "subReasonCode": subReasonCode,
        "hasPhoto": photo != null,
        "tempDowntimeId": tempId, // Store temp ID for reference
      };
      
      await _storage.addPendingOperation(operationData);
      
      // Cache it locally so it shows up in the UI
      await _storage.cacheActiveDowntime(machineId, tempDowntime);
      
      return tempDowntime;
    }
  }

  Future<Map<String, dynamic>?> getActiveDowntime(String machineId) async {
    final isOnline = await _connectivity.checkConnectivity();
    
    if (isOnline) {
      try {
        final res = await _dio.get("/downtime/active/$machineId");
        final downtime = res.data["downtime"];
        
        // Cache the active downtime
        await _storage.cacheActiveDowntime(machineId, downtime);
        
        return downtime;
      } on DioException catch (e) {
        // If 404, return null (no active downtime) and cache it
        if (e.response?.statusCode == 404) {
          await _storage.cacheActiveDowntime(machineId, null);
          return null;
        }
        
        // If network error, try cached data
        if (e.type == DioExceptionType.connectionTimeout ||
            e.type == DioExceptionType.connectionError) {
          return await _storage.getCachedActiveDowntime(machineId);
        }
        
        throw _handleError(e);
      }
    } else {
      // Offline mode - return cached data
      return await _storage.getCachedActiveDowntime(machineId);
    }
  }



  Future<Map<String, dynamic>> stopDowntime({
    required String downtimeId,
    required DateTime endTime,
  }) async {
    final isOnline = await _connectivity.checkConnectivity();
    
    if (isOnline) {
      try {
        final response = await _dio.put(
          "/downtime/stop/$downtimeId",
          data: {"endTime": endTime.toIso8601String()},
        );

        final downtime = response.data["downtime"];
        
        // Clear cached active downtime (since it's no longer active)
        final machineId = downtime["machine"]?["_id"] ?? downtime["machine"];
        if (machineId != null) {
          await _storage.cacheActiveDowntime(machineId.toString(), null);
        }
        
        return downtime;
      } on DioException catch (e) {
        throw _handleError(e);
      }
    } else {
      // Offline mode - queue the operation
      // Try to get machineId from cached active downtime or pending operations
      String? machineId;
      
      // First, try to get from cached active downtime
      // We need to check all machines, but we can also check pending operations
      final cachedActiveDowntime = await _getMachineIdFromDowntimeId(downtimeId);
      machineId = cachedActiveDowntime?['machineId'];
      
      // If we still don't have machineId, try to get it from the downtimeId itself
      // For temp IDs, we stored it in the startDowntime operation
      if (machineId == null && downtimeId.startsWith("temp_")) {
        final pendingOps = await _storage.getPendingOperations();
        for (var op in pendingOps) {
          if (op['type'] == 'startDowntime' && 
              (op['tempDowntimeId'] == downtimeId || op['id'] == downtimeId)) {
            machineId = op['machineId'] as String?;
            break;
          }
        }
      }
      
      // If still no machineId, try to extract from cached active downtime by checking all
      // For now, we'll queue it and let sync handle the machineId resolution
      await _storage.addPendingOperation({
        "type": "stopDowntime",
        "downtimeId": downtimeId,
        "endTime": endTime.toIso8601String(),
        if (machineId != null) "machineId": machineId,
      });
      
      // Clear cached active downtime optimistically if we found the machineId
      if (machineId != null) {
        await _storage.cacheActiveDowntime(machineId, null);
      }
      
      // Return updated downtime object for optimistic UI
      if (cachedActiveDowntime != null) {
        final updatedDowntime = Map<String, dynamic>.from(cachedActiveDowntime['downtime'] ?? {});
        updatedDowntime["endTime"] = endTime.toIso8601String();
        updatedDowntime["isActive"] = false;
        updatedDowntime["isPending"] = true;
        return updatedDowntime;
      }
      
      // If we can't find the downtime, still queue the operation
      // The sync service will handle it when online
      return {
        "_id": downtimeId,
        "endTime": endTime.toIso8601String(),
        "isActive": false,
        "isPending": true,
      };
    }
  }

  // Helper method to get machineId from downtimeId by checking cached data
  Future<Map<String, dynamic>?> _getMachineIdFromDowntimeId(String downtimeId) async {
    // Check if it's a temp ID (starts with "temp_")
    if (downtimeId.startsWith("temp_")) {
      // For temp IDs, we need to check pending operations
      final pendingOps = await _storage.getPendingOperations();
      for (var op in pendingOps) {
        // Check if this is the startDowntime operation that created this temp ID
        // The temp ID format is "temp_<timestamp>", and we stored it in the operation
        if (op['type'] == 'startDowntime') {
          // Check if the operation ID matches or if we can match by timestamp
          final opId = op['id'] as String?;
          if (opId == downtimeId || 
              (opId != null && downtimeId.contains(opId.split('_').last))) {
            return {
              'machineId': op['machineId'],
              'downtime': {
                '_id': downtimeId,
                'machine': op['machineId'],
                'startTime': op['startTime'],
                'reason': {
                  'categoryCode': op['categoryCode'],
                  'subReasonCode': op['subReasonCode'],
                },
              },
            };
          }
        }
      }
    } else {
      // For real downtime IDs, try to get from cached active downtime
      // We need to check all cached active downtimes
      // Since we don't have a direct lookup, we'll store machineId in the operation
    }
    
    return null;
  }


  String _handleError(DioException e) {
    debugPrint("DOWNTIME API ERROR: ${e.response?.data}");

    if (e.response != null) {
      return e.response?.data["message"] ?? "Server error";
    } else if (e.type == DioExceptionType.connectionTimeout) {
      return "Connection timeout. Please try again.";
    } else {
      return "Network error. Check your internet connection.";
    }
  }
}
