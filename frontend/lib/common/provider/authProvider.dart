import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/common/models/AuthResponse.dart';
import 'package:frontend/common/services/authService.dart';
import 'package:frontend/core/secureStorage.dart';
import 'package:frontend/core/fcm_service.dart';

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

final authProvider = AsyncNotifierProvider<AuthNotifier, AuthResponse?>(
  AuthNotifier.new,
);

class AuthNotifier extends AsyncNotifier<AuthResponse?> {
  @override
  Future<AuthResponse?> build() async {
    return null;
  }

  Future<void> login({required String email, required String password}) async {
    state = const AsyncLoading();

    try {
      final fcmToken = await FCMService.getToken();

      final response = await ref
          .read(authServiceProvider)
          .login(email: email, password: password, fcmToken: fcmToken);

      await SecureStorage.saveAuth(
        token: response.token,
        email: response.email,
        role: response.role,
      );

      state = AsyncData(response);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> register({
    required String email,
    required String password,
    required String role,
  }) async {
    state = const AsyncLoading();

    try {
      await ref
          .read(authServiceProvider)
          .register(email: email, password: password, role: role);

      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}
