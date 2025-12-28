/// This model represents the response returned by backend on LOGIN
/// Backend response:
/// {
///   success: true,
///   token: "...",
///   user: {
///     email: "...",
///     role: "operator"
///   }
/// }
class AuthResponse {
  final String token;
  final String email;
  final String role;

  AuthResponse({
    required this.token,
    required this.email,
    required this.role,
  });

  /// Factory constructor converts JSON → Dart object
  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      token: json["token"],
      email: json["user"]["email"],
      role: json["user"]["role"],
    );
  }
}
