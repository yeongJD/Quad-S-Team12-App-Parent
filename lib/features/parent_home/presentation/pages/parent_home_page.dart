import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/child/child_connection_store.dart';
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
  ParentHomeData _data = ParentHomeData.empty();
  bool _isLoading = true;
  int _selectedChildIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadParentHomeData();
  }

  Future<void> _loadParentHomeData() async {
    final ParentHomeData data;
    if (widget.showFilledPreview) {
      data = ParentHomeData.sampleFilled();
    } else if (widget.showTimeEmptyPreview) {
      data = ParentHomeData.sampleTimeEmpty();
    } else if (await ChildConnectionStore.hasLinkedChild()) {
      final String childName =
          await ChildConnectionStore.linkedChildName() ?? '박진아';
      data = ParentHomeData.withLinkedChild(name: childName);
    } else {
      data = ParentHomeData.empty();
    }

    if (!mounted) {
      return;
    }
    setState(() {
      _data = data;
      _isLoading = false;
    });
  }

  String get _timeConfirmationLocation {
    if (_data.hasConfiguredTime) {
      return '/today-time?demo=filled';
    }
    if (widget.showTimeEmptyPreview) {
      return '/today-time?demo=child-empty';
    }
    return '/today-time?demo=all-empty';
  }

  String get _missionConfirmationLocation {
    if (_data.hasConfiguredMissions) {
      return '/today-mission';
    }
    return '/today-mission?demo=empty';
  }

  void _openWhenChildLinked(String location) {
    if (_data.hasChildren) {
      context.push(location);
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('자녀를 먼저 추가해주세요.')));
  }

  @override
  Widget build(BuildContext context) {
    final bool hasFilledContent =
        _data.hasChildren ||
        _data.hasConfiguredTime ||
        _data.hasConfiguredMissions;

    return Scaffold(
      backgroundColor: hasFilledContent ? AppColors.gray100 : AppColors.gray050,
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 375),
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 14, 24, 28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ParentHomeHeader(
                          hasUnreadNotification: _data.hasUnreadNotification,
                          onMyTap: () => context.push('/mypage'),
                          onNotificationTap: () =>
                              context.push('/notifications'),
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
                        TodayTimeSection(
                          timeSummary: _data.timeSummary,
                          onOpen: () => context.push(_timeConfirmationLocation),
                          onSetup: () =>
                              context.push(_timeConfirmationLocation),
                          onAdd: () =>
                              _openWhenChildLinked('/today-time/setup'),
                        ),
                        const SizedBox(height: 36),
                        TodayMissionSection(
                          missions: _data.missions,
                          completedCount: _data.completedMissionCount,
                          totalCount: _data.missionCount,
                          onOpen: () =>
                              context.push(_missionConfirmationLocation),
                          onSetup: () =>
                              context.push(_missionConfirmationLocation),
                          onAdd: () =>
                              _openWhenChildLinked('/today-mission/setup'),
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
