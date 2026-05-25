import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/auth/auth_session.dart';
import '../../../../core/child/child_connection_store.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../today_mission/presentation/models/today_mission.dart';
import '../../../today_mission/presentation/pages/today_mission_check_page.dart';
import '../data/notification_store.dart';
import '../models/notification_item.dart';
import '../widgets/notification_card.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  List<NotificationItem> _notifications = <NotificationItem>[];
  bool _isLoading = true;
  bool _isPastNotificationsExpanded = false;
  String? _parentId;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    final String? parentId = await AuthSession.getCurrentParentId();
    final List<NotificationItem> notifications = await NotificationStore.load(
      parentId,
    );
    if (!mounted) {
      return;
    }

    setState(() {
      _parentId = parentId;
      _notifications = notifications;
      _isLoading = false;
    });
  }

  Future<void> _handleActionTap(NotificationItem item) async {
    bool didOpen = false;
    switch (item.type) {
      case NotificationType.missionCompleted:
      case NotificationType.missionConfirmationRequested:
        didOpen = await _openMissionNotification(item);
      case NotificationType.timeConfigured:
        didOpen = await _openTimeNotification(item);
      case NotificationType.weeklyUsageReport:
        didOpen = await _openUsageReportNotification(item);
    }

    if (didOpen) {
      await _markNotificationRead(item);
    }
  }

  Future<void> _markNotificationRead(NotificationItem item) async {
    final String? parentId = _parentId;
    if (parentId != null && parentId.isNotEmpty) {
      await NotificationStore.markRead(
        parentId: parentId,
        notificationId: item.id,
      );
    }

    if (!mounted) {
      return;
    }
    setState(() {
      _notifications = _notifications
          .map(
            (NotificationItem notification) => notification.id == item.id
                ? notification.copyWith(isRead: true)
                : notification,
          )
          .toList(growable: false);
    });
  }

  Future<bool> _openMissionNotification(NotificationItem item) async {
    final String parentId = _parentId?.isNotEmpty == true
        ? _parentId!
        : 'mock-parent';

    final ConnectedChild? child = await _childFromPayload(item);
    if (!mounted) {
      return false;
    }
    final String childrenId =
        child?.childrenId ?? _childCodeFromPayload(item) ?? 'GDG12-1';
    final int missionIndex = _missionIndexFromPayload(item) ?? 0;

    context.push(
      '/today-mission/check',
      extra: TodayMissionCheckArgs(
        parentId: parentId,
        childrenId: childrenId,
        index: missionIndex,
        mission: _missionMockForNotification(item.type),
        initialTab: MissionCheckTab.review,
      ),
    );
    return true;
  }

  Future<bool> _openTimeNotification(NotificationItem item) async {
    final String? parentId = _parentId;
    if (parentId == null || parentId.isEmpty) {
      _showFallbackMessage();
      context.push('/today-time?demo=filled');
      return true;
    }

    final ConnectedChild? child = await _childFromPayload(item);
    if (!mounted) {
      return false;
    }
    if (child == null) {
      _showFallbackMessage();
      context.push(_timeLocation(parentId: parentId, demo: 'filled'));
      return true;
    }

    context.push(
      _timeLocation(
        parentId: parentId,
        childrenId: child.childrenId,
        demo: 'filled',
      ),
    );
    return true;
  }

  Future<bool> _openUsageReportNotification(NotificationItem item) async {
    final String? parentId = _parentId;
    if (parentId == null || parentId.isEmpty) {
      _showFallbackMessage();
      context.push('/usage-report');
      return true;
    }

    final ConnectedChild? child = await _childFromPayload(item);
    if (!mounted) {
      return false;
    }
    if (child == null) {
      _showFallbackMessage();
      context.push(_usageReportLocation(parentId: parentId));
      return true;
    }

    context.push(
      _usageReportLocation(parentId: parentId, childrenId: child.childrenId),
    );
    return true;
  }

  Future<ConnectedChild?> _childFromPayload(NotificationItem item) async {
    final String? parentId = _parentId;
    final Object? childCode = item.payload?['childCode'];
    if (parentId == null || parentId.isEmpty || childCode is! String) {
      return null;
    }

    final List<ConnectedChild> children =
        await ChildConnectionStore.loadChildren(parentId);
    for (final ConnectedChild child in children) {
      if (child.childCode == childCode || child.childrenId == childCode) {
        return child;
      }
    }
    return null;
  }

  int? _missionIndexFromPayload(NotificationItem item) {
    final Object? missionIndex = item.payload?['missionIndex'];
    if (missionIndex is int) {
      return missionIndex;
    }
    return null;
  }

  String? _childCodeFromPayload(NotificationItem item) {
    final Object? childCode = item.payload?['childCode'];
    return childCode is String && childCode.isNotEmpty ? childCode : null;
  }

  TodayMission _missionMockForNotification(NotificationType type) {
    switch (type) {
      case NotificationType.missionCompleted:
        return const TodayMission(
          title: '숙제하기',
          category: MissionCategory.study,
          resetPeriod: MissionResetPeriod.daily,
          confirmationMethod: MissionConfirmationMethod.child,
          rewardMinutes: 15,
          description: '오늘 숙제를 끝내고 완료 사진을 올리기',
          status: TodayMissionStatus.completed,
          verificationStatus: MissionVerificationStatus.approved,
          submittedAtText: '2025.1.21 오후 7:01',
        );
      case NotificationType.missionConfirmationRequested:
        return const TodayMission(
          title: '숙제하기',
          category: MissionCategory.study,
          resetPeriod: MissionResetPeriod.daily,
          confirmationMethod: MissionConfirmationMethod.parent,
          rewardMinutes: 15,
          description: '오늘 숙제를 끝내고 완료 사진을 올리기',
          status: TodayMissionStatus.reviewing,
          verificationStatus: MissionVerificationStatus.waitingParentApproval,
          submittedAtText: '2025.1.21 오후 7:01',
        );
      case NotificationType.weeklyUsageReport:
      case NotificationType.timeConfigured:
        return const TodayMission(
          title: '미션 확인',
          category: MissionCategory.routine,
          resetPeriod: MissionResetPeriod.daily,
          confirmationMethod: MissionConfirmationMethod.child,
          rewardMinutes: 0,
          description: '',
        );
    }
  }

  String _timeLocation({
    required String parentId,
    String? childrenId,
    String? demo,
  }) {
    return Uri(
      path: '/today-time',
      queryParameters: <String, String>{
        'parentId': parentId,
        if (childrenId != null && childrenId.isNotEmpty)
          'childrenId': childrenId,
        if (demo != null && demo.isNotEmpty) 'demo': demo,
      },
    ).toString();
  }

  String _usageReportLocation({required String parentId, String? childrenId}) {
    return Uri(
      path: '/usage-report',
      queryParameters: <String, String>{
        'parentId': parentId,
        if (childrenId != null && childrenId.isNotEmpty)
          'childrenId': childrenId,
      },
    ).toString();
  }

  void _showFallbackMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('연결된 항목을 찾을 수 없어 목록으로 이동합니다.')),
    );
  }

  Future<void> _showDeleteDialog(NotificationItem item) {
    return showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'notification-delete-dialog',
      barrierColor: const Color.fromRGBO(68, 68, 68, 0.6),
      pageBuilder: (context, animation, secondaryAnimation) {
        return Material(
          type: MaterialType.transparency,
          child: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 375),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 21),
                  child: _DeleteNotificationDialog(
                    onConfirm: () async {
                      final String? parentId = _parentId;
                      setState(() {
                        _notifications.removeWhere(
                          (NotificationItem candidate) =>
                              candidate.id == item.id,
                        );
                      });
                      context.pop();
                      if (parentId != null && parentId.isNotEmpty) {
                        await NotificationStore.hide(
                          parentId: parentId,
                          notificationId: item.id,
                        );
                      }
                    },
                  ),
                ),
              ),
            ),
          ),
        );
      },
      transitionDuration: const Duration(milliseconds: 160),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          ),
          child: child,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<NotificationItem> activeNotifications = _notifications
        .where((NotificationItem item) => !item.isRead)
        .toList(growable: false);
    final List<NotificationItem> pastNotifications = _notifications
        .where((NotificationItem item) => item.isRead)
        .toList(growable: false);
    final bool isEmpty =
        !_isLoading && activeNotifications.isEmpty && pastNotifications.isEmpty;

    return Scaffold(
      backgroundColor: AppColors.gray100,
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 375),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _NotificationsTopBar(onBack: context.pop),
                  if (_isLoading)
                    const Expanded(
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (isEmpty)
                    Expanded(
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 40),
                          child: Text(
                            '확인하지 않은 알림이 없습니다.',
                            textAlign: TextAlign.center,
                            style: AppTypography.headlineMedium.copyWith(
                              fontSize: 16.183,
                              height: 1.445,
                              letterSpacing: -0.0032,
                              color: AppColors.gray300,
                              decoration: TextDecoration.none,
                            ),
                          ),
                        ),
                      ),
                    )
                  else
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 22),
                        child: ListView(
                          padding: EdgeInsets.zero,
                          children: [
                            if (activeNotifications.isEmpty)
                              const _UnreadEmptyMessage(),
                            for (
                              int index = 0;
                              index < activeNotifications.length;
                              index++
                            ) ...[
                              NotificationCard(
                                item: activeNotifications[index],
                                onTap: () {},
                                onActionTap: () => _handleActionTap(
                                  activeNotifications[index],
                                ),
                                onDeleteIntent: _showDeleteDialog,
                              ),
                              if (index < activeNotifications.length - 1)
                                const SizedBox(height: 13.486),
                            ],
                            if (pastNotifications.isNotEmpty) ...[
                              SizedBox(
                                height: activeNotifications.isEmpty ? 18 : 24,
                              ),
                              _PastNotificationsToggle(
                                expanded: _isPastNotificationsExpanded,
                                onTap: () {
                                  setState(() {
                                    _isPastNotificationsExpanded =
                                        !_isPastNotificationsExpanded;
                                  });
                                },
                              ),
                              if (_isPastNotificationsExpanded) ...[
                                const SizedBox(height: 13.486),
                                for (
                                  int index = 0;
                                  index < pastNotifications.length;
                                  index++
                                ) ...[
                                  NotificationCard(
                                    item: pastNotifications[index],
                                    onTap: () {},
                                    onActionTap: () => _handleActionTap(
                                      pastNotifications[index],
                                    ),
                                    onDeleteIntent: _showDeleteDialog,
                                  ),
                                  if (index < pastNotifications.length - 1)
                                    const SizedBox(height: 13.486),
                                ],
                              ],
                            ],
                          ],
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

class _UnreadEmptyMessage extends StatelessWidget {
  const _UnreadEmptyMessage();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
      child: Text(
        '확인하지 않은 알림이 없습니다.',
        textAlign: TextAlign.center,
        style: AppTypography.headlineMedium.copyWith(
          fontSize: 16.183,
          height: 1.445,
          letterSpacing: -0.0032,
          color: AppColors.gray300,
          decoration: TextDecoration.none,
        ),
      ),
    );
  }
}

