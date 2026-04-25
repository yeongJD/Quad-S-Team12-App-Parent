import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/auth/auth_session.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

class DeleteAccountCompletePage extends StatefulWidget {
  const DeleteAccountCompletePage({super.key});

  @override
  State<DeleteAccountCompletePage> createState() =>
      _DeleteAccountCompletePageState();
}

class _DeleteAccountCompletePageState extends State<DeleteAccountCompletePage> {
  Timer? _redirectTimer;

  @override
  void initState() {
    super.initState();
    unawaited(AuthSession.clearLogin());
    _redirectTimer = Timer(const Duration(seconds: 3), () {
      if (!mounted) {
        return;
      }
      context.go('/');
    });
  }

  @override
  void dispose() {
    _redirectTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                child: Text(
                  '탈퇴가 완료되었습니다.\n언제든 다시 찾아와주세요!',
                  textAlign: TextAlign.center,
                  style: AppTypography.heading2Regular.copyWith(
                    fontSize: 17.982,
                    height: 1.4,
                    letterSpacing: -0.2158,
                    color: AppColors.gray600,
                    decoration: TextDecoration.none,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
