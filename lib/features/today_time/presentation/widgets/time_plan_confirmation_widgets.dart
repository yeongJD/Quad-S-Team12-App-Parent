import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/theme/app_typography.dart';
import '../models/daily_time_rule.dart';
import '../styles/time_setup_tokens.dart';

class TimePlanSectionHeader extends StatelessWidget {
  const TimePlanSectionHeader({super.key, required this.title, this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: AppTypography.headlineSemiBold.copyWith(
              color: AppColors.gray800,
            ),
          ),
        ),
        ?trailing,
      ],
    );
  }
}

class TimeAmountBox extends StatelessWidget {
  const TimeAmountBox({super.key, required this.time});

  final TimeSelection time;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 45,
      width: double.infinity,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(TimeSetupRadius.field),
        border: Border.all(color: AppColors.gray200),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [TimeAmountText(time: time)],
      ),
    );
  }
}

class TimeAmountText extends StatelessWidget {
  const TimeAmountText({
    super.key,
    required this.time,
    this.valueColor = AppColors.inkBlack,
    this.textColor = AppColors.inkBlack,
  });

  final TimeSelection time;
  final Color valueColor;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    final TextStyle valueStyle = AppTypography.bodySemiBold.copyWith(
      color: valueColor,
    );
    final TextStyle labelStyle = AppTypography.bodyRegular.copyWith(
      color: textColor,
    );

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('${time.hour}', style: valueStyle),
        const SizedBox(width: 9),
        Text('시간', style: labelStyle),
        const SizedBox(width: 22),
        Text(time.minuteText, style: valueStyle),
        const SizedBox(width: 9),
        Text('분', style: labelStyle),
      ],
    );
  }
}

class EditTimeButton extends StatelessWidget {
  const EditTimeButton({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: TimeSetupPalette.tipBackground,
      borderRadius: BorderRadius.circular(AppTokens.buttonRadius),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        hoverColor: AppColors.primary.withValues(alpha: 0.08),
        highlightColor: AppColors.primary.withValues(alpha: 0.12),
        splashColor: AppColors.primary.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(AppTokens.buttonRadius),
        child: SizedBox(
          height: 28,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.edit_rounded,
                  size: 17,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 6),
                Text(
                  '수정하기',
                  style: AppTypography.labelMedium.copyWith(
                    color: AppColors.primary,
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

class RevisionToggle extends StatelessWidget {
  const RevisionToggle({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '수정허용',
          style: AppTypography.labelMedium.copyWith(color: AppColors.gray300),
        ),
        const SizedBox(width: 6),
        GestureDetector(
          onTap: () => onChanged(!value),
          behavior: HitTestBehavior.opaque,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            width: 40,
            height: 24,
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: value ? AppColors.primary : AppColors.gray200,
              borderRadius: BorderRadius.circular(200),
            ),
            child: AnimatedAlign(
              duration: const Duration(milliseconds: 160),
              curve: Curves.easeOutCubic,
              alignment: value ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                width: 18,
                height: 18,
                decoration: const BoxDecoration(
                  color: AppColors.white,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class DailyPlanRuleList extends StatelessWidget {
  const DailyPlanRuleList({super.key, required this.rules});

  final List<DailyTimeRule> rules;

  @override
  Widget build(BuildContext context) {
    if (rules.isEmpty) {
      return Text(
        '자녀가 아직 이번주의 사용 계획을 설정하지 않았어요.',
        textAlign: TextAlign.center,
        style: AppTypography.bodyMedium.copyWith(color: AppColors.gray300),
      );
    }

    return Column(
      children: rules
          .map(
            (DailyTimeRule rule) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: DailyPlanRuleCard(rule: rule),
            ),
          )
          .toList(),
    );
  }
}

class DailyPlanRuleCard extends StatelessWidget {
  const DailyPlanRuleCard({super.key, required this.rule});

  final DailyTimeRule rule;

  @override
  Widget build(BuildContext context) {
    final TextStyle textStyle = AppTypography.bodySemiBold.copyWith(
      color: AppColors.gray800,
    );

    return Container(
      width: double.infinity,
      height: 68,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppTokens.cardRadiusSmall),
      ),
      child: Row(
        children: [
          Text(rule.dayText, style: textStyle),
          Container(
            width: 1,
            height: 20,
            margin: const EdgeInsets.symmetric(horizontal: 18),
            color: AppColors.gray200,
          ),
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: TimeAmountText(
                time: rule.time,
                valueColor: AppColors.gray800,
                textColor: AppColors.gray800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