class _PastNotificationsToggle extends StatelessWidget {
  const _PastNotificationsToggle({required this.expanded, required this.onTap});

  final bool expanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        hoverColor: AppColors.gray500.withValues(alpha: 0.08),
        highlightColor: AppColors.gray500.withValues(alpha: 0.12),
        splashColor: AppColors.gray500.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          height: 46,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '지난알림 확인하기',
                style: AppTypography.labelBold.copyWith(
                  fontSize: 13,
                  height: 1.429,
                  letterSpacing: 0,
                  color: AppColors.gray600,
                  decoration: TextDecoration.none,
                ),
              ),
              const SizedBox(width: 6),
              Icon(
                expanded
                    ? Icons.keyboard_arrow_up_rounded
                    : Icons.keyboard_arrow_down_rounded,
                size: 20,
                color: AppColors.gray500,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DeleteNotificationDialog extends StatelessWidget {
  const _DeleteNotificationDialog({required this.onConfirm});

  final Future<void> Function() onConfirm;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 294.897,
        height: 189.705,
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 33, 18, 27),
          child: Column(
            children: [
              Container(
                width: 28.77,
                height: 28.77,
                decoration: const BoxDecoration(
                  color: AppColors.destructive,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: SizedBox(
                    width: 8,
                    height: 16,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Positioned(
                          top: 1.5,
                          child: Container(
                            width: 2.4,
                            height: 9.6,
                            decoration: BoxDecoration(
                              color: AppColors.white,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 0.5,
                          child: Container(
                            width: 2.4,
                            height: 2.4,
                            decoration: const BoxDecoration(
                              color: AppColors.white,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '알림을 삭제하시겠습니까?',
                style: AppTypography.labelBold.copyWith(
                  fontSize: 14.39,
                  height: 1.5,
                  letterSpacing: 0.082,
                  color: AppColors.gray800,
                  decoration: TextDecoration.none,
                ),
              ),
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _DeleteDialogButton(
                    label: '취소',
                    filled: false,
                    onTap: context.pop,
                  ),
                  const SizedBox(width: 13.486),
                  _DeleteDialogButton(
                    label: '확인',
                    filled: true,
                    onTap: () async {
                      await onConfirm();
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DeleteDialogButton extends StatelessWidget {
  const _DeleteDialogButton({
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
        width: 107.889,
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
            fontSize: 12.59,
            height: 1.429,
            letterSpacing: 0.1826,
            color: filled ? AppColors.white : AppColors.primary,
            decoration: TextDecoration.none,
          ),
        ),
      ),
    );
  }
}

class _NotificationsTopBar extends StatelessWidget {
  const _NotificationsTopBar({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: Stack(
        children: [
          Positioned(
            left: 0,
            top: 14,
            child: Material(
              color: Colors.transparent,
              shape: const CircleBorder(),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: onBack,
                hoverColor: AppColors.gray800.withValues(alpha: 0.06),
                highlightColor: AppColors.gray800.withValues(alpha: 0.10),
                splashColor: AppColors.gray800.withValues(alpha: 0.12),
                customBorder: const CircleBorder(),
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: Padding(
                    padding: const EdgeInsets.all(2),
                    child: SvgPicture.asset(
                      'assets/icons/cmp/btn/back.svg',
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Center(
            child: Text(
              '알림',
              style: AppTypography.headlineMedium.copyWith(
                fontSize: 16.18,
                height: 1.445,
                letterSpacing: -0.0032,
                color: const Color(0xFF050505),
                decoration: TextDecoration.none,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
