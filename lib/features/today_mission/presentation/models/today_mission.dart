enum MissionCategory { routine, study, exercise, cleaning, errand }

enum MissionResetPeriod { daily, weekly, monthly }

enum MissionConfirmationMethod { ai, child, parent }

class TodayMission {
  const TodayMission({
    required this.title,
    required this.category,
    required this.resetPeriod,
    required this.confirmationMethod,
    required this.rewardMinutes,
    required this.description,
  });

  final String title;
  final MissionCategory category;
  final MissionResetPeriod resetPeriod;
  final MissionConfirmationMethod confirmationMethod;
  final int rewardMinutes;
  final String description;

  String get rewardLabel => '$rewardMinutes분 지급';
}

extension MissionCategoryLabel on MissionCategory {
  String get label {
    switch (this) {
      case MissionCategory.routine:
        return '루틴';
      case MissionCategory.study:
        return '학습';
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
}
