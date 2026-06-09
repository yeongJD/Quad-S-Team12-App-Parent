import '../../core/models/result.dart';
import '../../features/today_mission/presentation/data/today_mission_store.dart';
import '../../features/today_mission/presentation/models/today_mission.dart';
import 'mission_repository.dart';

/// SharedPreferences-backed [MissionRepository] that delegates to
/// [TodayMissionStore]. The store has owned the local persistence model
/// since Phase 1; this wrapper layers a `Result<T>` contract on top so the
/// presentation layer can swap to ApiMissionRepository without changing
/// page-level error handling.
class MockMissionRepository implements MissionRepository {
  @override
  Future<Result<List<TodayMission>>> loadMissions({
    required String parentId,
    required String childrenId,
  }) async {
    final List<TodayMission> missions = await TodayMissionStore.load(
      parentId: parentId,
      childrenId: childrenId,
    );
    return Result<List<TodayMission>>.success(missions);
  }

  @override
  Future<Result<void>> saveMissions({
    required String parentId,
    required String childrenId,
    required List<TodayMission> missions,
  }) async {
    await TodayMissionStore.save(
      parentId: parentId,
      childrenId: childrenId,
      missions: missions,
    );
    return Result<void>.success(null);
  }

  @override
  Future<Result<void>> addMission({
    required String parentId,
    required String childrenId,
    required TodayMission mission,
  }) async {
    await TodayMissionStore.add(
      parentId: parentId,
      childrenId: childrenId,
      mission: mission,
    );
    return Result<void>.success(null);
  }

  @override
  Future<Result<void>> updateMissionAt({
    required String parentId,
    required String childrenId,
    required int index,
    required TodayMission mission,
  }) async {
    await TodayMissionStore.updateAt(
      parentId: parentId,
      childrenId: childrenId,
      index: index,
      mission: mission,
    );
    return Result<void>.success(null);
  }

  @override
  Future<Result<void>> removeMissionAt({
    required String parentId,
    required String childrenId,
    required int index,
  }) async {
    await TodayMissionStore.removeAt(
      parentId: parentId,
      childrenId: childrenId,
      index: index,
    );
    return Result<void>.success(null);
  }

  @override
  Future<Result<void>> approveMissionAt({
    required String parentId,
    required String childrenId,
    required int index,
  }) async {
    return _setVerificationStatusAt(
      parentId: parentId,
      childrenId: childrenId,
      index: index,
      target: MissionVerificationStatus.approved,
    );
  }

  @override
  Future<Result<void>> approveMissionPerformance({
    required String parentId,
    required String childrenId,
    required String performanceId,
  }) async {
    return _setVerificationStatusByPerformanceId(
      parentId: parentId,
      childrenId: childrenId,
      performanceId: performanceId,
      target: MissionVerificationStatus.approved,
    );
  }

  @override
  Future<Result<void>> rejectMissionAt({
    required String parentId,
    required String childrenId,
    required int index,
  }) async {
    return _setVerificationStatusAt(
      parentId: parentId,
      childrenId: childrenId,
      index: index,
      target: MissionVerificationStatus.rejected,
    );
  }

  @override
  Future<Result<void>> rejectMissionPerformance({
    required String parentId,
    required String childrenId,
    required String performanceId,
  }) async {
    return _setVerificationStatusByPerformanceId(
      parentId: parentId,
      childrenId: childrenId,
      performanceId: performanceId,
      target: MissionVerificationStatus.rejected,
    );
  }

  Future<Result<void>> _setVerificationStatusAt({
    required String parentId,
    required String childrenId,
    required int index,
    required MissionVerificationStatus target,
  }) async {
    final List<TodayMission> missions = await TodayMissionStore.load(
      parentId: parentId,
      childrenId: childrenId,
    );
    if (index < 0 || index >= missions.length) {
      return Result<void>.failure(MissionFailureMessages.missionNotFound);
    }
    final TodayMission updated = missions[index].copyWith(
      verificationStatus: target,
      status: target.legacyStatus,
    );
    await TodayMissionStore.updateAt(
      parentId: parentId,
      childrenId: childrenId,
      index: index,
      mission: updated,
    );
    return Result<void>.success(null);
  }

  Future<Result<void>> _setVerificationStatusByPerformanceId({
    required String parentId,
    required String childrenId,
    required String performanceId,
    required MissionVerificationStatus target,
  }) async {
    final List<TodayMission> missions = await TodayMissionStore.load(
      parentId: parentId,
      childrenId: childrenId,
    );
    final int index = missions.indexWhere(
      (TodayMission mission) => mission.performanceId == performanceId,
    );
    if (index < 0) {
      return Result<void>.failure(MissionFailureMessages.missionNotFound);
    }
    final TodayMission updated = missions[index].copyWith(
      verificationStatus: target,
      status: target.legacyStatus,
    );
    await TodayMissionStore.updateAt(
      parentId: parentId,
      childrenId: childrenId,
      index: index,
      mission: updated,
    );
    return Result<void>.success(null);
  }
}
