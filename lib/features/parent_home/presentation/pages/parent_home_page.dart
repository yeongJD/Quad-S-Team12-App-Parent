import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/auth/auth_session.dart';
import '../../../../core/child/child_connection_store.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../today_mission/presentation/data/today_mission_store.dart';
import '../../../today_mission/presentation/models/today_mission.dart';
import '../../../today_mission/presentation/pages/today_mission_check_page.dart';
import '../../../today_time/presentation/data/daily_time_rule_store.dart';
import '../../../today_time/presentation/models/daily_time_rule.dart';
import '../../../notifications/presentation/data/notification_store.dart';
import '../models/parent_home_models.dart';
import '../widgets/child_selector_section.dart';
import '../widgets/parent_home_header.dart';
import '../widgets/today_mission_section.dart';
import '../widgets/today_time_section.dart';

class _StoredParentHomeData {
  const _StoredParentHomeData({
    required this.data,
    required this.missions,
    required this.children,
  });

  final ParentHomeData data;
  final List<TodayMission> missions;
  final List<ConnectedChild> children;
}

class ParentHomePage extends StatefulWidget {
  const ParentHomePage({
    super.key,
    this.showFilledPreview = false,
    this.showTimeEmptyPreview = false,
    this.showLinkedChildPreview = false,
  });

  final bool showFilledPreview;
  final bool showTimeEmptyPreview;
  final bool showLinkedChildPreview;

  @override
  State<ParentHomePage> createState() => _ParentHomePageState();
}

class _ParentHomePageState extends State<ParentHomePage> {
  ParentHomeData _data = ParentHomeData.empty();
  bool _isLoading = true;
  int _selectedChildIndex = 0;
  int? _deleteChildIndex;
  List<ConnectedChild> _connectedChildren = <ConnectedChild>[];
  List<TodayMission> _savedMissions = <TodayMission>[];
  String? _parentId;
  final GlobalKey _childSelectorKey = GlobalKey();

  ConnectedChild? get _selectedChild {
    if (_selectedChildIndex < 0 ||
        _selectedChildIndex >= _connectedChildren.length) {
      return null;
    }
    return _connectedChildren[_selectedChildIndex];
  }

  @override
  void initState() {
    super.initState();
    _loadParentHomeData();
  }

  Future<void> _loadParentHomeData() async {
    final ParentHomeData data;
    final List<TodayMission> savedMissions;
    if (widget.showFilledPreview) {
      data = ParentHomeData.sampleFilled();
      savedMissions = <TodayMission>[];
      _connectedChildren = const <ConnectedChild>[
        ConnectedChild(
          childrenId: 'GDG12-1',
          name: '박진아',
          childCode: 'GDG12-1',
        ),
        ConnectedChild(
          childrenId: 'GDG12-2',
          name: '박진아',
          childCode: 'GDG12-2',
        ),
      ];
    } else if (widget.showTimeEmptyPreview) {
      data = ParentHomeData.sampleTimeEmpty();
      savedMissions = <TodayMission>[];
      _connectedChildren = const <ConnectedChild>[
        ConnectedChild(
          childrenId: 'GDG12-1',
          name: '박진아',
          childCode: 'GDG12-1',
        ),
      ];
    } else if (widget.showLinkedChildPreview) {
      data = ParentHomeData.withLinkedChild(name: '홍길동');
      savedMissions = <TodayMission>[];
      _connectedChildren = const <ConnectedChild>[
        ConnectedChild(
          childrenId: 'GDG12-1',
          name: '홍길동',
          childCode: 'GDG12-1',
        ),
      ];
    } else {
      final _StoredParentHomeData storedData =
          await _loadStoredParentHomeData();
      data = storedData.data;
      savedMissions = storedData.missions;
      _connectedChildren = storedData.children;
    }

    if (!mounted) {
      return;
    }
    setState(() {
      _data = data;
      _savedMissions = savedMissions;
      _isLoading = false;
    });
  }

