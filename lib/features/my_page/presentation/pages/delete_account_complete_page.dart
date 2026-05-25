import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/auth/auth_session.dart';
import '../../../../core/models/result.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../data/repositories/auth_repository.dart';

class DeleteAccountCompletePage extends StatefulWidget {
  const DeleteAccountCompletePage({super.key});

  @override
  State<DeleteAccountCompletePage> createState() =>
      _DeleteAccountCompletePageState();
}

class _DeleteAccountCompletePageState extends State<DeleteAccountCompletePage> {
  Timer? _redirectTimer;
  _DeleteAccountState _state = _DeleteAccountState.processing;

  @override
  void initState() {
    super.initState();
    unawaited(_deleteAccount());
  }

  Future<void> _deleteAccount() async {
    try {
      final String? parentId = await AuthSession.getCurrentParentId();
      if (parentId == null) {
        throw StateError('Cannot delete account without an active session.');
      }

      final AuthRepository authRepository = createAuthRepository();
      final Result<void> result = await authRepository.deleteAccount(
        parentId: parentId,
      );
      if (result is Failure<void>) {
        throw StateError(result.message);
      }
      await AuthSession.resetAllData();
      await AuthSession.clearTokens();
      await AuthSession.logout();

      if (!mounted) {
        return;
      }
      setState(() {
        _state = _DeleteAccountState.success;
      });
      _redirectTimer = Timer(const Duration(seconds: 3), () {
        if (!mounted) {
          return;
        }
        context.go('/');
      });
    } catch (error, stackTrace) {
      debugPrint('Account deletion failed: $error\n$stackTrace');
      if (!mounted) {
        return;
      }
      setState(() {
        _state = _DeleteAccountState.failure;
      });
    }
  }

  @override
  void dispose() {
    _redirectTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final String message = switch (_state) {
      _DeleteAccountState.processing => '탈퇴를 처리하고 있습니다.',
      _DeleteAccountState.success => '탈퇴가 완료되었습니다.\n언제든 다시 찾아와주세요!',
      _DeleteAccountState.failure => '탈퇴 처리 중 문제가 발생했습니다.\n잠시 후 다시 시도해주세요.',
    };

    return Scaffold(
      backgroundColor: AppColors.gray050,
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 375),
            child: Center(
              child: SizedBox(
                width: 294.897,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      message,
                      textAlign: TextAlign.center,
                      style: AppTypography.heading2Regular.copyWith(
                        fontSize: 17.982,
                        height: 1.4,
                        letterSpacing: -0.2158,
                        color: AppColors.gray600,
                        decoration: TextDecoration.none,
                      ),
                    ),
                    if (_state == _DeleteAccountState.failure) ...[
                      const SizedBox(height: 24),
                      GestureDetector(
                        onTap: () => context.go('/mypage'),
                        behavior: HitTestBehavior.opaque,
                        child: Container(
                          width: 120,
                          height: 40,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '돌아가기',
                            style: AppTypography.labelMedium.copyWith(
                              color: AppColors.white,
                              decoration: TextDecoration.none,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

enum _DeleteAccountState { processing, success, failure }
