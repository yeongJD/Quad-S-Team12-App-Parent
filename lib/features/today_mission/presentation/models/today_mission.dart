enum MissionCategory { routine, study, exercise, cleaning, errand }

const List<MissionCategory> missionCreateCategoryOptions = <MissionCategory>[
  MissionCategory.study,
  MissionCategory.exercise,
  MissionCategory.cleaning,
];

enum MissionResetPeriod { daily, weekly, monthly }

enum MissionConfirmationMethod { ai, child, parent }

enum TodayMissionStatus { pending, reviewing, completed, rejected }

enum MissionVerificationType { parent, self, ai }

enum MissionVerificationStatus {
  idle,
  waitingParentApproval,
  waitingAiVerification,
  approved,
  rejected,
}

class TodayMission {
  const TodayMission({
    this.missionId,
    this.performanceId,
    required this.title,
    required this.category,
    required this.resetPeriod,
    required this.confirmationMethod,
    required this.rewardMinutes,
    required this.description,
    this.status = TodayMissionStatus.pending,
    this.verificationStatus = MissionVerificationStatus.idle,
    this.submittedAtText,
    this.proofImageUrl,
  });

  final String? missionId;
  final String? performanceId;
  final String title;
  final MissionCategory category;
  final MissionResetPeriod resetPeriod;
  final MissionConfirmationMethod confirmationMethod;
  final int rewardMinutes;
  final String description;
  final TodayMissionStatus status;
  final MissionVerificationStatus verificationStatus;
  final String? submittedAtText;
  final String? proofImageUrl;

  MissionVerificationType get verificationType {
    return confirmationMethod.verificationType;
  }

  MissionVerificationStatus get effectiveVerificationStatus {
    if (verificationStatus != MissionVerificationStatus.idle ||
        status == TodayMissionStatus.pending) {
      return verificationStatus;
    }
    return missionVerificationStatusFromLegacyStatus(
      status: status,
      verificationType: verificationType,
    );
  }

  TodayMissionStatus get effectiveStatus {
    return effectiveVerificationStatus.legacyStatus;
  }

  TodayMission copyWith({
    String? missionId,
    String? performanceId,
    String? title,
    MissionCategory? category,
    MissionResetPeriod? resetPeriod,
    MissionConfirmationMethod? confirmationMethod,
    int? rewardMinutes,
    String? description,
    TodayMissionStatus? status,
    MissionVerificationStatus? verificationStatus,
    String? submittedAtText,
    String? proofImageUrl,
  }) {
    final MissionConfirmationMethod nextConfirmationMethod =
        confirmationMethod ?? this.confirmationMethod;
    final MissionVerificationStatus nextVerificationStatus =
        verificationStatus ??
        (status == null
            ? this.verificationStatus
            : missionVerificationStatusFromLegacyStatus(
                status: status,
                verificationType: nextConfirmationMethod.verificationType,
              ));

    return TodayMission(
      missionId: missionId ?? this.missionId,
      performanceId: performanceId ?? this.performanceId,
      title: title ?? this.title,
      category: category ?? this.category,
      resetPeriod: resetPeriod ?? this.resetPeriod,
      confirmationMethod: nextConfirmationMethod,
      rewardMinutes: rewardMinutes ?? this.rewardMinutes,
      description: description ?? this.description,
      status: status ?? nextVerificationStatus.legacyStatus,
      verificationStatus: nextVerificationStatus,
      submittedAtText: submittedAtText ?? this.submittedAtText,
      proofImageUrl: proofImageUrl ?? this.proofImageUrl,
    );
  }

  String get rewardLabel {
    final int hours = rewardMinutes ~/ 60;
    final int minutes = rewardMinutes % 60;
    if (hours > 0 && minutes > 0) {
      return '$hours시간 $minutes분 지급';
    }
    if (hours > 0) {
      return '$hours시간 지급';
    }
    return '$minutes분 지급';
  }
}

