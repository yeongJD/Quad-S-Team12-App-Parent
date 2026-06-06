import 'package:dio/dio.dart';

import '../../core/auth/auth_session.dart';
import '../../core/config/dio_config.dart';
import '../../core/models/result.dart';
import '../../core/network/api_error.dart';
import '../models/auth/auth_token.dart';
import 'auth_repository.dart';

/// Network-backed [AuthRepository].
///
/// Implements the auth endpoints per `docs/api/01-auth.md`:
/// - `POST /auth/parent/login`
/// - `POST /auth/parent/signup`
/// - `POST /auth/token/refresh`
/// - `PATCH /api/v1/members/password`
/// - `DELETE /api/v1/members`
/// - `POST /auth/logout`
///
/// Each method wraps the Dio call in a try/catch that funnels [DioException]s
/// through [failureFromDioException] for consistent Korean error messages.
/// Known `error.code` values (e.g. `INVALID_CREDENTIALS`) are pre-mapped to
/// canonical [AuthFailureMessages] strings so page-level switches keep
/// working without substring matching.
class ApiAuthRepository implements AuthRepository {
  ApiAuthRepository({Dio? dio}) : _dio = dio ?? DioConfig.create();

  final Dio _dio;

  @override
  Future<Result<AuthToken>> login({
    required String email,
    required String password,
  }) async {
    try {
      final Response<dynamic> response = await _dio.post<dynamic>(
        '/auth/parent/login',
        data: <String, dynamic>{
          'email': email,
          'password': password,
        },
      );
      final AuthToken token = _parseTokenResponse(
        response.data,
        fallbackEmail: email,
      );
      return Result<AuthToken>.success(token);
    } on DioException catch (e) {
      return _mapAuthLoginError(e);
    }
  }

  @override
  Future<Result<AuthToken>> signup({
    required String email,
    required String name,
    required String password,
  }) async {
    try {
      final Response<dynamic> response = await _dio.post<dynamic>(
        '/auth/parent/signup',
        data: <String, dynamic>{
          'email': email,
          'name': name,
          'password': password,
        },
      );
      final AuthToken token = _parseTokenResponse(
        response.data,
        fallbackEmail: email,
      );
      return Result<AuthToken>.success(token);
    } on DioException catch (e) {
      return _mapAuthSignupError(e);
    }
  }

  @override
  Future<Result<AuthToken>> refreshToken(String refreshToken) async {
    try {
      final Response<dynamic> response = await _dio.post<dynamic>(
        '/auth/token/refresh',
        data: <String, dynamic>{'refreshToken': refreshToken},
      );
      final AuthToken token = _parseTokenResponse(
        response.data,
        fallbackEmail: '',
      );
      return Result<AuthToken>.success(token);
    } on DioException catch (e) {
      return failureFromDioException<AuthToken>(e);
    }
  }

  @override
  Future<Result<void>> changePassword({
    required String parentId,
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      await _dio.patch<dynamic>(
        '/api/v1/members/password',
        data: <String, dynamic>{
          'oldPassword': currentPassword,
          'newPassword': newPassword,
        },
      );
      return Result<void>.success(null);
    } on DioException catch (e) {
      final String? code = errorCodeOf(e);
      if (code == 'INVALID_CREDENTIALS' || code == 'PASSWORD_MISMATCH') {
        return Result<void>.failure(
          AuthFailureMessages.passwordMismatch,
          cause: code,
        );
      }
      return failureFromDioException<void>(e);
    }
  }

  @override
  Future<Result<void>> deleteAccount({
    required String parentId,
  }) async {
    try {
      await _dio.delete<dynamic>('/api/v1/members');
      return Result<void>.success(null);
    } on DioException catch (e) {
      return failureFromDioException<void>(e);
    }
  }

  @override
  Future<Result<void>> logout({String? refreshToken}) async {
    String? token = refreshToken;
    if (token == null || token.isEmpty) {
      token = await AuthSession.refreshToken();
    }
    if (token == null || token.isEmpty) {
      // Backend requires a non-blank refreshToken; with none available we
      // skip the remote call and let the caller perform local cleanup.
      return Result<void>.success(null);
    }
    try {
      await _dio.post<dynamic>(
        '/auth/logout',
        data: <String, dynamic>{'refreshToken': token},
      );
      return Result<void>.success(null);
    } on DioException catch (e) {
      return failureFromDioException<void>(e);
    }
  }

  /// Tolerant parser: the `/auth/refresh` response shape is
  /// `{ accessToken, refreshToken }` (no parentId / email / name fields),
  /// while login/signup include the full profile. We accept both and
  /// substitute placeholder values when missing so refresh callers can
  /// preserve the previously stored session.
  AuthToken _parseTokenResponse(
    dynamic data, {
    required String fallbackEmail,
  }) {
    if (data is! Map) {
      throw const FormatException('Auth response was not a JSON object.');
    }
    final Map<String, dynamic> json = Map<String, dynamic>.from(data);
    return AuthToken(
      // Signup does not auto-login: the backend returns an empty body (no
      // tokens), so accept a missing accessToken as an empty string instead of
      // a hard cast that would throw. The signup page routes such tokenless
      // results to /login.
      accessToken: (json['accessToken'] as String?) ?? '',
      refreshToken: json['refreshToken'] as String?,
      parentId: json['memberId']?.toString() ??
          (json['parentId'] as String?) ??
          '',
      email: (json['email'] as String?) ?? fallbackEmail,
      name: (json['name'] as String?) ?? '',
    );
  }

  Failure<AuthToken> _mapAuthLoginError(DioException e) {
    final String? code = errorCodeOf(e);
    if (code == 'INVALID_CREDENTIALS') {
      return Failure<AuthToken>(
        AuthFailureMessages.wrongPassword,
        cause: code,
      );
    }
    if (code == 'USER_NOT_FOUND') {
      return Failure<AuthToken>(
        AuthFailureMessages.unknownEmail,
        cause: code,
      );
    }
    if (code == 'ACCOUNT_DORMANT') {
      return Failure<AuthToken>(
        AuthFailureMessages.accountDormant,
        cause: code,
      );
    }
    return failureFromDioException<AuthToken>(e);
  }

  Failure<AuthToken> _mapAuthSignupError(DioException e) {
    final String? code = errorCodeOf(e);
    if (code == 'DUPLICATE_EMAIL') {
      return Failure<AuthToken>(
        AuthFailureMessages.duplicatedEmail,
        cause: code,
      );
    }
    return failureFromDioException<AuthToken>(e);
  }
}
