import 'package:frontend/common/models/AuthResponse.dart';
import 'package:frontend/core/api.dart';

class AuthService {
  Future<AuthResponse> login({
    required String email,
    required String password,
    String? fcmToken,
  }) async {
    final response = await DioClient.dio.post(
      "/auth/login",
      data: {
        "email": email,
        "password": password,
        if (fcmToken != null) "fcmToken": fcmToken,
      },
    );

    return AuthResponse.fromJson(response.data);
  }

  Future<void> register({
    required String email,
    required String password,
    required String role,
  }) async {
    await DioClient.dio.post(
      "/auth/register",
      data: {"email": email, "password": password, "role": role},
    );
  }
}
