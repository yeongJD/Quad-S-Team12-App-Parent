import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../data/today_mission_mock_data.dart';
import '../models/today_mission.dart';
import '../widgets/mission_top_bar.dart';

class TodayMissionListPage extends StatefulWidget {
  const TodayMissionListPage({super.key, this.demo});

  final String? demo;

  @override
  State<TodayMissionListPage> createState() => _TodayMissionListPageState();
}

class _TodayMissionListPageState extends State<TodayMissionListPage> {
  late final List<TodayMission> _missions = <TodayMission>[
    ...TodayMissionMockData.missionsForDemo(widget.demo),
  ];
  late bool _showDeleteAction = widget.demo == 'delete';
  late bool _showDeleteDialog = widget.demo == 'dialog';

  void _handleBack() {
    final GoRouter router = GoRouter.of(context);
    if (router.canPop()) {
      router.pop();
      return;
    }
    router.go('/parent-home');
  }

  void _openEdit() {
    context.push('/today-mission/setup');
  }

  void _requestDelete() {
    setState(() {
      _showDeleteAction = true;
      _showDeleteDialog = true;
    });
  }

  void _cancelDelete() {
    setState(() {
      _showDeleteDialog = false;
    });
  }

  void _confirmDelete() {
    setState(() {
      if (_missions.isNotEmpty) {
        _missions.removeAt(0);
      }
      _showDeleteAction = false;
      _showDeleteDialog = false;
    });
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
                      child: isEmpty
                          ? const _MissionEmptyState()
                          : _MissionListContent(
                              missions: _missions,
                              showDeleteAction: _showDeleteAction,
                              onEdit: _openEdit,
                              onDelete: _requestDelete,
                              onAdd: _openEdit,
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
        style: AppTypography.bodyMedium.copyWith(
          fontSize: 16.183,
          height: 1.445,
          letterSpacing: -0.0032,
          color: AppColors.gray300,
        ),
      ),
    );
  }
}

class _MissionListContent extends StatelessWidget {
  const _MissionListContent({
    required this.missions,
    required this.showDeleteAction,
    required this.onEdit,
    required this.onDelete,
    required this.onAdd,
  });

  final List<TodayMission> missions;
  final bool showDeleteAction;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
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
              showDeleteAction: index == 0 && showDeleteAction,
              onEdit: onEdit,
              onDelete: onDelete,
            ),
            if (index != missions.length - 1) const SizedBox(height: 13.486),
          ],
          const SizedBox(height: 17.98),
          GestureDetector(
            onTap: onAdd,
            behavior: HitTestBehavior.opaque,
            child: const _MissionAddButton(),
          ),
        ],
      ),
    );
  }
}

class _MissionListCard extends StatelessWidget {
  const _MissionListCard({
    required this.mission,
    required this.showDeleteAction,
    required this.onEdit,
    required this.onDelete,
  });

  final TodayMission mission;
  final bool showDeleteAction;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    if (!showDeleteAction) {
      return _MissionCardSurface(mission: mission, onEdit: onEdit);
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(14.385),
      child: SizedBox(
        height: 76.421,
        child: Stack(
          children: [
            Positioned.fill(
              child: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 20),
                color: const Color(0xFFFFD3D3),
                child: GestureDetector(
                  onTap: onDelete,
                  behavior: HitTestBehavior.opaque,
                  child: const _DeleteActionButton(),
                ),
              ),
            ),
            Positioned(
              left: -58,
              top: 0,
              bottom: 0,
              width: 327,
              child: _MissionCardSurface(mission: mission, onEdit: onEdit),
            ),
          ],
        ),
      ),
    );
  }
}

class _MissionCardSurface extends StatelessWidget {
  const _MissionCardSurface({required this.mission, required this.onEdit});

  final TodayMission mission;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 76.421,
      padding: const EdgeInsets.all(16.183),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14.385),
      ),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3.596),
            child: SvgPicture.asset(
              mission.category.iconAsset,
              width: 43.156,
              height: 43.156,
            ),
          ),
          const SizedBox(width: 17.082),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  mission.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.headlineBold.copyWith(
                    fontSize: 16.183,
                    height: 1.445,
                    letterSpacing: -0.0032,
                    color: const Color(0xFF050505),
                  ),
                ),
                const SizedBox(height: 2.697),
                Text(
                  mission.rewardLabel,
                  style: AppTypography.labelMedium.copyWith(
                    fontSize: 12.587,
                    height: 1.429,
                    letterSpacing: 0.1825,
                    color: AppColors.gray500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: onEdit,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: SvgPicture.asset(
                'assets/icons/arrow button/Settings.svg',
                width: 17.982,
                height: 17.982,
                colorFilter: const ColorFilter.mode(
                  AppColors.gray300,
                  BlendMode.srcIn,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DeleteActionButton extends StatelessWidget {
  const _DeleteActionButton();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 21.578,
      height: 21.578,
      decoration: const BoxDecoration(
        color: AppColors.destructive,
        shape: BoxShape.circle,
      ),
      child: const Icon(Icons.close_rounded, size: 17, color: AppColors.white),
    );
  }
}

class _MissionAddButton extends StatelessWidget {
  const _MissionAddButton();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 35.963,
      height: 35.963,
      decoration: const BoxDecoration(
        color: Color(0xFFEBF5FE),
        shape: BoxShape.circle,
      ),
      child: const Icon(Icons.add_rounded, size: 28, color: AppColors.primary),
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
            width: 294.897,
            height: 189.705,
            padding: const EdgeInsets.fromLTRB(31, 33.27, 31, 26.97),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                const _WarningIcon(),
                const SizedBox(height: 16.183),
                Text(
                  '미션을 삭제하시겠습니까?',
                  textAlign: TextAlign.center,
                  style: AppTypography.labelBold.copyWith(
                    fontSize: 14.385,
                    height: 1.5,
                    letterSpacing: 0.082,
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
                    const SizedBox(width: 13.486),
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
      width: 28.77,
      height: 28.77,
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
        height: 37.761,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: filled ? AppColors.primary : const Color(0xFFEBF5FE),
          borderRadius: BorderRadius.circular(8),
          border: filled
              ? null
              : Border.all(color: AppColors.primary, width: 0.899),
        ),
        child: Text(
          label,
          style: AppTypography.labelMedium.copyWith(
            fontSize: 12.587,
            height: 1.429,
            letterSpacing: 0.1826,
            color: filled ? AppColors.white : AppColors.primary,
          ),
        ),
      ),
    );
  }
}
