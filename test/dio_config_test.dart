import 'package:bridge_p/core/auth/auth_session.dart';
import 'package:bridge_p/core/config/dio_config.dart';
import 'package:bridge_p/core/config/environment.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  const EnvironmentConfig testEnv = EnvironmentConfig(
    environment: AppEnvironment.development,
    baseUrl: 'https://test.local',
    useMocks: false,
  );

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('does not attach a stale bearer token to auth endpoints', () async {
    await AuthSession.saveTokens(
      accessToken: 'stale-access',
      refreshToken: 'stale-refresh',
    );
    final Dio dio = DioConfig.create(overrideConfig: testEnv);
    final List<RequestOptions> capturedRequests = <RequestOptions>[];
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (RequestOptions options, RequestInterceptorHandler handler) {
          capturedRequests.add(options);
          handler.resolve(
            Response<dynamic>(
              requestOptions: options,
              statusCode: 200,
              data: <String, dynamic>{},
            ),
          );
        },
      ),
    );

    await dio.post<dynamic>('/auth/parent/login');
    await dio.post<dynamic>('/auth/parent/signup');
    await dio.post<dynamic>('/auth/token/refresh');
    await dio.post<dynamic>('/auth/logout');

    expect(capturedRequests, hasLength(4));
    for (final RequestOptions request in capturedRequests) {
      expect(request.headers['Authorization'], isNull);
    }
  });

  test('attaches the bearer token to authenticated API endpoints', () async {
    await AuthSession.saveTokens(
      accessToken: 'current-access',
      refreshToken: 'current-refresh',
    );
    final Dio dio = DioConfig.create(overrideConfig: testEnv);
    RequestOptions? capturedRequest;
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (RequestOptions options, RequestInterceptorHandler handler) {
          capturedRequest = options;
          handler.resolve(
            Response<dynamic>(
              requestOptions: options,
              statusCode: 200,
              data: <String, dynamic>{},
            ),
          );
        },
      ),
    );

    await dio.get<dynamic>('/api/v1/parents/children');

    expect(capturedRequest?.headers['Authorization'], 'Bearer current-access');
  });
}
