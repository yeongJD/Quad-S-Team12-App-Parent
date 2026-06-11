import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/date/week_label.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/theme/app_typography.dart';

class WeeklyUsageReportPage extends StatelessWidget {
  const WeeklyUsageReportPage({super.key, this.parentId, this.childrenId});

  final String? parentId;
  final String? childrenId;

  @override
  Widget build(BuildContext context) {
    final String weekLabel = currentMonthWeekLabel();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 375),
            child: Column(
              children: [
                _ReportTopBar(onBack: () => _handleBack(context)),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                    child: Column(
                      children: [
                        _HeroReportCard(
                          subtitle: '이번주 자녀는 어떻게 사용했을까?',
                          title: '$weekLabel 사용리포트',
                        ),
                        const SizedBox(height: 20),
                        _WeeklyPlanCard(
                          title: '$weekLabel 자녀의 계획은',
                          total: '주 21시간',
                        ),
                        const SizedBox(height: 20),
                        const _UsageAnalysisCard(),
                        const SizedBox(height: 20),
                        const _PlanAchievementCard(),
                        const SizedBox(height: 20),
                        const _AiSuggestionCard(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _handleBack(BuildContext context) {
    final GoRouter router = GoRouter.of(context);
    if (router.canPop()) {
      router.pop();
      return;
    }
    router.go('/notifications');
  }
}

class _ReportTopBar extends StatelessWidget {
  const _ReportTopBar({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AppTokens.topBarHeight,
      child: Stack(
        children: [
          Positioned(
            left: 20,
            top: 14,
            child: Material(
              color: Colors.transparent,
              shape: const CircleBorder(),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: onBack,
                hoverColor: AppColors.gray800.withValues(alpha: 0.06),
                highlightColor: AppColors.gray800.withValues(alpha: 0.10),
                splashColor: AppColors.gray800.withValues(alpha: 0.12),
                customBorder: const CircleBorder(),
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: Padding(
                    padding: const EdgeInsets.all(2),
                    child: SvgPicture.asset(
                      'assets/icons/cmp/btn/back.svg',
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Center(
            child: Text(
              '사용 리포트',
              style: AppTypography.headlineMedium.copyWith(
                color: AppColors.inkBlack,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  const _ReportCard({required this.child, this.padding});

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding ?? const EdgeInsets.fromLTRB(20, 20, 20, 20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppTokens.cardRadiusSmall),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.08),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _HeroReportCard extends StatelessWidget {
  const _HeroReportCard({required this.subtitle, required this.title});

  final String subtitle;
  final String title;

  @override
  Widget build(BuildContext context) {
    return _ReportCard(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      child: SizedBox(
        height: 202,
        child: Stack(
          children: [
            Positioned.fill(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    subtitle,
                    style: AppTypography.labelMedium.copyWith(
                      color: AppColors.gray300,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    title,
                    style: AppTypography.heading2Bold.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    width: 282,
                    padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(
                        AppTokens.cardRadiusSmall,
                      ),
                    ),
                    child: Text(
                      '기존 계획을 확인하고,\n계획대로 사용했는지,\n계획대로 사용하지 못했다면 그 이유는 무엇인지,\n어떻게 조정하는 것이 좋을지 자녀와 함께 확인해요',
                      style: AppTypography.captionMedium.copyWith(
                        color: AppColors.gray600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Positioned(right: 2, bottom: 0, child: _ReportMascot()),
          ],
        ),
      ),
    );
  }
}

class _ReportMascot extends StatelessWidget {
  const _ReportMascot();

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      'assets/icons/cat.svg',
      width: 54,
      height: 52,
      fit: BoxFit.contain,
    );
  }
}

class _WeeklyPlanCard extends StatelessWidget {
  const _WeeklyPlanCard({required this.title, required this.total});

  final String title;
  final String total;

  static const List<_ScheduleRowData> _rows = [
    _ScheduleRowData(days: '월, 수, 금', hours: 7, minutes: 0),
    _ScheduleRowData(days: '화, 목', hours: 7, minutes: 0),
    _ScheduleRowData(days: '토, 일', hours: 7, minutes: 0),
  ];

  @override
  Widget build(BuildContext context) {
    return _ReportCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTypography.labelMedium.copyWith(color: AppColors.gray300),
          ),
          const SizedBox(height: 2),
          Text(
            total,
            style: AppTypography.headlineBold.copyWith(
              color: AppColors.gray900,
            ),
          ),
          const SizedBox(height: 18),
          for (int index = 0; index < _rows.length; index++) ...[
            _TimeRow(data: _rows[index]),
            if (index != _rows.length - 1) const SizedBox(height: 14),
          ],
        ],
      ),
    );
  }
}

class _UsageAnalysisCard extends StatelessWidget {
  const _UsageAnalysisCard();

  static const List<_DailyUsageData> _daily = [
    _DailyUsageData(day: '월', status: _UsageStatus.under, delta: '2시간'),
    _DailyUsageData(day: '화', status: _UsageStatus.over, delta: '2시간'),
    _DailyUsageData(day: '수', status: _UsageStatus.same, delta: ''),
    _DailyUsageData(day: '목', status: _UsageStatus.same, delta: ''),
    _DailyUsageData(day: '금', status: _UsageStatus.over, delta: '2시간'),
    _DailyUsageData(day: '토', status: _UsageStatus.over, delta: '3시간'),
  ];

  @override
  Widget build(BuildContext context) {
    return _ReportCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '이번주 사용 분석',
            style: AppTypography.headlineBold.copyWith(
              color: AppColors.gray900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '화·토·일에 계획보다 많이 사용했어요.\n월·금에는 계획보다 적게 사용하는 날이 많았어요.',
            style: AppTypography.captionMedium.copyWith(
              color: AppColors.gray300,
            ),
          ),
          const SizedBox(height: 16),
          const SizedBox(height: 164, child: _UsageBarChart()),
          const SizedBox(height: 10),
          for (int index = 0; index < _daily.length; index++) ...[
            _UsageDeltaRow(data: _daily[index]),
            if (index != _daily.length - 1) const SizedBox(height: 14),
          ],
        ],
      ),
    );
  }
}

class _PlanAchievementCard extends StatelessWidget {
  const _PlanAchievementCard();

  @override
  Widget build(BuildContext context) {
    return _ReportCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '계획 이행률 50%',
            style: AppTypography.headlineBold.copyWith(
              color: AppColors.gray900,
            ),
          ),
          const SizedBox(height: 10),
          const _Legend(color: AppColors.primary, label: '계획대로 사용한 날'),
          const SizedBox(height: 4),
          const _Legend(color: Color(0xFFFF6B6B), label: '계획보다 많이 사용한 날'),
          const SizedBox(height: 4),
          const _Legend(color: Color(0xFF2BCB65), label: '계획보다 적게 사용한 날'),
          const SizedBox(height: 18),
          const SizedBox(
            height: 142,
            child: Center(child: _AchievementDonut()),
          ),
        ],
      ),
    );
  }
}

class _AiSuggestionCard extends StatelessWidget {
  const _AiSuggestionCard();

  static const List<_SuggestionRowData> _rows = [
    _SuggestionRowData(days: '월, 금', status: _UsageStatus.under, delta: '2시간'),
    _SuggestionRowData(days: '토, 일', status: _UsageStatus.over, delta: '2시간'),
    _SuggestionRowData(days: '화, 목', status: _UsageStatus.same, delta: ''),
    _SuggestionRowData(days: '수', status: _UsageStatus.same, delta: ''),
  ];

  @override
  Widget build(BuildContext context) {
    return _ReportCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '다음주는 이렇게 조정해봐요',
            style: AppTypography.labelMedium.copyWith(color: AppColors.gray300),
          ),
          const SizedBox(height: 2),
          Text(
            'AI 조정 제안',
            style: AppTypography.headlineBold.copyWith(
              color: AppColors.gray900,
            ),
          ),
          const SizedBox(height: 18),
          for (int index = 0; index < _rows.length; index++) ...[
            _SuggestionTimeRow(data: _rows[index]),
            if (index != _rows.length - 1) const SizedBox(height: 14),
          ],
        ],
      ),
    );
  }
}

class _TimeRow extends StatelessWidget {
  const _TimeRow({required this.data});

  final _ScheduleRowData data;

  @override
  Widget build(BuildContext context) {
    return _SoftRow(
      child: Row(
        children: [
          SizedBox(width: 76, child: Text(data.days, style: _rowStrongStyle())),
          const _VerticalDivider(),
          Expanded(
            child: _TimeAmount(hours: data.hours, minutes: data.minutes),
          ),
        ],
      ),
    );
  }
}

class _UsageDeltaRow extends StatelessWidget {
  const _UsageDeltaRow({required this.data});

  final _DailyUsageData data;

  @override
  Widget build(BuildContext context) {
    return _SoftRow(
      child: Row(
        children: [
          SizedBox(width: 34, child: Text(data.day, style: _rowStrongStyle())),
          const _VerticalDivider(),
          const Expanded(child: _TimeAmount(hours: 7, minutes: 0)),
          _DeltaBadge(status: data.status, delta: data.delta),
        ],
      ),
    );
  }
}

class _SuggestionTimeRow extends StatelessWidget {
  const _SuggestionTimeRow({required this.data});

  final _SuggestionRowData data;

  @override
  Widget build(BuildContext context) {
    return _SoftRow(
      child: Row(
        children: [
          SizedBox(width: 56, child: Text(data.days, style: _rowStrongStyle())),
          const _VerticalDivider(),
          const Expanded(child: _TimeAmount(hours: 7, minutes: 0)),
          _DeltaBadge(status: data.status, delta: data.delta),
        ],
      ),
    );
  }
}

class _SoftRow extends StatelessWidget {
  const _SoftRow({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 58,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.gray100,
        borderRadius: BorderRadius.circular(AppTokens.cardRadiusSmall),
      ),
      child: Center(child: child),
    );
  }
}

class _VerticalDivider extends StatelessWidget {
  const _VerticalDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 24,
      margin: const EdgeInsets.only(right: 20),
      color: AppColors.gray200,
    );
  }
}

