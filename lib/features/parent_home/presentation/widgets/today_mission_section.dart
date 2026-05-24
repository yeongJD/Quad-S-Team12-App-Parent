import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../models/parent_home_models.dart';

class TodayMissionSection extends StatelessWidget {
  const TodayMissionSection({
    super.key,
    required this.missions,
    required this.completedCount,
    required this.totalCount,
    required this.onOpen,
    required this.onSetup,
    required this.onAdd,
    required this.onMissionTap,
  });

  final List<MissionItem> missions;
  final int completedCount;
  final int totalCount;
  final VoidCallback onOpen;
  final VoidCallback onSetup;
  final VoidCallback onAdd;
  final ValueChanged<int> onMissionTap;

  bool get _hasData => missions.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: _hasData ? onOpen : onSetup,
              behavior: HitTestBehavior.opaque,
              child: Text(
                '오늘의 미션',
                style: AppTypography.headlineBold.copyWith(
                  fontSize: 18,
                  height: 1.4,
                  letterSpacing: -0.22,
                  color: AppColors.black,
                ),
              ),
            ),
            const SizedBox(width: 6),
            GestureDetector(
              onTap: onSetup,
              behavior: HitTestBehavior.opaque,
              child: SvgPicture.asset(
                'assets/icons/arrow button/Settings.svg',
                width: 18,
                height: 18,
              ),
            ),
            const Spacer(),
            Text(
              '$completedCount개 완료',
              style: AppTypography.labelBold.copyWith(
                fontSize: 12.587,
                height: 1.429,
                letterSpacing: 0.18,
                color: AppColors.gray700,
              ),
            ),
            const SizedBox(width: 7),
            Container(width: 1, height: 12.587, color: AppColors.gray300),
            const SizedBox(width: 7),
            Text(
              '$totalCount',
              style: AppTypography.labelBold.copyWith(
                fontSize: 12.587,
                height: 1.429,
                letterSpacing: 0.18,
                color: AppColors.gray200,
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        if (_hasData) ...[
          Column(
            children: [
              for (int index = 0; index < missions.length; index++) ...[
                _MissionCard(
                  item: missions[index],
                  onTitleTap: () => onMissionTap(index),
                ),
                if (index != missions.length - 1) const SizedBox(height: 11),
              ],
            ],
          ),
          const SizedBox(height: 18),
          Center(
            child: GestureDetector(
              onTap: onAdd,
              behavior: HitTestBehavior.opaque,
              child: const _MissionAddButton(),
            ),
          ),
        ] else
          Center(
            child: Padding(
              padding: const EdgeInsets.only(top: 43, bottom: 40),
              child: GestureDetector(
                onTap: onAdd,
                behavior: HitTestBehavior.opaque,
                child: const _MissionAddButton(),
              ),
            ),
          ),
      ],
    );
  }
}

class _MissionCard extends StatelessWidget {
  const _MissionCard({required this.item, required this.onTitleTap});

  final MissionItem item;
  final VoidCallback onTitleTap;

  @override
  Widget build(BuildContext context) {
    final bool isCompleted = item.status == MissionStatus.completed;
    final TextDecoration? lineThrough = isCompleted
        ? TextDecoration.lineThrough
        : null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 17.082, vertical: 16.183),
      decoration: BoxDecoration(
        color: isCompleted ? const Color(0xFFEDEEF1) : AppColors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Opacity(
            opacity: isCompleted ? 0.3 : 1,
            child: SvgPicture.asset(
              item.iconAsset,
              width: 43.156,
              height: 43.156,
            ),
          ),
          const SizedBox(width: 17),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: onTitleTap,
                  behavior: HitTestBehavior.opaque,
                  child: Text(
                    item.title,
                    style: AppTypography.labelMedium.copyWith(
                      fontSize: isCompleted ? 16 : 14.39,
                      height: 1.5,
                      letterSpacing: isCompleted ? 0.0912 : 0.082,
                      color: isCompleted
                          ? AppColors.gray300
                          : AppColors.gray800,
                      decoration: lineThrough,
                      decorationColor: isCompleted ? AppColors.gray300 : null,
                    ),
                  ),
                ),
                const SizedBox(height: 2.7),
                Text(
                  item.reward,
                  style: AppTypography.captionRegular.copyWith(
                    fontSize: isCompleted ? 12 : 10.79,
                    height: 1.334,
                    letterSpacing: isCompleted ? 0.3024 : 0.2719,
                    color: isCompleted ? AppColors.gray300 : AppColors.gray500,
                    decoration: lineThrough,
                    decorationColor: isCompleted ? AppColors.gray300 : null,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          _MissionStatusIcon(status: item.status),
        ],
      ),
    );
  }
}

class _MissionStatusIcon extends StatelessWidget {
  const _MissionStatusIcon({required this.status});

  final MissionStatus status;

  @override
  Widget build(BuildContext context) {
    switch (status) {
      case MissionStatus.completed:
        return const _StatusCircle(
          backgroundColor: AppColors.positive,
          icon: Icons.check_rounded,
          iconColor: AppColors.white,
        );
      case MissionStatus.reviewing:
        return const _ProgressStatusCircle();
      case MissionStatus.pending:
        return const _StatusCircle(
          backgroundColor: AppColors.gray200,
          icon: Icons.radio_button_unchecked_rounded,
          iconColor: AppColors.gray400,
        );
      case MissionStatus.rejected:
        return const _StatusCircle(
          backgroundColor: AppColors.destructive,
          icon: Icons.close_rounded,
          iconColor: AppColors.white,
        );
    }
  }
}

class _ProgressStatusCircle extends StatelessWidget {
  const _ProgressStatusCircle();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 21.578,
      height: 21.578,
      decoration: const BoxDecoration(
        color: AppColors.cautionary,
        shape: BoxShape.circle,
      ),
      child: const Icon(Icons.sync_rounded, size: 13, color: AppColors.white),
    );
  }
}

class _StatusCircle extends StatelessWidget {
  const _StatusCircle({
    required this.backgroundColor,
    required this.icon,
    required this.iconColor,
  });

  final Color backgroundColor;
  final IconData icon;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 21.578,
      height: 21.578,
      decoration: BoxDecoration(color: backgroundColor, shape: BoxShape.circle),
      child: Icon(icon, size: 13, color: iconColor),
    );
  }
}

class _MissionAddButton extends StatelessWidget {
  const _MissionAddButton();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 35.963,
      height: 35.963,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Color(0xFFEBF5FE),
      ),
      child: const Center(
        child: _AddIcon(color: AppColors.primary, size: 21.578),
      ),
    );
  }
}

class _AddIcon extends StatelessWidget {
  const _AddIcon({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    const double stroke = 1.8;

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
