import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../models/daily_time_rule.dart';
import '../styles/time_setup_tokens.dart';
import 'time_setup_action_button.dart';

class DailyTimeRuleList extends StatelessWidget {
  const DailyTimeRuleList({
    super.key,
    required this.rules,
    required this.onEdit,
    required this.onAdd,
  });

  final List<DailyTimeRule> rules;
  final ValueChanged<int> onEdit;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ...rules.asMap().entries.map((MapEntry<int, DailyTimeRule> entry) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 15),
            child: DailyTimeRuleCard(
              rule: entry.value,
              onEdit: () => onEdit(entry.key),
            ),
          );
        }),
        TimeSetupAddButton(onTap: onAdd, muted: true),
      ],
    );
  }
}

class DailyTimeRuleCard extends StatelessWidget {
  const DailyTimeRuleCard({
    super.key,
    required this.rule,
    required this.onEdit,
  });

  final DailyTimeRule rule;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(TimeSetupRadius.card),
      ),
      child: Row(
        children: [
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Row(
                children: [
                  Text(
                    rule.dayText,
                    style: AppTypography.headlineBold.copyWith(
                      fontSize: 18,
                      height: 1.445,
                      letterSpacing: 0,
                      color: AppColors.gray800,
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 22,
                    margin: const EdgeInsets.symmetric(horizontal: 10),
                    color: AppColors.gray200,
                  ),
                  Text(
                    rule.time.displayText,
                    style: AppTypography.headlineBold.copyWith(
                      fontSize: 18,
                      height: 1.445,
                      letterSpacing: 0,
                      color: AppColors.gray800,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 14),
          GestureDetector(
            onTap: onEdit,
            behavior: HitTestBehavior.opaque,
            child: const Icon(
              Icons.edit_outlined,
              size: 24,
              color: AppColors.gray800,
            ),
          ),
        ],
      ),
    );
  }
}
