import '../../core/auth/account_store.dart';
import '../../core/child/child_connection_store.dart';
import '../../core/models/result.dart';
import '../models/child/child_summary.dart';
import 'child_repository.dart';

/// SharedPreferences-backed [ChildRepository].
///
/// Delegates code validation to [ChildConnectionStore] (which already
/// supports a `--dart-define=CHILD_CODE_VALIDATION_URL=...` override for
/// pre-backend smoke testing) and child enrolment to [AccountStore].
class MockChildRepository implements ChildRepository {
  @override
  Future<Result<bool>> validateChildCode(String code) async {
    final bool valid = await ChildConnectionStore.validateChildCode(code);
    return Result<bool>.success(valid);
  }

  @override
  Future<Result<List<ChildSummary>>> loadChildren(String parentId) async {
    final ParentAccount? account = await AccountStore.getAccountById(parentId);
    if (account == null) {
      return Result<List<ChildSummary>>.success(const <ChildSummary>[]);
    }
    final List<ChildSummary> children = account.children
        .map(
          (AccountChildData child) => ChildSummary(
            childrenId: child.childrenId,
            childCode: child.childCode,
            name: child.name,
            photoBase64: child.photoBase64,
          ),
        )
        .toList(growable: false);
    return Result<List<ChildSummary>>.success(children);
  }

  @override
  Future<Result<ChildSummary>> addChild({
    required String parentId,
    required String childCode,
    required String name,
    String? photoBase64,
  }) async {
    final bool valid = await ChildConnectionStore.validateChildCode(childCode);
    if (!valid) {
      return Result<ChildSummary>.failure(ChildFailureMessages.invalidCode);
    }

    final ParentAccount? account = await AccountStore.getAccountById(parentId);
    if (account == null) {
      return Result<ChildSummary>.failure(ChildFailureMessages.childNotFound);
    }

    final String normalizedCode = childCode.trim().toUpperCase();
    final bool alreadyLinked = account.children.any(
      (AccountChildData candidate) => candidate.childrenId == normalizedCode,
    );
    if (alreadyLinked) {
      return Result<ChildSummary>.failure(ChildFailureMessages.duplicateChild);
    }

    final AccountChildData newChild = AccountChildData(
      childrenId: normalizedCode,
      childCode: normalizedCode,
      name: name.trim(),
      photoBase64: photoBase64,
    );
    await AccountStore.addChild(parentId: parentId, child: newChild);
    return Result<ChildSummary>.success(
      ChildSummary(
        childrenId: newChild.childrenId,
        childCode: newChild.childCode,
        name: newChild.name,
        photoBase64: newChild.photoBase64,
      ),
    );
  }

  @override
  Future<Result<void>> removeChild({
    required String parentId,
    required String childrenId,
  }) async {
    await AccountStore.removeChild(
      parentId: parentId,
      childrenId: childrenId,
    );
    return Result<void>.success(null);
  }
}
