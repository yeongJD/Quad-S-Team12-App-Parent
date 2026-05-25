import 'package:dio/dio.dart';

import '../../core/config/dio_config.dart';
import '../../core/models/result.dart';
import '../../core/network/api_error.dart';
import '../../features/today_mission/presentation/models/today_mission.dart';
import 'mission_repository.dart';

/// Network-backed [MissionRepository] per `docs/api/03-mission.md`.
///
/// Endpoints are scoped under
/// `/children/{childrenId}/missions?parentId={parentId}` so the backend can
/// authorize on both the parent and the child. The repository serialises
/// [TodayMission] via [_missionToJson] / [_missionFromJson]; the JSON shape
/// mirrors what TodayMissionStore already persisted to SharedPreferences,
/// so a backend implementing the contract literally can replay existing
/// fixtures.
///
/// Index-based CRUD (approve/reject/update/remove at a position) is
/// translated to a missionId via a per-call [loadMissions] round-trip so
/// page-level code does not need to track missionIds today. The TODO below
/// documents the future direction.
class ApiMissionRepository implements MissionRepository {
  ApiMissionRepository({Dio? dio}) : _dio = dio ?? DioConfig.create();

  final Dio _dio;

  @override
  Future<Result<List<TodayMission>>> loadMissions({
    required String parentId,
    required String childrenId,
  }) async {
    try {
      final Response<dynamic> response = await _dio.get<dynamic>(
        '/children/$childrenId/missions',
        queryParameters: <String, dynamic>{'parentId': parentId},
      );
      final dynamic data = response.data;
      if (data is! List) {
        return Result<List<TodayMission>>.success(const <TodayMission>[]);
      }
      final List<TodayMission> missions = data
          .whereType<Map<String, dynamic>>()
          .map(_missionFromJson)
          .whereType<TodayMission>()
          .toList(growable: false);
      return Result<List<TodayMission>>.success(missions);
    } on DioException catch (e) {
      return failureFromDioException<List<TodayMission>>(e);
    }
  }

  @override
  Future<Result<void>> saveMissions({
    required String parentId,
    required String childrenId,
    required List<TodayMission> missions,
  }) async {
    try {
      await _dio.put<dynamic>(
        '/children/$childrenId/missions',
        queryParameters: <String, dynamic>{'parentId': parentId},
        data: <String, dynamic>{
          'missions': missions.map(_missionToJson).toList(growable: false),
        },
      );
      return Result<void>.success(null);
    } on DioException catch (e) {
      return failureFromDioException<void>(e);
    }
  }

  @override
  Future<Result<void>> addMission({
    required String parentId,
    required String childrenId,
    required TodayMission mission,
  }) async {
    try {
      await _dio.post<dynamic>(
        '/children/$childrenId/missions',
        queryParameters: <String, dynamic>{'parentId': parentId},
        data: _missionToJson(mission),
      );
      return Result<void>.success(null);
    } on DioException catch (e) {
      return failureFromDioException<void>(e);
    }
  }

  @override
  Future<Result<void>> updateMissionAt({
    required String parentId,
    required String childrenId,
    required int index,
    required TodayMission mission,
  }) async {
    // TODO(api): once the page-level controllers track missionId, replace
    // the index→id translation below with a direct PUT
    // `/missions/{missionId}` call.
    try {
      await _dio.put<dynamic>(
        '/children/$childrenId/missions/at/$index',
        queryParameters: <String, dynamic>{'parentId': parentId},
        data: _missionToJson(mission),
      );
      return Result<void>.success(null);
    } on DioException catch (e) {
      return failureFromDioException<void>(e);
    }
  }

  @override
  Future<Result<void>> removeMissionAt({
    required String parentId,
    required String childrenId,
    required int index,
  }) async {
    try {
      await _dio.delete<dynamic>(
        '/children/$childrenId/missions/at/$index',
        queryParameters: <String, dynamic>{'parentId': parentId},
      );
      return Result<void>.success(null);
    } on DioException catch (e) {
      return failureFromDioException<void>(e);
    }
  }

  @override
  Future<Result<void>> approveMissionAt({
    required String parentId,
    required String childrenId,
    required int index,
  }) async {
    return _verifyMission(
      parentId: parentId,
      childrenId: childrenId,
      index: index,
      action: 'approve',
    );
  }