  Future<_StoredParentHomeData> _loadStoredParentHomeData() async {
    final String? parentId = await AuthSession.getCurrentParentId();
    _parentId = parentId;
    if (parentId == null || parentId.isEmpty) {
      _selectedChildIndex = 0;
      return const _StoredParentHomeData(
        data: ParentHomeData(
          children: <ParentHomeChild>[],
          hasUnreadNotification: false,
        ),
        missions: <TodayMission>[],
        children: <ConnectedChild>[],
      );
    }

    final bool hasUnreadNotification = await NotificationStore.hasUnread(
      parentId,
    );
    final List<ConnectedChild> children =
        await ChildConnectionStore.loadChildren(parentId);
    if (children.isEmpty) {
      _selectedChildIndex = 0;
      return _StoredParentHomeData(
        data: ParentHomeData(
          children: const <ParentHomeChild>[],
          hasUnreadNotification: hasUnreadNotification,
        ),
        missions: <TodayMission>[],
        children: children,
      );
    }

    _selectedChildIndex = _selectedChildIndex.clamp(0, children.length - 1);
    final ConnectedChild selectedChild = children[_selectedChildIndex];
    final List<DailyTimeRule> savedTimeRules = await DailyTimeRuleStore.load(
      parentId: parentId,
      childrenId: selectedChild.childrenId,
    );
    final List<TodayMission> savedMissions = await TodayMissionStore.load(
      parentId: parentId,
      childrenId: selectedChild.childrenId,
    );
    final TimeSummary? timeSummary = _timeSummaryFromRules(savedTimeRules);
    final List<MissionItem> missions = savedMissions
        .map(MissionItem.fromTodayMission)
        .toList();

    return _StoredParentHomeData(
      data: ParentHomeData.withLinkedChildren(
        names: children.map((ConnectedChild child) => child.name).toList(),
        timeSummary: timeSummary,
        hasChildTimePlan: timeSummary != null,
        missions: missions,
        hasUnreadNotification: hasUnreadNotification,
      ),
      missions: savedMissions,
      children: children,
    );
  }

  TimeSummary? _timeSummaryFromRules(List<DailyTimeRule> rules) {
    if (rules.isEmpty) {
      return null;
    }

    final int totalMinutes = _calculateMonthlyMinutes(rules);
    if (totalMinutes <= 0) {
      return null;
    }

    return TimeSummary(
      basicTime: _formatTime(totalMinutes),
      bonusTime: _formatTime(0),
      basicProgress: 1,
      bonusProgress: 0,
    );
  }

  int _calculateMonthlyMinutes(List<DailyTimeRule> rules) {
    final DateTime now = DateTime.now();
    final int lastDay = DateTime(now.year, now.month + 1, 0).day;
    final List<int> weekdayCounts = List<int>.filled(DateTime.daysPerWeek, 0);
    for (int day = 1; day <= lastDay; day++) {
      final int weekdayIndex = DateTime(now.year, now.month, day).weekday - 1;
      weekdayCounts[weekdayIndex]++;
    }

    int total = 0;
    for (final DailyTimeRule rule in rules) {
      final int dailyMinutes = rule.time.hour * 60 + rule.time.minute;
      for (final int dayIndex in rule.days) {
        if (dayIndex < 0 || dayIndex >= weekdayCounts.length) {
          continue;
        }
        total += dailyMinutes * weekdayCounts[dayIndex];
      }
    }
    return total;
  }

  String _formatTime(int totalMinutes) {
    final int hours = totalMinutes ~/ 60;
    final int minutes = totalMinutes % 60;
    return '${hours.toString().padLeft(2, '0')}:'
        '${minutes.toString().padLeft(2, '0')}';
  }

  String get _missionConfirmationLocation {
    if (_data.hasConfiguredMissions) {
      return _withChildCode('/today-mission');
    }
    return _withChildCode('/today-mission', demo: 'empty');
  }

  Future<void> _openTimeSettingsEntry() async {
    if (!_ensureSelectedChild()) {
      return;
    }

    await context.push(_timeConfirmationLocation);
    if (!mounted) {
      return;
    }
    await _loadParentHomeData();
  }

  Future<void> _openMissionSetup() async {
    if (!_ensureSelectedChild()) {
      return;
    }

    await context.push(_withChildCode('/today-mission/setup'));
    if (!mounted) {
      return;
    }
    await _loadParentHomeData();
  }

  Future<void> _openMissionList() async {
    if (!_ensureSelectedChild()) {
      return;
    }

    await context.push(_missionConfirmationLocation);
    if (!mounted) {
      return;
    }
    await _loadParentHomeData();
  }

  Future<void> _openMissionCheck(int index) async {
    if (!_ensureSelectedChild()) {
      return;
    }

    final String? parentId = _parentId;
    final ConnectedChild? selectedChild = _selectedChild;
    if (index < 0 || index >= _savedMissions.length) {
      await _openMissionList();
      return;
    }

    await context.push(
      '/today-mission/check',
      extra: TodayMissionCheckArgs(
        parentId: parentId!,
        childrenId: selectedChild!.childrenId,
        index: index,
        mission: _savedMissions[index],
      ),
    );
    if (!mounted) {
      return;
    }
    await _loadParentHomeData();
  }

  Future<void> _handleChildTap(int index) async {
    if (_selectedChildIndex != index) {
      setState(() {
        _selectedChildIndex = index;
        _deleteChildIndex = null;
        _isLoading = true;
      });
      await _loadParentHomeData();
      return;
    }

    setState(() {
      _deleteChildIndex = _deleteChildIndex == index ? null : index;
    });
  }

