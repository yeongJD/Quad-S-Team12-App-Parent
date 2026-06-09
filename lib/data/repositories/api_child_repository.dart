import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../../core/config/dio_config.dart';
import '../../core/models/result.dart';
import '../../core/network/api_error.dart';
import '../models/child/child_summary.dart';
import 'child_repository.dart';

/// Network-backed [ChildRepository] per `docs/api/02-child.md`.
///
/// - `GET  /api/v1/parents/children`
/// - `POST /api/v1/parents/children`
/// - `POST /api/v1/files/photos`
class ApiChildRepository implements ChildRepository {
  ApiChildRepository({Dio? dio}) : _dio = dio ?? DioConfig.create();

  final Dio _dio;

  @override
  Future<Result<bool>> validateChildCode(String code) async {
    // AWS has no separate validate endpoint. Let registerChild perform the
    // authoritative validation and surface its server error.
    return Result<bool>.success(code.trim().isNotEmpty);
  }

  @override
  Future<Result<List<ChildSummary>>> loadChildren(String parentId) async {
    try {
      final Response<dynamic> response = await _dio.get<dynamic>(
        '/api/v1/parents/children',
      );
      final List<dynamic> data = _jsonList(response.data);
      final List<ChildSummary> children = data
          .whereType<Map>()
          .map(
            (Map child) =>
                ChildSummary.fromJson(Map<String, dynamic>.from(child)),
          )
          .toList(growable: false);
      return Result<List<ChildSummary>>.success(children);
    } on DioException catch (e) {
      return failureFromDioException<List<ChildSummary>>(e);
    }
  }

  @override
  Future<Result<ChildSummary>> addChild({
    required String parentId,
    required String childCode,
    required String name,
    int? birthYear,
    String? photoBase64,
  }) async {
    // Backend identifies the parent via JWT, so parentId is not sent. Field
    // names follow RegisterChildRequest {childrenName, childrenCode,
    // childrenBirth, profileImageKey}. childrenBirth is optional in the
    // backend, but the screen collects a birth year, so send a stable
    // YYYY-01-01 value when available.
    final Map<String, dynamic> body = <String, dynamic>{
      'childrenName': name,
      'childrenCode': childCode,
      if (birthYear != null) 'childrenBirth': '$birthYear-01-01',
    };
    // Profile photos are stored on S3: the picked image is uploaded first to
    // POST /api/v1/files/photos (category=PROFILE), which returns an S3 key the
    // register call references via `profileImageKey`. Upload is best-effort —
    // a failure registers the child without an avatar rather than blocking.
    if (photoBase64 != null && photoBase64.isNotEmpty) {
      final String? key = await _uploadProfilePhoto(photoBase64);
      if (key != null) {
        body['profileImageKey'] = key;
      }
    }
    try {
      final Response<dynamic> response = await _dio.post<dynamic>(
        '/api/v1/parents/children',
        data: body,
      );
      final Map<String, dynamic>? data = _jsonMap(response.data);
      if (data == null) {
        throw const FormatException('addChild response was not a JSON object.');
      }
      return Result<ChildSummary>.success(ChildSummary.fromJson(data));
    } on DioException catch (e) {
      final String? code = errorCodeOf(e);
      if (code == 'INVALID_CHILD_CODE') {
        return Result<ChildSummary>.failure(
          ChildFailureMessages.invalidCode,
          cause: code,
        );
      }
      if (code == 'CHILD_ALREADY_LINKED') {
        return Result<ChildSummary>.failure(
          ChildFailureMessages.duplicateChild,
          cause: code,
        );
      }
      return failureFromDioException<ChildSummary>(e);
    }
  }

  @override
  Future<Result<void>> removeChild({
    required String parentId,
    required String childrenId,
  }) async {
    return Result<void>.failure('AWS API에 자녀 삭제 경로가 없어요.');
  }

  /// Uploads a base64-encoded profile image to `POST /api/v1/files/photos`
  /// (category=PROFILE) and returns the S3 key, or `null` on any failure.
  ///
  /// The backend rejects non-image content types, so the multipart part is
  /// tagged with an image media type sniffed from the bytes (PNG/WebP magic,
  /// else JPEG — image_picker re-encodes gallery picks to JPEG).
  Future<String?> _uploadProfilePhoto(String base64Data) async {
    try {
      final Uint8List bytes = base64Decode(base64Data);
      if (bytes.isEmpty) {
        return null;
      }
      final ({String subtype, String ext}) media = _sniffImageType(bytes);
      final FormData form = FormData.fromMap(<String, dynamic>{
        'file': MultipartFile.fromBytes(
          bytes,
          filename: 'profile.${media.ext}',
          contentType: DioMediaType('image', media.subtype),
        ),
      });
      final Response<dynamic> response = await _dio.post<dynamic>(
        '/api/v1/files/photos',
        queryParameters: <String, dynamic>{'category': 'PROFILE'},
        data: form,
        options: Options(contentType: 'multipart/form-data'),
      );
      final dynamic data = response.data;
      if (data is Map && data['key'] is String) {
        return data['key'] as String;
      }
      return null;
    } catch (_) {
      // Best-effort: never block child registration on an avatar upload.
      return null;
    }
  }

  /// Minimal magic-byte sniff for the image media type the backend will accept.
  ({String subtype, String ext}) _sniffImageType(Uint8List bytes) {
    if (bytes.length >= 8 &&
        bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4E &&
        bytes[3] == 0x47) {
      return (subtype: 'png', ext: 'png');
    }
    if (bytes.length >= 12 &&
        bytes[0] == 0x52 &&
        bytes[1] == 0x49 &&
        bytes[2] == 0x46 &&
        bytes[3] == 0x46 &&
        bytes[8] == 0x57 &&
        bytes[9] == 0x45 &&
        bytes[10] == 0x42 &&
        bytes[11] == 0x50) {
      return (subtype: 'webp', ext: 'webp');
    }
    return (subtype: 'jpeg', ext: 'jpg');
  }

  List<dynamic> _jsonList(dynamic data) {
    if (data is Map && data['data'] is List) {
      return List<dynamic>.from(data['data'] as List);
    }
    if (data is List) {
      return List<dynamic>.from(data);
    }
    return const <dynamic>[];
  }

  Map<String, dynamic>? _jsonMap(dynamic data) {
    if (data is Map && data['data'] is Map) {
      return Map<String, dynamic>.from(data['data'] as Map);
    }
    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }
    return null;
  }
}
