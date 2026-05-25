import 'package:dio/dio.dart';

import '../models/result.dart';

/// Standard error payload shape per `docs/api/00-overview.md`:
/// `{ "error": { "code": String, "message": String, "details": object? } }`
///
/// Repositories normally consume failures via [failureFromDioException]; this
/// class is exposed for the rare case a caller wants the structured
/// representation (e.g. for matching `code` against UI-specific switches).
class ApiError {
  const ApiError({
    required this.message,
    this.code,
    this.cause,
  });

  /// Human-readable Korean message — safe to surface in the UI.
  final String message;

  /// Stable SCREAMING_SNAKE_CASE identifier (e.g. `INVALID_CREDENTIALS`) when
  /// the server provided one; `null` when only an HTTP status was available.
  final String? code;

  /// Original [DioException] (or other underlying cause), retained for
  /// diagnostics. Pages should not introspect this.
  final Object? cause;
}

Map<String, dynamic>? _extractErrorPayload(Response<dynamic>? response) {
  final dynamic data = response?.data;
  if (data is! Map) {
    return null;
  }
  final dynamic error = data['error'];
  if (error is! Map) {
    return null;
  }
  return Map<String, dynamic>.from(error);
}

abstract final class _GenericMessages {
  static const String network = '네트워크 연결을 확인해 주세요.';
  static const String expiredSession = '로그인이 만료되었어요. 다시 로그인해 주세요.';
  static const String forbidden = '권한이 없어요.';
  static const String notFound = '찾을 수 없어요.';
  static const String serverError = '잠시 후 다시 시도해 주세요.';
  static const String unknown = '요청을 처리할 수 없어요.';
}

/// Converts a [DioException] into a typed [Failure] carrying a user-facing
/// Korean message. Prefers the server-supplied `error.message` when present;
/// otherwise falls back to a status-code-based default per the contract.
Failure<T> failureFromDioException<T>(DioException e) {
  switch (e.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.receiveTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.connectionError:
      return Failure<T>(_GenericMessages.network, cause: e);
    case DioExceptionType.cancel:
    case DioExceptionType.badCertificate:
    case DioExceptionType.badResponse:
    case DioExceptionType.unknown:
      break;
  }

  final Response<dynamic>? response = e.response;
  final int? statusCode = response?.statusCode;

  final Map<String, dynamic>? errorMap = _extractErrorPayload(response);
  if (errorMap != null) {
    final String? message = errorMap['message'] as String?;
    final String? code = errorMap['code'] as String?;
    if (message != null && message.isNotEmpty) {
      return Failure<T>(message, cause: code ?? statusCode?.toString());
    }
  }

  if (statusCode == null) {
    return Failure<T>(_GenericMessages.unknown, cause: e);
  }
  if (statusCode == 401) {
    return Failure<T>(_GenericMessages.expiredSession, cause: '401');
  }
  if (statusCode == 403) {
    return Failure<T>(_GenericMessages.forbidden, cause: '403');
  }
  if (statusCode == 404) {
    return Failure<T>(_GenericMessages.notFound, cause: '404');
  }
  if (statusCode >= 500 && statusCode < 600) {
    return Failure<T>(_GenericMessages.serverError, cause: '$statusCode');
  }
  return Failure<T>(_GenericMessages.unknown, cause: '$statusCode');
}

/// Returns the `error.code` from a [DioException] response body, or `null` if
/// the body isn't in contract shape. Repositories use this to map specific
/// codes (e.g. `INVALID_CREDENTIALS`) to UI-anchored failure messages BEFORE
/// falling back to [failureFromDioException].
String? errorCodeOf(DioException e) {
  final Map<String, dynamic>? errorMap = _extractErrorPayload(e.response);
  return errorMap?['code'] as String?;
}
