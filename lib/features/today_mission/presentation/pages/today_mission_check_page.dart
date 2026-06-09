import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/models/result.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../data/repositories/mission_repository.dart';
import '../../../today_time/presentation/models/daily_time_rule.dart';
import '../../../today_time/presentation/styles/time_setup_tokens.dart';
import '../../../today_time/presentation/widgets/daily_time_rule_sheet.dart';
import '../models/today_mission.dart';
import '../widgets/mission_top_bar.dart';

class TodayMissionCheckArgs {
  const TodayMissionCheckArgs({
    required this.parentId,
    required this.childrenId,
    required this.index,
    required this.mission,
    this.initialTab = MissionCheckTab.info,
  });

  final String parentId;
  final String childrenId;
  final int index;
  final TodayMission mission;
  final MissionCheckTab initialTab;
}

enum MissionCheckTab { info, review }

class TodayMissionCheckPage extends StatefulWidget {
  const TodayMissionCheckPage({
    super.key,
    required this.parentId,
    required this.childrenId,
    required this.missionIndex,
    required this.initialMission,
    this.initialTab = MissionCheckTab.info,
  });

  final String? parentId;
  final String? childrenId;
  final int? missionIndex;
  final TodayMission? initialMission;
  final MissionCheckTab initialTab;

  @override
  State<TodayMissionCheckPage> createState() => _TodayMissionCheckPageState();
}

class _TodayMissionCheckPageState extends State<TodayMissionCheckPage> {
  static const double _horizontalPadding = 24;
  static const String _fallbackSubmittedAt = '2025.1.21 오후 7:01';

  final MissionRepository _missionRepository = createMissionRepository();
  late TodayMission? _mission = widget.initialMission;
  late int _selectedTabIndex = widget.initialTab.index;
  bool _isUpdatingVerification = false;

  void _handleBack() {
    final GoRouter router = GoRouter.of(context);
    if (router.canPop()) {
      router.pop();
      return;
    }
    router.go('/today-mission');
  }

