import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../models/daily_time_rule.dart';
import '../routes/today_time_routes.dart';
import '../styles/time_setup_tokens.dart';
import '../widgets/daily_time_rule_sheet.dart';
import '../widgets/time_setup_action_button.dart';
import '../widgets/time_setup_top_bar.dart';
import 'whitelist_setup_page.dart';

class MonthlyTimeSetupArgs {
  const MonthlyTimeSetupArgs({
    required this.parentId,
    required this.childrenId,
    required this.rules,
  });

  final String? parentId;
  final String? childrenId;
  final List<DailyTimeRule> rules;
}

class MonthlyTimeSetupPage extends StatefulWidget {
  const MonthlyTimeSetupPage({
    super.key,
    this.parentId,
    this.childrenId,
    required this.rules,
  });

  final String? parentId;
  final String? childrenId;
  final List<DailyTimeRule> rules;

  @override
  State<MonthlyTimeSetupPage> createState() => _MonthlyTimeSetupPageState();
}

class _MonthlyTimeSetupPageState extends State<MonthlyTimeSetupPage> {
  late int _minimumTotalMinutes;
  late int _selectedTotalMinutes;

  @override
  void initState() {
    super.initState();
    _minimumTotalMinutes = _calculateMonthlyMinutes(widget.rules);
    _selectedTotalMinutes = _minimumTotalMinutes;
  }

  int _calculateMonthlyMinutes(List<DailyTimeRule> rules) {
    final DateTime now = DateTime.now();
    final int lastDay = DateTime(now.year, now.month + 1, 0).day;
    final List<int> weekdayCounts = List<int>.filled(7, 0);
    for (int day = 1; day <= lastDay; day++) {
      final int weekdayIndex = DateTime(now.year, now.month, day).weekday - 1;
      weekdayCounts[weekdayIndex]++;
    }

    int total = 0;
    for (final DailyTimeRule rule in rules) {
      final int dailyMinutes = rule.time.hour * 60 + rule.time.minute;
      for (final int dayIndex in rule.days) {
        total += dailyMinutes * weekdayCounts[dayIndex];
      }
    }
    return total;
  }

  TimeSelection _timeFromMinutes(int minutes) {
    return TimeSelection(hour: minutes ~/ 60, minute: minutes % 60);
  }

  Future<void> _openMonthlyPicker() async {
    final int? result = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: const Color.fromRGBO(68, 68, 68, 0.6),
      builder: (BuildContext context) {
        return _MonthlyTimePickerSheet(
          initialMinutes: _selectedTotalMinutes,
          minimumMinutes: _minimumTotalMinutes,
        );
      },
    );

    if (result == null || !mounted) {
      return;
    }
    setState(() {
      _selectedTotalMinutes = result;
    });
  }

  void _handleBack(BuildContext context) {
    final GoRouter router = GoRouter.of(context);
    if (router.canPop()) {
      router.pop();
      return;
    }
    router.go(TodayTimeRoutes.setup);
  }

  @override
  Widget build(BuildContext context) {
    final TimeSelection total = _timeFromMinutes(_selectedTotalMinutes);

    return Scaffold(
      backgroundColor: AppColors.gray050,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: TimeSetupSpacing.screenMaxWidth,
            ),
            child: Column(
              children: [
                TimeSetupTopBar(
                  title: '시간설정',
                  onBack: () => _handleBack(context),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 4, 24, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '이번 달 총 시간 설정',
                          style: TimeSetupTextStyles.sectionTitle,
                        ),
                        const SizedBox(height: 10.789),
                        Text(
                          '일별 시간 설정을 바탕으로 이번 달 총 시간이 계산되었어요\n'
                          '이대로 확정하거나, 여유 시간을 조금 더 보탤 수 있어요.',
                          style: AppTypography.labelMedium.copyWith(
                            fontSize: 12.587,
                            height: 1.429,
                            letterSpacing: 0.1825,
                            color: AppColors.gray500,
                          ),
                        ),
                        const SizedBox(height: 26.972),
                        _MonthlyTotalField(
                          time: total,
                          onTap: _openMonthlyPicker,
                        ),
                        const SizedBox(height: 35.963),
                        ...widget.rules.map(
                          (DailyTimeRule rule) => Padding(
                            padding: const EdgeInsets.only(bottom: 13.486),
                            child: _MonthlyRuleCard(rule: rule),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 31),
                  child: TimeSetupActionButton(
                    label: '확인',
                    enabled: true,
                    onTap: () => context.go(
                      TodayTimeRoutes.whitelist,
                      extra: WhitelistSetupArgs(
                        parentId: widget.parentId,
                        childrenId: widget.childrenId,
                        total: total,
                        rules: List<DailyTimeRule>.from(widget.rules),
                      ),
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
}

class _MonthlyTotalField extends StatelessWidget {
  const _MonthlyTotalField({required this.time, required this.onTap});

  final TimeSelection time;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(TimeSetupRadius.field),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        hoverColor: AppColors.primary.withValues(alpha: 0.06),
        highlightColor: AppColors.primary.withValues(alpha: 0.10),
        splashColor: AppColors.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(TimeSetupRadius.field),
        child: Container(
          height: 56.642,
          width: double.infinity,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10.789),
            border: Border.all(color: AppColors.gray200, width: 1.798),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TimeSelectorPart(
                value: time.hour.toString(),
                label: '시간',
                color: AppColors.primary,
                selected: true,
              ),
              const SizedBox(width: 25.174),
              TimeSelectorPart(
                value: time.minute.toString().padLeft(2, '0'),
                label: '분',
                color: AppColors.primary,
                selected: true,
              ),
              const SizedBox(width: 34),
              const Icon(
                Icons.edit_outlined,
                size: 21.578,
                color: AppColors.gray800,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MonthlyRuleCard extends StatelessWidget {
  const _MonthlyRuleCard({required this.rule});

  final DailyTimeRule rule;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16.183),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14.385),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            rule.dayText,
            style: AppTypography.headlineBold.copyWith(
              fontSize: 16.183,
              height: 1.445,
              letterSpacing: -0.0032,
              color: AppColors.gray800,
            ),
          ),
          Container(
            width: 1,
            height: 19.78,
            margin: const EdgeInsets.symmetric(horizontal: 8.991),
            color: AppColors.gray200,
          ),
          Text(
            rule.time.displayText,
            style: AppTypography.headlineBold.copyWith(
              fontSize: 16.183,
              height: 1.445,
              letterSpacing: -0.0032,
              color: AppColors.gray800,
            ),
          ),
        ],
      ),
    );
  }
}

