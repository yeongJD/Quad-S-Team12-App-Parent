import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

abstract final class _TimeSetupMetrics {
  static const double screenMaxWidth = 375;
  static const double horizontalPadding = 24;
  static const double topBarHeight = 52;
  static const double contentTopGap = 14;
  static const double titleToDescriptionGap = 12;
  static const double addButtonSize = 40;
  static const double addIconSize = 24;
  static const double bottomButtonGap = 31;
  static const double buttonHeight = 54;
  static const double sheetHeight = 397;
  static const double sheetRadius = 24;
  static const double sheetHorizontalPadding = 24;
  static const double sheetTopPadding = 38;
  static const double sheetButtonBottom = 63;
  static const double dayChipSize = 40;
  static const double fieldHeight = 50;
}

const List<String> _weekdayLabels = <String>['월', '화', '수', '목', '금', '토', '일'];

class _TimeSelection {
  const _TimeSelection({required this.hour, required this.minute});

  final int hour;
  final int minute;

  bool get isEmpty => hour == 0 && minute == 0;

  String get hourText => hour.toString().padLeft(2, '0');
  String get minuteText => minute.toString().padLeft(2, '0');

  String get displayText {
    if (minute == 0) {
      return '$hour시간';
    }
    if (hour == 0) {
      return '$minute분';
    }
    return '$hour시간 $minute분';
  }
}

class _DailyTimeEntry {
  const _DailyTimeEntry({required this.days, required this.time});

  final Set<int> days;
  final _TimeSelection time;

  String get dayText {
    final Set<int> allDays = Set<int>.from(List<int>.generate(7, (int i) => i));
    const Set<int> weekdays = <int>{0, 1, 2, 3, 4};
    const Set<int> weekend = <int>{5, 6};

    if (days.length == allDays.length && days.containsAll(allDays)) {
      return '매일';
    }
    if (days.length == weekdays.length && days.containsAll(weekdays)) {
      return '주중';
    }
    if (days.length == weekend.length && days.containsAll(weekend)) {
      return '주말';
    }
    final List<int> sortedDays = days.toList()..sort();
    return sortedDays.map((int index) => _weekdayLabels[index]).join(', ');
  }
}

class TodayTimeSetupPage extends StatefulWidget {
  const TodayTimeSetupPage({super.key});

  @override
  State<TodayTimeSetupPage> createState() => _TodayTimeSetupPageState();
}

class _TodayTimeSetupPageState extends State<TodayTimeSetupPage> {
  final List<_DailyTimeEntry> _entries = <_DailyTimeEntry>[];

  bool _showTip = false;

  bool get _hasEntries => _entries.isNotEmpty;

  void _toggleTip() {
    setState(() {
      _showTip = !_showTip;
    });
  }

  void _closeTip() {
    if (!_showTip) {
      return;
    }
    setState(() {
      _showTip = false;
    });
  }

  Future<void> _openEntrySheet({
    _DailyTimeEntry? initialEntry,
    int? index,
  }) async {
    final _DailyTimeEntry? result = await showModalBottomSheet<_DailyTimeEntry>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: const Color.fromRGBO(68, 68, 68, 0.6),
      builder: (BuildContext context) {
        return _DailyTimeEntrySheet(initialEntry: initialEntry);
      },
    );