class _TimeAmount extends StatelessWidget {
  const _TimeAmount({required this.hours, required this.minutes});

  final int hours;
  final int minutes;

  @override
  Widget build(BuildContext context) {
    final TextStyle numberStyle = AppTypography.headlineBold.copyWith(
      color: AppColors.gray800,
    );
    final TextStyle labelStyle = AppTypography.headlineMedium.copyWith(
      color: AppColors.gray800,
    );

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('$hours', style: numberStyle),
        const SizedBox(width: 9),
        Text('시간', style: labelStyle),
        const SizedBox(width: 20),
        Text(minutes.toString().padLeft(2, '0'), style: numberStyle),
        const SizedBox(width: 9),
        Text('분', style: labelStyle),
      ],
    );
  }
}

class _DeltaBadge extends StatelessWidget {
  const _DeltaBadge({required this.status, required this.delta});

  final _UsageStatus status;
  final String delta;

  @override
  Widget build(BuildContext context) {
    final Color color = switch (status) {
      _UsageStatus.under => AppColors.positive,
      _UsageStatus.over => AppColors.destructive,
      _UsageStatus.same => AppColors.gray400,
    };
    final String text = switch (status) {
      _UsageStatus.under => '▼ $delta',
      _UsageStatus.over => '▲ $delta',
      _UsageStatus.same => '—',
    };

    return SizedBox(
      width: 48,
      child: Text(
        text,
        textAlign: TextAlign.right,
        style: AppTypography.captionBold.copyWith(
          fontSize: 11,
          height: 1.334,
          letterSpacing: 0,
          color: color,
        ),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 5, height: 5, color: color),
        const SizedBox(width: 6),
        Text(
          label,
          style: AppTypography.captionMedium.copyWith(
            fontSize: 11,
            height: 1.334,
            letterSpacing: 0,
            color: AppColors.gray400,
          ),
        ),
      ],
    );
  }
}

