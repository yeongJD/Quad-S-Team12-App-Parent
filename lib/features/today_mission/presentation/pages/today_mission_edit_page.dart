import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../data/today_mission_mock_data.dart';
import '../models/today_mission.dart';
import '../widgets/mission_top_bar.dart';

class TodayMissionEditPage extends StatefulWidget {
  const TodayMissionEditPage({super.key, this.initialMission});

  final TodayMission? initialMission;

  @override
  State<TodayMissionEditPage> createState() => _TodayMissionEditPageState();
}

class _TodayMissionEditPageState extends State<TodayMissionEditPage> {
  late final TodayMission _mission =
      widget.initialMission ?? TodayMissionMockData.roomCleaning;

  late MissionCategory _category = MissionCategory.routine;
  late MissionResetPeriod _resetPeriod = _mission.resetPeriod;
  late MissionConfirmationMethod _confirmationMethod =
      _mission.confirmationMethod;

  void _handleBack() {
    final GoRouter router = GoRouter.of(context);
    if (router.canPop()) {
      router.pop();
      return;
    }
    router.go('/today-mission');
  }

  void _complete() {
    _handleBack();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 375),
            child: Stack(
              children: [
                Column(
                  children: [
                    MissionTopBar(title: '', onBack: _handleBack),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(24, 14, 24, 129),
                        child: Column(
                          children: [
                            _TitleField(title: _mission.title),
                            const SizedBox(height: 35.963),
                            _SelectionSection<MissionCategory>(
                              title: '미션',
                              values: MissionCategory.values,
                              selectedValue: _category,
                              labelOf: (MissionCategory value) => value.label,
                              onSelected: (MissionCategory value) {
                                setState(() {
                                  _category = value;
                                });
                              },
                            ),
                            const _SectionDivider(),
                            _SelectionSection<MissionResetPeriod>(
                              title: '미션 리셋 주기',
                              values: MissionResetPeriod.values,
                              selectedValue: _resetPeriod,
                              labelOf: (MissionResetPeriod value) =>
                                  value.label,
                              onSelected: (MissionResetPeriod value) {
                                setState(() {
                                  _resetPeriod = value;
                                });
                              },
                            ),
                            const _SectionDivider(),
                            _SelectionSection<MissionConfirmationMethod>(
                              title: '확인방식',
                              values: MissionConfirmationMethod.values,
                              selectedValue: _confirmationMethod,
                              labelOf: (MissionConfirmationMethod value) =>
                                  value.label,
                              onSelected: (MissionConfirmationMethod value) {
                                setState(() {
                                  _confirmationMethod = value;
                                });
                              },
                            ),
                            const _SectionDivider(),
                            _RewardTimeRow(minutes: _mission.rewardMinutes),
                            const _SectionDivider(),
                            _DescriptionSection(
                              description: _mission.description,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                Positioned(
                  left: 24,
                  right: 24,
                  bottom: 56.64,
                  child: GestureDetector(
                    onTap: _complete,
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      height: 48.55,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '수정완료',
                        style: AppTypography.headlineMedium.copyWith(
                          fontSize: 16.183,
                          height: 1.445,
                          letterSpacing: -0.0032,
                          color: AppColors.white,
                        ),
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

class _TitleField extends StatelessWidget {
  const _TitleField({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 62.935,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(7.193),
        border: Border.all(color: AppColors.gray600, width: 0.899),
      ),
      child: Text(
        title,
        style: AppTypography.heading2Bold.copyWith(
          fontSize: 21.578,
          height: 1.364,
          letterSpacing: -0.4186,
          color: const Color(0xFF050505),
        ),
      ),
    );
  }
}

class _SelectionSection<T> extends StatelessWidget {
  const _SelectionSection({
    required this.title,
    required this.values,
    required this.selectedValue,
    required this.labelOf,
    required this.onSelected,
  });

  final String title;
  final List<T> values;
  final T selectedValue;
  final String Function(T value) labelOf;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(title),
          const SizedBox(height: 12.587),
          Wrap(
            spacing: 7.193,
            runSpacing: 7.193,
            children: [
              for (final T value in values)
                _OptionChip(
                  label: labelOf(value),
                  selected: value == selectedValue,
                  onTap: () => onSelected(value),
                ),
            ],
          ),
        ],
      ),
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
    final bool wide = label.length >= 4;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 46.752,
        constraints: BoxConstraints(minWidth: wide ? 66.532 : 52.146),
        padding: EdgeInsets.symmetric(horizontal: wide ? 12 : 10.789),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.gray100,
          borderRadius: BorderRadius.circular(10.789),
          border: selected
              ? null
              : Border.all(color: AppColors.gray200, width: 0.899),
        ),
        child: Text(
          label,
          style: AppTypography.labelMedium.copyWith(
            fontSize: 14.385,
            height: 1.5,
            letterSpacing: 0.082,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            color: selected ? AppColors.white : AppColors.gray600,
          ),
        ),
      ),
    );
  }
}

class _SectionDivider extends StatelessWidget {
  const _SectionDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 6.294,
      margin: const EdgeInsets.symmetric(vertical: 21.578),
      color: AppColors.gray100,
    );
  }
}

class _RewardTimeRow extends StatelessWidget {
  const _RewardTimeRow({required this.minutes});

  final int minutes;

  @override
  Widget build(BuildContext context) {
    final int hours = minutes ~/ 60;
    final int remainderMinutes = minutes % 60;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const _SectionTitle('지급 시간'),
        Container(
          height: 46.752,
          padding: const EdgeInsets.symmetric(horizontal: 17.982),
          decoration: BoxDecoration(
            color: AppColors.gray050,
            borderRadius: BorderRadius.circular(7.193),
            border: Border.all(color: AppColors.gray200, width: 0.899),
          ),
          child: Row(
            children: [
              _TimeText(value: hours.toString().padLeft(2, '0'), unit: '시간'),
              const SizedBox(width: 14.385),
              _TimeText(
                value: remainderMinutes.toString().padLeft(2, '0'),
                unit: '분',
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TimeText extends StatelessWidget {
  const _TimeText({required this.value, required this.unit});

  final String value;
  final String unit;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          value,
          style: AppTypography.headlineBold.copyWith(
            fontSize: 16.183,
            height: 1.445,
            letterSpacing: -0.0032,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: 3.596),
        Text(
          unit,
          style: AppTypography.headlineMedium.copyWith(
            fontSize: 16.183,
            height: 1.445,
            letterSpacing: -0.0032,
            color: const Color(0xFF050505),
          ),
        ),
      ],
    );
  }
}

class _DescriptionSection extends StatelessWidget {
  const _DescriptionSection({required this.description});

  final String description;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle('상세설명'),
          const SizedBox(height: 12.587),
          Container(
            width: double.infinity,
            height: 178.017,
            padding: const EdgeInsets.fromLTRB(12.587, 10.789, 12.587, 10.789),
            decoration: BoxDecoration(
              color: AppColors.gray050,
              borderRadius: BorderRadius.circular(10.789),
              border: Border.all(color: AppColors.gray200, width: 0.899),
            ),
            child: Text(
              description,
              style: AppTypography.labelRegular.copyWith(
                fontSize: 14.385,
                height: 1.5,
                letterSpacing: 0.082,
                color: const Color(0xFF050505),
              ),
            ),
          ),
        ],
      ),
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
        fontSize: 16.183,
        height: 1.445,
        letterSpacing: -0.0032,
        color: AppColors.gray800,
      ),
    );
  }
}
