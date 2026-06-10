import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../styles/time_setup_tokens.dart';

class TimeSetupHeader extends StatelessWidget {
  const TimeSetupHeader({
    super.key,
    required this.title,
    required this.description,
    required this.showTip,
    required this.onTipTap,
  });

  final String title;
  final String description;
  final bool showTip;
  final VoidCallback onTipTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Flexible(
              child: Text(title, style: TimeSetupTextStyles.sectionTitle),
            ),
            const SizedBox(width: 10),
            TipButton(active: showTip, onTap: onTipTap),
          ],
        ),
        const SizedBox(height: TimeSetupSpacing.titleToDescriptionGap),
        Text(description, style: TimeSetupTextStyles.description),
      ],
    );
  }
}

class TipButton extends StatelessWidget {
  const TipButton({super.key, required this.active, required this.onTap});

  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 27,
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
        decoration: BoxDecoration(
          color: TimeSetupPalette.tipBackground,
          borderRadius: BorderRadius.circular(TimeSetupRadius.control),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              active ? Icons.lightbulb : Icons.lightbulb_outline,
              size: 18,
              color: AppColors.primary,
            ),
            const SizedBox(width: 5),
            Text(
              'Tip',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
