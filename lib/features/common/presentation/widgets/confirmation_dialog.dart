import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

Future<void> showAppConfirmationDialog({
  required BuildContext context,
  required String message,
  required VoidCallback onConfirm,
  String barrierLabel = 'confirmation-dialog',
}) {
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: barrierLabel,
    barrierColor: const Color.fromRGBO(68, 68, 68, 0.6),
    pageBuilder: (context, animation, secondaryAnimation) {
      return Material(
        type: MaterialType.transparency,
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 375),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 21),
                child: AppConfirmationDialog(
                  message: message,
                  onConfirm: onConfirm,
                ),
              ),
            ),
          ),
        ),
      );
    },
    transitionDuration: const Duration(milliseconds: 160),
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
        child: child,
      );
    },
  );
}

class AppConfirmationDialog extends StatelessWidget {
  const AppConfirmationDialog({
    super.key,
    required this.message,
    required this.onConfirm,
  });

  final String message;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 294.897,
      height: 189.705,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 33, 18, 27),
        child: Column(
          children: [
            Container(
              width: 28.77,
              height: 28.77,
              decoration: const BoxDecoration(
                color: AppColors.destructive,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: SizedBox(
                  width: 8,
                  height: 16,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Positioned(
                        top: 1.5,
                        child: Container(
                          width: 2.4,
                          height: 9.6,
                          decoration: BoxDecoration(
                            color: AppColors.white,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 0.5,
                        child: Container(
                          width: 2.4,
                          height: 2.4,
                          decoration: const BoxDecoration(
                            color: AppColors.white,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: AppTypography.labelBold.copyWith(
                fontSize: 14.39,
                height: 1.5,
                letterSpacing: 0.082,
                color: AppColors.gray800,
                decoration: TextDecoration.none,
              ),
            ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _ConfirmationDialogButton(
                  label: '취소',
                  filled: false,
                  onTap: context.pop,
                ),
                const SizedBox(width: 13.486),
                _ConfirmationDialogButton(
                  label: '확인',
                  filled: true,
                  onTap: onConfirm,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ConfirmationDialogButton extends StatelessWidget {
  const _ConfirmationDialogButton({
    required this.label,
    required this.filled,
    required this.onTap,
  });

  final String label;
  final bool filled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color foregroundColor = filled ? AppColors.white : AppColors.primary;

    return Material(
      color: filled ? AppColors.primary : const Color(0xFFEBF5FE),
      borderRadius: BorderRadius.circular(8),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        hoverColor: foregroundColor.withValues(alpha: 0.08),
        highlightColor: foregroundColor.withValues(alpha: 0.12),
        splashColor: foregroundColor.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 107.889,
          height: 37.761,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            border: filled
                ? null
                : Border.all(color: AppColors.primary, width: 0.899),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            style: AppTypography.labelMedium.copyWith(
              fontSize: 12.59,
              height: 1.429,
              letterSpacing: 0.1826,
              color: foregroundColor,
              decoration: TextDecoration.none,
            ),
          ),
        ),
      ),
    );
  }
}
