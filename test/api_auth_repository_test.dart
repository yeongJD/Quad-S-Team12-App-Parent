import 'package:bridge_p/core/models/result.dart';
import 'package:bridge_p/data/models/auth/auth_token.dart';
import 'package:bridge_p/data/repositories/api_auth_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ApiAuthRepository', () {
    test('login parses AWS ApiResponse-wrapped auth response', () async {
      final Dio dio = Dio(BaseOptions(baseUrl: 'https://test.local'));
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest:
              (RequestOptions options, RequestInterceptorHandler handler) {
                handler.resolve(
                  Response<dynamic>(
                    requestOptions: options,
                    statusCode: 200,
                    data: <String, dynamic>{
                      'isSuccess': true,
                      'code': 'PARENT200_LOGIN',
                      'message': '부모 로그인 성공',
                      'data': <String, dynamic>{
                        'accessToken': 'access-1',
                        'refreshToken': 'refresh-1',
                        'memberId': 7,
                        'name': '박부모',
                      },
                    },
                  ),
                );
              },
        ),
      );
      final ApiAuthRepository repository = ApiAuthRepository(dio: dio);

      final Result<AuthToken> result = await repository.login(
        email: 'parent@test.com',
        password: 'Password123!',
      );

      expect(result, isA<Success<AuthToken>>());
      final AuthToken token = (result as Success<AuthToken>).data;
      expect(token.accessToken, 'access-1');
      expect(token.refreshToken, 'refresh-1');
      expect(token.parentId, '7');
      expect(token.email, 'parent@test.com');
      expect(token.name, '박부모');
    });

    test('refresh parses wrapped access-token-only response', () async {
      final Dio dio = Dio(BaseOptions(baseUrl: 'https://test.local'));
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest:
              (RequestOptions options, RequestInterceptorHandler handler) {
                handler.resolve(
                  Response<dynamic>(
                    requestOptions: options,
                    statusCode: 200,
                    data: <String, dynamic>{
                      'isSuccess': true,
                      'data': <String, dynamic>{
                        'accessToken': 'access-refreshed',
                        'memberId': 7,
                      },
                    },
                  ),
                );
              },
        ),
      );
      final ApiAuthRepository repository = ApiAuthRepository(dio: dio);

      final Result<AuthToken> result = await repository.refreshToken(
        'refresh-1',
      );

      expect(result, isA<Success<AuthToken>>());
      final AuthToken token = (result as Success<AuthToken>).data;
      expect(token.accessToken, 'access-refreshed');
      expect(token.refreshToken, isNull);
      expect(token.parentId, '7');
    });

    test('signup tolerates wrapped tokenless response', () async {
      final Dio dio = Dio(BaseOptions(baseUrl: 'https://test.local'));
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest:
              (RequestOptions options, RequestInterceptorHandler handler) {
                handler.resolve(
                  Response<dynamic>(
                    requestOptions: options,
                    statusCode: 200,
                    data: <String, dynamic>{
                      'isSuccess': true,
                      'data': <String, dynamic>{},
                    },
                  ),
                );
              },
        ),
      );
      final ApiAuthRepository repository = ApiAuthRepository(dio: dio);

      final Result<AuthToken> result = await repository.signup(
        email: 'parent@test.com',
        name: '박부모',
        password: 'Password123!',
      );

      expect(result, isA<Success<AuthToken>>());
      final AuthToken token = (result as Success<AuthToken>).data;
      expect(token.accessToken, isEmpty);
      expect(token.parentId, isEmpty);
      expect(token.email, 'parent@test.com');
    });
  });
}
