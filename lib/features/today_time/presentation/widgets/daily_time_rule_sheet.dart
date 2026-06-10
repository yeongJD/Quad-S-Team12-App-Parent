import 'package:flutter/cupertino.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/pickers/bridge_time_bottom_sheet.dart';
import '../models/daily_time_rule.dart';
import '../styles/time_setup_tokens.dart';
import 'time_setup_action_button.dart';

class DailyTimeRuleSheet extends StatefulWidget {
  const DailyTimeRuleSheet({
    super.key,
    this.initialRule,
    this.unavailableDays = const <int>{},
  });

  final DailyTimeRule? initialRule;
  final Set<int> unavailableDays;

  @override
  State<DailyTimeRuleSheet> createState() => _DailyTimeRuleSheetState();
}

class _DailyTimeRuleSheetState extends State<DailyTimeRuleSheet> {
  late Set<int> _selectedDays;
  late TimeSelection _selectedTime;

  bool get _canConfirm => _selectedDays.isNotEmpty && !_selectedTime.isEmpty;

  @override
  void initState() {
    super.initState();
    _selectedDays = Set<int>.from(widget.initialRule?.days ?? <int>{});
    _selectedTime =
        widget.initialRule?.time ?? const TimeSelection(hour: 0, minute: 0);
  }

  void _toggleDay(int index) {
    if (_isDayUnavailable(index)) {
      return;
    }
    setState(() {
      if (_selectedDays.contains(index)) {
        _selectedDays.remove(index);
      } else {
        _selectedDays.add(index);
      }
    });
  }

  bool _isDayUnavailable(int index) {
    return widget.unavailableDays.contains(index) &&
        !_selectedDays.contains(index);
  }

  Future<void> _openTimePicker() async {
    final TimeOfDayPick? result = await BridgeTimeBottomSheet.show(
      context,
      initialHours: _selectedTime.hour,
      initialMinutes: _selectedTime.minute,
    );

    if (result == null || !mounted) {
      return;
    }
    setState(() {
      _selectedTime = TimeSelection(hour: result.hours, minute: result.minutes);
    });
  }

  void _confirm() {
    if (!_canConfirm) {
      return;
    }
    Navigator.of(context).pop(
      DailyTimeRule(days: Set<int>.from(_selectedDays), time: _selectedTime),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double bottomInset = MediaQuery.paddingOf(context).bottom;
    final double sheetHeight =
        MediaQuery.sizeOf(context).height * TimeSetupSize.timeSheetHeightRatio;

    return Container(
      height: sheetHeight + bottomInset,
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(TimeSetupRadius.sheet),
        ),
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              TimeSetupSpacing.sheetHorizontalPadding,
              TimeSetupSpacing.sheetTopPadding,
              TimeSetupSpacing.sheetHorizontalPadding,
              0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SheetLabel('요일 선택'),
                const SizedBox(height: TimeSetupSpacing.sheetLabelGap),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: weekdayLabels
                      .asMap()
                      .entries
                      .map(
                        (MapEntry<int, String> day) => DayChip(
                          label: day.value,
                          selected: _selectedDays.contains(day.key),
                          enabled: !_isDayUnavailable(day.key),
                          onTap: () => _toggleDay(day.key),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: TimeSetupSpacing.sheetSectionGap),
                const SheetLabel('시간 선택'),
                const SizedBox(height: TimeSetupSpacing.sheetLabelGap),
                TimeSelectorField(time: _selectedTime, onTap: _openTimePicker),
              ],
            ),
          ),
          Positioned(
            left: TimeSetupSpacing.sheetHorizontalPadding,
            right: TimeSetupSpacing.sheetHorizontalPadding,
            bottom: TimeSetupSpacing.sheetButtonBottom + bottomInset,
            child: SheetConfirmButton(enabled: _canConfirm, onTap: _confirm),
          ),
        ],
      ),
    );
  }
}

class SheetLabel extends StatelessWidget {
  const SheetLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(text, style: TimeSetupTextStyles.sheetLabel);
  }
}

