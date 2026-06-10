import 'package:dio/dio.dart';

import '../../core/config/dio_config.dart';
import '../../core/models/result.dart';
import '../../core/network/api_error.dart';
import '../../features/today_mission/presentation/models/today_mission.dart';
import 'mission_repository.dart';

/// Network-backed [MissionRepository] per `docs/api/03-mission.md`.
///
/// Uses only the AWS Swagger mission endpoints:
/// `GET/POST /api/v1/missions`, `GET /api/v1/missions/{missionId}/performance`,
/// and `PATCH /api/v1/missions/performances/{performanceId}/{approve|reject}`.
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
    final int? childId = _positiveNumericId(childrenId);
    if (childId == null) {
      return Result<List<TodayMission>>.failure(
        MissionFailureMessages.invalidChild,
      );
    }
    try {
      final Response<dynamic> response = await _dio.get<dynamic>(
        '/api/v1/missions',
        queryParameters: <String, dynamic>{'childId': childId},
      );
      final List<dynamic> data = _jsonList(response.data);
      final List<TodayMission> missions = <TodayMission>[];
      for (final dynamic entry in data) {
        if (entry is! Map) {
          continue;
        }
        final TodayMission? mission = _missionFromJson(
          Map<String, dynamic>.from(entry),
        );
        if (mission == null) {
          continue;
        }
        missions.add(await _hydrateMission(mission));
      }
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
    return Result<void>.failure(MissionFailureMessages.unsupportedByAws);
  }

  @override
  Future<Result<void>> addMission({
    required String parentId,
    required String childrenId,
    required TodayMission mission,
  }) async {
    final int? childId = _positiveNumericId(childrenId);
    if (childId == null) {
      return Result<void>.failure(MissionFailureMessages.invalidChild);
    }
    final String? category = mission.category.backendCreateName;
    if (category == null) {
      return Result<void>.failure(MissionFailureMessages.unsupportedCategory);
    }
    try {
      await _dio.post<dynamic>(
        '/api/v1/missions',
        data: <String, dynamic>{
          'childId': childId,
          'title': mission.title,
          // Backend enums are UPPER_CASE. confirmationMethod {ai,child,parent}
          // maps 1:1 to the backend VerificationType {AI,CHILD,PARENT}.
          'category': category,
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
    return Result<void>.failure(MissionFailureMessages.unsupportedByAws);
  }

  @override
  Future<Result<void>> removeMissionAt({
    required String parentId,
    required String childrenId,
    required int index,
  }) async {
    return Result<void>.failure(MissionFailureMessages.unsupportedByAws);
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
  Future<Result<void>> approveMissionPerformance({
    required String parentId,
    required String childrenId,
    required String performanceId,
  }) {
    return _verifyPerformance(performanceId: performanceId, action: 'approve');
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

  @override
  Future<Result<void>> rejectMissionPerformance({
    required String parentId,
    required String childrenId,
    required String performanceId,
  }) {
    return _verifyPerformance(performanceId: performanceId, action: 'reject');
  }

  Future<Result<void>> _verifyMission({
    required String parentId,
    required String childrenId,
    required int index,
    required String action,
  }) async {
    try {
      final Result<List<TodayMission>> loaded = await loadMissions(
        parentId: parentId,
        childrenId: childrenId,
      );
      final List<TodayMission> missions;
      switch (loaded) {
        case Success<List<TodayMission>>(:final List<TodayMission> data):
          missions = data;
        case Failure<List<TodayMission>>(
          :final String message,
          :final Object? cause,
        ):
          return Result<void>.failure(message, cause: cause);
      }
      if (index < 0 || index >= missions.length) {
        return Result<void>.failure(MissionFailureMessages.missionNotFound);
      }
      final String? performanceId = missions[index].performanceId;
      if (performanceId == null || performanceId.isEmpty) {
        return Result<void>.failure(MissionFailureMessages.invalidState);
      }

      return _verifyPerformance(performanceId: performanceId, action: action);
    } on DioException catch (e) {
      return _verifyFailure(e);
    }
  }

  Future<Result<void>> _verifyPerformance({
    required String performanceId,
    required String action,
  }) async {
    final int? verifiedPerformanceId = _positiveNumericId(performanceId);
    if (verifiedPerformanceId == null) {
      return Result<void>.failure(MissionFailureMessages.invalidState);
    }
    try {
      await _dio.patch<dynamic>(
        '/api/v1/missions/performances/$verifiedPerformanceId/$action',
      );
      return Result<void>.success(null);
    } on DioException catch (e) {
      return _verifyFailure(e);
    }
  }

  Result<void> _verifyFailure(DioException e) {
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

  TodayMission? _missionFromJson(Map<String, dynamic> json) {
    final Object? missionId = json['missionId'];
    final Object? title = json['title'];
    final Object? category = json['category'];
    final Object? resetPeriod = json['resetPeriod'] ?? json['resetCycle'];
    final Object? confirmationMethod = json['confirmationMethod'];
    final Object? verificationType = json['verificationType'];
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
    final MissionCategory safeCategory =
        decodedCategory ?? MissionCategory.routine;
    final MissionResetPeriod decodedResetPeriod = resetPeriod is String
        ? _decodeEnum(MissionResetPeriod.values, resetPeriod) ??
              MissionResetPeriod.daily
        : MissionResetPeriod.daily;
    final MissionConfirmationMethod decodedConfirmationMethod =
        _decodeConfirmationMethod(
          confirmationMethod: confirmationMethod,
          verificationType: verificationType,
        );
    final int decodedReward = reward is int
        ? reward
        : (rewardMinutes is int ? rewardMinutes : 0);
    final String decodedDescription = description is String ? description : '';

    final TodayMissionStatus decodedStatus = status is String
        ? _decodeEnum(TodayMissionStatus.values, status) ??
              TodayMissionStatus.pending
        : TodayMissionStatus.pending;
    final MissionVerificationStatus decodedVerification =
        verificationStatus is String
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
      missionId: missionId?.toString(),
      title: title,
      category: safeCategory,
      resetPeriod: decodedResetPeriod,
      confirmationMethod: decodedConfirmationMethod,
      rewardMinutes: decodedReward,
      description: decodedDescription,
      status: decodedVerification.legacyStatus,
      verificationStatus: decodedVerification,
      submittedAtText: submittedAtText is String ? submittedAtText : null,
    );
  }

  Future<TodayMission> _hydrateMission(TodayMission mission) async {
    final String? missionId = mission.missionId;
    if (missionId == null || missionId.isEmpty) {
      return mission;
    }

    TodayMission hydrated = mission;
    try {
      final Response<dynamic> detailResp = await _dio.get<dynamic>(
        '/api/v1/missions/$missionId',
      );
      final Map<String, dynamic>? detail = _jsonMap(detailResp.data);
      if (detail != null) {
        hydrated = _missionFromJson(detail) ?? hydrated;
      }
    } on DioException catch (e) {
      if (e.response?.statusCode != 404) {
        // Keep the summary item renderable even if detail enrichment fails.
      }
    }

    try {
      final Response<dynamic> perfResp = await _dio.get<dynamic>(
        '/api/v1/missions/$missionId/performance',
      );
      final Map<String, dynamic>? performance = _jsonMap(perfResp.data);
      if (performance != null) {
        hydrated = _applyPerformance(hydrated, performance);
      }
    } on DioException catch (e) {
      final String? code = errorCodeOf(e);
      if (e.response?.statusCode != 404 && code != 'MISSION_NOT_FOUND') {
        // The list itself is still useful without a submitted performance.
      }
    }

    return hydrated;
  }

  TodayMission _applyPerformance(
    TodayMission mission,
    Map<String, dynamic> performance,
  ) {
    final MissionVerificationStatus verificationStatus =
        _verificationFromPerformanceStatus(
          performance['status']?.toString(),
          mission.verificationType,
        );
    return mission.copyWith(
      performanceId: performance['performanceId']?.toString(),
      verificationStatus: verificationStatus,
      proofImageUrl: performance['proofImageUrl']?.toString(),
    );
  }

  MissionVerificationStatus _verificationFromPerformanceStatus(
    String? status,
    MissionVerificationType verificationType,
  ) {
    switch (status?.toUpperCase()) {
      case 'ACCEPTED':
        return MissionVerificationStatus.approved;
      case 'REJECTED':
        return MissionVerificationStatus.rejected;
      case 'PENDING':
        return switch (verificationType) {
          MissionVerificationType.ai =>
            MissionVerificationStatus.waitingAiVerification,
          MissionVerificationType.parent =>
            MissionVerificationStatus.waitingParentApproval,
          MissionVerificationType.self => MissionVerificationStatus.approved,
        };
    }
    return MissionVerificationStatus.idle;
  }

  MissionConfirmationMethod _decodeConfirmationMethod({
    required Object? confirmationMethod,
    required Object? verificationType,
  }) {
    if (confirmationMethod is String) {
      return _decodeEnum(
            MissionConfirmationMethod.values,
            confirmationMethod,
          ) ??
          MissionConfirmationMethod.parent;
    }
    if (verificationType is String) {
      return _decodeEnum(MissionConfirmationMethod.values, verificationType) ??
          MissionConfirmationMethod.parent;
    }
    return MissionConfirmationMethod.parent;
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

  List<dynamic> _jsonList(dynamic data) {
    if (data is Map && data['data'] is List) {
      return List<dynamic>.from(data['data'] as List);
    }
    if (data is List) {
      return List<dynamic>.from(data);
    }
    return const <dynamic>[];
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

  int? _positiveNumericId(String id) {
    final int? parsed = int.tryParse(id.trim());
    if (parsed == null || parsed <= 0) {
      return null;
    }
    return parsed;
  }
}