  Future<void> _updateVerificationStatus(
    MissionVerificationStatus verificationStatus,
  ) async {
    if (_isUpdatingVerification) {
      return;
    }
    final TodayMission? mission = _mission;
    final int? missionIndex = widget.missionIndex;
    final String? parentId = widget.parentId;
    final String? childrenId = widget.childrenId;
    if (mission == null ||
        parentId == null ||
        parentId.isEmpty ||
        childrenId == null ||
        childrenId.isEmpty) {
      return;
    }

    setState(() {
      _isUpdatingVerification = true;
    });

    final TodayMission updatedMission = mission.copyWith(
      verificationStatus: verificationStatus,
      submittedAtText: mission.submittedAtText ?? _fallbackSubmittedAt,
    );
    late final Result<void> result;
    // Use dedicated approve/reject endpoints when the status transition is a
    // verdict; fall back to a generic updateAt for the in-progress states
    // (idle / waiting*).
    switch (verificationStatus) {
      case MissionVerificationStatus.approved:
        result = await _approveMission(
          parentId: parentId,
          childrenId: childrenId,
          mission: mission,
          missionIndex: missionIndex,
        );
      case MissionVerificationStatus.rejected:
        result = await _rejectMission(
          parentId: parentId,
          childrenId: childrenId,
          mission: mission,
          missionIndex: missionIndex,
        );
      case MissionVerificationStatus.idle:
      case MissionVerificationStatus.waitingParentApproval:
      case MissionVerificationStatus.waitingAiVerification:
        if (missionIndex == null) {
          result = Result<void>.failure(MissionFailureMessages.invalidState);
        } else {
          result = await _missionRepository.updateMissionAt(
            parentId: parentId,
            childrenId: childrenId,
            index: missionIndex,
            mission: updatedMission,
          );
        }
    }
    if (!mounted) {
      return;
    }

    switch (result) {
      case Success<void>():
        setState(() {
          _mission = updatedMission;
          _isUpdatingVerification = false;
        });
      case Failure<void>(:final message):
        setState(() {
          _isUpdatingVerification = false;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
        return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          verificationStatus == MissionVerificationStatus.approved
              ? '수행완료!'
              : '반려!',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final TodayMission? mission = _mission;
    final bool isInfoTab = _selectedTabIndex == 0;

    return Scaffold(
      backgroundColor: AppColors.gray100,
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 375),
            child: mission == null
                ? _MissingMissionView(onBack: _handleBack)
                : Column(
                    children: [
                      MissionTopBar(title: mission.title, onBack: _handleBack),
                      _MissionCheckTabs(
                        selectedIndex: _selectedTabIndex,
                        onSelected: (int index) {
                          setState(() {
                            _selectedTabIndex = index;
                          });
                        },
                      ),
                      Expanded(
                        child: isInfoTab
                            ? _MissionInfoContent(mission: mission)
                            : _MissionReviewContent(
                                mission: mission,
                                onReject: () => _updateVerificationStatus(
                                  MissionVerificationStatus.rejected,
                                ),
                                onApprove: () => _updateVerificationStatus(
                                  MissionVerificationStatus.approved,
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

  Future<Result<void>> _approveMission({
    required String parentId,
    required String childrenId,
    required TodayMission mission,
    required int? missionIndex,
  }) {
    final String? performanceId = mission.performanceId;
    if (performanceId != null && performanceId.isNotEmpty) {
      return _missionRepository.approveMissionPerformance(
        parentId: parentId,
        childrenId: childrenId,
        performanceId: performanceId,
      );
    }
    if (missionIndex == null) {
      return Future<Result<void>>.value(
        Result<void>.failure(MissionFailureMessages.invalidState),
      );
    }
    return _missionRepository.approveMissionAt(
      parentId: parentId,
      childrenId: childrenId,
      index: missionIndex,
    );
  }

  Future<Result<void>> _rejectMission({
    required String parentId,
    required String childrenId,
    required TodayMission mission,
    required int? missionIndex,
  }) {
    final String? performanceId = mission.performanceId;
    if (performanceId != null && performanceId.isNotEmpty) {
      return _missionRepository.rejectMissionPerformance(
        parentId: parentId,
        childrenId: childrenId,
        performanceId: performanceId,
      );
    }
    if (missionIndex == null) {
      return Future<Result<void>>.value(
        Result<void>.failure(MissionFailureMessages.invalidState),
      );
    }
    return _missionRepository.rejectMissionAt(
      parentId: parentId,
      childrenId: childrenId,
      index: missionIndex,
    );
  }
}

class _MissingMissionView extends StatelessWidget {
  const _MissingMissionView({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        MissionTopBar(title: '미션 확인', onBack: onBack),
        Expanded(
          child: Center(
            child: Text(
              '미션을 찾을 수 없습니다.',
              style: AppTypography.bodyMedium.copyWith(
                fontSize: 16,
                height: 1.5,
                letterSpacing: 0,
                color: AppColors.gray300,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _MissionCheckTabs extends StatelessWidget {
  const _MissionCheckTabs({
    required this.selectedIndex,
    required this.onSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 190,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _MissionCheckTab(
              label: '미션정보',
              selected: selectedIndex == 0,
              onTap: () => onSelected(0),
            ),
            _MissionCheckTab(
              label: '수행확인',
              selected: selectedIndex == 1,
              onTap: () => onSelected(1),
            ),
          ],
        ),
      ),
    );
  }
}

class _MissionCheckTab extends StatelessWidget {
  const _MissionCheckTab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color feedbackColor = selected ? AppColors.black : AppColors.gray400;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(6),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        hoverColor: feedbackColor.withValues(alpha: 0.06),
        highlightColor: feedbackColor.withValues(alpha: 0.10),
        splashColor: feedbackColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 7.193,
            vertical: 5.394,
          ),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: selected ? AppColors.black : Colors.transparent,
                width: 1.259,
              ),
            ),
          ),
          child: Text(
            label,
            style: AppTypography.labelMedium.copyWith(
              fontSize: 14.385,
              height: 1.5,
              letterSpacing: 0.082,
              color: selected ? AppColors.black : AppColors.gray400,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

class _MissionInfoContent extends StatelessWidget {
  const _MissionInfoContent({required this.mission});

  static const double _contentHorizontalPadding = 24;

  final TodayMission mission;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints viewport) {
        return SingleChildScrollView(
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _SectionTitle('카테고리'),
                      const SizedBox(height: 18),
                      _ReadOnlyEvenSelectionRow<MissionCategory>(
                        values: MissionCategory.values,
                        selectedValue: mission.category,
                        spacing: 8,
                        labelOf: (MissionCategory value) => value.label,
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
                      _ReadOnlyFixedSelectionRow<MissionResetPeriod>(
                        values: MissionResetPeriod.values,
                        selectedValue: mission.resetPeriod,
                        widths: const <double>[74, 88, 74],
                        spacing: 14,
                        labelOf: (MissionResetPeriod value) => value.label,
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
                      _ReadOnlyEvenSelectionRow<MissionConfirmationMethod>(
                        values: MissionConfirmationMethod.values,
                        selectedValue: mission.confirmationMethod,
                        spacing: 14,
                        labelOf: (MissionConfirmationMethod value) =>
                            value.label,
                      ),
                    ],
                  ),
                ),
                const _SectionDivider(),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: _contentHorizontalPadding,
                  ),
                  child: _ReadOnlyRewardTimeRow(minutes: mission.rewardMinutes),
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
                      _ReadOnlyMissionDescriptionField(
                        description: mission.description,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ReadOnlyEvenSelectionRow<T> extends StatelessWidget {
  const _ReadOnlyEvenSelectionRow({
    required this.values,
    required this.selectedValue,
    required this.spacing,
    required this.labelOf,
  });

  final List<T> values;
  final T selectedValue;
  final double spacing;
  final String Function(T value) labelOf;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (int index = 0; index < values.length; index++) ...[
          if (index > 0) SizedBox(width: spacing),
          Expanded(
            child: _ReadOnlyOptionChip(
              label: labelOf(values[index]),
              selected: values[index] == selectedValue,
            ),
          ),
        ],
      ],
    );
  }
}

class _ReadOnlyFixedSelectionRow<T> extends StatelessWidget {
  const _ReadOnlyFixedSelectionRow({
    required this.values,
    required this.selectedValue,
    required this.widths,
    required this.spacing,
    required this.labelOf,
  });

  final List<T> values;
  final T selectedValue;
  final List<double> widths;
  final double spacing;
  final String Function(T value) labelOf;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (int index = 0; index < values.length; index++) ...[
          if (index > 0) SizedBox(width: spacing),
          SizedBox(
            width: widths[index],
            child: _ReadOnlyOptionChip(
              label: labelOf(values[index]),
              selected: values[index] == selectedValue,
            ),
          ),
        ],
      ],
    );
  }
}

class _ReadOnlyOptionChip extends StatelessWidget {
  const _ReadOnlyOptionChip({required this.label, required this.selected});

  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
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
    );
  }
}

class _ReadOnlyRewardTimeRow extends StatelessWidget {
  const _ReadOnlyRewardTimeRow({required this.minutes});

  final int minutes;

  @override
  Widget build(BuildContext context) {
    final TimeSelection time = TimeSelection(
      hour: minutes ~/ 60,
      minute: minutes % 60,
    );
    final Color numberColor = time.isEmpty
        ? AppColors.gray300
        : AppColors.gray800;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const _SectionTitle('지급시간'),
        Container(
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
      ],
    );
  }
}

class _ReadOnlyMissionDescriptionField extends StatelessWidget {
  const _ReadOnlyMissionDescriptionField({required this.description});

  final String description;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 214,
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 22),
      alignment: Alignment.topLeft,
      decoration: BoxDecoration(
        color: AppColors.gray100,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.gray200),
      ),
      child: Text(
        description,
        style: AppTypography.labelRegular.copyWith(
          fontSize: 16,
          height: 1.625,
          letterSpacing: 0,
          color: AppColors.gray700,
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

class _MissionReviewContent extends StatelessWidget {
  const _MissionReviewContent({
    required this.mission,
    required this.onReject,
    required this.onApprove,
  });

  final TodayMission mission;
  final VoidCallback onReject;
  final VoidCallback onApprove;

  @override
  Widget build(BuildContext context) {
    final MissionVerificationType verificationType = mission.verificationType;
    final MissionVerificationStatus verificationStatus =
        mission.effectiveVerificationStatus;

    if (verificationStatus == MissionVerificationStatus.idle) {
      return Center(
        child: Text(
          '미션이 아직 수행되지 않았어요.',
          textAlign: TextAlign.center,
          style: AppTypography.headlineMedium.copyWith(
            fontSize: 16.183,
            height: 1.445,
            letterSpacing: -0.0032,
            color: AppColors.gray300,
          ),
        ),
      );
    }

    final bool showApproveButton =
        verificationType == MissionVerificationType.parent &&
        verificationStatus == MissionVerificationStatus.waitingParentApproval;
    final bool showRejectButton =
        verificationStatus == MissionVerificationStatus.waitingParentApproval ||
        (verificationStatus == MissionVerificationStatus.approved &&
            verificationType != MissionVerificationType.parent);
    final bool showActionButtons = showApproveButton || showRejectButton;
    final bool showAiLoading =
        verificationStatus == MissionVerificationStatus.waitingAiVerification;
    final String title = switch (verificationStatus) {
      MissionVerificationStatus.waitingParentApproval => '부모 확인 대기중',
      MissionVerificationStatus.waitingAiVerification => 'AI 확인 대기중입니다.',
      MissionVerificationStatus.approved => '미션 수행완료!',
      MissionVerificationStatus.rejected => '미션 수행 반려!',
      MissionVerificationStatus.idle => '',
    };
    final String message = switch (verificationStatus) {
      MissionVerificationStatus.waitingParentApproval =>
        '부모가 확인하면 보상 시간이 지급돼요.',
      MissionVerificationStatus.waitingAiVerification =>
        'AI가 사진을 확인하고 있어요.\n확인 전에는 시간이 지급되지 않아요.',
      MissionVerificationStatus.approved =>
        verificationType == MissionVerificationType.parent
            ? '부모 승인이 완료되어 보상 시간이 지급되었습니다.'
            : '보상 시간이 지급되었습니다.\n필요하면 사후 반려할 수 있어요.',
      MissionVerificationStatus.rejected =>
        verificationType == MissionVerificationType.parent
            ? '반려가 완료되었습니다.\n보상 시간은 지급되지 않았어요.'
            : '반려가 완료되었습니다.\n지급된 시간은 회수 대상입니다.',
      MissionVerificationStatus.idle => '',
    };
    final String submittedAt =
        mission.submittedAtText ??
        _TodayMissionCheckPageState._fallbackSubmittedAt;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              _TodayMissionCheckPageState._horizontalPadding,
              42,
              _TodayMissionCheckPageState._horizontalPadding,
              showActionButtons ? 24 : 32,
            ),
            child: Column(
              children: [
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: AppTypography.headlineBold.copyWith(
                    fontSize: 18,
                    height: 1.4,
                    letterSpacing: -0.2158,
                    color: const Color(0xFF050505),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: AppTypography.bodyMedium.copyWith(
                    fontSize: 14,
                    height: 1.5,
                    letterSpacing: 0,
                    color: AppColors.gray500,
                  ),
                ),
                if (showAiLoading) ...[
                  const SizedBox(height: 18),
                  const SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      color: AppColors.primary,
                    ),
                  ),
                ],
                const SizedBox(height: 36),
                _ProofPhotoGrid(proofImageUrl: mission.proofImageUrl),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '$submittedAt 수행 제출\n$submittedAt 확인 요청',
                    style: AppTypography.captionMedium.copyWith(
                      fontSize: 10.789,
                      height: 1.334,
                      letterSpacing: 0.2719,
                      color: AppColors.gray300,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (showActionButtons)
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 31),
            child: Row(
              children: [
                if (showRejectButton)
                  Expanded(
                    child: _ReviewActionButton(
                      label: '반려',
                      filled: false,
                      onTap: onReject,
                    ),
                  ),
                if (showRejectButton && showApproveButton)
                  const SizedBox(width: 12),
                if (showApproveButton)
                  Expanded(
                    child: _ReviewActionButton(
                      label: '승인',
                      filled: true,
                      onTap: onApprove,
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

class _ProofPhotoGrid extends StatelessWidget {
  const _ProofPhotoGrid({this.proofImageUrl});

  final String? proofImageUrl;

  @override
  Widget build(BuildContext context) {
    final String? imageUrl = proofImageUrl;
    return Wrap(
      spacing: 10.789,
      runSpacing: 10.789,
      children: [
        if (imageUrl != null && imageUrl.isNotEmpty)
          _ProofPhotoImage(imageUrl: imageUrl)
        else
          const _ProofPhotoPlaceholder(),
        const _ProofPhotoPlaceholder(),
        const _ProofPhotoPlaceholder(),
        const _ProofPhotoPlaceholder(),
      ],
    );
  }
}

class _ProofPhotoImage extends StatelessWidget {
  const _ProofPhotoImage({required this.imageUrl});

  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(7.193),
      child: Image.network(
        imageUrl,
        width: 141.155,
        height: 140.256,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) =>
            const _ProofPhotoPlaceholder(),
      ),
    );
  }
}

class _ProofPhotoPlaceholder extends StatelessWidget {
  const _ProofPhotoPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 141.155,
      height: 140.256,
      decoration: BoxDecoration(
        color: AppColors.gray200,
        borderRadius: BorderRadius.circular(7.193),
      ),
    );
  }
}

class _ReviewActionButton extends StatelessWidget {
  const _ReviewActionButton({
    required this.label,
    required this.filled,
    required this.onTap,
  });

  final String label;
  final bool filled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 54,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: filled ? AppColors.primary : AppColors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: filled ? AppColors.primary : AppColors.destructive,
          ),
        ),
        child: Text(
          label,
          style: AppTypography.headlineMedium.copyWith(
            fontSize: 18,
            height: 1.445,
            letterSpacing: 0,
            color: filled ? AppColors.white : AppColors.destructive,
          ),
        ),
      ),
    );
  }
}
