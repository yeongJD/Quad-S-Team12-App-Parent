import 'package:bridge_p/core/models/result.dart';
import 'package:bridge_p/core/network/api_error.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('failureFromDioException prefers backend ApiResponse data message', () {
    final RequestOptions requestOptions = RequestOptions(path: '/test');
    final Failure<void> failure = failureFromDioException<void>(
      DioException(
        requestOptions: requestOptions,
        response: Response<dynamic>(
          requestOptions: requestOptions,
          statusCode: 400,
          data: <String, dynamic>{
            'isSuccess': false,
            'code': 'COMMON400',
            'message': '잘못된 요청입니다.',
            'data': '정책이 없습니다.',
          },
        ),
      ),
    );

    expect(failure.message, '정책이 없습니다.');
    expect(failure.cause, 'COMMON400');
  });

  test('errorCodeOf maps backend mission codes to app aliases', () {
    expect(
      errorCodeOf(_dioExceptionWithCode('MISSION404')),
      'MISSION_NOT_FOUND',
    );
    expect(
      errorCodeOf(_dioExceptionWithCode('MISSION400')),
      'MISSION_ALREADY_COMPLETED',
    );
    expect(
      errorCodeOf(_dioExceptionWithCode('INVALID_MISSION_STATE')),
      'INVALID_MISSION_STATE',
    );
  });
}

DioException _dioExceptionWithCode(String code) {
  final RequestOptions requestOptions = RequestOptions(path: '/missions/1');
  return DioException(
    requestOptions: requestOptions,
    response: Response<dynamic>(
      requestOptions: requestOptions,
      statusCode: 400,
      data: <String, dynamic>{
        'isSuccess': false,
        'code': code,
        'message': '미션 오류입니다.',
      },
    ),
  );
}
