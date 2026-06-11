import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/models/result.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../data/repositories/mission_repository.dart';
import '../data/today_mission_mock_data.dart';
import '../models/today_mission.dart';
import '../widgets/mission_top_bar.dart';
import 'today_mission_check_page.dart';
import 'today_mission_edit_page.dart';

class TodayMissionListPage extends StatefulWidget {
  const TodayMissionListPage({
    super.key,
    this.parentId,
    this.childrenId,
    this.demo,
    this.initialMissionId,
    this.initialPerformanceId,
    this.initialMissionIndex,
    this.initialTab = MissionCheckTab.info,
    this.missionRepository,
  });

  final String? parentId;
  final String? childrenId;
  final String? demo;
  final String? initialMissionId;
  final String? initialPerformanceId;
  final int? initialMissionIndex;
  final MissionCheckTab initialTab;
  final MissionRepository? missionRepository;

  @override
  State<TodayMissionListPage> createState() => _TodayMissionListPageState();
}

class _TodayMissionListPageState extends State<TodayMissionListPage> {
  late final MissionRepository _missionRepository;

  List<TodayMission> _missions = <TodayMission>[];
  bool _isLoading = true;
  bool _didOpenInitialMission = false;
  late bool _showDeleteDialog = widget.demo == 'dialog';
  int? _pendingDeleteIndex;

  bool get _usesDemo => widget.demo != null;

  @override
  void initState() {
    super.initState();
    _missionRepository = widget.missionRepository ?? createMissionRepository();
    _loadMissions();
  }

  Future<void> _loadMissions() async {
    final List<TodayMission> missions = _usesDemo
        ? TodayMissionMockData.missionsForDemo(widget.demo)
        : await _loadStoredMissions();
    if (!mounted) {
      return;
    }
    setState(() {
      _missions = missions;
      _isLoading = false;
    });
    _openInitialMissionIfNeeded(missions);
  }

  void _handleBack() {
    final GoRouter router = GoRouter.of(context);
    if (router.canPop()) {
      router.pop();
      return;
    }
    router.go('/parent-home');
  }

  Future<void> _openAdd() async {
    await context.push(_missionSetupLocation);
    if (!_usesDemo) {
      await _loadMissions();
    }
  }

  Future<void> _openEdit(int index) async {
    if (index < 0 || index >= _missions.length) {
      return;
    }
    await context.push(
      _missionSetupLocation,
      extra: TodayMissionEditArgs(
        parentId: widget.parentId ?? '',
        childrenId: widget.childrenId ?? '',
        index: index,
        mission: _missions[index],
      ),
    );
    if (!_usesDemo) {
      await _loadMissions();
    }
  }

  Future<void> _openCheck(int index, MissionCheckTab tab) async {
    if (index < 0 || index >= _missions.length) {
      return;
    }
    await context.push(
      '/today-mission/check',
      extra: TodayMissionCheckArgs(
        parentId: widget.parentId ?? '',
        childrenId: widget.childrenId ?? '',
        index: index,
        mission: _missions[index],
        initialTab: tab,
      ),
    );
    if (!_usesDemo) {
      await _loadMissions();
    }
  }

  void _requestDelete(int index) {
    setState(() {
      _showDeleteDialog = true;
      _pendingDeleteIndex = index;
    });
  }

  void _cancelDelete() {
    setState(() {
      _showDeleteDialog = false;
      _pendingDeleteIndex = null;
    });
  }

