import '../../core/auth/account_store.dart';
import '../../core/models/result.dart';
import '../models/parent_profile/parent_profile.dart';
import 'parent_profile_repository.dart';

/// SharedPreferences-backed [ParentProfileRepository] that delegates to
/// [AccountStore]. Projects [ParentAccount] (minus the password hash) into
/// [ParentProfile] so feature pages don't need to know the on-disk schema.
class MockParentProfileRepository implements ParentProfileRepository {
  @override
  Future<Result<ParentProfile>> getProfile(String parentId) async {
    final ParentAccount? account = await AccountStore.getAccountById(parentId);
    if (account == null) {
      return Result<ParentProfile>.failure(
        ParentProfileFailureMessages.notFound,
      );
    }
    return Result<ParentProfile>.success(_project(account));
  }

  @override
  Future<Result<ParentProfile>> updateName({
    required String parentId,
    required String name,
  }) async {
    final ParentAccount? account = await AccountStore.getAccountById(parentId);
    if (account == null) {
      return Result<ParentProfile>.failure(
        ParentProfileFailureMessages.notFound,
      );
    }
    final ParentAccount updated = account.copyWith(name: name);
    await AccountStore.saveAccount(updated);
    return Result<ParentProfile>.success(_project(updated));
  }

  @override
  Future<Result<void>> updateStatus({
    required String parentId,
    required ParentProfileStatus status,
  }) async {
    try {
      await AccountStore.updateStatus(
        parentId: parentId,
        status: status == ParentProfileStatus.dormant
            ? AccountStatus.dormant
            : AccountStatus.active,
      );
      return Result<void>.success(null);
    } on StateError catch (e) {
      return Result<void>.failure(
        ParentProfileFailureMessages.notFound,
        cause: e,
      );
    }
  }

  ParentProfile _project(ParentAccount account) {
    return ParentProfile(
      parentId: account.parentId,
      email: account.email,
      name: account.name,
      status: account.status == AccountStatus.dormant
          ? ParentProfileStatus.dormant
          : ParentProfileStatus.active,
    );
  }
}
