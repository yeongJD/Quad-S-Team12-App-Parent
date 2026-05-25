import '../../core/auth/account_store.dart';
import '../../core/models/result.dart';
import '../models/auth/auth_token.dart';
import 'auth_repository.dart';

/// SharedPreferences-backed [AuthRepository] used while the real backend is
/// unavailable.
///
/// Delegates the heavy lifting to [AccountStore], which has owned the local
/// mock persistence model since Phase 1. The mock surface is intentionally
/// chatty so backend integration can later swap [AccountStore] calls with
/// `_dio.post(...)` calls one method at a time.
class MockAuthRepository implements AuthRepository {
  @override
  Future<Result<AuthToken>> login({
    required String email,
    required String password,
  }) async {
    final ParentAccount? account = await AccountStore.getAccountByEmail(email);
    if (account == null) {
      return Result<AuthToken>.failure(AuthFailureMessages.unknownEmail);
    }
    if (account.status == AccountStatus.dormant) {
      return Result<AuthToken>.failure(AuthFailureMessages.accountDormant);
    }
    final bool ok = await AccountStore.validateLogin(
      email: email,
      password: password,
    );
    if (!ok) {
      return Result<AuthToken>.failure(AuthFailureMessages.wrongPassword);
    }
    return Result<AuthToken>.success(
      AuthToken(
        accessToken: 'mock_access_${account.parentId}',
        refreshToken: 'mock_refresh_${account.parentId}',
        parentId: account.parentId,
        email: account.email,
        name: account.name,
      ),
    );
  }

  @override
  Future<Result<AuthToken>> signup({
    required String email,
    required String name,
    required String password,
  }) async {
    final ParentAccount? existing = await AccountStore.getAccountByEmail(email);
    if (existing != null) {
      return Result<AuthToken>.failure(AuthFailureMessages.duplicatedEmail);
    }
    final String parentId = AccountStore.parentIdFromEmail(email);
    final ParentAccount account = ParentAccount(
      parentId: parentId,
      email: email,
      name: name,
      passwordHash: AccountStore.passwordHashForLocalMock(password),
    );
    await AccountStore.saveAccount(account);
    return Result<AuthToken>.success(
      AuthToken(
        accessToken: 'mock_access_$parentId',
        refreshToken: 'mock_refresh_$parentId',
        parentId: parentId,
        email: email,
        name: name,
      ),
    );
  }

  @override
  Future<Result<AuthToken>> refreshToken(String refreshToken) async {
    return Result<AuthToken>.success(
      const AuthToken(
        accessToken: 'mock_access_refreshed',
        refreshToken: 'mock_refresh_rotated',
        parentId: '',
        email: '',
        name: '',
      ),
    );
  }

  @override
  Future<Result<void>> changePassword({
    required String parentId,
    required String currentPassword,
    required String newPassword,
  }) async {
    final ParentAccount? account = await AccountStore.getAccountById(parentId);
    if (account == null) {
      return Result<void>.failure(AuthFailureMessages.accountNotFound);
    }
    final String expected = AccountStore.passwordHashForLocalMock(
      currentPassword,
    );
    if (account.passwordHash != expected) {
      return Result<void>.failure(AuthFailureMessages.passwordMismatch);
    }
    await AccountStore.updatePassword(parentId: parentId, password: newPassword);
    return Result<void>.success(null);
  }

  @override
  Future<Result<void>> deleteAccount({
    required String parentId,
  }) async {
    try {
      await AccountStore.removeAccount(parentId);
      return Result<void>.success(null);
    } on StateError catch (e) {
      return Result<void>.failure(
        AuthFailureMessages.accountNotFound,
        cause: e,
      );
    }
  }

  @override
  Future<Result<void>> logout({String? refreshToken}) async {
    // Mock backend has no session table; report success so the caller still
    // clears local tokens.
    return Result<void>.success(null);
  }
}
