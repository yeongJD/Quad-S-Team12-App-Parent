import 'package:dio/dio.dart';

import '../../core/config/dio_config.dart';
import '../../core/models/result.dart';
import '../../core/network/api_error.dart';
import '../models/auth/auth_token.dart';
import 'auth_repository.dart';

/// Network-backed [AuthRepository].
///
/// Implements the auth endpoints per `docs/api/01-auth.md`:
/// - `POST /auth/login`
/// - `POST /auth/signup`
/// - `POST /auth/refresh`
/// - `PUT  /auth/password`
/// - `DELETE /auth/account`
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
        '/auth/login',
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
        '/auth/signup',
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
        '/auth/refresh',
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
      await _dio.put<dynamic>(
        '/auth/password',
        data: <String, dynamic>{
          'parentId': parentId,
          'currentPassword': currentPassword,
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
      await _dio.delete<dynamic>(
        '/auth/account',
        data: <String, dynamic>{'parentId': parentId},
      );
      return Result<void>.success(null);
    } on DioException catch (e) {
      return failureFromDioException<void>(e);
    }
  }

  @override
  Future<Result<void>> logout({String? refreshToken}) async {
    final Map<String, dynamic> body = <String, dynamic>{};
    if (refreshToken != null) {
      body['refreshToken'] = refreshToken;
    }
    try {
      await _dio.post<dynamic>('/auth/logout', data: body);
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
      accessToken: json['accessToken'] as String,
      refreshToken: json['refreshToken'] as String?,
      parentId: (json['parentId'] as String?) ?? '',
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
