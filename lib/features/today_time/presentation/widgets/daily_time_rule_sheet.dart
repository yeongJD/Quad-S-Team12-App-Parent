import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../models/daily_time_rule.dart';
import '../styles/time_setup_tokens.dart';
import 'time_setup_action_button.dart';

class DailyTimeRuleSheet extends StatefulWidget {
  const DailyTimeRuleSheet({super.key, this.initialRule});

  final DailyTimeRule? initialRule;

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
    setState(() {
      if (_selectedDays.contains(index)) {
        _selectedDays.remove(index);
      } else {
        _selectedDays.add(index);
      }
    });
  }

  Future<void> _openTimePicker() async {
    final TimeSelection? result = await showModalBottomSheet<TimeSelection>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: const Color.fromRGBO(68, 68, 68, 0.6),
      builder: (BuildContext context) {
        return TimePickerSheet(initialTime: _selectedTime);
      },
    );

    if (result == null || !mounted) {
      return;
    }
    setState(() {
      _selectedTime = result;
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
    return SafeArea(
      top: false,
      child: Container(
        height: TimeSetupSize.ruleSheetHeight,
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
                            onTap: () => _toggleDay(day.key),
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: TimeSetupSpacing.sheetSectionGap),
                  const SheetLabel('시간 선택'),
                  const SizedBox(height: TimeSetupSpacing.sheetLabelGap),
                  TimeSelectorField(
                    time: _selectedTime,
                    onTap: _openTimePicker,
                  ),
                ],
              ),
            ),
            Positioned(
              left: TimeSetupSpacing.sheetHorizontalPadding,
              right: TimeSetupSpacing.sheetHorizontalPadding,
              bottom: TimeSetupSpacing.sheetButtonBottom,
              child: SheetConfirmButton(enabled: _canConfirm, onTap: _confirm),
            ),
          ],
        ),
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
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
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
          style: AppTypography.bodyMedium.copyWith(
            fontSize: 16,
            height: 1.5,
            letterSpacing: 0,
            color: selected ? AppColors.white : AppColors.gray600,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
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
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: TimeSetupTextStyles.timeNumber(
            selected: selected,
          ).copyWith(color: color),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: AppTypography.headlineRegular.copyWith(
            fontSize: 18,
            height: 1.445,
            letterSpacing: 0,
            color: const Color(0xFF050505),
          ),
        ),
      ],
    );
  }
}

class TimePickerSheet extends StatefulWidget {
  const TimePickerSheet({super.key, required this.initialTime});

  final TimeSelection initialTime;

  @override
  State<TimePickerSheet> createState() => _TimePickerSheetState();
}

class _TimePickerSheetState extends State<TimePickerSheet> {
  static const List<int> _hours = <int>[0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10];
  static const List<int> _minutes = <int>[
    0,
    5,
    10,
    15,
    20,
    25,
    30,
    35,
    40,
    45,
    50,
    55,
  ];

  late int _selectedHourIndex;
  late int _selectedMinuteIndex;
  late final FixedExtentScrollController _hourController;
  late final FixedExtentScrollController _minuteController;

  TimeSelection get _selectedTime {
    return TimeSelection(
      hour: _hours[_selectedHourIndex],
      minute: _minutes[_selectedMinuteIndex],
    );
  }

  int _initialIndexFor(List<int> values, int value) {
    final int index = values.indexOf(value);
    if (index < 0) {
      return 0;
    }
    return index;
  }

  @override
  void initState() {
    super.initState();
    final TimeSelection initial = widget.initialTime.isEmpty
        ? const TimeSelection(hour: 1, minute: 5)
        : widget.initialTime;
    _selectedHourIndex = _initialIndexFor(_hours, initial.hour);
    _selectedMinuteIndex = _initialIndexFor(_minutes, initial.minute);
    _hourController = FixedExtentScrollController(
      initialItem: _selectedHourIndex,
    );
    _minuteController = FixedExtentScrollController(
      initialItem: _selectedMinuteIndex,
    );
  }

  @override
  void dispose() {
    _hourController.dispose();
    _minuteController.dispose();
    super.dispose();
  }

  void _confirm() {
    Navigator.of(context).pop(_selectedTime);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        height: TimeSetupSize.pickerSheetHeight,
        decoration: const BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(TimeSetupRadius.sheet),
          ),
        ),
        child: Stack(
          children: [
            const Positioned(
              top: TimeSetupSpacing.pickerTitleTop,
              left: 0,
              right: 0,
              child: Center(child: SheetLabel('시간 선택')),
            ),
            Positioned(
              left: TimeSetupSpacing.sheetHorizontalPadding,
              right: TimeSetupSpacing.sheetHorizontalPadding,
              top: TimeSetupSpacing.pickerHighlightTop,
              height: TimeSetupSize.fieldHeight,
              child: const DecoratedBox(
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(color: AppColors.primary, width: 2),
                    bottom: BorderSide(color: AppColors.primary, width: 2),
                  ),
                ),
              ),
            ),
            Positioned(
              top: TimeSetupSpacing.pickerTop,
              left: 62,
              right: 62,
              height: TimeSetupSize.pickerHeight,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  PickerColumn(
                    controller: _hourController,
                    values: _hours,
                    selectedIndex: _selectedHourIndex,
                    onSelectedItemChanged: (int index) {
                      setState(() {
                        _selectedHourIndex = index;
                      });
                    },
                  ),
                  PickerColumn(
                    controller: _minuteController,
                    values: _minutes,
                    selectedIndex: _selectedMinuteIndex,
                    onSelectedItemChanged: (int index) {
                      setState(() {
                        _selectedMinuteIndex = index;
                      });
                    },
                  ),
                ],
              ),
            ),
            const Positioned(left: 143, top: 141, child: PickerUnitLabel('시간')),
            const Positioned(right: 63, top: 141, child: PickerUnitLabel('분')),
            Positioned(
              left: TimeSetupSpacing.sheetHorizontalPadding,
              right: TimeSetupSpacing.sheetHorizontalPadding,
              bottom: TimeSetupSpacing.sheetButtonBottom,
              child: SheetConfirmButton(enabled: true, onTap: _confirm),
            ),
          ],
        ),
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
                  fontSize: 24,
                  height: 1.364,
                  letterSpacing: 0,
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

class PickerUnitLabel extends StatelessWidget {
  const PickerUnitLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppTypography.headlineMedium.copyWith(
        fontSize: 18,
        height: 1.4,
        letterSpacing: 0,
        color: const Color(0xFF050505),
      ),
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
