import 'package:frontend/core/connectivity_service.dart';
import 'package:frontend/core/offline_storage.dart';
import 'package:frontend/operator/services/machineService.dart';
import 'package:frontend/operator/services/downtimeService.dart';
import 'package:flutter/foundation.dart';

class SyncService {
  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;
  SyncService._internal();

  final ConnectivityService _connectivity = ConnectivityService();
  final OfflineStorage _storage = OfflineStorage();
  bool _isSyncing = false;

  bool get isSyncing => _isSyncing;

  /// Initialize sync service and listen for connectivity changes
  Future<void> initialize({
    MachineService? machineService,
    DowntimeService? downtimeService,
  }) async {
    // Listen to connectivity changes
    _connectivity.connectionStream.listen((isConnected) {
      if (isConnected && !_isSyncing) {
        debugPrint("🔄 Connection restored, starting sync...");
        syncPendingOperations(
          machineService: machineService,
          downtimeService: downtimeService,
        );
      }
    });
  }

  /// Sync all pending operations when connection is restored
  Future<void> syncPendingOperations({
    MachineService? machineService,
    DowntimeService? downtimeService,
  }) async {
    if (_isSyncing) {
      debugPrint("⏳ Sync already in progress");
      return;
    }

    final isOnline = await _connectivity.checkConnectivity();
    if (!isOnline) {
      debugPrint("❌ Still offline, cannot sync");
      return;
    }

    _isSyncing = true;
    debugPrint("🔄 Starting sync of pending operations...");

    try {
      final pendingOps = await _storage.getPendingOperations();
      if (pendingOps.isEmpty) {
        debugPrint("✅ No pending operations to sync");
        _isSyncing = false;
        return;
      }

      debugPrint("📋 Found ${pendingOps.length} pending operations");

      final failedOps = <Map<String, dynamic>>[];

      for (final op in pendingOps) {
        try {
          await _processOperation(
            op,
            machineService: machineService,
            downtimeService: downtimeService,
          );
          
          // Remove successfully synced operation
          await _storage.removePendingOperation(op['id']);
          debugPrint("✅ Synced operation: ${op['type']} (${op['id']})");
        } catch (e) {
          debugPrint("❌ Failed to sync operation ${op['id']}: $e");
          failedOps.add(op);
        }
      }

      if (failedOps.isNotEmpty) {
        debugPrint("⚠️ ${failedOps.length} operations failed to sync");
      } else {
        debugPrint("✅ All operations synced successfully");
      }
    } catch (e) {
      debugPrint("❌ Error during sync: $e");
    } finally {
      _isSyncing = false;
    }
  }

  Future<void> _processOperation(
    Map<String, dynamic> operation, {
    MachineService? machineService,
    DowntimeService? downtimeService,
  }) async {
    final type = operation['type'] as String;

    switch (type) {
      case 'addMachine':
        if (machineService != null) {
          final data = operation['data'] as Map<String, dynamic>;
          await machineService.addMachine(
            machineId: data['machineId'] as String,
            name: data['name'] as String,
            type: data['type'] as String,
            details: data['details'] as Map<String, dynamic>?,
            lastMaintenance: data['maintenance']?['lastMaintenance'] != null
                ? DateTime.parse(data['maintenance']['lastMaintenance'])
                : null,
            maintenanceNotes: data['maintenance']?['notes'] as String?,
          );
        }
        break;

      case 'updateMachine':
        if (machineService != null) {
          final id = operation['id'] as String;
          final data = operation['data'] as Map<String, dynamic>;
          await machineService.updateMachine(
            id: id,
            name: data['name'] as String?,
            type: data['type'] as String?,
            status: data['status'] as String?,
            details: data['details'] as Map<String, dynamic>?,
            nextMaintenance: data['maintenance']?['lastMaintenance'] != null
                ? DateTime.parse(data['maintenance']['lastMaintenance'])
                : null,
            maintenanceNotes: data['maintenance']?['notes'] as String?,
          );
        }
        break;

      case 'deleteMachine':
        if (machineService != null) {
          final id = operation['id'] as String;
          await machineService.deleteMachine(id);
        }
        break;

      case 'startDowntime':
        if (downtimeService != null) {
          final result = await downtimeService.startDowntime(
            machineId: operation['machineId'] as String,
            startTime: DateTime.parse(operation['startTime'] as String),
            categoryCode: operation['categoryCode'] as String,
            subReasonCode: operation['subReasonCode'] as String,
            photo: null, // Photo cannot be synced when offline
          );
          
          debugPrint("✅ Started downtime: ${result['_id']}");
          
          // Update cached active downtime with the real server response
          final machineId = operation['machineId'] as String;
          await _storage.cacheActiveDowntime(machineId, result);
        }
        break;

      case 'stopDowntime':
        if (downtimeService != null) {
          final downtimeId = operation['downtimeId'] as String;
          final endTime = DateTime.parse(operation['endTime'] as String);
          
          // If downtimeId is a temp ID, we need to find the real downtime ID
          // by checking if there's a corresponding startDowntime operation
          String actualDowntimeId = downtimeId;
          
          if (downtimeId.startsWith('temp_')) {
            // Find the corresponding startDowntime operation
            final allPendingOps = await _storage.getPendingOperations();
            Map<String, dynamic>? startOp;
            
            // Look for a startDowntime operation with matching temp ID
            for (var op in allPendingOps) {
              if (op['type'] == 'startDowntime') {
                final tempId = op['tempDowntimeId'] as String?;
                if (tempId == downtimeId || op['id'] == downtimeId) {
                  startOp = op;
                  break;
                }
              }
            }
            
            // If we found a start operation, we need to sync it first
            // Then get the real downtime ID from the server response
            if (startOp != null) {
              debugPrint("🔄 Found matching startDowntime operation, syncing it first...");
              
              // Sync the start operation first
              await _processOperation(
                startOp,
                machineService: machineService,
                downtimeService: downtimeService,
              );
              
              // Remove the start operation from queue since we just synced it
              await _storage.removePendingOperation(startOp['id']);
              
              // After starting, get the active downtime to get the real ID
              final machineId = startOp['machineId'] as String;
              final activeDowntime = await downtimeService.getActiveDowntime(machineId);
              
              if (activeDowntime != null && activeDowntime['_id'] != null) {
                actualDowntimeId = activeDowntime['_id'] as String;
                debugPrint("✅ Got real downtime ID: $actualDowntimeId");
              } else {
                throw "Could not find active downtime after syncing start operation";
              }
            } else {
              // If no matching start operation found, try to use machineId from operation
              final machineId = operation['machineId'] as String?;
              if (machineId != null) {
                final activeDowntime = await downtimeService.getActiveDowntime(machineId);
                if (activeDowntime != null && activeDowntime['_id'] != null) {
                  actualDowntimeId = activeDowntime['_id'] as String;
                }
              }
            }
          }
          
          // Now stop the downtime with the actual ID
          await downtimeService.stopDowntime(
            downtimeId: actualDowntimeId,
            endTime: endTime,
          );
        }
        break;

      default:
        debugPrint("⚠️ Unknown operation type: $type");
    }
  }

  /// Manually trigger sync (can be called from UI)
  Future<void> manualSync({
    MachineService? machineService,
    DowntimeService? downtimeService,
  }) async {
    await syncPendingOperations(
      machineService: machineService,
      downtimeService: downtimeService,
    );
  }
}

