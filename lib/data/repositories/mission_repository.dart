import '../../core/config/environment.dart';
import '../../core/models/result.dart';
import '../../features/today_mission/presentation/models/today_mission.dart';
import 'api_mission_repository.dart';
import 'mock_mission_repository.dart';

/// Repository contract for the parent-set mission domain.
///
/// Each operation is scoped to a `(parentId, childrenId)` pair — the parent
/// can have multiple children, and each child has its own mission list.
///
/// CRUD methods take an `index` because the existing presentation layer
/// (TodayMissionListPage etc.) tracks missions by their position. The API
/// implementation translates the index into the backend-assigned missionId
/// at the call site via a fresh [loadMissions] round-trip.
abstract interface class MissionRepository {
  Future<Result<List<TodayMission>>> loadMissions({
    required String parentId,
    required String childrenId,
  });

  /// Replaces the entire mission list for `(parentId, childrenId)`. Used
  /// when the page-level controller has the full list ready (e.g. after a
  /// drag-reorder or bulk import) — individual edits should prefer the
  /// scoped CRUD methods below.
  Future<Result<void>> saveMissions({
    required String parentId,
    required String childrenId,
    required List<TodayMission> missions,
  });

  Future<Result<void>> addMission({
    required String parentId,
    required String childrenId,
    required TodayMission mission,
  });

  Future<Result<void>> updateMissionAt({
    required String parentId,
    required String childrenId,
    required int index,
    required TodayMission mission,
  });

  Future<Result<void>> removeMissionAt({
    required String parentId,
    required String childrenId,
    required int index,
  });

  /// Parent approves the child's submission. Backend transitions the
  /// mission's verificationStatus → approved and credits reward minutes.
  Future<Result<void>> approveMissionAt({
    required String parentId,
    required String childrenId,
    required int index,
  });

  /// Parent approves a concrete mission performance. Prefer this when the UI
  /// already has `performanceId` from a mission detail or notification payload.
  Future<Result<void>> approveMissionPerformance({
    required String parentId,
    required String childrenId,
    required String performanceId,
  });

  /// Parent rejects the child's submission. Backend transitions the
  /// mission's verificationStatus → rejected and surfaces the rejection
  /// to the child.
  Future<Result<void>> rejectMissionAt({
    required String parentId,
    required String childrenId,
    required int index,
  });

  /// Parent rejects a concrete mission performance. Prefer this when the UI
  /// already has `performanceId` from a mission detail or notification payload.
  Future<Result<void>> rejectMissionPerformance({
    required String parentId,
    required String childrenId,
    required String performanceId,
  });
}

final MissionRepository _missionRepository = currentEnvironment.useMocks
    ? MockMissionRepository()
    : ApiMissionRepository();

MissionRepository createMissionRepository() => _missionRepository;

abstract final class MissionFailureMessages {
  static const String missionNotFound = '미션을 찾을 수 없어요.';
  static const String invalidState = '지금 상태에서는 이 작업을 할 수 없어요.';
  static const String unsupportedByAws = 'AWS API에 미션 수정/삭제 경로가 없어요.';
}
