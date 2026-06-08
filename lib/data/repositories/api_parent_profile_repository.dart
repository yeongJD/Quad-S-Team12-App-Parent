import '../../core/auth/account_store.dart';
import '../../core/auth/auth_session.dart';
import '../../core/models/result.dart';
import '../models/parent_profile/parent_profile.dart';
import 'parent_profile_repository.dart';

/// Network-backed [ParentProfileRepository] per `docs/api/06-parent-profile.md`.
///
/// AWS Swagger does not expose parent profile read/update endpoints. This
/// repository therefore uses the locally stored auth session/account snapshot
/// and does not call the legacy `/parents/{parentId}` compatibility paths.
class ApiParentProfileRepository implements ParentProfileRepository {
  const ApiParentProfileRepository();

  @override
  Future<Result<ParentProfile>> getProfile(String parentId) async {
    final ParentAccount? account = await AccountStore.getAccountById(parentId);
    final String? email = await AuthSession.getCurrentEmail();
    return Result<ParentProfile>.success(
      ParentProfile(
        parentId: parentId,
        email: account?.email ?? email ?? '',
        name: account?.name ?? AuthSession.fallbackName,
        status: _profileStatusFromAccount(account?.status),
      ),
    );
  }

  @override
  Future<Result<ParentProfile>> updateName({
    required String parentId,
    required String name,
  }) async {
    final ParentAccount? account = await AccountStore.getAccountById(parentId);
    if (account != null) {
      await AccountStore.saveAccount(account.copyWith(name: name));
    }
    return getProfile(parentId);
  }

  @override
  Future<Result<void>> updateStatus({
    required String parentId,
    required ParentProfileStatus status,
  }) async {
    final AccountStatus accountStatus = status == ParentProfileStatus.dormant
        ? AccountStatus.dormant
        : AccountStatus.active;
    final ParentAccount? account = await AccountStore.getAccountById(parentId);
    if (account != null) {
      await AccountStore.updateStatus(parentId: parentId, status: accountStatus);
    }
    return Result<void>.success(null);
  }

  ParentProfileStatus _profileStatusFromAccount(AccountStatus? status) {
    return status == AccountStatus.dormant
        ? ParentProfileStatus.dormant
        : ParentProfileStatus.active;
  }
}