  Future<void> _confirmDelete() async {
    final int? deleteIndex = _pendingDeleteIndex;
    if (deleteIndex == null ||
        deleteIndex < 0 ||
        deleteIndex >= _missions.length) {
      _cancelDelete();
      return;
    }

    if (!_usesDemo) {
      final String? parentId = widget.parentId;
      final String? childrenId = widget.childrenId;
      if (parentId != null &&
          parentId.isNotEmpty &&
          childrenId != null &&
          childrenId.isNotEmpty) {
        final Result<void> result = await _missionRepository.removeMissionAt(
          parentId: parentId,
          childrenId: childrenId,
          index: deleteIndex,
        );
        if (!mounted) {
          return;
        }
        switch (result) {
          case Success<void>():
            break;
          case Failure<void>(:final String message):
            setState(() {
              _showDeleteDialog = false;
              _pendingDeleteIndex = null;
            });
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(message)));
            return;
        }
      }
    }
    if (!mounted) {
      return;
    }
    setState(() {
      _missions.removeAt(deleteIndex);
      _showDeleteDialog = false;
      _pendingDeleteIndex = null;
    });
  }

  Future<List<TodayMission>> _loadStoredMissions() async {
    final String? parentId = widget.parentId;
    final String? childrenId = widget.childrenId;
    if (parentId == null ||
        parentId.isEmpty ||
        childrenId == null ||
        childrenId.isEmpty) {
      return <TodayMission>[];
    }
    final Result<List<TodayMission>> result = await _missionRepository
        .loadMissions(parentId: parentId, childrenId: childrenId);
    return switch (result) {
      Success<List<TodayMission>>(:final data) => data,
      Failure<List<TodayMission>>() => const <TodayMission>[],
    };
  }

  void _openInitialMissionIfNeeded(List<TodayMission> missions) {
    if (_didOpenInitialMission || missions.isEmpty) {
      return;
    }
    final int? index = _initialMissionIndexFor(missions);
    if (index == null) {
      return;
    }
    _didOpenInitialMission = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      unawaited(_openCheck(index, widget.initialTab));
    });
  }

  int? _initialMissionIndexFor(List<TodayMission> missions) {
    final String? missionId = widget.initialMissionId;
    if (missionId != null && missionId.isNotEmpty) {
      final int index = missions.indexWhere(
        (TodayMission mission) => mission.missionId == missionId,
      );
      if (index >= 0) {
        return index;
      }
    }

    final String? performanceId = widget.initialPerformanceId;
    if (performanceId != null && performanceId.isNotEmpty) {
      final int index = missions.indexWhere(
        (TodayMission mission) => mission.performanceId == performanceId,
      );
      if (index >= 0) {
        return index;
      }
    }

    final int? missionIndex = widget.initialMissionIndex;
    if (missionIndex != null &&
        missionIndex >= 0 &&
        missionIndex < missions.length) {
      return missionIndex;
    }
    return null;
  }

  String get _missionSetupLocation {
    final String? parentId = widget.parentId;
    final String? childrenId = widget.childrenId;
    return Uri(
      path: '/today-mission/setup',
      queryParameters: <String, String>{
        if (parentId != null && parentId.isNotEmpty) 'parentId': parentId,
        if (childrenId != null && childrenId.isNotEmpty)
          'childrenId': childrenId,
      },
    ).toString();
  }

  @override
  Widget build(BuildContext context) {
    final bool isEmpty = _missions.isEmpty;

    return Scaffold(
      backgroundColor: AppColors.gray100,
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 375),
            child: Stack(
              children: [
                Column(
                  children: [
                    MissionTopBar(onBack: _handleBack),
                    Expanded(
                      child: _isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : isEmpty
                          ? const _MissionEmptyState()
                          : _MissionListContent(
                              missions: _missions,
                              onEdit: _openEdit,
                              onOpenInfo: (int index) =>
                                  _openCheck(index, MissionCheckTab.info),
                              onOpenReview: (int index) =>
                                  _openCheck(index, MissionCheckTab.review),
                              onDelete: _requestDelete,
                              onAdd: _openAdd,
                            ),
                    ),
                  ],
                ),
                if (_showDeleteDialog)
                  _DeleteConfirmationOverlay(
                    onCancel: _cancelDelete,
                    onConfirm: _confirmDelete,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MissionEmptyState extends StatelessWidget {
  const _MissionEmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        '등록된 미션이 없습니다.',
        style: AppTypography.bodyMedium.copyWith(color: AppColors.gray300),
      ),
    );
  }
}

class _MissionListContent extends StatelessWidget {
  const _MissionListContent({
    required this.missions,
    required this.onEdit,
    required this.onOpenInfo,
    required this.onOpenReview,
    required this.onDelete,
    required this.onAdd,
  });

  final List<TodayMission> missions;
  final ValueChanged<int> onEdit;
  final ValueChanged<int> onOpenInfo;
  final ValueChanged<int> onOpenReview;
  final ValueChanged<int> onDelete;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 48),
      child: Column(
        children: [
          for (int index = 0; index < missions.length; index++) ...[
            _MissionListCard(
              mission: missions[index],
              index: index,
              onEdit: () => onEdit(index),
              onOpenInfo: () => onOpenInfo(index),
              onOpenReview: () => onOpenReview(index),
              onDeleteRequested: onDelete,
            ),
            if (index != missions.length - 1) const SizedBox(height: 14),
          ],
          const SizedBox(height: 18),
          _MissionAddButton(onTap: onAdd),
        ],
      ),
    );
  }
}

