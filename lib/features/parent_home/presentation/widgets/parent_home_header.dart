import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

class ParentHomeHeader extends StatelessWidget {
  const ParentHomeHeader({
    super.key,
    required this.hasUnreadNotification,
    required this.onMyTap,
    required this.onNotificationTap,
  });

  final bool hasUnreadNotification;
  final VoidCallback onMyTap;
  final VoidCallback onNotificationTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: onMyTap,
            behavior: HitTestBehavior.opaque,
            child: Container(
              width: 33,
              height: 24,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                border: Border(
                  left: BorderSide(color: AppColors.gray800, width: 1.8),
                ),
              ),
              child: Text(
                'my',
                style: AppTypography.labelBold.copyWith(
                  fontSize: 12.6,
                  height: 1.429,
                  letterSpacing: 0.18,
                  color: AppColors.gray800,
                ),
              ),
            ),
          ),
          GestureDetector(
            onTap: onNotificationTap,
            behavior: HitTestBehavior.opaque,
            child: SizedBox(
              width: 32,
              height: 32,
              child: Center(
                child: SvgPicture.asset(
                  hasUnreadNotification
                      ? 'assets/icons/속성 1=새알림.svg'
                      : 'assets/icons/속성 1=알림없음.svg',
                  width: 28.77,
                  height: 28.77,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
