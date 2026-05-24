import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
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
    if (_dragOffset <= -_maxSlide * 0.85) {
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
                    color: const Color(0xFFFFD3D3),
                    borderRadius: BorderRadius.circular(14.385),
                  ),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 16.183),
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
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14.385,
                    vertical: 12.587,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          _NotificationLeadingIcon(style: style),
                          const SizedBox(width: 3.596),
                          Text(
                            widget.item.title,
                            style: AppTypography.labelBold.copyWith(
                              fontSize: 10.79,
                              height: 1.334,
                              letterSpacing: 0.2719,
                              color: style.accentColor,
                              decoration: TextDecoration.none,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            widget.item.timeAgo,
                            style: AppTypography.captionRegular.copyWith(
                              fontSize: 10.79,
                              height: 1.334,
                              letterSpacing: 0.2719,
                              color: AppColors.gray300,
                              decoration: TextDecoration.none,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10.789),
                      Text(
                        widget.item.message,
                        style: AppTypography.labelMedium.copyWith(
                          fontSize: 12.59,
                          height: 1.429,
                          letterSpacing: 0.1826,
                          color: AppColors.gray800,
                          decoration: TextDecoration.none,
                        ),
                      ),
                      const SizedBox(height: 10.789),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: _NotificationActionChip(
                          label: widget.item.actionLabel,
                          onTap: widget.onActionTap,
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

class _NotificationActionChip extends StatelessWidget {
  const _NotificationActionChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 24,
        padding: const EdgeInsets.symmetric(horizontal: 9),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.gray100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          '$label →',
          style: AppTypography.captionBold.copyWith(
            fontSize: 11,
            height: 1.334,
            letterSpacing: 0,
            color: AppColors.gray500,
            decoration: TextDecoration.none,
          ),
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
      width: 21.578,
      height: 21.578,
      decoration: const BoxDecoration(
        color: Color(0xFFFF4B4B),
        shape: BoxShape.circle,
      ),
      child: const Icon(Icons.close_rounded, size: 14, color: AppColors.white),
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
        width: 18,
        height: 18,
        child: Icon(style.icon, size: 17, color: style.accentColor),
      );
    }

    return Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        color: style.backgroundColor,
        shape: BoxShape.circle,
      ),
      child: Icon(
        style.icon,
        size: style.icon == Icons.schedule_rounded ? 11 : 12,
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
