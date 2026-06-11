import '../../core/config/environment.dart';
import '../../core/models/result.dart';
import '../models/parent_profile/parent_profile.dart';
import 'api_parent_profile_repository.dart';
import 'mock_parent_profile_repository.dart';

/// Repository contract for parent profile operations.
///
/// Scope is intentionally narrow: identifying info + status. Authentication
/// (password, account deletion) lives in [AuthRepository]; child enrolment
/// in [ChildRepository].
abstract interface class ParentProfileRepository {
  Future<Result<ParentProfile>> getProfile(String parentId);

  Future<Result<ParentProfile>> updateName({
    required String parentId,
    required String name,
  });

  Future<Result<void>> updateStatus({
    required String parentId,
    required ParentProfileStatus status,
  });
}

final ParentProfileRepository _parentProfileRepository =
    currentEnvironment.useMocks
        ? MockParentProfileRepository()
        : ApiParentProfileRepository();

ParentProfileRepository createParentProfileRepository() =>
    _parentProfileRepository;

abstract final class ParentProfileFailureMessages {
  static const String notFound = '계정을 찾을 수 없어요.';
}
