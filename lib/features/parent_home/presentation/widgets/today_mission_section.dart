import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
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
  final void Function(int index, {bool goToReview}) onMissionTap;

  bool get _hasData => missions.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(6),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: _hasData ? onOpen : onSetup,
                hoverColor: AppColors.gray800.withValues(alpha: 0.06),
                highlightColor: AppColors.gray800.withValues(alpha: 0.10),
                splashColor: AppColors.gray800.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
                child: Text(
                  '오늘의 미션',
                  style: AppTypography.headlineSemiBold.copyWith(
                    color: AppColors.black,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 6),
            _SettingsIconButton(onTap: onSetup),
            const Spacer(),
            Text(
              '$completedCount개 완료',
              style: AppTypography.captionSemiBold.copyWith(
                color: AppColors.gray700,
              ),
            ),
            const SizedBox(width: 7),
            Container(width: 1, height: 12, color: AppColors.gray300),
            const SizedBox(width: 7),
            Text(
              '$totalCount',
              style: AppTypography.captionSemiBold.copyWith(
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
                  onTap: (bool goToReview) =>
                      onMissionTap(index, goToReview: goToReview),
                ),
                if (index != missions.length - 1) const SizedBox(height: 11),
              ],
            ],
          ),
          const SizedBox(height: 18),
          Center(child: _MissionAddButton(onTap: onAdd)),
        ] else
          Center(
            child: Padding(
              padding: const EdgeInsets.only(top: 43, bottom: 40),
              child: _MissionAddButton(onTap: onAdd),
            ),
          ),
      ],
    );
  }
}

class _SettingsIconButton extends StatelessWidget {
  const _SettingsIconButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        hoverColor: AppColors.gray800.withValues(alpha: 0.06),
        highlightColor: AppColors.gray800.withValues(alpha: 0.10),
        splashColor: AppColors.gray800.withValues(alpha: 0.12),
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 28,
          height: 28,
          child: Center(
            child: SvgPicture.asset(
              'assets/icons/arrow button/Settings.svg',
              width: 18,
              height: 18,
            ),
          ),
        ),
      ),
    );
  }
}

class _MissionCard extends StatelessWidget {
  const _MissionCard({required this.item, required this.onTap});

  final MissionItem item;
  final void Function(bool goToReview) onTap;

  @override
  Widget build(BuildContext context) {
    final bool isCompleted = item.status == MissionStatus.completed;
    final TextDecoration? lineThrough = isCompleted
        ? TextDecoration.lineThrough
        : null;
    final Color feedbackColor = isCompleted
        ? AppColors.gray500
        : AppColors.gray800;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 19, vertical: 18),
      decoration: BoxDecoration(
        color: isCompleted ? AppColors.gray150 : AppColors.white,
        borderRadius: BorderRadius.circular(AppTokens.cardRadiusSmall),
      ),
      child: Row(
        children: [
          Opacity(
            opacity: isCompleted ? 0.3 : 1,
            child: SvgPicture.asset(item.iconAsset, width: 48, height: 48),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () => onTap(isCompleted),
                    hoverColor: feedbackColor.withValues(alpha: 0.06),
                    highlightColor: feedbackColor.withValues(alpha: 0.10),
                    splashColor: feedbackColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                    child: Text(
                      item.title,
                      style: AppTypography.bodyMedium.copyWith(
                        color: isCompleted
                            ? AppColors.gray300
                            : AppColors.gray800,
                        decoration: lineThrough,
                        decorationColor: isCompleted ? AppColors.gray300 : null,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  item.reward,
                  style: AppTypography.captionRegular.copyWith(
                    color: isCompleted ? AppColors.gray300 : AppColors.gray500,
                    decoration: lineThrough,
                    decorationColor: isCompleted ? AppColors.gray300 : null,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Material(
            color: Colors.transparent,
            shape: const CircleBorder(),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () => onTap(true),
              hoverColor: feedbackColor.withValues(alpha: 0.06),
              highlightColor: feedbackColor.withValues(alpha: 0.10),
              splashColor: feedbackColor.withValues(alpha: 0.12),
              customBorder: const CircleBorder(),
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: _MissionStatusIcon(status: item.status),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MissionStatusIcon extends StatelessWidget {
  const _MissionStatusIcon({required this.status});

  static const double _iconSize = 22;

  final MissionStatus status;

  @override
  Widget build(BuildContext context) {
    final String assetPath = switch (status) {
      MissionStatus.completed => 'assets/icons/속성1=완료.svg',
      MissionStatus.reviewing => 'assets/icons/로딩.svg',
      MissionStatus.rejected => 'assets/icons/반려.svg',
      MissionStatus.pending => 'assets/icons/속성1=미완료.svg',
    };

    return SvgPicture.asset(assetPath, width: _iconSize, height: _iconSize);
  }
}

class _MissionAddButton extends StatelessWidget {
  const _MissionAddButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.primaryLight,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        hoverColor: AppColors.primary.withValues(alpha: 0.08),
        highlightColor: AppColors.primary.withValues(alpha: 0.12),
        splashColor: AppColors.primary.withValues(alpha: 0.16),
        customBorder: const CircleBorder(),
        child: const SizedBox(
          width: 40,
          height: 40,
          child: Center(child: _AddIcon(color: AppColors.primary, size: 24)),
        ),
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
    const BorderRadius strokeRadius = BorderRadius.all(
      Radius.circular(stroke / 2),
    );

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: stroke,
            height: size * 0.75,
            decoration: BoxDecoration(color: color, borderRadius: strokeRadius),
          ),
          Container(
            width: size * 0.75,
            height: stroke,
            decoration: BoxDecoration(color: color, borderRadius: strokeRadius),
          ),
        ],
      ),
    );
  }
}
