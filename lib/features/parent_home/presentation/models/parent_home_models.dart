import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

enum MissionStatus { completed, inProgress, pending }

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
}

class ParentHomeData {
  const ParentHomeData({
    required this.children,
    required this.hasUnreadNotification,
    this.timeSummary,
    this.missions = const <MissionItem>[],
    this.totalMissionCount,
  });

  final List<ParentHomeChild> children;
  final bool hasUnreadNotification;
  final TimeSummary? timeSummary;
  final List<MissionItem> missions;
  final int? totalMissionCount;

  bool get hasChildren => children.isNotEmpty;
  bool get hasConfiguredTime => timeSummary != null;
  bool get hasConfiguredMissions => missions.isNotEmpty;

  int get completedMissionCount => missions.where((MissionItem mission) {
    return mission.status == MissionStatus.completed;
  }).length;

  int get missionCount => totalMissionCount ?? missions.length;

  factory ParentHomeData.empty() {
    return const ParentHomeData(
      children: <ParentHomeChild>[],
      hasUnreadNotification: false,
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
        basicProgress: 0.78,
        bonusProgress: 0.66,
      ),
      missions: const <MissionItem>[
        MissionItem(
          title: '방청소 하기',
          reward: '1시간 지급',
          status: MissionStatus.completed,
        ),
        MissionItem(
          title: '방청소 하기',
          reward: '1시간 지급',
          status: MissionStatus.inProgress,
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
