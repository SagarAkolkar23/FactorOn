import 'package:frontend/common/models/AuthResponse.dart';
import 'package:frontend/core/api.dart';

class AuthService {
  Future<AuthResponse> login({
    required String email,
    required String password,
  }) async {
    final response = await DioClient.dio.post(
      "/auth/login",
      data: {"email": email, "password": password},
    );
    //debugPrint("Auth: token from backend, ${response.data.token}");

    return AuthResponse.fromJson(response.data);
  }

  Future<void> register({
    required String email,
    required String password,
    required String role,
  }) async {
    print("Entered register");
    await DioClient.dio.post(
      "/auth/register",
      data: {"email": email, "password": password, "role": role},
    );
  }
}
