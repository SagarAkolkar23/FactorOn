import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:frontend/core/secureStorage.dart';


class DioClient {
  static final Dio dio = Dio(
    BaseOptions(
      baseUrl: "http://10.17.185.212:8000/API",
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ),
  );


  static void initialize() {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await SecureStorage.getToken();
          debugPrint("Auth: token in bearer = $token");

          if (token != null) {
            options.headers["Authorization"] = "Bearer $token";
          }

          print("➡️ ${options.method} ${options.path}");
          handler.next(options);
        },
        onError: (error, handler) {
          print("❌ API Error: ${error.message}");
          handler.next(error);
        },
      ),
    );
  }
}
