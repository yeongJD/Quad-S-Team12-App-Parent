import 'package:dio/dio.dart';

import '../auth/auth_session.dart';
import 'environment.dart';

/// Factory for the app-wide [Dio] HTTP client.
///
/// Wires two interceptors:
/// 1. Request: inject `Authorization: Bearer <accessToken>` when available.
/// 2. Error: on `401`, attempt one `/auth/token/refresh` rotation and retry the
///    original request transparently. On refresh failure, tokens are cleared
///    and the original error propagates to the caller — pages then route the
///    user back to login per the standard `Result.failure` flow.
class DioConfig {
  const DioConfig._();

  static const String _kRetriedFlag = '__bridge_p_refresh_retried__';
  static const String _kRefreshPath = '/auth/token/refresh';

  static Dio create({EnvironmentConfig? overrideConfig}) {
    final EnvironmentConfig env = overrideConfig ?? currentEnvironment;
    final Dio dio = Dio(
      BaseOptions(
        baseUrl: env.baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 15),
        contentType: 'application/json',
        responseType: ResponseType.json,
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest:
            (RequestOptions options, RequestInterceptorHandler handler) async {
              final String? token = await AuthSession.accessToken();
              if (token != null && token.isNotEmpty) {
                options.headers['Authorization'] = 'Bearer $token';
              }
              handler.next(options);
            },
        onResponse:
            (Response<dynamic> response, ResponseInterceptorHandler handler) {
              final dynamic body = response.data;
              if (body is Map && body.containsKey('isSuccess')) {
                response.data = body['data'];
              }
              handler.next(response);
            },
        onError: (DioException error, ErrorInterceptorHandler handler) async {
          final dynamic body = error.response?.data;
          if (body is Map &&
              !body.containsKey('error') &&
              body.containsKey('code') &&
              body.containsKey('message')) {
            final Object? detail = body['data'];
            final String? detailMessage = detail is String && detail.isNotEmpty
                ? detail
                : null;
            error.response!.data = <String, dynamic>{
              'error': <String, dynamic>{
                'code': body['code'],
                'message': detailMessage ?? body['message'],
              },
            };
          }
          await _handleError(
            dio: dio,
            baseUrl: env.baseUrl,
            error: error,
            handler: handler,
          );
        },
      ),
    );

    return dio;
  }

  static Future<void> _handleError({
    required Dio dio,
    required String baseUrl,
    required DioException error,
    required ErrorInterceptorHandler handler,
  }) async {
    final RequestOptions original = error.requestOptions;
    final bool isUnauthorized = error.response?.statusCode == 401;
    final bool isRefreshCall = original.path.endsWith(_kRefreshPath);
    final bool alreadyRetried = original.extra[_kRetriedFlag] == true;

    if (!isUnauthorized || isRefreshCall || alreadyRetried) {
      handler.next(error);
      return;
    }

    final String? currentRefreshToken = await AuthSession.refreshToken();
    if (currentRefreshToken == null || currentRefreshToken.isEmpty) {
      await _forceLogout();
      handler.next(error);
      return;
    }

    final Dio refreshClient = Dio(BaseOptions(baseUrl: baseUrl));
    final Response<dynamic> refreshResponse;
    try {
      refreshResponse = await refreshClient.post<dynamic>(
        _kRefreshPath,
        data: <String, dynamic>{'refreshToken': currentRefreshToken},
      );
    } on DioException {
      await _forceLogout();
      handler.next(error);
      return;
    } finally {
      refreshClient.close(force: true);
    }

    final dynamic body = refreshResponse.data;
    if (body is! Map) {
      await _forceLogout();
      handler.next(error);
      return;
    }
    final Map<dynamic, dynamic> data = body['data'] is Map
        ? body['data'] as Map
        : body;
    final String? newAccess = data['accessToken'] as String?;
    final String? newRefresh = data['refreshToken'] as String?;
    if (newAccess == null || newAccess.isEmpty) {
      await _forceLogout();
      handler.next(error);
      return;
    }
    await AuthSession.saveTokens(
      accessToken: newAccess,
      refreshToken: newRefresh,
    );

    final Options retryOptions = Options(
      method: original.method,
      headers: <String, dynamic>{
        ...original.headers,
        'Authorization': 'Bearer $newAccess',
      },
      contentType: original.contentType,
      responseType: original.responseType,
      sendTimeout: original.sendTimeout,
      receiveTimeout: original.receiveTimeout,
      extra: <String, dynamic>{...original.extra, _kRetriedFlag: true},
    );

    try {
      final Response<dynamic> retried = await dio.request<dynamic>(
        original.path,
        data: original.data,
        queryParameters: original.queryParameters,
        options: retryOptions,
      );
      handler.resolve(retried);
    } on DioException catch (retryError) {
      handler.next(retryError);
    }
  }

  static Future<void> _forceLogout() async {
    await AuthSession.clearTokens();
    await AuthSession.logout();
  }
}
