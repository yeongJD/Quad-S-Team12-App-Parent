import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../today_time/presentation/models/daily_time_rule.dart';
import '../../../today_time/presentation/styles/time_setup_tokens.dart';
import '../../../../data/repositories/mission_repository.dart';
import '../../../today_time/presentation/widgets/daily_time_rule_sheet.dart';
import '../../../today_time/presentation/widgets/time_setup_action_button.dart';
import '../models/today_mission.dart';
import '../widgets/mission_top_bar.dart';

class TodayMissionEditArgs {
  const TodayMissionEditArgs({
    required this.parentId,
    required this.childrenId,
    required this.index,
    required this.mission,
  });

  final String parentId;
  final String childrenId;
  final int index;
  final TodayMission mission;
}

class TodayMissionEditPage extends StatefulWidget {
  const TodayMissionEditPage({
    super.key,
    this.parentId,
    this.childrenId,
    this.initialMission,
    this.missionIndex,
  });

  final String? parentId;
  final String? childrenId;
  final TodayMission? initialMission;
  final int? missionIndex;

  @override
  State<TodayMissionEditPage> createState() => _TodayMissionEditPageState();
}

class _TodayMissionEditPageState extends State<TodayMissionEditPage> {
  static const double _contentHorizontalPadding = 24;

  final MissionRepository _missionRepository = createMissionRepository();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  MissionCategory? _category;
  MissionResetPeriod? _resetPeriod;
  MissionConfirmationMethod? _confirmationMethod;
  TimeSelection _rewardTime = const TimeSelection(hour: 0, minute: 0);

  bool get _canSubmit {
    return _titleController.text.trim().isNotEmpty &&
        _category != null &&
        _resetPeriod != null &&
        _confirmationMethod != null &&
        !_rewardTime.isEmpty;
  }

  @override
  void initState() {
    super.initState();
    final TodayMission? initialMission = widget.initialMission;
    _titleController = TextEditingController(text: initialMission?.title ?? '');
    _descriptionController = TextEditingController(
      text: initialMission?.description ?? '',
    );
    _category = initialMission?.category;
    _resetPeriod = initialMission?.resetPeriod;
    _confirmationMethod = initialMission?.confirmationMethod;
    if (initialMission != null) {
      _rewardTime = TimeSelection(
        hour: initialMission.rewardMinutes ~/ 60,
        minute: initialMission.rewardMinutes % 60,
      );
    }
    _titleController.addListener(_handleFieldChanged);
    _descriptionController.addListener(_handleFieldChanged);
  }

