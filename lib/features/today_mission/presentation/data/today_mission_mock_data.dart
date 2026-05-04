import '../models/today_mission.dart';

abstract final class TodayMissionMockData {
  static const TodayMission roomCleaning = TodayMission(
    title: '방청소하기',
    category: MissionCategory.cleaning,
    resetPeriod: MissionResetPeriod.daily,
    confirmationMethod: MissionConfirmationMethod.child,
    rewardMinutes: 30,
    description: '방청소하고 깨끗하진 방 사진 찍기',
  );

  static const List<TodayMission> filledMissions = <TodayMission>[
    roomCleaning,
    TodayMission(
      title: '설거지 하기',
      category: MissionCategory.exercise,
      resetPeriod: MissionResetPeriod.daily,
      confirmationMethod: MissionConfirmationMethod.child,
      rewardMinutes: 30,
      description: '설거지 완료하기',
    ),
    TodayMission(
      title: '수학 문제 풀기',
      category: MissionCategory.study,
      resetPeriod: MissionResetPeriod.daily,
      confirmationMethod: MissionConfirmationMethod.child,
      rewardMinutes: 30,
      description: '수학 문제집 풀기',
    ),
    TodayMission(
      title: '7시 기상',
      category: MissionCategory.routine,
      resetPeriod: MissionResetPeriod.daily,
      confirmationMethod: MissionConfirmationMethod.child,
      rewardMinutes: 30,
      description: '아침 7시에 일어나기',
    ),
    TodayMission(
      title: '7시 기상',
      category: MissionCategory.errand,
      resetPeriod: MissionResetPeriod.daily,
      confirmationMethod: MissionConfirmationMethod.child,
      rewardMinutes: 30,
      description: '아침 7시에 일어나기',
    ),
  ];

  static List<TodayMission> missionsForDemo(String? demo) {
    if (demo == 'empty') {
      return <TodayMission>[];
    }
    return filledMissions;
  }
}