class _UsageBarChart extends StatelessWidget {
  const _UsageBarChart();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _UsageBarChartPainter(),
      child: const SizedBox.expand(),
    );
  }
}

class _AchievementDonut extends StatelessWidget {
  const _AchievementDonut();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(150, 130),
      painter: _AchievementDonutPainter(),
    );
  }
}

class _UsageBarChartPainter extends CustomPainter {
  static const List<double> _planned = [
    0.63,
    0.63,
    0.55,
    0.58,
    0.37,
    0.63,
    0.63,
  ];
  static const List<double> _under = [0.14, 0, 0, 0, 0.21, 0, 0];
  static const List<double> _over = [0, 0.15, 0, 0, 0, 0.14, 0.33];
  static const List<String> _labels = ['월', '화', '수', '목', '금', '토', '일'];

  @override
  void paint(Canvas canvas, Size size) {
    const Color plannedColor = Color(0xFFB7DCFF);
    const Color overColor = Color(0xFFFF6B6B);
    const Color underColor = Color(0xFF34C76B);
    final Paint axisPaint = Paint()
      ..color = const Color(0xFF8E87DD)
      ..strokeWidth = 1.2;
    final Paint barPaint = Paint();

    final double chartLeft = 18;
    final double chartTop = 8;
    final double chartBottom = size.height - 28;
    final double chartHeight = chartBottom - chartTop;
    final double step = (size.width - chartLeft - 8) / _labels.length;
    final double barWidth = 10;

    canvas.drawLine(
      Offset(chartLeft, chartTop),
      Offset(chartLeft, chartBottom),
      axisPaint,
    );
    canvas.drawLine(
      Offset(chartLeft - 4, chartBottom),
      Offset(size.width - 4, chartBottom),
      axisPaint,
    );

    for (int index = 0; index < _labels.length; index++) {
      final double x = chartLeft + step * index + step / 2 - barWidth / 2;
      final double plannedHeight = chartHeight * _planned[index];
      final double plannedTop = chartBottom - plannedHeight;
      barPaint.color = plannedColor;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, plannedTop, barWidth, plannedHeight),
          const Radius.circular(2),
        ),
        barPaint,
      );

      if (_under[index] > 0) {
        barPaint.color = underColor;
        final double h = chartHeight * _under[index];
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(x, plannedTop - h, barWidth, h),
            const Radius.circular(2),
          ),
          barPaint,
        );
      }
      if (_over[index] > 0) {
        barPaint.color = overColor;
        final double h = chartHeight * _over[index];
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(x, plannedTop - h, barWidth, h),
            const Radius.circular(2),
          ),
          barPaint,
        );
      }

      final TextPainter labelPainter = TextPainter(
        text: TextSpan(
          text: _labels[index],
          style: AppTypography.captionMedium.copyWith(
            fontSize: 10,
            height: 1.2,
            letterSpacing: 0,
            color: AppColors.gray400,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      labelPainter.paint(
        canvas,
        Offset(x + barWidth / 2 - labelPainter.width / 2, chartBottom + 10),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _AchievementDonutPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = Offset(size.width / 2, size.height / 2 + 4);
    const double radius = 48;
    const double stroke = 16;
    final Rect rect = Rect.fromCircle(center: center, radius: radius);
    final Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.butt;

    double start = -math.pi / 2;
    void drawSegment(double percent, Color color) {
      paint.color = color;
      final double sweep = math.pi * 2 * percent;
      canvas.drawArc(rect, start, sweep, false, paint);
      start += sweep;
    }

    drawSegment(0.50, AppColors.primary);
    drawSegment(0.30, const Color(0xFFFF6B6B));
    drawSegment(0.20, const Color(0xFF2BCB65));

    _drawLabel(
      canvas,
      '20%',
      Offset(center.dx - 56, center.dy - 62),
      const Color(0xFF2BCB65),
    );
    _drawLabel(
      canvas,
      '50%',
      Offset(center.dx + 61, center.dy - 2),
      AppColors.primary,
    );
    _drawLabel(
      canvas,
      '30%',
      Offset(center.dx - 78, center.dy + 44),
      const Color(0xFFFF6B6B),
    );
  }

  void _drawLabel(Canvas canvas, String text, Offset offset, Color color) {
    final TextPainter painter = TextPainter(
      text: TextSpan(
        text: text,
        style: AppTypography.captionBold.copyWith(
          fontSize: 12,
          height: 1.2,
          letterSpacing: 0,
          color: color,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ScheduleRowData {
  const _ScheduleRowData({
    required this.days,
    required this.hours,
    required this.minutes,
  });

  final String days;
  final int hours;
  final int minutes;
}

class _DailyUsageData {
  const _DailyUsageData({
    required this.day,
    required this.status,
    required this.delta,
  });

  final String day;
  final _UsageStatus status;
  final String delta;
}

class _SuggestionRowData {
  const _SuggestionRowData({
    required this.days,
    required this.status,
    required this.delta,
  });

  final String days;
  final _UsageStatus status;
  final String delta;
}

enum _UsageStatus { under, over, same }

TextStyle _rowStrongStyle() {
  return AppTypography.headlineBold.copyWith(
    fontSize: 17,
    height: 1.445,
    letterSpacing: 0,
    color: AppColors.gray800,
  );
}
