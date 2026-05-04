import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../styles/time_setup_tokens.dart';

class TimeSetupTopBar extends StatelessWidget {
  const TimeSetupTopBar({super.key, required this.title, required this.onBack});

  final String title;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: TimeSetupSpacing.topBarHeight,
      child: Stack(
        children: [
          Center(child: Text(title, style: TimeSetupTextStyles.pageTitle)),
          Positioned(
            left: TimeSetupSpacing.horizontalPadding,
            top: 14,
            child: GestureDetector(
              onTap: onBack,
              behavior: HitTestBehavior.opaque,
              child: SizedBox(
                width: 24,
                height: 24,
                child: Padding(
                  padding: const EdgeInsets.all(2),
                  child: SvgPicture.asset('assets/icons/cmp/btn/back.svg'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
