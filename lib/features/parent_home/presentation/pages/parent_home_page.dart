import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../models/parent_home_models.dart';
import '../widgets/child_selector_section.dart';
import '../widgets/parent_home_header.dart';
import '../widgets/today_mission_section.dart';
import '../widgets/today_time_section.dart';

class ParentHomePage extends StatefulWidget {
  const ParentHomePage({
    super.key,
    this.showFilledPreview = false,
    this.showTimeEmptyPreview = false,
  });

  final bool showFilledPreview;
  final bool showTimeEmptyPreview;

  @override
  State<ParentHomePage> createState() => _ParentHomePageState();
}

class _ParentHomePageState extends State<ParentHomePage> {
  late final ParentHomeData _data = widget.showFilledPreview
      ? ParentHomeData.sampleFilled()
      : widget.showTimeEmptyPreview
      ? ParentHomeData.sampleTimeEmpty()
      : ParentHomeData.empty();

  int _selectedChildIndex = 0;

  @override
  Widget build(BuildContext context) {
    final bool hasFilledContent =
        _data.hasChildren ||
        _data.hasConfiguredTime ||
        _data.hasConfiguredMissions;
    final bool hasChildren = _data.hasChildren;

    return Scaffold(
      backgroundColor: hasFilledContent ? AppColors.gray100 : AppColors.gray050,
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 375),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 14, 24, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ParentHomeHeader(
                    hasUnreadNotification: _data.hasUnreadNotification,
                    onMyTap: () => context.push('/mypage'),
                    onNotificationTap: () => context.push('/notifications'),
                  ),
                  const SizedBox(height: 35),
                  ChildSelectorSection(
                    children: _data.children,
                    selectedIndex: _selectedChildIndex,
                    onChildTap: (int index) {
                      setState(() {
                        _selectedChildIndex = index;
                      });
                    },
                    onAddChildTap: () => context.push('/child/add'),
                  ),
                  const SizedBox(height: 36),
                  Opacity(
                    opacity: hasChildren ? 1 : 0.2,
                    child: IgnorePointer(
                      ignoring: !hasChildren,
                      child: TodayTimeSection(
                        timeSummary: _data.timeSummary,
                        onOpen: () => context.push('/today-time'),
                        onSetup: () => context.push('/today-time/setup'),
                      ),
                    ),
                  ),
                  const SizedBox(height: 36),
                  Opacity(
                    opacity: hasChildren ? 1 : 0.2,
                    child: IgnorePointer(
                      ignoring: !hasChildren,
                      child: TodayMissionSection(
                        missions: _data.missions,
                        completedCount: _data.completedMissionCount,
                        totalCount: _data.missionCount,
                        onOpen: () => context.push('/today-mission'),
                        onSetup: () => context.push('/today-mission/setup'),
                        onAdd: () => context.push('/today-mission/setup'),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
