import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

class OfflineStorage {
  static final OfflineStorage _instance = OfflineStorage._internal();
  factory OfflineStorage() => _instance;
  OfflineStorage._internal();

  static const String _machinesKey = 'cached_machines';
  static const String _downtimesKey = 'cached_downtimes';
  static const String _activeDowntimeKey = 'cached_active_downtime_';
  static const String _lastSyncKey = 'last_sync_timestamp';
  static const String _pendingOperationsKey = 'pending_operations';

  // Cache machines list
  Future<void> cacheMachines(List<Map<String, dynamic>> machines) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = jsonEncode(machines);
      await prefs.setString(_machinesKey, jsonString);
      await prefs.setString(_lastSyncKey, DateTime.now().toIso8601String());
      debugPrint("💾 Cached ${machines.length} machines");
    } catch (e) {
      debugPrint("❌ Error caching machines: $e");
    }
  }

  // Get cached machines
  Future<List<Map<String, dynamic>>?> getCachedMachines() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_machinesKey);
      if (jsonString != null) {
        final List<dynamic> decoded = jsonDecode(jsonString);
        return decoded.cast<Map<String, dynamic>>();
      }
    } catch (e) {
      debugPrint("❌ Error reading cached machines: $e");
    }
    return null;
  }

  // Cache downtimes list
  Future<void> cacheDowntimes(List<Map<String, dynamic>> downtimes) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = jsonEncode(downtimes);
      await prefs.setString(_downtimesKey, jsonString);
      debugPrint("💾 Cached ${downtimes.length} downtimes");
    } catch (e) {
      debugPrint("❌ Error caching downtimes: $e");
    }
  }

  // Get cached downtimes
  Future<List<Map<String, dynamic>>?> getCachedDowntimes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_downtimesKey);
      if (jsonString != null) {
        final List<dynamic> decoded = jsonDecode(jsonString);
        return decoded.cast<Map<String, dynamic>>();
      }
    } catch (e) {
      debugPrint("❌ Error reading cached downtimes: $e");
    }
    return null;
  }

  // Cache active downtime for a specific machine
  Future<void> cacheActiveDowntime(
    String machineId,
    Map<String, dynamic>? downtime,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '$_activeDowntimeKey$machineId';
      if (downtime != null) {
        await prefs.setString(key, jsonEncode(downtime));
      } else {
        await prefs.remove(key);
      }
    } catch (e) {
      debugPrint("❌ Error caching active downtime: $e");
    }
  }

  // Get cached active downtime for a specific machine
  Future<Map<String, dynamic>?> getCachedActiveDowntime(String machineId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '$_activeDowntimeKey$machineId';
      final jsonString = prefs.getString(key);
      if (jsonString != null) {
        return jsonDecode(jsonString) as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint("❌ Error reading cached active downtime: $e");
    }
    return null;
  }

  // Add pending operation to queue
  Future<void> addPendingOperation(Map<String, dynamic> operation) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final operations = await getPendingOperations();
      
      // Generate unique ID if not provided
      final operationId = operation['id'] ?? 
          '${operation['type']}_${DateTime.now().millisecondsSinceEpoch}';
      
      operations.add({
        ...operation,
        'id': operationId,
        'timestamp': DateTime.now().toIso8601String(),
        'status': 'pending', // pending, syncing, completed, failed
      });
      
      await prefs.setString(_pendingOperationsKey, jsonEncode(operations));
      debugPrint("📝 Added pending operation: ${operation['type']} (ID: $operationId)");
    } catch (e) {
      debugPrint("❌ Error adding pending operation: $e");
    }
  }

  // Get all pending operations
  Future<List<Map<String, dynamic>>> getPendingOperations() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_pendingOperationsKey);
      if (jsonString != null) {
        final List<dynamic> decoded = jsonDecode(jsonString);
        return decoded.cast<Map<String, dynamic>>();
      }
    } catch (e) {
      debugPrint("❌ Error reading pending operations: $e");
    }
    return [];
  }

  // Remove pending operation after successful sync
  Future<void> removePendingOperation(String operationId) async {
    try {
      final operations = await getPendingOperations();
      operations.removeWhere((op) => op['id'] == operationId);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_pendingOperationsKey, jsonEncode(operations));
      debugPrint("✅ Removed pending operation: $operationId");
    } catch (e) {
      debugPrint("❌ Error removing pending operation: $e");
    }
  }

  // Clear all pending operations
  Future<void> clearPendingOperations() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_pendingOperationsKey);
      debugPrint("🧹 Cleared all pending operations");
    } catch (e) {
      debugPrint("❌ Error clearing pending operations: $e");
    }
  }

  // Get last sync timestamp
  Future<DateTime?> getLastSyncTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestamp = prefs.getString(_lastSyncKey);
      if (timestamp != null) {
        return DateTime.parse(timestamp);
      }
    } catch (e) {
      debugPrint("❌ Error reading last sync time: $e");
    }
    return null;
  }

  // Clear all cached data
  Future<void> clearAllCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_machinesKey);
      await prefs.remove(_downtimesKey);
      await prefs.remove(_lastSyncKey);
      // Clear all active downtime keys
      final keys = prefs.getKeys().where((k) => k.startsWith(_activeDowntimeKey));
      for (final key in keys) {
        await prefs.remove(key);
      }
      debugPrint("🧹 Cleared all cached data");
    } catch (e) {
      debugPrint("❌ Error clearing cache: $e");
    }
  }
}

