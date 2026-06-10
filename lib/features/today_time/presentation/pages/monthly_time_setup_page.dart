import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/models/result.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../data/repositories/time_plan_repository.dart';
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
    this.initialMonthlyTotalMinutes,
    this.initialSelectedAppIds,
  });

  final String? parentId;
  final String? childrenId;
  final List<DailyTimeRule> rules;
  final int? initialMonthlyTotalMinutes;
  final Set<String>? initialSelectedAppIds;
}

class MonthlyTimeSetupPage extends StatefulWidget {
  const MonthlyTimeSetupPage({
    super.key,
    this.parentId,
    this.childrenId,
    required this.rules,
    this.initialMonthlyTotalMinutes,
    this.initialSelectedAppIds,
  });

  final String? parentId;
  final String? childrenId;
  final List<DailyTimeRule> rules;
  final int? initialMonthlyTotalMinutes;
  final Set<String>? initialSelectedAppIds;

  @override
  State<MonthlyTimeSetupPage> createState() => _MonthlyTimeSetupPageState();
}

class _MonthlyTimeSetupPageState extends State<MonthlyTimeSetupPage> {
  final TimePlanRepository _timePlanRepository = createTimePlanRepository();
  late int _minimumTotalMinutes;
  late int _selectedTotalMinutes;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _minimumTotalMinutes = calculateMonthlyMinutesForRules(widget.rules);
    _selectedTotalMinutes =
        widget.initialMonthlyTotalMinutes == null ||
            widget.initialMonthlyTotalMinutes! < _minimumTotalMinutes
        ? _minimumTotalMinutes
        : widget.initialMonthlyTotalMinutes!;
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

  Future<void> _continueToWhitelist(TimeSelection total) async {
    if (_isSaving) {
      return;
    }
    final String? parentId = widget.parentId;
    final String? childrenId = widget.childrenId;
    if (parentId != null &&
        parentId.isNotEmpty &&
        childrenId != null &&
        childrenId.isNotEmpty) {
      setState(() {
        _isSaving = true;
      });
      final Result<void> result = await _timePlanRepository.saveMonthlyTotal(
        parentId: parentId,
        childrenId: childrenId,
        totalMinutes: _selectedTotalMinutes,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _isSaving = false;
      });
      if (result case Failure<void>(:final message)) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
        return;
      }
    }
    if (!mounted) {
      return;
    }
    context.go(
      TodayTimeRoutes.whitelist,
      extra: WhitelistSetupArgs(
        parentId: parentId,
        childrenId: childrenId,
        total: total,
        rules: List<DailyTimeRule>.from(widget.rules),
        initialSelectedAppIds: widget.initialSelectedAppIds,
      ),
    );
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
                        const SizedBox(
                          height: TimeSetupSpacing.titleToDescriptionGap,
                        ),
                        Text(
                          '일별 시간 설정을 바탕으로 이번 달 총 시간이 계산되었어요\n'
                          '이대로 확정하거나, 여유 시간을 조금 더 보탤 수 있어요.',
                          style: AppTypography.labelMedium.copyWith(
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
                    label: _isSaving ? '저장중' : '확인',
                    enabled: !_isSaving,
                    disabledMessage: '시간 설정을 저장하는 중입니다.',
                    onTap: () => _continueToWhitelist(total),
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
            borderRadius: BorderRadius.circular(TimeSetupRadius.field),
            border: Border.all(color: AppColors.gray200),
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
        borderRadius: BorderRadius.circular(TimeSetupRadius.card),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            rule.dayText,
            style: AppTypography.bodySemiBold.copyWith(
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
            style: AppTypography.bodySemiBold.copyWith(
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
