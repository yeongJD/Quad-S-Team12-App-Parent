import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/theme/app_typography.dart';
import '../models/notification_item.dart';

class NotificationCard extends StatefulWidget {
  const NotificationCard({
    super.key,
    required this.item,
    required this.onTap,
    required this.onActionTap,
    required this.onDeleteIntent,
  });

  final NotificationItem item;
  final VoidCallback onTap;
  final VoidCallback onActionTap;
  final Future<void> Function(NotificationItem item) onDeleteIntent;

  @override
  State<NotificationCard> createState() => _NotificationCardState();
}

class _NotificationCardState extends State<NotificationCard>
    with SingleTickerProviderStateMixin {
  static const double _maxSlide = 57.09;

  late final AnimationController _slideController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 180),
  );

  late Animation<double> _slideAnimation = AlwaysStoppedAnimation<double>(
    _dragOffset,
  );

  double _dragOffset = 0;
  bool _isShowingDialog = false;

  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }

  void _animateTo(double target) {
    _slideAnimation =
        Tween<double>(begin: _dragOffset, end: target).animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
        )..addListener(() {
          if (!mounted) {
            return;
          }
          setState(() {
            _dragOffset = _slideAnimation.value;
          });
        });

    _slideController
      ..reset()
      ..forward();
  }

  Future<void> _handleDragEnd() async {
    if (_dragOffset <= -_maxSlide * 0.4) {
      _animateTo(-_maxSlide);
      _isShowingDialog = true;
      await widget.onDeleteIntent(widget.item);
      if (!mounted) {
        return;
      }
      _isShowingDialog = false;
      _animateTo(0);
      return;
    }

    _animateTo(0);
  }

  @override
  Widget build(BuildContext context) {
    final _NotificationStyle style = _NotificationStyle.fromType(
      widget.item.type,
    );

    return GestureDetector(
      onHorizontalDragUpdate: (DragUpdateDetails details) {
        if (_isShowingDialog) {
          return;
        }
        setState(() {
          _dragOffset = (_dragOffset + details.delta.dx).clamp(-_maxSlide, 0);
        });
      },
      onHorizontalDragEnd: (_) => _handleDragEnd(),
      onHorizontalDragCancel: () => _animateTo(0),
      child: SizedBox(
        width: double.infinity,
        child: Stack(
          children: [
            Positioned.fill(
              child: Align(
                alignment: Alignment.centerRight,
                child: Container(
                  width: _maxSlide + 22,
                  decoration: BoxDecoration(
                    color: AppColors.destructiveSubtle,
                    borderRadius: BorderRadius.circular(AppTokens.dialogRadius),
                  ),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 16),
                      child: Opacity(
                        opacity: (-_dragOffset / _maxSlide).clamp(0, 1),
                        child: const _DeleteRevealIcon(),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Transform.translate(
              offset: Offset(_dragOffset, 0),
              child: GestureDetector(
                onTap: widget.onTap,
                behavior: HitTestBehavior.opaque,
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(AppTokens.dialogRadius),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          _NotificationLeadingIcon(style: style),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              widget.item.title,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.captionSemiBold.copyWith(
                                color: style.accentColor,
                                decoration: TextDecoration.none,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            widget.item.timeAgo,
                            style: AppTypography.captionRegular.copyWith(
                              color: AppColors.gray300,
                              decoration: TextDecoration.none,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        widget.item.message,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.labelMedium.copyWith(
                          color: AppColors.gray800,
                          decoration: TextDecoration.none,
                        ),
                      ),
                      const SizedBox(height: 12),
                      GestureDetector(
                        onTap: widget.onActionTap,
                        behavior: HitTestBehavior.opaque,
                        child: Text(
                          '${widget.item.actionLabel} →',
                          style: AppTypography.captionMedium.copyWith(
                            color: AppColors.gray500,
                            decoration: TextDecoration.none,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DeleteRevealIcon extends StatelessWidget {
  const _DeleteRevealIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 24,
      decoration: const BoxDecoration(
        color: AppColors.destructive,
        shape: BoxShape.circle,
      ),
      child: const Icon(Icons.close_rounded, size: 16, color: AppColors.white),
    );
  }
}

class _NotificationLeadingIcon extends StatelessWidget {
  const _NotificationLeadingIcon({required this.style});

  final _NotificationStyle style;

  @override
  Widget build(BuildContext context) {
    if (!style.hasBackground) {
      return SizedBox(
        width: 20,
        height: 20,
        child: Icon(style.icon, size: 18, color: style.accentColor),
      );
    }

    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        color: style.backgroundColor,
        shape: BoxShape.circle,
      ),
      child: Icon(
        style.icon,
        size: style.icon == Icons.schedule_rounded ? 13 : 14,
        color: AppColors.white,
      ),
    );
  }
}

class _NotificationStyle {
  const _NotificationStyle({
    required this.accentColor,
    required this.backgroundColor,
    required this.icon,
    this.hasBackground = true,
  });

  final Color accentColor;
  final Color backgroundColor;
  final IconData icon;
  final bool hasBackground;

  factory _NotificationStyle.fromType(NotificationType type) {
    switch (type) {
      case NotificationType.weeklyUsageReport:
        return const _NotificationStyle(
          accentColor: AppColors.primary,
          backgroundColor: AppColors.primary,
          icon: Icons.menu_book_rounded,
          hasBackground: false,
        );
      case NotificationType.missionCompleted:
        return const _NotificationStyle(
          accentColor: Color(0xFFFFCC33),
          backgroundColor: Color(0xFFFFCC33),
          icon: Icons.check_rounded,
        );
      case NotificationType.missionConfirmationRequested:
        return const _NotificationStyle(
          accentColor: AppColors.positive,
          backgroundColor: AppColors.positive,
          icon: Icons.autorenew_rounded,
        );
      case NotificationType.timeConfigured:
        return const _NotificationStyle(
          accentColor: AppColors.primary,
          backgroundColor: AppColors.primary,
          icon: Icons.schedule_rounded,
        );
    }
  }
}