  Future<void> _deleteChild(int index) async {
    final List<ParentHomeChild> children = <ParentHomeChild>[..._data.children];
    if (index < 0 || index >= children.length) {
      return;
    }

    children.removeAt(index);
    final String? parentId = _parentId;
    final ConnectedChild? selectedChild = index < _connectedChildren.length
        ? _connectedChildren[index]
        : null;
    if (parentId == null || selectedChild == null) {
      return;
    }
    await ChildConnectionStore.removeChild(
      parentId: parentId,
      childrenId: selectedChild.childrenId,
    );

    if (!mounted) {
      return;
    }
    _selectedChildIndex = children.isEmpty
        ? 0
        : _selectedChildIndex.clamp(0, children.length - 1);
    _deleteChildIndex = null;
    await _loadParentHomeData();
  }

  void _clearDeleteChildStateIfNeeded(PointerDownEvent event) {
    final int? deleteChildIndex = _deleteChildIndex;
    if (deleteChildIndex == null) {
      return;
    }

    final BuildContext? childSelectorContext = _childSelectorKey.currentContext;
    final RenderObject? renderObject = childSelectorContext?.findRenderObject();
    if (renderObject is! RenderBox) {
      return;
    }

    final Offset localPosition = renderObject.globalToLocal(event.position);
    final bool tappedInsideChildSelector = renderObject.size.contains(
      localPosition,
    );
    if (tappedInsideChildSelector) {
      return;
    }

    setState(() {
      _selectedChildIndex = deleteChildIndex;
      _deleteChildIndex = null;
    });
  }

  bool _ensureSelectedChild() {
    if (_parentId != null && _selectedChild != null) {
      return true;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('자녀를 먼저 추가해주세요.')));
    return false;
  }

  String get _timeConfirmationLocation {
    String? demo;
    if (_data.hasConfiguredTime && _data.hasChildTimePlan) {
      demo = 'filled';
    } else if (_data.hasConfiguredTime) {
      demo = 'parent-only';
    } else if (widget.showTimeEmptyPreview) {
      demo = 'child-empty';
    } else {
      demo = 'all-empty';
    }
    return _withChildCode('/today-time', demo: demo);
  }

  String _withChildCode(String path, {String? demo}) {
    final String? parentId = _parentId;
    final ConnectedChild? selectedChild = _selectedChild;
    final Map<String, String> queryParameters = <String, String>{};
    if (parentId != null && parentId.isNotEmpty) {
      queryParameters['parentId'] = parentId;
    }
    if (selectedChild != null && selectedChild.childrenId.isNotEmpty) {
      queryParameters['childrenId'] = selectedChild.childrenId;
    }
    if (demo case final String demo) {
      queryParameters['demo'] = demo;
    }

    return Uri(path: path, queryParameters: queryParameters).toString();
  }

  @override
  Widget build(BuildContext context) {
    final bool hasFilledContent =
        _data.hasChildren ||
        _data.hasConfiguredTime ||
        _data.hasConfiguredMissions;

    return Scaffold(
      backgroundColor: hasFilledContent ? AppColors.gray100 : AppColors.gray050,
      body: Listener(
        behavior: HitTestBehavior.translucent,
        onPointerDown: _clearDeleteChildStateIfNeeded,
        child: SafeArea(
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
                            onNotificationTap: () async {
                              await context.push('/notifications');
                              if (!mounted) {
                                return;
                              }
                              await _loadParentHomeData();
                            },
                          ),
                          const SizedBox(height: 35),
                          KeyedSubtree(
                            key: _childSelectorKey,
                            child: ChildSelectorSection(
                              children: _data.children,
                              selectedIndex: _selectedChildIndex,
                              deleteIndex: _deleteChildIndex,
                              onChildTap: _handleChildTap,
                              onChildDelete: _deleteChild,
                              onAddChildTap: () async {
                                await context.push('/child/add');
                                if (!mounted) {
                                  return;
                                }
                                await _loadParentHomeData();
                              },
                            ),
                          ),
                          const SizedBox(height: 36),
                          TodayTimeSection(
                            timeSummary: _data.timeSummary,
                            waitingForChildPlan: _data.waitingForChildTimePlan,
                            onSetup: _openTimeSettingsEntry,
                          ),
                          const SizedBox(height: 36),
                          TodayMissionSection(
                            missions: _data.missions,
                            completedCount: _data.completedMissionCount,
                            totalCount: _data.missionCount,
                            onOpen: _openMissionList,
                            onSetup: _openMissionList,
                            onAdd: _openMissionSetup,
                            onMissionTap: _openMissionCheck,
                          ),
                        ],
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