  @override
  void dispose() {
    _titleController.removeListener(_handleFieldChanged);
    _descriptionController.removeListener(_handleFieldChanged);
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _handleFieldChanged() {
    setState(() {});
  }

  void _handleBack() {
    final GoRouter router = GoRouter.of(context);
    if (router.canPop()) {
      router.pop();
      return;
    }
    router.go('/today-mission');
  }

  Future<void> _openRewardTimeSheet() async {
    final TimeSelection? selectedTime =
        await showModalBottomSheet<TimeSelection>(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          barrierColor: const Color.fromRGBO(68, 68, 68, 0.6),
          builder: (BuildContext context) {
            return _MissionRewardTimeSheet(initialTime: _rewardTime);
          },
        );

    if (selectedTime == null || !mounted) {
      return;
    }

    setState(() {
      _rewardTime = selectedTime;
    });
  }

  Future<void> _submit() async {
    if (!_canSubmit) {
      return;
    }

    final TodayMission mission = TodayMission(
      title: _titleController.text.trim(),
      category: _category!,
      resetPeriod: _resetPeriod!,
      confirmationMethod: _confirmationMethod!,
      rewardMinutes: _rewardTime.hour * 60 + _rewardTime.minute,
      description: _descriptionController.text.trim(),
      status: widget.initialMission?.status ?? TodayMissionStatus.pending,
      verificationStatus:
          widget.initialMission?.effectiveVerificationStatus ??
          MissionVerificationStatus.idle,
      submittedAtText: widget.initialMission?.submittedAtText,
    );

    final int? missionIndex = widget.missionIndex;
    final String? parentId = widget.parentId;
    final String? childrenId = widget.childrenId;
    if (parentId == null ||
        parentId.isEmpty ||
        childrenId == null ||
        childrenId.isEmpty) {
      return;
    }

    if (missionIndex == null) {
      await _missionRepository.addMission(
        parentId: parentId,
        childrenId: childrenId,
        mission: mission,
      );
    } else {
      await _missionRepository.updateMissionAt(
        parentId: parentId,
        childrenId: childrenId,
        index: missionIndex,
        mission: mission,
      );
    }

    if (!mounted) {
      return;
    }
    _handleBack();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.gray100,
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 375),
            child: Column(
              children: [
                MissionTopBar(title: '미션 등록', onBack: _handleBack),
                Expanded(
                  child: LayoutBuilder(
                    builder: (BuildContext context, BoxConstraints viewport) {
                      return SingleChildScrollView(
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.onDrag,
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minWidth: viewport.maxWidth,
                            minHeight: viewport.maxHeight,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  _contentHorizontalPadding,
                                  18,
                                  _contentHorizontalPadding,
                                  0,
                                ),
                                child: _MissionTitleField(
                                  controller: _titleController,
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  _contentHorizontalPadding,
                                  18,
                                  _contentHorizontalPadding,
                                  0,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const _SectionTitle('카테고리'),
                                    const SizedBox(height: 18),
                                    _EvenSelectionRow<MissionCategory>(
                                      values: MissionCategory.values,
                                      selectedValue: _category,
                                      spacing: 8,
                                      labelOf: (MissionCategory value) =>
                                          value.label,
                                      onSelected: (MissionCategory value) {
                                        setState(() {
                                          _category = value;
                                        });
                                      },
                                    ),
                                  ],
                                ),
                              ),
                              const _SectionDivider(),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: _contentHorizontalPadding,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const _SectionTitle('리셋주기'),
                                    const SizedBox(height: 18),
                                    _FixedSelectionRow<MissionResetPeriod>(
                                      values: MissionResetPeriod.values,
                                      selectedValue: _resetPeriod,
                                      widths: const <double>[74, 88, 74],
                                      spacing: 14,
                                      labelOf: (MissionResetPeriod value) =>
                                          value.label,
                                      onSelected: (MissionResetPeriod value) {
                                        setState(() {
                                          _resetPeriod = value;
                                        });
                                      },
                                    ),
                                  ],
                                ),
                              ),
                              const _SectionDivider(),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: _contentHorizontalPadding,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const _SectionTitle('확인방식'),
                                    const SizedBox(height: 18),
                                    _EvenSelectionRow<
                                      MissionConfirmationMethod
                                    >(
                                      values: MissionConfirmationMethod.values,
                                      selectedValue: _confirmationMethod,
                                      spacing: 14,
                                      labelOf:
                                          (MissionConfirmationMethod value) =>
                                              value.label,
                                      onSelected:
                                          (MissionConfirmationMethod value) {
                                            setState(() {
                                              _confirmationMethod = value;
                                            });
                                          },
                                    ),
                                  ],
                                ),
                              ),
                              const _SectionDivider(),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: _contentHorizontalPadding,
                                ),
                                child: _RewardTimeRow(
                                  time: _rewardTime,
                                  onTap: _openRewardTimeSheet,
                                ),
                              ),
                              const _SectionDivider(),
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  _contentHorizontalPadding,
                                  0,
                                  _contentHorizontalPadding,
                                  24,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const _SectionTitle('상세설명'),
                                    const SizedBox(height: 18),
                                    _MissionDescriptionField(
                                      controller: _descriptionController,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 31),
                  child: TimeSetupActionButton(
                    label: '등록',
                    enabled: _canSubmit,
                    onTap: _submit,
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

class _MissionTitleField extends StatelessWidget {
  const _MissionTitleField({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 76,
      child: TextField(
        controller: controller,
        textAlign: TextAlign.center,
        cursorColor: AppColors.primary,
        style: AppTypography.heading1Bold.copyWith(
          fontSize: 24,
          height: 1.364,
          letterSpacing: 0,
          color: AppColors.gray800,
        ),
        decoration: InputDecoration(
          hintText: '미션 이름을 작성해주세요',
          hintStyle: AppTypography.heading2Bold.copyWith(
            fontSize: 18,
            height: 1.4,
            letterSpacing: 0,
            color: AppColors.gray300,
          ),
          contentPadding: EdgeInsets.zero,
          filled: true,
          fillColor: AppColors.white,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.gray200),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.primary),
          ),
        ),
      ),
    );
  }
}

