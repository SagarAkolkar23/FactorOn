import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';


class SecureStorage {
  static const _storage = FlutterSecureStorage();

  static Future<void> saveAuth({
    required String token,
    required String email,
    required String role,
  }) async {
    await _storage.write(key: "token", value: token);
    await _storage.write(key: "email", value: email);
    await _storage.write(key: "role", value: role);
    debugPrint("Auth: token in storage $token");

  }
  

  static Future<String?> getToken() => _storage.read(key: "token");

  static Future<String?> getRole() => _storage.read(key: "role");

  static Future<void> logout() async {
    await _storage.deleteAll();
  }
}
