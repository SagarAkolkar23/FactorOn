import 'dart:io';
import 'package:dio/dio.dart';
import 'package:frontend/core/api.dart';
import 'package:frontend/core/connectivity_service.dart';
import 'package:frontend/supervisor/models/dashboardStatsModel.dart';
import 'package:frontend/supervisor/models/downtimeModel.dart';
import 'package:path_provider/path_provider.dart';

class SupervisorService {
  final Dio _dio = DioClient.dio;
  final ConnectivityService _connectivity = ConnectivityService();

  Future<DashboardStatsModel> getDashboardStats() async {
    final isOnline = await _connectivity.checkConnectivity();

    if (isOnline) {
      try {
        final response = await _dio.get("/supervisor/dashboard/stats");
        return DashboardStatsModel.fromJson(response.data);
      } on DioException catch (e) {
        throw _handleError(e);
      }
    } else {
      throw "No internet connection. Please connect to view dashboard.";
    }
  }

  Future<List<DowntimeModel>> getAllDowntimes({
    int page = 1,
    int limit = 20,
    String? machineId,
    bool? isActive,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final isOnline = await _connectivity.checkConnectivity();

    if (isOnline) {
      try {
        final queryParams = <String, dynamic>{
          "page": page,
          "limit": limit,
        };

        if (machineId != null) queryParams["machineId"] = machineId;
        if (isActive != null) queryParams["isActive"] = isActive.toString();
        if (startDate != null) {
          queryParams["startDate"] = startDate.toIso8601String();
        }
        if (endDate != null) {
          queryParams["endDate"] = endDate.toIso8601String();
        }

        final response = await _dio.get(
          "/supervisor/downtimes",
          queryParameters: queryParams,
        );

        final List<dynamic> downtimesJson = response.data["downtimes"];
        return downtimesJson
            .map((json) => DowntimeModel.fromJson(json))
            .toList();
      } on DioException catch (e) {
        throw _handleError(e);
      }
    } else {
      throw "No internet connection. Please connect to view downtimes.";
    }
  }

  Future<String> downloadDowntimeReport({
    String? machineId,
    bool? isActive,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final isOnline = await _connectivity.checkConnectivity();

    if (!isOnline) {
      throw "No internet connection. Please connect to download report.";
    }

    try {
      // Build query parameters
      final queryParams = <String, dynamic>{};
      if (machineId != null) queryParams["machineId"] = machineId;
      if (isActive != null) queryParams["isActive"] = isActive.toString();
      if (startDate != null) {
        queryParams["startDate"] = startDate.toIso8601String();
      }
      if (endDate != null) {
        queryParams["endDate"] = endDate.toIso8601String();
      }

      // Get download directory
      Directory downloadDir;
      if (Platform.isAndroid) {
        // For Android, try to use external storage directory first
        // This works without special permissions on Android 10+
        final externalDir = await getExternalStorageDirectory();
        if (externalDir != null) {
          // Use a Downloads subdirectory in the app's external storage
          downloadDir = Directory('${externalDir.path}/Download');
          if (!await downloadDir.exists()) {
            await downloadDir.create(recursive: true);
          }
        } else {
          // Fallback to app documents directory
          downloadDir = await getApplicationDocumentsDirectory();
        }
      } else if (Platform.isIOS) {
        downloadDir = await getApplicationDocumentsDirectory();
      } else {
        downloadDir = await getApplicationDocumentsDirectory();
      }

      // Generate filename with timestamp
      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-').split('.')[0];
      final filename = 'downtime-report-$timestamp.csv';
      final filePath = '${downloadDir.path}/$filename';

      // Download the file
      await _dio.download(
        "/supervisor/downtimes/report",
        filePath,
        queryParameters: queryParams.isEmpty ? null : queryParams,
        options: Options(
          responseType: ResponseType.bytes,
          followRedirects: false,
          validateStatus: (status) => status! < 500,
        ),
      );

      return filePath;
    } on DioException catch (e) {
      throw _handleError(e);
    } catch (e) {
      throw e.toString();
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

