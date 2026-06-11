import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/theme/app_typography.dart';

class MissionTopBar extends StatelessWidget {
  const MissionTopBar({super.key, this.title = '미션 목록', required this.onBack});

  final String title;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AppTokens.topBarHeight,
      child: Stack(
        children: [
          Center(
            child: Text(
              title,
              style: AppTypography.headlineMedium.copyWith(
                color: AppColors.inkBlack,
              ),
            ),
          ),
          Positioned(
            left: AppTokens.pageHorizontal,
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
                      colorFilter: const ColorFilter.mode(
                        AppColors.black,
                        BlendMode.srcIn,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