class _EvenSelectionRow<T> extends StatelessWidget {
  const _EvenSelectionRow({
    required this.values,
    required this.selectedValue,
    required this.spacing,
    required this.labelOf,
    required this.onSelected,
  });

  final List<T> values;
  final T? selectedValue;
  final double spacing;
  final String Function(T value) labelOf;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (int index = 0; index < values.length; index++) ...[
          if (index > 0) SizedBox(width: spacing),
          Expanded(
            child: _OptionChip(
              label: labelOf(values[index]),
              selected: values[index] == selectedValue,
              onTap: () => onSelected(values[index]),
            ),
          ),
        ],
      ],
    );
  }
}

class _FixedSelectionRow<T> extends StatelessWidget {
  const _FixedSelectionRow({
    required this.values,
    required this.selectedValue,
    required this.widths,
    required this.spacing,
    required this.labelOf,
    required this.onSelected,
  });

  final List<T> values;
  final T? selectedValue;
  final List<double> widths;
  final double spacing;
  final String Function(T value) labelOf;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (int index = 0; index < values.length; index++) ...[
          if (index > 0) SizedBox(width: spacing),
          SizedBox(
            width: widths[index],
            child: _OptionChip(
              label: labelOf(values[index]),
              selected: values[index] == selectedValue,
              onTap: () => onSelected(values[index]),
            ),
          ),
        ],
      ],
    );
  }
}

class _OptionChip extends StatelessWidget {
  const _OptionChip({
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
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.gray050,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.gray200,
          ),
        ),
        child: Text(
          label,
          style: AppTypography.headlineMedium.copyWith(
            fontSize: 16,
            height: 1.445,
            letterSpacing: 0,
            color: selected ? AppColors.white : AppColors.gray600,
          ),
          maxLines: 1,
          overflow: TextOverflow.visible,
        ),
      ),
    );
  }
}

class _RewardTimeRow extends StatelessWidget {
  const _RewardTimeRow({required this.time, required this.onTap});

  final TimeSelection time;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color numberColor = time.isEmpty
        ? AppColors.gray300
        : AppColors.gray800;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const _SectionTitle('지급시간'),
        GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: Container(
            height: TimeSetupSize.fieldHeight,
            width: 192,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(TimeSetupRadius.field),
              border: Border.all(color: AppColors.gray200),
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
                const SizedBox(width: 8),
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
      ],
    );
  }
}

class _MissionDescriptionField extends StatelessWidget {
  const _MissionDescriptionField({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 214,
      child: TextField(
        controller: controller,
        inputFormatters: <TextInputFormatter>[
          LengthLimitingTextInputFormatter(50),
        ],
        maxLength: 50,
        maxLines: null,
        expands: true,
        textAlignVertical: TextAlignVertical.top,
        cursorColor: AppColors.primary,
        style: AppTypography.labelRegular.copyWith(
          fontSize: 16,
          height: 1.625,
          letterSpacing: 0,
          color: AppColors.gray700,
        ),
        decoration: InputDecoration(
          hintText:
              '설명을 자세히 적어주면 자녀도 헷갈리지 않고,\nAI 확인도 훨씬 쉬워져요.\n\n'
              '예: 쎈 중학수학 5장 1~20번 풀이하고 채점 완료하기, '
              '채점된 페이지 사진 1장 찍어서 올리기!',
          hintMaxLines: 6,
          counterText: '',
          hintStyle: AppTypography.labelRegular.copyWith(
            fontSize: 16,
            height: 1.625,
            letterSpacing: 0,
            color: AppColors.gray300,
          ),
          contentPadding: const EdgeInsets.fromLTRB(22, 22, 22, 22),
          filled: true,
          fillColor: AppColors.gray100,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: const BorderSide(color: AppColors.gray200),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: const BorderSide(color: AppColors.primary),
          ),
        ),
      ),
    );
  }
}

class _MissionRewardTimeSheet extends StatefulWidget {
  const _MissionRewardTimeSheet({required this.initialTime});

  final TimeSelection initialTime;

  @override
  State<_MissionRewardTimeSheet> createState() =>
      _MissionRewardTimeSheetState();
}

