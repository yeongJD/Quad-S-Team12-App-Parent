import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../today_mission/presentation/models/today_mission.dart';

enum MissionStatus { pending, reviewing, completed, rejected }

class ParentHomeChild {
  const ParentHomeChild({required this.name, required this.accentColor});

  final String name;
  final Color accentColor;
}

class TimeSummary {
  const TimeSummary({
    required this.basicTime,
    required this.bonusTime,
    required this.basicProgress,
    required this.bonusProgress,
  });

  final String basicTime;
  final String bonusTime;
  final double basicProgress;
  final double bonusProgress;
}

class MissionItem {
  const MissionItem({
    required this.title,
    required this.reward,
    required this.status,
    this.iconAsset = 'assets/icons/청소.svg',
  });

  final String title;
  final String reward;
  final MissionStatus status;
  final String iconAsset;

  factory MissionItem.fromTodayMission(TodayMission mission) {
    final MissionStatus status = switch (mission.effectiveStatus) {
      TodayMissionStatus.pending => MissionStatus.pending,
      TodayMissionStatus.reviewing => MissionStatus.reviewing,
      TodayMissionStatus.completed => MissionStatus.completed,
      TodayMissionStatus.rejected => MissionStatus.rejected,
    };
    return MissionItem(
      title: mission.title,
      reward: mission.rewardLabel,
      status: status,
      iconAsset: mission.category.iconAsset,
    );
  }
}

class ParentHomeData {
  const ParentHomeData({
    required this.children,
    required this.hasUnreadNotification,
    this.timeSummary,
    this.waitingForChildTimePlan = false,
    this.hasChildTimePlan = false,
    this.missions = const <MissionItem>[],
    this.totalMissionCount,
  });

  final List<ParentHomeChild> children;
  final bool hasUnreadNotification;
  final TimeSummary? timeSummary;
  final bool waitingForChildTimePlan;
  final bool hasChildTimePlan;
  final List<MissionItem> missions;
  final int? totalMissionCount;

  bool get hasChildren => children.isNotEmpty;
  bool get hasConfiguredTime => timeSummary != null;
  bool get hasConfiguredMissions => missions.isNotEmpty;

  int get completedMissionCount => missions.where((MissionItem mission) {
    return mission.status == MissionStatus.completed;
  }).length;

  int get missionCount => totalMissionCount ?? missions.length;

  ParentHomeData copyWith({List<ParentHomeChild>? children}) {
    return ParentHomeData(
      children: children ?? this.children,
      hasUnreadNotification: hasUnreadNotification,
      timeSummary: timeSummary,
      waitingForChildTimePlan: waitingForChildTimePlan,
      hasChildTimePlan: hasChildTimePlan,
      missions: missions,
      totalMissionCount: totalMissionCount,
    );
  }

  factory ParentHomeData.empty() {
    return const ParentHomeData(
      children: <ParentHomeChild>[],
      hasUnreadNotification: false,
    );
  }

  factory ParentHomeData.sampleTimeEmpty() {
    return const ParentHomeData(
      children: <ParentHomeChild>[
        ParentHomeChild(name: '박진아', accentColor: AppColors.primary),
      ],
      hasUnreadNotification: true,
    );
  }

  factory ParentHomeData.withLinkedChild({required String name}) {
    return ParentHomeData(
      children: <ParentHomeChild>[
        ParentHomeChild(name: name, accentColor: AppColors.primary),
      ],
      hasUnreadNotification: true,
    );
  }

  factory ParentHomeData.withLinkedChildren({
    required List<String> names,
    TimeSummary? timeSummary,
    bool waitingForChildTimePlan = false,
    bool hasChildTimePlan = false,
    List<MissionItem> missions = const <MissionItem>[],
    bool hasUnreadNotification = true,
  }) {
    return ParentHomeData(
      children: <ParentHomeChild>[
        for (int index = 0; index < names.length; index++)
          ParentHomeChild(
            name: names[index],
            accentColor: index == 0 ? AppColors.primary : AppColors.gray200,
          ),
      ],
      hasUnreadNotification: hasUnreadNotification,
      timeSummary: timeSummary,
      waitingForChildTimePlan: waitingForChildTimePlan,
      hasChildTimePlan: hasChildTimePlan,
      missions: missions,
      totalMissionCount: missions.length,
    );
  }

  factory ParentHomeData.sampleFilled() {
    return ParentHomeData(
      children: const <ParentHomeChild>[
        ParentHomeChild(name: '박진아', accentColor: AppColors.primary),
        ParentHomeChild(name: '박진아', accentColor: AppColors.gray200),
      ],
      hasUnreadNotification: true,
      timeSummary: const TimeSummary(
        basicTime: '01:30',
        bonusTime: '00:30',
        basicProgress: 0.76,
        bonusProgress: 0.82,
      ),
      hasChildTimePlan: true,
      missions: const <MissionItem>[
        MissionItem(
          title: '방청소 하기',
          reward: '1시간 지급',
          status: MissionStatus.completed,
        ),
        MissionItem(
          title: '방청소 하기',
          reward: '1시간 지급',
          status: MissionStatus.reviewing,
        ),
        MissionItem(
          title: '방청소 하기',
          reward: '1시간 지급',
          status: MissionStatus.pending,
        ),
        MissionItem(
          title: '방청소 하기',
          reward: '1시간 지급',
          status: MissionStatus.pending,
        ),
      ],
      totalMissionCount: 4,
    );
  }
}
