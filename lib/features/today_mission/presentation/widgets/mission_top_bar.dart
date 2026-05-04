import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

class MissionTopBar extends StatelessWidget {
  const MissionTopBar({super.key, this.title = '미션 목록', required this.onBack});

  final String title;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: Stack(
        children: [
          Center(
            child: Text(
              title,
              style: AppTypography.headlineMedium.copyWith(
                fontSize: 18,
                height: 1.445,
                letterSpacing: 0,
                color: const Color(0xFF050505),
              ),
            ),
          ),
          Positioned(
            left: 24,
            top: 14,
            child: GestureDetector(
              onTap: onBack,
              behavior: HitTestBehavior.opaque,
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
        ],
      ),
    );
  }
}
