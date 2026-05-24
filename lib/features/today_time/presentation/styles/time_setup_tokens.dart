import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

abstract final class TimeSetupSpacing {
  static const double screenMaxWidth = 375;
  static const double horizontalPadding = 24;
  static const double topBarHeight = 52;
  static const double contentTopGap = 14;
  static const double titleToDescriptionGap = 12;
  static const double emptyAddTopGap = 40;
  static const double listTopGap = 30;
  static const double bottomButtonGap = 31;
  static const double sheetHorizontalPadding = 24;
  static const double sheetTopPadding = 38;
  static const double sheetSectionGap = 32;
  static const double sheetLabelGap = 10;
  static const double sheetButtonBottom = 63;
  static const double pickerTitleTop = 27;
  static const double pickerHighlightTop = 128;
  static const double pickerTop = 80;
}

abstract final class TimeSetupSize {
  static const double timeSheetHeightRatio = 0.45;
  static const double addButton = 40;
  static const double addIcon = 24;
  static const double bottomButtonHeight = 54;
  static const double ruleSheetHeight = 397;
  static const double pickerSheetHeight = 397;
  static const double dayChip = 40;
  static const double fieldHeight = 50;
  static const double pickerHeight = 148;
  static const double pickerColumnWidth = 56;
  static const double pickerItemExtent = 48;
}

abstract final class TimeSetupRadius {
  static const double control = 8;
  static const double field = 12;
  static const double card = 16;
  static const double sheet = 24;
}

abstract final class TimeSetupPalette {
  static const Color tipBackground = Color(0xFFEBF5FE);
  static const Color popoverBackground = Color(0xFF666A6F);
  static const Color disabledButton = AppColors.gray200;
  static const Color disabledText = AppColors.gray300;
  static const Color mutedAddBackground = Color(0xFFEDEEF1);
}

abstract final class TimeSetupTextStyles {
  static TextStyle pageTitle = AppTypography.headlineMedium.copyWith(
    fontSize: 18,
    height: 1.445,
    letterSpacing: 0,
    color: const Color(0xFF050505),
  );

  static TextStyle sectionTitle = AppTypography.heading1Bold.copyWith(
    fontSize: 24,
    height: 1.364,
    letterSpacing: 0,
    color: const Color(0xFF050505),
  );

  static TextStyle description = AppTypography.labelMedium.copyWith(
    fontSize: 14,
    height: 1.429,
    letterSpacing: 0,
    color: AppColors.gray500,
  );

  static TextStyle sheetLabel = AppTypography.headlineBold.copyWith(
    fontSize: 18,
    height: 1.445,
    letterSpacing: 0,
    color: AppColors.gray800,
  );

  static TextStyle timeNumber({required bool selected}) {
    return AppTypography.headlineBold.copyWith(
      fontSize: 18,
      height: 1.445,
      letterSpacing: 0,
      color: selected ? AppColors.primary : AppColors.gray300,
    );
  }

  static TextStyle confirmLabel({required bool enabled}) {
    return AppTypography.headlineMedium.copyWith(
      fontSize: 18,
      height: 1.445,
      letterSpacing: 0,
      color: enabled ? AppColors.white : TimeSetupPalette.disabledText,
    );
  }
}
