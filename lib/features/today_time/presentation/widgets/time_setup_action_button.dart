import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../styles/time_setup_tokens.dart';

class TimeSetupActionButton extends StatelessWidget {
  const TimeSetupActionButton({
    super.key,
    required this.label,
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: TimeSetupSize.bottomButtonHeight,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: enabled ? AppColors.primary : TimeSetupPalette.disabledButton,
          borderRadius: BorderRadius.circular(TimeSetupRadius.control),
        ),
        child: Text(
          label,
          style: TimeSetupTextStyles.confirmLabel(enabled: enabled),
        ),
      ),
    );
  }
}

class TimeSetupAddButton extends StatelessWidget {
  const TimeSetupAddButton({
    super.key,
    required this.onTap,
    this.muted = false,
    this.enabled = true,
  });

  final VoidCallback onTap;
  final bool muted;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '시간 추가',
      button: true,
      child: GestureDetector(
        key: const ValueKey<String>('daily-time-add-button'),
        onTap: enabled ? onTap : null,
        behavior: HitTestBehavior.opaque,
        child: Container(
          width: TimeSetupSize.addButton,
          height: TimeSetupSize.addButton,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: muted
                ? TimeSetupPalette.mutedAddBackground
                : TimeSetupPalette.tipBackground,
          ),
          child: Center(
            child: PlusIcon(
              size: TimeSetupSize.addIcon,
              color: muted ? AppColors.gray400 : AppColors.primary,
            ),
          ),
        ),
      ),
    );
  }
}

class PlusIcon extends StatelessWidget {
  const PlusIcon({super.key, required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    const double stroke = 2;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: stroke,
            height: size * 0.75,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          Container(
            width: size * 0.75,
            height: stroke,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ],
      ),
    );
  }
}