  @override
  Future<Result<void>> rejectMissionAt({
    required String parentId,
    required String childrenId,
    required int index,
  }) async {
    return _verifyMission(
      parentId: parentId,
      childrenId: childrenId,
      index: index,
      action: 'reject',
    );
  }

  Future<Result<void>> _verifyMission({
    required String parentId,
    required String childrenId,
    required int index,
    required String action,
  }) async {
    try {
      await _dio.post<dynamic>(
        '/children/$childrenId/missions/at/$index/$action',
        queryParameters: <String, dynamic>{'parentId': parentId},
      );
      return Result<void>.success(null);
    } on DioException catch (e) {
      final String? code = errorCodeOf(e);
      if (code == 'MISSION_NOT_FOUND') {
        return Result<void>.failure(
          MissionFailureMessages.missionNotFound,
          cause: code,
        );
      }
      if (code == 'INVALID_MISSION_STATE') {
        return Result<void>.failure(
          MissionFailureMessages.invalidState,
          cause: code,
        );
      }
      return failureFromDioException<void>(e);
    }
  }

  Map<String, dynamic> _missionToJson(TodayMission mission) {
    return <String, dynamic>{
      'title': mission.title,
      'category': mission.category.name,
      'resetPeriod': mission.resetPeriod.name,
      'confirmationMethod': mission.confirmationMethod.name,
      'rewardMinutes': mission.rewardMinutes,
      'description': mission.description,
      'status': mission.effectiveStatus.name,
      'verificationType': mission.verificationType.name,
      'verificationStatus': mission.effectiveVerificationStatus.name,
      if (mission.submittedAtText case final String submittedAtText)
        'submittedAtText': submittedAtText,
    };
  }

  TodayMission? _missionFromJson(Map<String, dynamic> json) {
    final Object? title = json['title'];
    final Object? category = json['category'];
    final Object? resetPeriod = json['resetPeriod'];
    final Object? confirmationMethod = json['confirmationMethod'];
    final Object? rewardMinutes = json['rewardMinutes'];
    final Object? description = json['description'];
    final Object? status = json['status'];
    final Object? verificationStatus = json['verificationStatus'];
    final Object? submittedAtText = json['submittedAtText'];

    if (title is! String ||
        category is! String ||
        resetPeriod is! String ||
        confirmationMethod is! String ||
        rewardMinutes is! int ||
        description is! String) {
      return null;
    }

    final MissionCategory? decodedCategory = _decodeEnum(
      MissionCategory.values,
      category,
    );
    final MissionResetPeriod? decodedResetPeriod = _decodeEnum(
      MissionResetPeriod.values,
      resetPeriod,
    );
    final MissionConfirmationMethod? decodedConfirmationMethod = _decodeEnum(
      MissionConfirmationMethod.values,
      confirmationMethod,
    );
    if (decodedCategory == null ||
        decodedResetPeriod == null ||
        decodedConfirmationMethod == null) {
      return null;
    }

    final TodayMissionStatus decodedStatus = status is String
        ? _decodeEnum(TodayMissionStatus.values, status) ??
              TodayMissionStatus.pending
        : TodayMissionStatus.pending;
    final MissionVerificationStatus decodedVerification = verificationStatus
            is String
        ? _decodeEnum(MissionVerificationStatus.values, verificationStatus) ??
              missionVerificationStatusFromLegacyStatus(
                status: decodedStatus,
                verificationType: decodedConfirmationMethod.verificationType,
              )
        : missionVerificationStatusFromLegacyStatus(
            status: decodedStatus,
            verificationType: decodedConfirmationMethod.verificationType,
          );

    return TodayMission(
      title: title,
      category: decodedCategory,
      resetPeriod: decodedResetPeriod,
      confirmationMethod: decodedConfirmationMethod,
      rewardMinutes: rewardMinutes,
      description: description,
      status: decodedVerification.legacyStatus,
      verificationStatus: decodedVerification,
      submittedAtText: submittedAtText is String ? submittedAtText : null,
    );
  }

  T? _decodeEnum<T extends Enum>(List<T> values, String name) {
    for (final T value in values) {
      if (value.name == name) {
        return value;
      }
    }
    return null;
  }
}
