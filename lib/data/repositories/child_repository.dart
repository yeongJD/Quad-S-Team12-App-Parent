import '../../core/config/environment.dart';
import '../../core/models/result.dart';
import '../models/child/child_summary.dart';
import 'api_child_repository.dart';
import 'mock_child_repository.dart';

/// Repository contract for the parent ↔ child connection domain.
///
/// Covers code validation, child enrolment, and the parent's enrolled-child
/// list. Mission/time-plan/notification details are scoped to the
/// [ChildSummary.childrenId] returned here but live in their own repositories.
abstract interface class ChildRepository {
  /// Confirms that [code] matches a real child account on the backend.
  Future<Result<bool>> validateChildCode(String code);

  /// Returns every child currently linked to [parentId]. Empty list when the
  /// parent has none yet — pages render the empty state widget instead of an
  /// error message.
  Future<Result<List<ChildSummary>>> loadChildren(String parentId);

  /// Adds a child to [parentId]'s account. The backend assigns the canonical
  /// [ChildSummary.childrenId]; the returned value MUST be used for any
  /// subsequent child-scoped calls (missions, time-plan, etc.).
  Future<Result<ChildSummary>> addChild({
    required String parentId,
    required String childCode,
    required String name,
    String? photoBase64,
  });

  Future<Result<void>> removeChild({
    required String parentId,
    required String childrenId,
  });
}

final ChildRepository _childRepository = currentEnvironment.useMocks
    ? MockChildRepository()
    : ApiChildRepository();

ChildRepository createChildRepository() => _childRepository;

abstract final class ChildFailureMessages {
  static const String invalidCode = '존재하지 않는 자녀 코드예요.';
  static const String duplicateChild = '이미 등록된 자녀예요.';
  static const String childNotFound = '자녀 정보를 찾을 수 없어요.';
}
