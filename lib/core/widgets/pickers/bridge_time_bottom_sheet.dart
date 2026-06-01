import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import 'bridge_wheel_picker.dart';

/// Result returned by [BridgeTimeBottomSheet] when the user confirms.
@immutable
class TimeOfDayPick {
  const TimeOfDayPick({required this.hours, required this.minutes});

  final int hours;
  final int minutes;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TimeOfDayPick &&
          runtimeType == other.runtimeType &&
          hours == other.hours &&
          minutes == other.minutes;

  @override
  int get hashCode => Object.hash(hours, minutes);

  @override
  String toString() => 'TimeOfDayPick(hours: $hours, minutes: $minutes)';
}

/// Reusable hour + minute wheel picker bottom sheet.
///
/// Ported from the child app's `BridgeTimeBottomSheet`
/// (`docs/figma-specs/08a-time-v1-entry-weekly.md` §13485) so parent and child
/// flows share the same picker affordance.
///
/// Anatomy (top → bottom):
///   1. Drag handle — 40 × 4 `AppColors.gray200` pill, 8px from sheet top.
///   2. Header — centered title, 27px from sheet top.
///   3. Two [BridgeWheelPicker] columns (hour, minute) side-by-side, centered.
///   4. Selection band — primary-border top/bottom, opacity 0.8, with right-
///      aligned `시간` / `분` unit labels next to each wheel's selected row.
///   5. Primary CTA — bottom-anchored confirm button.
class BridgeTimeBottomSheet extends StatefulWidget {
  const BridgeTimeBottomSheet({
    super.key,
    required this.initialHours,
    required this.initialMinutes,
    this.maxHours = 23,
    this.minuteStep = 5,
    this.title = '시간 선택',
    this.confirmLabel = '확인',
  });

  final int initialHours;
  final int initialMinutes;
  final int maxHours;
  final int minuteStep;
  final String title;
  final String confirmLabel;

  /// Opens the bottom sheet and resolves with a [TimeOfDayPick] on confirm
  /// or `null` on dismiss.
  static Future<TimeOfDayPick?> show(
    BuildContext context, {
    required int initialHours,
    required int initialMinutes,
    int maxHours = 23,
    int minuteStep = 5,
    String title = '시간 선택',
    String confirmLabel = '확인',
  }) {
    return showModalBottomSheet<TimeOfDayPick>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: const Color.fromRGBO(68, 68, 68, 0.6),
      isScrollControlled: true,
      builder: (_) => BridgeTimeBottomSheet(
        initialHours: initialHours,
        initialMinutes: initialMinutes,
        maxHours: maxHours,
        minuteStep: minuteStep,
        title: title,
        confirmLabel: confirmLabel,
      ),
    );
  }

  @override
  State<BridgeTimeBottomSheet> createState() => _BridgeTimeBottomSheetState();
}

class _BridgeTimeBottomSheetState extends State<BridgeTimeBottomSheet> {
  static const double _wheelItemWidth = 56;
  static const double _wheelItemHeight = 50;
  static const int _visibleItems = 5;
  static const double _wheelTotalHeight = _wheelItemHeight * _visibleItems;

  static const double _sheetHeight = 397;
  static const double _sheetTopRadius = 24;
  static const double _handleTop = 8;
  static const double _handleWidth = 40;
  static const double _handleHeight = 4;
  static const double _headerTop = 27;
  static const double _wheelsTop = 85;
  static const double _bandWidth = 324;
  static const double _bandHeight = 50;
  static const double _ctaBottom = 63;
  static const double _ctaHorizontalPadding = 24;
  static const double _wheelGap = 80;

  late List<String> _hourValues;
  late List<String> _minuteValues;
  late int _hourIndex;
  late int _minuteIndex;

  @override
  void initState() {
    super.initState();
    _buildValues();
    _hourIndex = widget.initialHours.clamp(0, _hourValues.length - 1);
    final int step = widget.minuteStep <= 0 ? 5 : widget.minuteStep;
    final int snappedMinute =
        (widget.initialMinutes ~/ step) * step;
    final int minuteIdx = _minuteValues.indexOf(_format(snappedMinute));
    _minuteIndex = minuteIdx >= 0 ? minuteIdx : 0;
  }

