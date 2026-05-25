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
          Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(6),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onMyTap,
              hoverColor: AppColors.gray800.withValues(alpha: 0.06),
              highlightColor: AppColors.gray800.withValues(alpha: 0.10),
              splashColor: AppColors.gray800.withValues(alpha: 0.12),
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
          ),
          Material(
            color: Colors.transparent,
            shape: const CircleBorder(),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onNotificationTap,
              hoverColor: AppColors.gray800.withValues(alpha: 0.06),
              highlightColor: AppColors.gray800.withValues(alpha: 0.10),
              splashColor: AppColors.gray800.withValues(alpha: 0.12),
              customBorder: const CircleBorder(),
              child: SizedBox(
                width: 32,
                height: 32,
                child: _NotificationIcon(hasUnread: hasUnreadNotification),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationIcon extends StatelessWidget {
  const _NotificationIcon({required this.hasUnread});

  final bool hasUnread;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Center(
          child: SvgPicture.asset(
            'assets/icons/alert.svg',
            width: 32,
            height: 32,
          ),
        ),
        if (hasUnread)
          Positioned(
            top: 4,
            right: 4,
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: AppColors.destructive,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.white, width: 1),
              ),
            ),
          ),
      ],
    );
  }
}
