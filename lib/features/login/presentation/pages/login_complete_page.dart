import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

class LoginCompletePage extends StatelessWidget {
  const LoginCompletePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.gray050,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 375),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 29),
              child: Column(
                children: [
                  const Spacer(),
                  Text(
                    '로그인이  완료되었습니다.',
                    textAlign: TextAlign.center,
                    style: AppTypography.headlineRegular.copyWith(
                      fontSize: 17.982,
                      height: 1.4,
                      letterSpacing: -0.2158,
                      color: AppColors.gray600,
                    ),
                  ),
                  const Spacer(),
                  _LoginCompleteButton(
                    label: '시작하기',
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.white,
                    onPressed: () => context.go('/parent-home'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LoginCompleteButton extends StatelessWidget {
  const _LoginCompleteButton({
    required this.label,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.onPressed,
  });

  final String label;
  final Color backgroundColor;
  final Color foregroundColor;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 49,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          elevation: 0,
          backgroundColor: backgroundColor,
          foregroundColor: foregroundColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTypography.headlineMedium.copyWith(
            fontSize: 16.18,
            height: 1.445,
            letterSpacing: -0.0032,
            color: foregroundColor,
          ),
        ),
      ),
    );
  }
}