  @override
  void didUpdateWidget(covariant BridgeTimeBottomSheet oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.maxHours != widget.maxHours ||
        oldWidget.minuteStep != widget.minuteStep) {
      setState(_buildValues);
    }
  }

  void _buildValues() {
    _hourValues =
        List<String>.generate(widget.maxHours + 1, (i) => _format(i));
    final int step = widget.minuteStep <= 0 ? 5 : widget.minuteStep;
    final int count = (60 / step).floor();
    _minuteValues = List<String>.generate(count, (i) => _format(i * step));
  }

  String _format(int value) => value.toString().padLeft(2, '0');

  int get _hours => _hourIndex;
  int get _minutes {
    final int step = widget.minuteStep <= 0 ? 5 : widget.minuteStep;
    return _minuteIndex * step;
  }

  void _handleConfirm() {
    Navigator.of(context).pop(TimeOfDayPick(hours: _hours, minutes: _minutes));
  }

  @override
  Widget build(BuildContext context) {
    final double bottomInset = MediaQuery.paddingOf(context).bottom;

    return Material(
      color: AppColors.white,
      clipBehavior: Clip.antiAlias,
      borderRadius: const BorderRadius.vertical(
        top: Radius.circular(_sheetTopRadius),
      ),
      child: SizedBox(
        height: _sheetHeight + bottomInset,
        width: double.infinity,
        child: Stack(
          children: <Widget>[
            Positioned(
              top: _handleTop,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  width: _handleWidth,
                  height: _handleHeight,
                  decoration: BoxDecoration(
                    color: AppColors.gray200,
                    borderRadius: BorderRadius.circular(_handleHeight / 2),
                  ),
                ),
              ),
            ),
            Positioned(
              top: _headerTop,
              left: 0,
              right: 0,
              child: Text(
                widget.title,
                textAlign: TextAlign.center,
                style: AppTypography.headlineBold.copyWith(
                  color: AppColors.gray800,
                ),
              ),
            ),
            Positioned(
              top: _wheelsTop,
              left: 0,
              right: 0,
              height: _wheelTotalHeight,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  BridgeWheelPicker(
                    values: _hourValues,
                    selectedIndex: _hourIndex,
                    itemWidth: _wheelItemWidth,
                    itemHeight: _wheelItemHeight,
                    visibleItems: _visibleItems,
                    onChanged: (int i) => setState(() => _hourIndex = i),
                  ),
                  const SizedBox(width: _wheelGap),
                  BridgeWheelPicker(
                    values: _minuteValues,
                    selectedIndex: _minuteIndex,
                    itemWidth: _wheelItemWidth,
                    itemHeight: _wheelItemHeight,
                    visibleItems: _visibleItems,
                    onChanged: (int i) => setState(() => _minuteIndex = i),
                  ),
                ],
              ),
            ),
            Positioned(
              top: _wheelsTop + (_wheelTotalHeight - _bandHeight) / 2,
              left: 0,
              right: 0,
              height: _bandHeight,
              child: IgnorePointer(
                child: LayoutBuilder(
                  builder: (BuildContext context, BoxConstraints constraints) {
                    final double bandWidth =
                        constraints.maxWidth < _bandWidth
                            ? constraints.maxWidth
                            : _bandWidth;

                    return Center(
                      child: Opacity(
                        opacity: 0.8,
                        child: Container(
                          width: bandWidth,
                          height: _bandHeight,
                          decoration: const BoxDecoration(
                            border: Border(
                              top: BorderSide(
                                color: AppColors.primary,
                                width: 2,
                              ),
                              bottom: BorderSide(
                                color: AppColors.primary,
                                width: 2,
                              ),
                            ),
                          ),
                          child: _BandLabels(
                            wheelItemWidth: _wheelItemWidth,
                            wheelGap: _wheelGap,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            Positioned(
              left: _ctaHorizontalPadding,
              right: _ctaHorizontalPadding,
              bottom: _ctaBottom + bottomInset,
              child: _ConfirmButton(
                label: widget.confirmLabel,
                onTap: _handleConfirm,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BandLabels extends StatelessWidget {
  const _BandLabels({required this.wheelItemWidth, required this.wheelGap});

  final double wheelItemWidth;
  final double wheelGap;

  static const double _labelGap = 12;
  static const double _minWheelSeparation = 8;

  @override
  Widget build(BuildContext context) {
    final TextStyle unitStyle = AppTypography.heading2Medium.copyWith(
      color: AppColors.gray800,
    );

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double wheelRowWidth = wheelItemWidth * 2 + wheelGap;
        final double wheelRowLeft = (constraints.maxWidth - wheelRowWidth) / 2;
        final double safeWheelRowLeft = wheelRowLeft < 0 ? 0 : wheelRowLeft;
        final double hourWheelRight = safeWheelRowLeft + wheelItemWidth;
        final double minuteWheelLeft =
            safeWheelRowLeft + wheelItemWidth + wheelGap;
        final double minuteWheelRight = minuteWheelLeft + wheelItemWidth;
        final double hourLabelLeft = hourWheelRight + _labelGap;
        final double minuteLabelLeft = minuteWheelRight + _labelGap;
        final double hourLabelWidth =
            minuteWheelLeft - hourLabelLeft - _minWheelSeparation;
        final double minuteLabelWidth = constraints.maxWidth - minuteLabelLeft;

        Widget buildLabel({
          required String text,
          required double left,
          required double width,
        }) {
          if (width <= 0) return const SizedBox.shrink();
          return Positioned(
            left: left,
            top: 0,
            bottom: 0,
            width: width,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(text, maxLines: 1, softWrap: false, style: unitStyle),
            ),
          );
        }

        return Stack(
          clipBehavior: Clip.none,
          children: <Widget>[
            buildLabel(text: '시간', left: hourLabelLeft, width: hourLabelWidth),
            buildLabel(
              text: '분',
              left: minuteLabelLeft,
              width: minuteLabelWidth,
            ),
          ],
        );
      },
    );
  }
}

class _ConfirmButton extends StatelessWidget {
  const _ConfirmButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.primary,
      borderRadius: BorderRadius.circular(8),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        hoverColor: AppColors.primary.withValues(alpha: 0.12),
        highlightColor: AppColors.primary.withValues(alpha: 0.18),
        splashColor: AppColors.primary.withValues(alpha: 0.20),
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          height: 54,
          width: double.infinity,
          child: Center(
            child: Text(
              label,
              style: AppTypography.headlineMedium.copyWith(
                fontSize: 18,
                height: 1.445,
                letterSpacing: 0,
                color: AppColors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
