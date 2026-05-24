import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

class SignupCompletePage extends StatelessWidget {
  const SignupCompletePage({super.key});

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
                    '회원가입이 완료되었습니다.',
                    textAlign: TextAlign.center,
                    style: AppTypography.headlineRegular.copyWith(
                      fontSize: 17.982,
                      height: 1.4,
                      letterSpacing: -0.2158,
                      color: AppColors.gray600,
                    ),
                  ),
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: FilledButton(
                      onPressed: () => context.go('/parent-home'),
                      style: FilledButton.styleFrom(
                        elevation: 0,
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        '시작하기',
                        style: AppTypography.headlineMedium.copyWith(
                          fontSize: 18,
                          height: 1.445,
                          letterSpacing: -0.0036,
                          color: AppColors.white,
                        ),
                      ),
                    ),
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