class _MonthlyTimePickerSheet extends StatefulWidget {
  const _MonthlyTimePickerSheet({
    required this.initialMinutes,
    required this.minimumMinutes,
  });

  final int initialMinutes;
  final int minimumMinutes;

  @override
  State<_MonthlyTimePickerSheet> createState() =>
      _MonthlyTimePickerSheetState();
}

class _MonthlyTimePickerSheetState extends State<_MonthlyTimePickerSheet> {
  static const List<int> _minuteSteps = <int>[
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

  late final List<int> _hours;
  late final List<int> _minutes;
  late int _selectedHourIndex;
  late int _selectedMinuteIndex;
  late final FixedExtentScrollController _hourController;
  late final FixedExtentScrollController _minuteController;

  int get _selectedMinutes =>
      _hours[_selectedHourIndex] * 60 + _minutes[_selectedMinuteIndex];

  @override
  void initState() {
    super.initState();
    final int minimumHour = widget.minimumMinutes ~/ 60;
    _hours = List<int>.generate(26, (int index) => minimumHour + index);
    _minutes = _rotatedMinuteSteps(widget.minimumMinutes % 60);
    _setInitialMinutes(widget.initialMinutes);
    _hourController = FixedExtentScrollController(
      initialItem: _selectedHourIndex,
    );
    _minuteController = FixedExtentScrollController(
      initialItem: _selectedMinuteIndex,
    );
  }

  List<int> _rotatedMinuteSteps(int startMinute) {
    final int startIndex = _minuteSteps.indexOf(startMinute);
    if (startIndex < 0) {
      return _minuteSteps;
    }
    return <int>[
      ..._minuteSteps.skip(startIndex),
      ..._minuteSteps.take(startIndex),
    ];
  }

  void _selectDefaultAddedTime() {
    final int minimumHour = widget.minimumMinutes ~/ 60;
    _selectedHourIndex = _hours
        .indexOf(minimumHour + 1)
        .clamp(0, _hours.length - 1);
    _selectedMinuteIndex = _minutes.length > 1 ? 1 : 0;
  }

  void _setInitialMinutes(int minutes) {
    if (minutes <= widget.minimumMinutes) {
      _selectDefaultAddedTime();
      return;
    }

    final int hour = minutes ~/ 60;
    final int minute = minutes % 60;
    _selectedHourIndex = _hours.indexOf(hour).clamp(0, _hours.length - 1);
    _selectedMinuteIndex = _minutes.indexOf(minute);
    if (_selectedMinuteIndex < 0) {
      _selectedMinuteIndex = 0;
    }
    if (_selectedMinutes <= widget.minimumMinutes) {
      _selectDefaultAddedTime();
    }
  }

  void _clampIfNeeded() {
    if (_selectedMinutes > widget.minimumMinutes) {
      return;
    }
    _selectDefaultAddedTime();
    _hourController.jumpToItem(_selectedHourIndex);
    _minuteController.jumpToItem(_selectedMinuteIndex);
  }

  @override
  void dispose() {
    _hourController.dispose();
    _minuteController.dispose();
    super.dispose();
  }

  void _confirm() {
    Navigator.of(context).pop(_selectedMinutes);
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
          const Positioned(
            top: TimeSetupSpacing.pickerTitleTop,
            left: 0,
            right: 0,
            child: Center(child: SheetLabel('시간 수정')),
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
            left: TimeSetupSpacing.pickerHorizontalInset,
            right: TimeSetupSpacing.pickerHorizontalInset,
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
                      _clampIfNeeded();
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
                      _clampIfNeeded();
                    });
                  },
                ),
              ],
            ),
          ),
          const Positioned(
            left: TimeSetupSpacing.sheetHorizontalPadding,
            right: TimeSetupSpacing.sheetHorizontalPadding,
            top: TimeSetupSpacing.pickerHighlightTop,
            height: 44.954,
            child: IgnorePointer(child: PickerSelectionUnits()),
          ),
          Positioned(
            left: TimeSetupSpacing.sheetHorizontalPadding,
            right: TimeSetupSpacing.sheetHorizontalPadding,
            bottom: TimeSetupSpacing.sheetButtonBottom + bottomInset,
            child: SheetConfirmButton(enabled: true, onTap: _confirm),
          ),
        ],
      ),
    );
  }
}
