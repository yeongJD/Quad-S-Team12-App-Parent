import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../models/daily_time_rule.dart';
import '../routes/today_time_routes.dart';
import '../styles/time_setup_tokens.dart';
import '../widgets/time_setup_action_button.dart';
import '../widgets/time_setup_top_bar.dart';
import 'whitelist_setup_page.dart';

class TodayTimeCompleteData {
  const TodayTimeCompleteData({
    required this.total,
    required this.rules,
    this.parentId,
    this.childrenId,
    this.whitelistAppIds = const <String>{},
  });

  final String? parentId;
  final String? childrenId;
  final TimeSelection total;
  final List<DailyTimeRule> rules;
  final Set<String> whitelistAppIds;
}

class TodayTimeCompletePage extends StatelessWidget {
  const TodayTimeCompletePage({super.key, this.data});

  final TodayTimeCompleteData? data;

  void _handleBack(BuildContext context) {
    final TodayTimeCompleteData? completeData = data;
    if (completeData == null) {
      context.go(TodayTimeRoutes.whitelist);
      return;
    }
    context.go(
      TodayTimeRoutes.whitelist,
      extra: WhitelistSetupArgs(
        parentId: completeData.parentId,
        childrenId: completeData.childrenId,
        total: completeData.total,
        rules: completeData.rules,
        initialSelectedAppIds: completeData.whitelistAppIds,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.gray050,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: TimeSetupSpacing.screenMaxWidth,
            ),
            child: Column(
              children: [
                TimeSetupTopBar(
                  title: '시간설정',
                  onBack: () => _handleBack(context),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
                    child: Column(
                      children: [
                        const Spacer(flex: 18),
                        Text(
                          '시간 설정 완료!',
                          style: AppTypography.headlineBold.copyWith(
                            fontSize: 28,
                            height: 1.445,
                            letterSpacing: -0.0056,
                            color: AppColors.gray900,
                          ),
                        ),
                        const SizedBox(height: 41),
                        Container(
                          width: 114,
                          height: 114,
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.check_rounded,
                            color: AppColors.white,
                            size: 52,
                          ),
                        ),
                        const SizedBox(height: 76),
                        Text(
                          '이번 달 총 시간이 자녀에게 전달되었어요.\n'
                          '자녀가 스스로 분배 계획을 세울 때까지\n'
                          '잠시만 기다려주세요!',
                          textAlign: TextAlign.center,
                          style: AppTypography.headlineMedium.copyWith(
                            fontSize: 16,
                            height: 1.625,
                            letterSpacing: -0.0032,
                            color: AppColors.gray600,
                          ),
                        ),
                        const Spacer(flex: 23),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 31),
                  child: TimeSetupActionButton(
                    label: '홈으로',
                    enabled: true,
                    onTap: () => context.go('/parent-home'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
