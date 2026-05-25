import '../../core/config/environment.dart';
import '../../core/models/result.dart';
import '../models/auth/auth_token.dart';
import 'api_auth_repository.dart';
import 'mock_auth_repository.dart';

/// Repository contract for authentication operations (login, signup, refresh,
/// password change, account deletion, logout).
///
/// Implementations return [Result] so the presentation layer can branch on
/// success / failure without exceptions leaking into widget code. Failure
/// messages are user-facing Korean strings that pages map back into their
/// local error enums.
abstract interface class AuthRepository {
  Future<Result<AuthToken>> login({
    required String email,
    required String password,
  });

  Future<Result<AuthToken>> signup({
    required String email,
    required String name,
    required String password,
  });

  /// Exchanges a [refreshToken] for a fresh access/refresh pair.
  ///
  /// The Dio 401 interceptor uses a separate, interceptor-free client to
  /// perform this exchange (so the refresh call itself cannot recurse). This
  /// method exists for callers that want an explicit refresh — e.g. a future
  /// "force re-auth" admin flow — and for tests.
  Future<Result<AuthToken>> refreshToken(String refreshToken);

  Future<Result<void>> changePassword({
    required String parentId,
    required String currentPassword,
    required String newPassword,
  });

  Future<Result<void>> deleteAccount({
    required String parentId,
  });

  /// Best-effort backend logout — the server invalidates the refresh token.
  /// Local cleanup (AuthSession.clearTokens / logout) is always the caller's
  /// responsibility, even when this fails.
  Future<Result<void>> logout({String? refreshToken});
}

final AuthRepository _authRepository = currentEnvironment.useMocks
    ? MockAuthRepository()
    : ApiAuthRepository();

/// Factory that resolves the active [AuthRepository] implementation. The
/// instance is cached so every call site shares the same Dio (and therefore
/// the same interceptor chain).
AuthRepository createAuthRepository() => _authRepository;

/// Canonical failure messages emitted by [MockAuthRepository]. Exposed as
/// constants so login/signup/password-change pages can do exact-match
/// comparisons when mapping back into their local error enums.
abstract final class AuthFailureMessages {
  static const String unknownEmail = '가입되지 않은 이메일이에요.';
  static const String wrongPassword = '비밀번호가 일치하지 않아요.';
  static const String duplicatedEmail = '이미 사용 중인 이메일이에요.';
  static const String accountDormant = '휴면 계정이에요. 고객센터에 문의해 주세요.';
  static const String accountNotFound = '계정을 찾을 수 없어요.';
  static const String passwordMismatch = '현재 비밀번호가 일치하지 않아요.';
}
