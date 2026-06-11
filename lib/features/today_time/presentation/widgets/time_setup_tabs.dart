import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../styles/time_setup_tokens.dart';

class TimeSetupTabData {
  const TimeSetupTabData({required this.label, required this.enabled});

  final String label;
  final bool enabled;
}

class TimeSetupTabs extends StatelessWidget {
  const TimeSetupTabs({
    super.key,
    required this.tabs,
    required this.selectedIndex,
    required this.onTabSelected,
  });

  final List<TimeSetupTabData> tabs;
  final int selectedIndex;
  final ValueChanged<int> onTabSelected;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: tabs.asMap().entries.map((MapEntry<int, TimeSetupTabData> tab) {
        final bool selected = tab.key == selectedIndex;
        return Expanded(
          child: GestureDetector(
            onTap: tab.value.enabled ? () => onTabSelected(tab.key) : null,
            behavior: HitTestBehavior.opaque,
            child: Container(
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected ? AppColors.primary : AppColors.gray100,
                borderRadius: BorderRadius.circular(TimeSetupRadius.control),
              ),
              child: Text(
                tab.value.label,
                style: AppTypography.labelMedium.copyWith(
                  color: selected ? AppColors.white : AppColors.gray500,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