    if (result == null || !mounted) {
      return;
    }
    setState(() {
      if (index == null) {
        _entries.add(result);
      } else {
        _entries[index] = result;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.gray050,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: _TimeSetupMetrics.screenMaxWidth,
            ),
            child: Stack(
              children: [
                Column(
                  children: [
                    const _TimeSetupTopBar(),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(
                          _TimeSetupMetrics.horizontalPadding,
                          _TimeSetupMetrics.contentTopGap,
                          _TimeSetupMetrics.horizontalPadding,
                          24,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _TimeSetupHeader(
                              showTip: _showTip,
                              onTipTap: _toggleTip,
                            ),
                            SizedBox(height: _hasEntries ? 30 : 40),
                            if (_hasEntries)
                              _DailyTimeEntryList(
                                entries: _entries,
                                onEdit: (int index) {
                                  _openEntrySheet(
                                    initialEntry: _entries[index],
                                    index: index,
                                  );
                                },
                                onAdd: () => _openEntrySheet(),
                              )
                            else
                              Center(
                                child: _TimeAddButton(
                                  onTap: () => _openEntrySheet(),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        _TimeSetupMetrics.horizontalPadding,
                        0,
                        _TimeSetupMetrics.horizontalPadding,
                        _TimeSetupMetrics.bottomButtonGap,
                      ),
                      child: _ConfirmButton(enabled: _hasEntries),
                    ),
                  ],
                ),
                if (_showTip)
                  Positioned(
                    left: 42,
                    right: 38,
                    top: 111,
                    child: _TimeTipPopover(onClose: _closeTip),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TimeSetupTopBar extends StatelessWidget {
  const _TimeSetupTopBar();

  void _handleBack(BuildContext context) {
    final GoRouter router = GoRouter.of(context);
    if (router.canPop()) {
      router.pop();
      return;
    }
    router.go('/parent-home');
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _TimeSetupMetrics.topBarHeight,
      child: Stack(
        children: [
          Center(
            child: Text(
              '시간설정',
              style: AppTypography.headlineMedium.copyWith(
                fontSize: 18,
                height: 1.445,
                letterSpacing: 0,
                color: const Color(0xFF050505),
              ),
            ),
          ),
          Positioned(
            left: _TimeSetupMetrics.horizontalPadding,
            top: 14,
            child: GestureDetector(
              onTap: () => _handleBack(context),
              behavior: HitTestBehavior.opaque,
              child: SizedBox(
                width: 24,
                height: 24,
                child: Padding(
                  padding: const EdgeInsets.all(2),
                  child: SvgPicture.asset('assets/icons/cmp/btn/back.svg'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TimeSetupHeader extends StatelessWidget {
  const _TimeSetupHeader({required this.showTip, required this.onTipTap});

  final bool showTip;
  final VoidCallback onTipTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '일간 시간 설정',
              style: AppTypography.heading1Bold.copyWith(
                fontSize: 24,
                height: 1.364,
                letterSpacing: 0,
                color: const Color(0xFF050505),
              ),
            ),
            const SizedBox(width: 10),
            _TipButton(active: showTip, onTap: onTipTap),
          ],
        ),
        const SizedBox(height: _TimeSetupMetrics.titleToDescriptionGap),
        Text(
          '자녀가 하루에 사용했으면 하는 시간을 설정해주세요!\n'
          '이 시간을 이용해서 주간 총시간이 자동 계산 됩니다.',
          style: AppTypography.labelMedium.copyWith(
            fontSize: 14,
            height: 1.429,
            letterSpacing: 0,
            color: AppColors.gray500,
          ),
        ),
      ],
    );
  }
}

class _TipButton extends StatelessWidget {
  const _TipButton({required this.active, required this.onTap});

  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 27,
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
        decoration: BoxDecoration(
          color: const Color(0xFFEBF5FE),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              active ? Icons.lightbulb : Icons.lightbulb_outline,
              size: 18,
              color: AppColors.primary,
            ),
            const SizedBox(width: 5),
            Text(
              'Tip',
              style: AppTypography.bodyMedium.copyWith(
                fontSize: 14,
                height: 1.5,
                letterSpacing: 0,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TimeAddButton extends StatelessWidget {
  const _TimeAddButton({required this.onTap, this.muted = false});

  final VoidCallback onTap;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '시간 추가',
      button: true,
      child: GestureDetector(
        key: const ValueKey<String>('daily-time-add-button'),
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          width: _TimeSetupMetrics.addButtonSize,
          height: _TimeSetupMetrics.addButtonSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: muted ? const Color(0xFFEDEEF1) : const Color(0xFFEBF5FE),
          ),
          child: Center(
            child: _PlusIcon(
              size: _TimeSetupMetrics.addIconSize,
              color: muted ? AppColors.gray400 : AppColors.primary,
            ),
          ),
        ),
      ),
    );
  }
}

class _DailyTimeEntryList extends StatelessWidget {
  const _DailyTimeEntryList({
    required this.entries,
    required this.onEdit,
    required this.onAdd,
  });

  final List<_DailyTimeEntry> entries;
  final ValueChanged<int> onEdit;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (int index = 0; index < entries.length; index++) ...[
          _DailyTimeEntryCard(
            entry: entries[index],
            onEdit: () => onEdit(index),
          ),
          const SizedBox(height: 15),
        ],
        _TimeAddButton(onTap: onAdd, muted: true),
      ],
    );
  }
}

class _DailyTimeEntryCard extends StatelessWidget {
  const _DailyTimeEntryCard({required this.entry, required this.onEdit});

  final _DailyTimeEntry entry;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Row(
                children: [
                  Text(
                    entry.dayText,
                    style: AppTypography.headlineBold.copyWith(
                      fontSize: 18,
                      height: 1.445,
                      letterSpacing: 0,
                      color: AppColors.gray800,
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 22,
                    margin: const EdgeInsets.symmetric(horizontal: 10),
                    color: AppColors.gray200,
                  ),
                  Text(
                    entry.time.displayText,
                    style: AppTypography.headlineBold.copyWith(
                      fontSize: 18,
                      height: 1.445,
                      letterSpacing: 0,
                      color: AppColors.gray800,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 14),
          GestureDetector(
            onTap: onEdit,
            behavior: HitTestBehavior.opaque,
            child: const Icon(
              Icons.edit_outlined,
              size: 24,
              color: AppColors.gray800,
            ),
          ),
        ],
      ),
    );
  }
}

class _PlusIcon extends StatelessWidget {
  const _PlusIcon({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    const double stroke = 2;

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

class _DailyTimeEntrySheet extends StatefulWidget {
  const _DailyTimeEntrySheet({this.initialEntry});

  final _DailyTimeEntry? initialEntry;

  @override
  State<_DailyTimeEntrySheet> createState() => _DailyTimeEntrySheetState();
}

class _DailyTimeEntrySheetState extends State<_DailyTimeEntrySheet> {
  late Set<int> _selectedDays;
  late _TimeSelection _selectedTime;

  bool get _canConfirm => _selectedDays.isNotEmpty && !_selectedTime.isEmpty;

  @override
  void initState() {
    super.initState();
    _selectedDays = Set<int>.from(widget.initialEntry?.days ?? <int>{});
    _selectedTime =
        widget.initialEntry?.time ?? const _TimeSelection(hour: 0, minute: 0);
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
    final _TimeSelection? result = await showModalBottomSheet<_TimeSelection>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: const Color.fromRGBO(68, 68, 68, 0.6),
      builder: (BuildContext context) {
        return _TimePickerSheet(initialTime: _selectedTime);
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
      _DailyTimeEntry(days: Set<int>.from(_selectedDays), time: _selectedTime),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        height: _TimeSetupMetrics.sheetHeight,
        decoration: const BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(_TimeSetupMetrics.sheetRadius),
          ),
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                _TimeSetupMetrics.sheetHorizontalPadding,
                _TimeSetupMetrics.sheetTopPadding,
                _TimeSetupMetrics.sheetHorizontalPadding,
                0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SheetLabel('요일 선택'),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      for (
                        int index = 0;
                        index < _weekdayLabels.length;
                        index++
                      )
                        _DayChip(
                          label: _weekdayLabels[index],
                          selected: _selectedDays.contains(index),
                          onTap: () => _toggleDay(index),
                        ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  _SheetLabel('시간 선택'),
                  const SizedBox(height: 10),
                  _TimeSelectorField(
                    time: _selectedTime,
                    onTap: _openTimePicker,
                  ),
                ],
              ),
            ),
            Positioned(
              left: _TimeSetupMetrics.sheetHorizontalPadding,
              right: _TimeSetupMetrics.sheetHorizontalPadding,
              bottom: _TimeSetupMetrics.sheetButtonBottom,
              child: _SheetConfirmButton(enabled: _canConfirm, onTap: _confirm),
            ),
          ],
        ),
      ),
    );
  }
}

class _SheetLabel extends StatelessWidget {
  const _SheetLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppTypography.headlineBold.copyWith(
        fontSize: 18,
        height: 1.445,
        letterSpacing: 0,
        color: AppColors.gray800,
      ),
    );
  }
}

class _DayChip extends StatelessWidget {
  const _DayChip({
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
        width: _TimeSetupMetrics.dayChipSize,
        height: _TimeSetupMetrics.dayChipSize,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.gray100,
          borderRadius: BorderRadius.circular(12),
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

class _TimeSelectorField extends StatelessWidget {
  const _TimeSelectorField({required this.time, required this.onTap});

  final _TimeSelection time;
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
          height: _TimeSetupMetrics.fieldHeight,
          width: double.infinity,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.gray200, width: 2),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _TimeSelectorPart(
                value: time.hourText,
                label: '시간',
                color: numberColor,
              ),
              const SizedBox(width: 34),
              _TimeSelectorPart(
                value: time.minuteText,
                label: '분',
                color: numberColor,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TimeSelectorPart extends StatelessWidget {
  const _TimeSelectorPart({
    required this.value,
    required this.label,
    required this.color,
  });

  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: AppTypography.headlineBold.copyWith(
            fontSize: 18,
            height: 1.445,
            letterSpacing: 0,
            color: color,
          ),
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

class _TimePickerSheet extends StatefulWidget {
  const _TimePickerSheet({required this.initialTime});

  final _TimeSelection initialTime;

  @override
  State<_TimePickerSheet> createState() => _TimePickerSheetState();
}

class _TimePickerSheetState extends State<_TimePickerSheet> {
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

  _TimeSelection get _selectedTime {
    return _TimeSelection(
      hour: _hours[_selectedHourIndex],
      minute: _minutes[_selectedMinuteIndex],
    );
  }

  @override
  void initState() {
    super.initState();
    final _TimeSelection initial = widget.initialTime.isEmpty
        ? const _TimeSelection(hour: 1, minute: 5)
        : widget.initialTime;
    _selectedHourIndex = _hours
        .indexOf(initial.hour)
        .clamp(0, _hours.length - 1);
    _selectedMinuteIndex = _minutes
        .indexOf(initial.minute)
        .clamp(0, _minutes.length - 1);
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
        height: _TimeSetupMetrics.sheetHeight,
        decoration: const BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(_TimeSetupMetrics.sheetRadius),
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: 27,
              left: 0,
              right: 0,
              child: Center(child: _SheetLabel('시간 선택')),
            ),
            Positioned(
              left: _TimeSetupMetrics.sheetHorizontalPadding,
              right: _TimeSetupMetrics.sheetHorizontalPadding,
              top: 128,
              height: 50,
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
              top: 80,
              left: 62,
              right: 62,
              height: 148,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _PickerColumn(
                    controller: _hourController,
                    values: _hours,
                    selectedIndex: _selectedHourIndex,
                    onSelectedItemChanged: (int index) {
                      setState(() {
                        _selectedHourIndex = index;
                      });
                    },
                  ),
                  _PickerColumn(
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
            const Positioned(
              left: 143,
              top: 141,
              child: _PickerUnitLabel('시간'),
            ),
            const Positioned(right: 63, top: 141, child: _PickerUnitLabel('분')),
            Positioned(
              left: _TimeSetupMetrics.sheetHorizontalPadding,
              right: _TimeSetupMetrics.sheetHorizontalPadding,
              bottom: _TimeSetupMetrics.sheetButtonBottom,
              child: _SheetConfirmButton(enabled: true, onTap: _confirm),
            ),
          ],
        ),
      ),
    );
  }
}

class _PickerColumn extends StatelessWidget {
  const _PickerColumn({
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
      width: 56,
      child: CupertinoPicker(
        scrollController: controller,
        itemExtent: 48,
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

class _PickerUnitLabel extends StatelessWidget {
  const _PickerUnitLabel(this.text);

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

class _SheetConfirmButton extends StatelessWidget {
  const _SheetConfirmButton({required this.enabled, required this.onTap});

  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: _TimeSetupMetrics.buttonHeight,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: enabled ? AppColors.primary : AppColors.gray200,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          '확인',
          style: AppTypography.headlineMedium.copyWith(
            fontSize: 18,
            height: 1.445,
            letterSpacing: 0,
            color: enabled ? AppColors.white : AppColors.gray300,
          ),
        ),
      ),
    );
  }
}

class _TimeTipPopover extends StatelessWidget {
  const _TimeTipPopover({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          top: -8,
          left: 130,
          child: CustomPaint(
            size: const Size(12, 8),
            painter: _TipCaretPainter(),
          ),
        ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
          decoration: BoxDecoration(
            color: AppColors.gray600,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '적절한 사용 시간이 고민되시나요?',
                      style: AppTypography.bodyMedium.copyWith(
                        fontSize: 16,
                        height: 1.5,
                        letterSpacing: 0,
                        color: AppColors.gray100,
                      ),
                    ),
                    const SizedBox(height: 14),
                    _TipParagraph(
                      title: '1. 초등 고학년 권장 스마트폰 사용 시간',
                      body: '주중 약 55분 / 주말 약 80분',
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '*대한소아청소년의학회의 정신건강의학과 전문의 121명\n'
                      '대상 설문 조사 결과 (2014)\n'
                      '*학습앱, 전화, 문자 기본앱 사용 제외',
                      style: AppTypography.captionRegular.copyWith(
                        fontSize: 12,
                        height: 1.334,
                        letterSpacing: 0,
                        color: AppColors.gray100,
                      ),
                    ),
                    const SizedBox(height: 22),
                    _TipParagraph(title: '2. 또래 평균 스마트폰 사용 시간', body: '약 2시간'),
                    const SizedBox(height: 24),
                    Text(
                      '위 기준을 참고해 자녀의 생활 패턴에 맞는\n'
                      '사용 시간을 설정해 보세요.',
                      style: AppTypography.captionRegular.copyWith(
                        fontSize: 14,
                        height: 1.429,
                        letterSpacing: 0,
                        color: AppColors.gray100,
                      ),
                    ),
                    const SizedBox(height: 26),
                    RichText(
                      text: TextSpan(
                        style: AppTypography.captionRegular.copyWith(
                          fontSize: 14,
                          height: 1.429,
                          letterSpacing: 0,
                          color: AppColors.gray100,
                        ),
                        children: const [
                          TextSpan(text: '더 많은 정보 보기: 스마트쉼센터 '),
                          TextSpan(
                            text: 'https://www.iapc.or.kr',
                            style: TextStyle(
                              decoration: TextDecoration.underline,
                              decorationColor: AppColors.gray100,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                right: 0,
                top: 0,
                child: GestureDetector(
                  onTap: onClose,
                  behavior: HitTestBehavior.opaque,
                  child: const Icon(
                    Icons.close_rounded,
                    size: 18,
                    color: AppColors.gray200,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TipParagraph extends StatelessWidget {
  const _TipParagraph({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: '$title\n',
            style: AppTypography.labelBold.copyWith(
              fontSize: 14,
              height: 1.429,
              letterSpacing: 0,
              color: AppColors.gray100,
            ),
          ),
          TextSpan(
            text: body,
            style: AppTypography.labelRegular.copyWith(
              fontSize: 14,
              height: 1.429,
              letterSpacing: 0,
              color: AppColors.gray100,
            ),
          ),
        ],
      ),
    );
  }
}

class _TipCaretPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()..color = AppColors.gray600;
    final Path path = Path()
      ..moveTo(size.width / 2, 0)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ConfirmButton extends StatelessWidget {
  const _ConfirmButton({required this.enabled});

  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: _TimeSetupMetrics.buttonHeight,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: enabled ? AppColors.primary : AppColors.gray200,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '확인',
        style: AppTypography.headlineMedium.copyWith(
          fontSize: 18,
          height: 1.445,
          letterSpacing: 0,
          color: enabled ? AppColors.white : AppColors.gray300,
        ),
      ),
    );
  }
}