class _MissionListCard extends StatelessWidget {
  const _MissionListCard({
    required this.mission,
    required this.index,
    required this.onEdit,
    required this.onOpenInfo,
    required this.onOpenReview,
    required this.onDeleteRequested,
  });

  final TodayMission mission;
  final int index;
  final VoidCallback onEdit;
  final VoidCallback onOpenInfo;
  final VoidCallback onOpenReview;
  final ValueChanged<int> onDeleteRequested;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppTokens.cardRadiusSmall),
      child: Dismissible(
        key: ValueKey<String>(
          'mission-${mission.title}-${mission.category.name}-$index',
        ),
        direction: DismissDirection.endToStart,
        confirmDismiss: (DismissDirection direction) async {
          onDeleteRequested(index);
          return false;
        },
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          color: AppColors.destructiveSubtle,
          child: const _DeleteActionButton(),
        ),
        child: _MissionCardSurface(
          mission: mission,
          onEdit: onEdit,
          onOpenInfo: onOpenInfo,
          onOpenReview: onOpenReview,
        ),
      ),
    );
  }
}

class _MissionStatusBadge extends StatelessWidget {
  const _MissionStatusBadge({required this.status, required this.onTap});

  final TodayMissionStatus status;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color backgroundColor;
    final Color textColor;
    switch (status) {
      case TodayMissionStatus.pending:
        backgroundColor = AppColors.gray100;
        textColor = AppColors.gray500;
      case TodayMissionStatus.reviewing:
        backgroundColor = const Color(0xFFFFF5D6);
        textColor = AppColors.cautionary;
      case TodayMissionStatus.completed:
        backgroundColor = const Color(0xFFE9F8EF);
        textColor = AppColors.positive;
      case TodayMissionStatus.rejected:
        backgroundColor = AppColors.destructiveSubtle;
        textColor = AppColors.destructive;
    }

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 24,
        padding: const EdgeInsets.symmetric(horizontal: 9),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(AppTokens.dialogRadius),
        ),
        child: Text(
          status.label,
          style: AppTypography.captionBold.copyWith(color: textColor),
        ),
      ),
    );
  }
}

class _MissionCardSurface extends StatelessWidget {
  const _MissionCardSurface({
    required this.mission,
    required this.onEdit,
    required this.onOpenInfo,
    required this.onOpenReview,
  });

