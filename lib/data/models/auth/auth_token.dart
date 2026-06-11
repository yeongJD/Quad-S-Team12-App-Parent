/// Authentication token bundle returned from a successful login or signup.
///
/// Carries the [accessToken] (and optional [refreshToken]) used by the Dio
/// auth interceptor, plus the resolved [parentId] / [email] / [name] that
/// the page layer persists into [AuthSession] alongside the token pair.
class AuthToken {
  const AuthToken({
    required this.accessToken,
    this.refreshToken,
    required this.parentId,
    required this.email,
    required this.name,
  });

  final String accessToken;
  final String? refreshToken;
  final String parentId;
  final String email;
  final String name;

  factory AuthToken.fromJson(Map<String, dynamic> json) => AuthToken(
        accessToken: json['accessToken'] as String,
        refreshToken: json['refreshToken'] as String?,
        parentId: json['parentId'] as String,
        email: json['email'] as String,
        name: json['name'] as String,
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'accessToken': accessToken,
        'refreshToken': refreshToken,
        'parentId': parentId,
        'email': email,
        'name': name,
      };
}
