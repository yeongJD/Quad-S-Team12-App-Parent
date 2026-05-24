import '../../../../core/auth/account_store.dart';
import '../models/today_mission.dart';

abstract final class TodayMissionStore {
  static Future<List<TodayMission>> load({
    required String parentId,
    required String childrenId,
  }) async {
    if (parentId.isEmpty || childrenId.isEmpty) {
      return <TodayMission>[];
    }

    final AccountChildData? child = await AccountStore.getChild(
      parentId: parentId,
      childrenId: childrenId,
    );
    if (child == null) {
      return <TodayMission>[];
    }

    return child.missions
        .map(_decodeMission)
        .whereType<TodayMission>()
        .toList();
  }

  static Future<void> save({
    required String parentId,
    required String childrenId,
    required List<TodayMission> missions,
  }) async {
    if (parentId.isEmpty || childrenId.isEmpty) {
      return;
    }

    await AccountStore.updateChild(
      parentId: parentId,
      childrenId: childrenId,
      update: (AccountChildData child) {
        return child.copyWith(
          missions: missions.map(_encodeMission).toList(growable: false),
        );
      },
    );
  }

  static Future<void> add({
    required String parentId,
    required String childrenId,
    required TodayMission mission,
  }) async {
    final List<TodayMission> missions = await load(
      parentId: parentId,
      childrenId: childrenId,
    );
    missions.add(mission);
    await save(parentId: parentId, childrenId: childrenId, missions: missions);
  }

  static Future<void> updateAt({
    required String parentId,
    required String childrenId,
    required int index,
    required TodayMission mission,
  }) async {
    final List<TodayMission> missions = await load(
      parentId: parentId,
      childrenId: childrenId,
    );
    if (index < 0 || index >= missions.length) {
      return;
    }
    missions[index] = mission;
    await save(parentId: parentId, childrenId: childrenId, missions: missions);
  }

  static Future<void> removeAt({
    required String parentId,
    required String childrenId,
    required int index,
  }) async {
    final List<TodayMission> missions = await load(
      parentId: parentId,
      childrenId: childrenId,
    );
    if (index < 0 || index >= missions.length) {
      return;
    }
    missions.removeAt(index);
    await save(parentId: parentId, childrenId: childrenId, missions: missions);
  }

  static Map<String, Object> _encodeMission(TodayMission mission) {
    return <String, Object>{
      'title': mission.title,
      'category': mission.category.name,
      'resetPeriod': mission.resetPeriod.name,
      'confirmationMethod': mission.confirmationMethod.name,
      'rewardMinutes': mission.rewardMinutes,
      'description': mission.description,
      'status': mission.effectiveStatus.name,
      'verificationType': mission.verificationType.name,
      'verificationStatus': mission.effectiveVerificationStatus.name,
      if (mission.submittedAtText case final String submittedAtText)
        'submittedAtText': submittedAtText,
    };
  }

  static TodayMission? _decodeMission(Map<String, Object?> json) {
    final Object? title = json['title'];
    final Object? category = json['category'];
    final Object? resetPeriod = json['resetPeriod'];
    final Object? confirmationMethod = json['confirmationMethod'];
    final Object? rewardMinutes = json['rewardMinutes'];
    final Object? description = json['description'];
    final Object? status = json['status'];
    final Object? verificationStatus = json['verificationStatus'];
    final Object? submittedAtText = json['submittedAtText'];

    if (title is! String ||
        category is! String ||
        resetPeriod is! String ||
        confirmationMethod is! String ||
        rewardMinutes is! int ||
        description is! String ||
        (status != null && status is! String) ||
        (verificationStatus != null && verificationStatus is! String) ||
        (submittedAtText != null && submittedAtText is! String)) {
      return null;
    }

    final MissionCategory? decodedCategory = _decodeEnum(
      MissionCategory.values,
      category,
    );
    final MissionResetPeriod? decodedResetPeriod = _decodeEnum(
      MissionResetPeriod.values,
      resetPeriod,
    );
    final MissionConfirmationMethod? decodedConfirmationMethod = _decodeEnum(
      MissionConfirmationMethod.values,
      confirmationMethod,
    );
    final TodayMissionStatus decodedStatus = status is String
        ? _decodeEnum(TodayMissionStatus.values, status) ??
              TodayMissionStatus.pending
        : TodayMissionStatus.pending;

    if (decodedCategory == null ||
        decodedResetPeriod == null ||
        decodedConfirmationMethod == null) {
      return null;
    }
    final MissionVerificationStatus decodedVerificationStatus =
        verificationStatus is String
        ? _decodeEnum(MissionVerificationStatus.values, verificationStatus) ??
              missionVerificationStatusFromLegacyStatus(
                status: decodedStatus,
                verificationType: decodedConfirmationMethod.verificationType,
              )
        : missionVerificationStatusFromLegacyStatus(
            status: decodedStatus,
            verificationType: decodedConfirmationMethod.verificationType,
          );

    return TodayMission(
      title: title,
      category: decodedCategory,
      resetPeriod: decodedResetPeriod,
      confirmationMethod: decodedConfirmationMethod,
      rewardMinutes: rewardMinutes,
      description: description,
      status: decodedVerificationStatus.legacyStatus,
      verificationStatus: decodedVerificationStatus,
      submittedAtText: submittedAtText is String ? submittedAtText : null,
    );
  }

  static T? _decodeEnum<T extends Enum>(List<T> values, String name) {
    for (final T value in values) {
      if (value.name == name) {
        return value;
      }
    }
    return null;
  }
}
