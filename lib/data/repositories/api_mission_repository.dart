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
        '/api/v1/missions',
        queryParameters: <String, dynamic>{'childId': childrenId},
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
        '/api/v1/missions',
        data: <String, dynamic>{
          'childId': childrenId,
          'title': mission.title,
          // Backend enums are UPPER_CASE. confirmationMethod {ai,child,parent}
          // maps 1:1 to the backend VerificationType {AI,CHILD,PARENT}.
          'category': mission.category.name.toUpperCase(),
          'description': mission.description,
          'reward': mission.rewardMinutes,
          'resetCycle': mission.resetPeriod.name.toUpperCase(),
          'verificationType': mission.confirmationMethod.name.toUpperCase(),
        },
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
      // Backend exposes approval only by performanceId. Bridge the page's
      // index-based call via the existing endpoints: list → missionId →
      // performance → performanceId, then PATCH the approval state. No backend
      // change required (see backend-handoff §3.3).
      final Response<dynamic> listResp = await _dio.get<dynamic>(
        '/api/v1/missions',
        queryParameters: <String, dynamic>{'childId': childrenId},
      );
      final dynamic listData = listResp.data;
      if (listData is! List || index < 0 || index >= listData.length) {
        return Result<void>.failure(MissionFailureMessages.missionNotFound);
      }
      final dynamic entry = listData[index];
      final Object? missionId = entry is Map ? entry['missionId'] : null;
      if (missionId == null) {
        return Result<void>.failure(MissionFailureMessages.missionNotFound);
      }

      final Response<dynamic> perfResp = await _dio.get<dynamic>(
        '/api/v1/missions/$missionId/performance',
      );
      final dynamic perfData = perfResp.data;
      final Object? performanceId =
          perfData is Map ? perfData['performanceId'] : null;
      if (performanceId == null) {
        return Result<void>.failure(MissionFailureMessages.invalidState);
      }

      await _dio.patch<dynamic>(
        '/api/v1/missions/performances/$performanceId/$action',
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
    final Object? reward = json['reward'];
    final Object? rewardMinutes = json['rewardMinutes'];
    final Object? description = json['description'];
    final Object? status = json['status'];
    final Object? verificationStatus = json['verificationStatus'];
    final Object? submittedAtText = json['submittedAtText'];

    if (title is! String || category is! String) {
      return null;
    }

    final MissionCategory? decodedCategory = _decodeEnum(
      MissionCategory.values,
      category,
    );
    if (decodedCategory == null) {
      return null;
    }
    final MissionResetPeriod decodedResetPeriod = resetPeriod is String
        ? _decodeEnum(MissionResetPeriod.values, resetPeriod) ??
              MissionResetPeriod.daily
        : MissionResetPeriod.daily;
    final MissionConfirmationMethod decodedConfirmationMethod =
        confirmationMethod is String
        ? _decodeEnum(MissionConfirmationMethod.values, confirmationMethod) ??
              MissionConfirmationMethod.parent
        : MissionConfirmationMethod.parent;
    final int decodedReward = reward is int
        ? reward
        : (rewardMinutes is int ? rewardMinutes : 0);
    final String decodedDescription = description is String ? description : '';

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
      rewardMinutes: decodedReward,
      description: decodedDescription,
      status: decodedVerification.legacyStatus,
      verificationStatus: decodedVerification,
      submittedAtText: submittedAtText is String ? submittedAtText : null,
    );
  }

  T? _decodeEnum<T extends Enum>(List<T> values, String name) {
    // Backend serialises enums in UPPER_CASE (e.g. STUDY, DAILY, AI) while the
    // app enums are lowerCamel; match case-insensitively so backend payloads
    // are not silently dropped.
    final String target = name.toLowerCase();
    for (final T value in values) {
      if (value.name.toLowerCase() == target) {
        return value;
      }
    }
    return null;
  }
}