  final TodayMission mission;
  final VoidCallback onEdit;
  final VoidCallback onOpenInfo;
  final VoidCallback onOpenReview;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 76,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppTokens.cardRadiusSmall),
      ),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: SvgPicture.asset(
              mission.category.iconAsset,
              width: 43,
              height: 43,
            ),
          ),
          const SizedBox(width: 17),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: onOpenInfo,
                  behavior: HitTestBehavior.opaque,
                  child: Text(
                    mission.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.bodySemiBold.copyWith(
                      color: AppColors.inkBlack,
                    ),
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        mission.rewardLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.captionRegular.copyWith(
                          color: AppColors.gray500,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _MissionStatusBadge(
                      status: mission.effectiveStatus,
                      onTap: onOpenReview,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          _MissionSettingsButton(onTap: onEdit),
        ],
      ),
    );
  }
}

class _MissionSettingsButton extends StatelessWidget {
  const _MissionSettingsButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        hoverColor: AppColors.gray300.withValues(alpha: 0.08),
        highlightColor: AppColors.gray300.withValues(alpha: 0.12),
        splashColor: AppColors.gray300.withValues(alpha: 0.16),
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 28,
          height: 28,
          child: Center(
            child: SvgPicture.asset(
              'assets/icons/arrow button/Settings.svg',
              width: 18,
              height: 18,
              colorFilter: const ColorFilter.mode(
                AppColors.gray300,
                BlendMode.srcIn,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DeleteActionButton extends StatelessWidget {
  const _DeleteActionButton();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      decoration: const BoxDecoration(
        color: AppColors.destructive,
        shape: BoxShape.circle,
      ),
      child: const Icon(Icons.close_rounded, size: 17, color: AppColors.white),
    );
  }
}

class _MissionAddButton extends StatelessWidget {
  const _MissionAddButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.primaryLight,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        hoverColor: AppColors.primary.withValues(alpha: 0.08),
        highlightColor: AppColors.primary.withValues(alpha: 0.12),
        splashColor: AppColors.primary.withValues(alpha: 0.16),
        customBorder: const CircleBorder(),
        child: const SizedBox(
          width: 36,
          height: 36,
          child: Icon(Icons.add_rounded, size: 28, color: AppColors.primary),
        ),
      ),
    );
  }
}

class _DeleteConfirmationOverlay extends StatelessWidget {
  const _DeleteConfirmationOverlay({
    required this.onCancel,
    required this.onConfirm,
  });

  final VoidCallback onCancel;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Container(
        color: const Color.fromRGBO(68, 68, 68, 0.6),
        child: Center(
          child: Container(
            width: 295,
            height: 190,
            padding: const EdgeInsets.fromLTRB(31, 33, 31, 27),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(AppTokens.dialogRadius),
            ),
            child: Column(
              children: [
                const _WarningIcon(),
                const SizedBox(height: 16),
                Text(
                  '미션을 삭제하시겠습니까?',
                  textAlign: TextAlign.center,
                  style: AppTypography.labelSemiBold.copyWith(
                    color: AppColors.gray800,
                  ),
                ),
                const Spacer(),
                Row(
                  children: [
                    Expanded(
                      child: _DialogActionButton(
                        label: '취소',
                        filled: false,
                        onTap: onCancel,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: _DialogActionButton(
                        label: '확인',
                        filled: true,
                        onTap: onConfirm,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _WarningIcon extends StatelessWidget {
  const _WarningIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 29,
      height: 29,
      decoration: const BoxDecoration(
        color: AppColors.destructive,
        shape: BoxShape.circle,
      ),
      child: const Icon(Icons.priority_high_rounded, color: AppColors.white),
    );
  }
}

class _DialogActionButton extends StatelessWidget {
  const _DialogActionButton({
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
        height: 38,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: filled ? AppColors.primary : AppColors.primaryLight,
          borderRadius: BorderRadius.circular(AppTokens.buttonRadius),
          border: filled ? null : Border.all(color: AppColors.primary),
        ),
        child: Text(
          label,
          style: AppTypography.captionMedium.copyWith(
            color: filled ? AppColors.white : AppColors.primary,
          ),
        ),
      ),
    );
  }
}