class _MissionRewardTimeSheetState extends State<_MissionRewardTimeSheet> {
  static const double _pickerGroupWidth = 102;
  static const double _pickerGroupGap = 28;
  static const double _pickerUnitGap = 8;

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
    return index < 0 ? 0 : index;
  }

  @override
  void initState() {
    super.initState();
    final TimeSelection initialTime = widget.initialTime.isEmpty
        ? const TimeSelection(hour: 1, minute: 5)
        : widget.initialTime;
    _selectedHourIndex = _initialIndexFor(_hours, initialTime.hour);
    _selectedMinuteIndex = _initialIndexFor(_minutes, initialTime.minute);
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
    final double bottomInset = MediaQuery.paddingOf(context).bottom;
    final double sheetHeight =
        MediaQuery.sizeOf(context).height * TimeSetupSize.timeSheetHeightRatio;

    return SafeArea(
      top: false,
      bottom: false,
      child: Container(
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
              child: Center(child: _RewardSheetLabel('지급시간')),
            ),
            Positioned(
              left: TimeSetupSpacing.sheetHorizontalPadding,
              right: TimeSetupSpacing.sheetHorizontalPadding,
              top: TimeSetupSpacing.pickerHighlightTop,
              height: 44.954,
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
              left: 0,
              right: 0,
              height: TimeSetupSize.pickerHeight,
              child: Center(
                child: SizedBox(
                  width: _pickerGroupWidth * 2 + _pickerGroupGap,
                  child: Row(
                    children: [
                      _MissionPickerGroup(
                        controller: _hourController,
                        values: _hours,
                        selectedIndex: _selectedHourIndex,
                        unit: '시간',
                        unitGap: _pickerUnitGap,
                        onSelectedItemChanged: (int index) {
                          setState(() {
                            _selectedHourIndex = index;
                          });
                        },
                      ),
                      const SizedBox(width: _pickerGroupGap),
                      _MissionPickerGroup(
                        controller: _minuteController,
                        values: _minutes,
                        selectedIndex: _selectedMinuteIndex,
                        unit: '분',
                        unitGap: _pickerUnitGap,
                        onSelectedItemChanged: (int index) {
                          setState(() {
                            _selectedMinuteIndex = index;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              left: TimeSetupSpacing.sheetHorizontalPadding,
              right: TimeSetupSpacing.sheetHorizontalPadding,
              bottom: TimeSetupSpacing.sheetButtonBottom + bottomInset,
              child: SheetConfirmButton(enabled: true, onTap: _confirm),
            ),
          ],
        ),
      ),
    );
  }
}

class _MissionPickerGroup extends StatelessWidget {
  const _MissionPickerGroup({
    required this.controller,
    required this.values,
    required this.selectedIndex,
    required this.unit,
    required this.unitGap,
    required this.onSelectedItemChanged,
  });

  final FixedExtentScrollController controller;
  final List<int> values;
  final int selectedIndex;
  final String unit;
  final double unitGap;
  final ValueChanged<int> onSelectedItemChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _MissionRewardTimeSheetState._pickerGroupWidth,
      child: Row(
        children: [
          PickerColumn(
            controller: controller,
            values: values,
            selectedIndex: selectedIndex,
            onSelectedItemChanged: onSelectedItemChanged,
          ),
          SizedBox(width: unitGap),
          IgnorePointer(
            child: SizedBox(
              height: TimeSetupSize.pickerHeight,
              child: Align(
                alignment: Alignment.center,
                child: _MissionPickerUnitLabel(unit),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MissionPickerUnitLabel extends StatelessWidget {
  const _MissionPickerUnitLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Baseline(
      baseline: 20,
      baselineType: TextBaseline.alphabetic,
      child: Text(
        text,
        style: AppTypography.headlineMedium.copyWith(
          fontSize: 18,
          height: 1.4,
          letterSpacing: 0,
          color: const Color(0xFF050505),
        ),
      ),
    );
  }
}

class _RewardSheetLabel extends StatelessWidget {
  const _RewardSheetLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(text, style: TimeSetupTextStyles.sheetLabel);
  }
}

class _SectionDivider extends StatelessWidget {
  const _SectionDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 6,
      margin: const EdgeInsets.symmetric(vertical: 26),
      color: const Color(0xFFEDEEF1),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: AppTypography.headlineBold.copyWith(
        fontSize: 16,
        height: 1.445,
        letterSpacing: 0,
        color: AppColors.gray800,
      ),
    );
  }
}
