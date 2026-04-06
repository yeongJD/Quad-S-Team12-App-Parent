import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../models/parent_home_models.dart';

class TodayTimeSection extends StatelessWidget {
  const TodayTimeSection({
    super.key,
    required this.timeSummary,
    required this.onOpen,
    required this.onSetup,
  });

  final TimeSummary? timeSummary;
  final VoidCallback onOpen;
  final VoidCallback onSetup;

  bool get _hasData => timeSummary != null;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          title: '오늘의 시간',
          onTap: _hasData ? onOpen : onSetup,
          onSettingsTap: onSetup,
        ),
        const SizedBox(height: 18),
        GestureDetector(
          onTap: _hasData ? onOpen : onSetup,
          behavior: HitTestBehavior.opaque,
          child: Container(
            width: double.infinity,
            height: 157.338,
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(14.385),
              boxShadow: const [
                BoxShadow(
                  color: Color.fromRGBO(217, 217, 217, 0.5),
                  blurRadius: 7.2,
                  offset: Offset(0, 3.6),
                ),
              ],
            ),
            child: _hasData
                ? _TimeSummaryContent(summary: timeSummary!)
                : const Center(child: _PrimaryAddButton()),
          ),
        ),
      ],
    );
  }
}

class _TimeSummaryContent extends StatelessWidget {
  const _TimeSummaryContent({required this.summary});

  final TimeSummary summary;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          SizedBox(
            width: 111.485,
            height: 111.485,
            child: CustomPaint(
              painter: _TimeRingPainter(
                outerProgress: summary.basicProgress,
                innerProgress: summary.bonusProgress,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '기본시간',
                  style: AppTypography.labelMedium.copyWith(
                    fontSize: 12.587,
                    height: 1.429,
                    letterSpacing: 0.18,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  summary.basicTime,
                  style: AppTypography.heading2Bold.copyWith(
                    fontSize: 21.578,
                    height: 1.364,
                    letterSpacing: -0.42,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  '보너스시간',
                  style: AppTypography.labelMedium.copyWith(
                    fontSize: 12.587,
                    height: 1.429,
                    letterSpacing: 0.18,
                    color: const Color(0xFFFFB300),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  summary.bonusTime,
                  style: AppTypography.heading2Bold.copyWith(
                    fontSize: 21.578,
                    height: 1.364,
                    letterSpacing: -0.42,
                    color: const Color(0xFFFFB300),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.onTap,
    required this.onSettingsTap,
  });

  final String title;
  final VoidCallback onTap;
  final VoidCallback onSettingsTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: Text(
            title,
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
          onTap: onSettingsTap,
          behavior: HitTestBehavior.opaque,
          child: SvgPicture.asset(
            'assets/icons/arrow button/Settings.svg',
            width: 18,
            height: 18,
          ),
        ),
      ],
    );
  }
}

class _PrimaryAddButton extends StatelessWidget {
  const _PrimaryAddButton();

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
        child: _AddIcon(size: 21.578, color: AppColors.primary),
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

class _TimeRingPainter extends CustomPainter {
  const _TimeRingPainter({
    required this.outerProgress,
    required this.innerProgress,
  });

  final double outerProgress;
  final double innerProgress;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = size.center(Offset.zero);
    final Paint basePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.butt;

    basePaint
      ..color = AppColors.gray200
      ..strokeWidth = 11;
    canvas.drawCircle(center, size.width / 2 - 5.5, basePaint);

    basePaint
      ..color = const Color(0xFFDFE4EA)
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
      2 * math.pi * outerProgress,
      false,
      outerPaint,
    );

    final Paint innerPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.butt
      ..strokeWidth = 11
      ..color = const Color(0xFFFFB300);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: size.width / 2 - 21),
      -math.pi / 2,
      2 * math.pi * innerProgress,
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
