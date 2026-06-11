import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/theme/app_typography.dart';
import '../models/parent_home_models.dart';

class TodayTimeSection extends StatelessWidget {
  const TodayTimeSection({
    super.key,
    required this.timeSummary,
    this.waitingForChildPlan = false,
    this.emptyMessage,
    required this.onSetup,
    required this.onAdd,
  });

  final TimeSummary? timeSummary;
  final bool waitingForChildPlan;
  final String? emptyMessage;
  final VoidCallback onSetup;
  final VoidCallback onAdd;

  bool get _hasData => timeSummary != null;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(title: '오늘의 시간', onSettingsTap: onSetup),
        const SizedBox(height: 18),
        Container(
          width: double.infinity,
          height: 157,
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(AppTokens.cardRadiusSmall),
            boxShadow: const [
              BoxShadow(
                color: AppTokens.cardShadowColor,
                blurRadius: 7.2,
                offset: Offset(0, 3.6),
              ),
            ],
          ),
          child: _hasData
              ? _TimeSummaryContent(summary: timeSummary!)
              : waitingForChildPlan || emptyMessage != null
              ? _WaitingTimePlanMessage(
                  message: emptyMessage ?? '자녀가 아직 시간 설정 이전입니다.',
                )
              : Center(child: _PrimaryAddButton(onTap: onAdd)),
        ),
      ],
    );
  }
}

class _WaitingTimePlanMessage extends StatelessWidget {
  const _WaitingTimePlanMessage({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: AppTypography.bodyMedium.copyWith(color: AppColors.gray300),
      ),
    );
  }
}

class _TimeSummaryContent extends StatelessWidget {
  const _TimeSummaryContent({required this.summary});

  final TimeSummary summary;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
      child: Row(
        children: [
          SizedBox(
            width: 112,
            height: 112,
            child: CustomPaint(
              painter: _TimeRingPainter(
                outerProgress: summary.basicProgress,
                innerProgress: summary.bonusProgress,
              ),
            ),
          ),
          const SizedBox(width: 36),
          SizedBox(
            width: 95,
            height: 105,
            child: FittedBox(
              alignment: Alignment.centerLeft,
              fit: BoxFit.scaleDown,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '오늘 사용 예정 시간',
                    style: AppTypography.captionMedium.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    summary.basicTime,
                    style: AppTypography.heading2Bold.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    '월간 남은시간',
                    style: AppTypography.captionMedium.copyWith(
                      color: _TimeRingPainter.monthlyRemainingColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    summary.bonusTime,
                    style: AppTypography.heading2Bold.copyWith(
                      color: _TimeRingPainter.monthlyRemainingColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.onSettingsTap});

  final String title;
  final VoidCallback onSettingsTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: AppTypography.headlineSemiBold.copyWith(
            color: AppColors.black,
          ),
        ),
        const SizedBox(width: 6),
        _SettingsIconButton(onTap: onSettingsTap),
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

class _PrimaryAddButton extends StatelessWidget {
  const _PrimaryAddButton({required this.onTap});

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
          child: Center(child: _AddIcon(size: 24, color: AppColors.primary)),
        ),
      ),
    );
  }
}

class _AddIcon extends StatelessWidget {
  const _AddIcon({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    const double stroke = 2;
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

class _TimeRingPainter extends CustomPainter {
  const _TimeRingPainter({
    required this.outerProgress,
    required this.innerProgress,
  });

  final double outerProgress;
  final double innerProgress;
  static const Color monthlyRemainingColor = Color(0xFFFFB300);

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = size.center(Offset.zero);
    final double safeOuterProgress = outerProgress.clamp(0, 1).toDouble();
    final double safeInnerProgress = innerProgress.clamp(0, 1).toDouble();
    final Paint basePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.butt;

    basePaint
      ..color = const Color(0xFFE8EBF0)
      ..strokeWidth = 11;
    canvas.drawCircle(center, size.width / 2 - 5.5, basePaint);

    basePaint
      ..color = const Color(0xFFF0F2F5)
      ..strokeWidth = 11;
    canvas.drawCircle(center, size.width / 2 - 21, basePaint);

    final Paint outerPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.butt
      ..strokeWidth = 11
      ..color = AppColors.primary;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: size.width / 2 - 5.5),
      -math.pi / 2,
      2 * math.pi * safeOuterProgress,
      false,
      outerPaint,
    );

    final Paint innerPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.butt
      ..strokeWidth = 11
      ..color = monthlyRemainingColor;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: size.width / 2 - 21),
      -math.pi / 2,
      2 * math.pi * safeInnerProgress,
      false,
      innerPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _TimeRingPainter oldDelegate) {
    return oldDelegate.outerProgress != outerProgress ||
        oldDelegate.innerProgress != innerProgress;
  }
}