class DayChip extends StatelessWidget {
  const DayChip({
    super.key,
    required this.label,
    required this.selected,
    this.enabled = true,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: TimeSetupSize.dayChip,
        height: TimeSetupSize.dayChip,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.gray100,
          borderRadius: BorderRadius.circular(TimeSetupRadius.field),
          border: selected ? null : Border.all(color: AppColors.gray200),
        ),
        child: Text(
          label,
          style:
              (selected ? AppTypography.bodySemiBold : AppTypography.bodyMedium)
                  .copyWith(
                    color: selected
                        ? AppColors.white
                        : enabled
                        ? AppColors.gray600
                        : AppColors.gray300,
                  ),
        ),
      ),
    );
  }
}

class TimeSelectorField extends StatelessWidget {
  const TimeSelectorField({super.key, required this.time, required this.onTap});

  final TimeSelection time;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color numberColor = time.isEmpty
        ? AppColors.gray300
        : AppColors.primary;

    return Semantics(
      label: '시간 선택 필드',
      button: true,
      child: GestureDetector(
        key: const ValueKey<String>('daily-time-selector-field'),
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          height: TimeSetupSize.fieldHeight,
          width: double.infinity,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(TimeSetupRadius.field),
            border: Border.all(color: AppColors.gray200, width: 2),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TimeSelectorPart(
                value: time.hourText,
                label: '시간',
                color: numberColor,
                selected: !time.isEmpty,
              ),
              const SizedBox(width: 34),
              TimeSelectorPart(
                value: time.minuteText,
                label: '분',
                color: numberColor,
                selected: !time.isEmpty,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class TimeSelectorPart extends StatelessWidget {
  const TimeSelectorPart({
    super.key,
    required this.value,
    required this.label,
    required this.color,
    required this.selected,
  });

  final String value;
  final String label;
  final Color color;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final double groupWidth = label == '시간' ? 88 : 70;

    return SizedBox(
      width: groupWidth,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Baseline(
            baseline: 20,
            baselineType: TextBaseline.alphabetic,
            child: Text(
              value,
              style: TimeSetupTextStyles.timeNumber(
                selected: selected,
              ).copyWith(color: color),
            ),
          ),
          const SizedBox(width: 15),
          Baseline(
            baseline: 20,
            baselineType: TextBaseline.alphabetic,
            child: Text(
              label,
              style: AppTypography.headlineRegular.copyWith(
                color: AppColors.inkBlack,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class PickerColumn extends StatelessWidget {
  const PickerColumn({
    super.key,
    required this.controller,
    required this.values,
    required this.selectedIndex,
    required this.onSelectedItemChanged,
  });

  final FixedExtentScrollController controller;
  final List<int> values;
  final int selectedIndex;
  final ValueChanged<int> onSelectedItemChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: TimeSetupSize.pickerColumnWidth,
      child: CupertinoPicker(
        scrollController: controller,
        itemExtent: TimeSetupSize.pickerItemExtent,
        diameterRatio: 10,
        squeeze: 1,
        selectionOverlay: const SizedBox.shrink(),
        onSelectedItemChanged: onSelectedItemChanged,
        children: [
          for (int index = 0; index < values.length; index++)
            Center(
              child: Text(
                values[index].toString().padLeft(2, '0'),
                style: AppTypography.heading2Bold.copyWith(
                  color: index == selectedIndex
                      ? AppColors.gray800
                      : AppColors.gray200,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class PickerSelectionUnits extends StatelessWidget {
  const PickerSelectionUnits({super.key});

  static const double _numberToUnitGap = 10;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double pickerInset =
            TimeSetupSpacing.pickerHorizontalInset -
            TimeSetupSpacing.sheetHorizontalPadding;
        final double unitOffset =
            pickerInset + TimeSetupSize.pickerColumnWidth + _numberToUnitGap;

        return Stack(
          children: [
            Positioned(
              left: unitOffset,
              top: 0,
              bottom: 0,
              child: const Center(child: _PickerUnitLabel('시간')),
            ),
            Positioned(
              left: constraints.maxWidth - pickerInset + _numberToUnitGap,
              top: 0,
              bottom: 0,
              child: const Center(child: _PickerUnitLabel('분')),
            ),
          ],
        );
      },
    );
  }
}

class _PickerUnitLabel extends StatelessWidget {
  const _PickerUnitLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppTypography.headlineMedium.copyWith(color: AppColors.inkBlack),
    );
  }
}

class SheetConfirmButton extends StatelessWidget {
  const SheetConfirmButton({
    super.key,
    required this.enabled,
    required this.onTap,
  });

  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return TimeSetupActionButton(label: '확인', enabled: enabled, onTap: onTap);
  }
}