extension MissionVerificationStatusX on MissionVerificationStatus {
  TodayMissionStatus get legacyStatus {
    switch (this) {
      case MissionVerificationStatus.idle:
        return TodayMissionStatus.pending;
      case MissionVerificationStatus.waitingParentApproval:
      case MissionVerificationStatus.waitingAiVerification:
        return TodayMissionStatus.reviewing;
      case MissionVerificationStatus.approved:
        return TodayMissionStatus.completed;
      case MissionVerificationStatus.rejected:
        return TodayMissionStatus.rejected;
    }
  }

  String get label {
    switch (this) {
      case MissionVerificationStatus.idle:
        return '수행 대기';
      case MissionVerificationStatus.waitingParentApproval:
        return '부모 확인 대기중';
      case MissionVerificationStatus.waitingAiVerification:
        return 'AI 확인 대기중';
      case MissionVerificationStatus.approved:
        return '수행완료';
      case MissionVerificationStatus.rejected:
        return '반려';
    }
  }
}

MissionVerificationStatus missionVerificationStatusFromLegacyStatus({
  required TodayMissionStatus status,
  required MissionVerificationType verificationType,
}) {
  switch (status) {
    case TodayMissionStatus.pending:
      return MissionVerificationStatus.idle;
    case TodayMissionStatus.reviewing:
      return switch (verificationType) {
        MissionVerificationType.parent =>
          MissionVerificationStatus.waitingParentApproval,
        MissionVerificationType.ai =>
          MissionVerificationStatus.waitingAiVerification,
        MissionVerificationType.self => MissionVerificationStatus.approved,
      };
    case TodayMissionStatus.completed:
      return MissionVerificationStatus.approved;
    case TodayMissionStatus.rejected:
      return MissionVerificationStatus.rejected;
  }
}

extension TodayMissionStatusLabel on TodayMissionStatus {
  String get label {
    switch (this) {
      case TodayMissionStatus.pending:
        return '수행전';
      case TodayMissionStatus.reviewing:
        return '확인중';
      case TodayMissionStatus.completed:
        return '수행완료';
      case TodayMissionStatus.rejected:
        return '반려';
    }
  }
}

extension MissionCategoryLabel on MissionCategory {
  String get label {
    switch (this) {
      case MissionCategory.routine:
        return '루틴';
      case MissionCategory.study:
        return '공부';
      case MissionCategory.exercise:
        return '운동';
      case MissionCategory.cleaning:
        return '청소';
      case MissionCategory.errand:
        return '심부름';
    }
  }

  String get iconAsset {
    switch (this) {
      case MissionCategory.routine:
        return 'assets/icons/루틴.svg';
      case MissionCategory.study:
        return 'assets/icons/학습.svg';
      case MissionCategory.exercise:
        return 'assets/icons/운동.svg';
      case MissionCategory.cleaning:
        return 'assets/icons/청소.svg';
      case MissionCategory.errand:
        return 'assets/icons/심부름.svg';
    }
  }
}

extension MissionCategoryBackendWire on MissionCategory {
  String? get backendCreateName {
    switch (this) {
      case MissionCategory.study:
        return 'STUDY';
      case MissionCategory.exercise:
        return 'EXERCISE';
      case MissionCategory.cleaning:
        return 'CLEANING';
      case MissionCategory.routine:
      case MissionCategory.errand:
        return null;
    }
  }
}

extension MissionResetPeriodLabel on MissionResetPeriod {
  String get label {
    switch (this) {
      case MissionResetPeriod.daily:
        return '매일';
      case MissionResetPeriod.weekly:
        return '일주일';
      case MissionResetPeriod.monthly:
        return '한 달';
    }
  }
}

extension MissionConfirmationMethodLabel on MissionConfirmationMethod {
  String get label {
    switch (this) {
      case MissionConfirmationMethod.ai:
        return 'AI 자동확인';
      case MissionConfirmationMethod.child:
        return '자녀 확인';
      case MissionConfirmationMethod.parent:
        return '부모 확인';
    }
  }

  MissionVerificationType get verificationType {
    switch (this) {
      case MissionConfirmationMethod.ai:
        return MissionVerificationType.ai;
      case MissionConfirmationMethod.child:
        return MissionVerificationType.self;
      case MissionConfirmationMethod.parent:
        return MissionVerificationType.parent;
    }
  }
}
