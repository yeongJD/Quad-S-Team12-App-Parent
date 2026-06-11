import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/theme/app_typography.dart';

abstract final class TimeSetupSpacing {
  static const double screenMaxWidth = AppTokens.mobileFrameWidth;
  static const double horizontalPadding = AppTokens.pageHorizontal;
  static const double topBarHeight = AppTokens.topBarHeight;
  static const double contentTopGap = 14;
  static const double titleToDescriptionGap = 12;
  static const double emptyAddTopGap = 40;
  static const double listTopGap = 30;
  static const double bottomButtonGap = 31;
  static const double sheetHorizontalPadding = AppTokens.pageHorizontal;
  static const double sheetTopPadding = 38;
  static const double sheetSectionGap = 32;
  static const double sheetLabelGap = 10;
  static const double sheetButtonBottom = 63;
  static const double pickerTitleTop = 27;
  static const double pickerHighlightTop = 128;
  static const double pickerTop = 80;
  static const double pickerHorizontalInset = 62;
}

abstract final class TimeSetupSize {
  static const double timeSheetHeightRatio = 0.45;
  static const double addButton = 40;
  static const double addIcon = 24;
  static const double bottomButtonHeight = 54;
  static const double ruleSheetHeight = AppTokens.bottomSheetHeight;
  static const double pickerSheetHeight = AppTokens.bottomSheetHeight;
  static const double dayChip = 40;
  static const double fieldHeight = 50;
  static const double pickerHeight = 148;
  static const double pickerColumnWidth = 56;
  static const double pickerItemExtent = 48;
}

abstract final class TimeSetupRadius {
  static const double control = AppTokens.buttonRadius;
  static const double field = AppTokens.fieldRadius;
  static const double card = AppTokens.cardRadiusSmall;
  static const double sheet = AppTokens.bottomSheetTopRadius;
}

abstract final class TimeSetupPalette {
  static const Color tipBackground = AppColors.primaryLight;
  static const Color popoverBackground = Color(0xFF666A6F);
  static const Color disabledButton = AppColors.gray200;
  static const Color disabledText = AppColors.gray300;
  static const Color mutedAddBackground = AppColors.gray150;
}

abstract final class TimeSetupTextStyles {
  static TextStyle pageTitle = AppTypography.headlineMedium.copyWith(
    color: AppColors.inkBlack,
  );

  static TextStyle sectionTitle = AppTypography.heading1SemiBold.copyWith(
    color: AppColors.inkBlack,
  );

  static TextStyle description = AppTypography.labelMedium.copyWith(
    color: AppColors.gray500,
  );

  static TextStyle sheetLabel = AppTypography.headlineSemiBold.copyWith(
    color: AppColors.gray800,
  );

  static TextStyle timeNumber({required bool selected}) {
    return AppTypography.headlineSemiBold.copyWith(
      color: selected ? AppColors.primary : AppColors.gray300,
    );
  }

  static TextStyle confirmLabel({required bool enabled}) {
    return AppTypography.headlineMedium.copyWith(
      color: enabled ? AppColors.white : TimeSetupPalette.disabledText,
    );
  }
}
