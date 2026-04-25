import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/auth/auth_session.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  static const double _designWidth = 375;
  static const double _designHeight = 812;
  static const double _introTop = 250;
  static const double _introWidth = 294.897;
  static const double _introGap = 17.982;
  static const double _iconSize = 80.917;
  static const double _actionWidth = 293.998;
  static const double _actionBottom = 48.55;
  static const double _actionGap = 13.486;
  static const double _buttonHeight = 48.55;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    _redirectCachedLogin();
  }

  Future<void> _redirectCachedLogin() async {
    final bool isLoggedIn = await AuthSession.isLoggedIn();
    if (!mounted || !isLoggedIn) {
      return;
    }
    context.go('/parent-home');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.gray050,
      body: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final double xScale = constraints.maxWidth / HomePage._designWidth;
          final double yScale = constraints.maxHeight / HomePage._designHeight;

          return Stack(
            children: [
              Positioned(
                top: HomePage._introTop * yScale,
                left:
                    (constraints.maxWidth - (HomePage._introWidth * xScale)) /
                    2,
                width: HomePage._introWidth * xScale,
                child: _IntroSection(xScale: xScale, yScale: yScale),
              ),
              Positioned(
                left:
                    (constraints.maxWidth - (HomePage._actionWidth * xScale)) /
                    2,
                bottom: HomePage._actionBottom * yScale,
                width: HomePage._actionWidth * xScale,
                child: _ActionSection(xScale: xScale, yScale: yScale),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _IntroSection extends StatelessWidget {
  const _IntroSection({required this.xScale, required this.yScale});

  final double xScale;
  final double yScale;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Bridge',
          textAlign: TextAlign.center,
          style: GoogleFonts.sigmar(
            color: const Color(0xFFFF7D71),
            fontSize: 35.963 * xScale,
            fontStyle: FontStyle.normal,
            fontWeight: FontWeight.w400,
            height: 1.364,
            letterSpacing: -0.698 * xScale,
          ),
        ),
        SizedBox(height: HomePage._introGap * yScale),
        _LogoIcon(scaleX: xScale, scaleY: yScale),
        SizedBox(height: HomePage._introGap * yScale),
        Text(
          '통제를 넘어 자율로,\n자기주도적 스마트폰 사용의 시작',
          textAlign: TextAlign.center,
          style: AppTypography.heading2Regular.copyWith(
            color: AppColors.gray600,
            fontSize: 17.982 * xScale,
            height: 1.4,
            letterSpacing: -0.216 * xScale,
          ),
        ),
      ],
    );
  }
}

class _LogoIcon extends StatelessWidget {
  const _LogoIcon({required this.scaleX, required this.scaleY});

  final double scaleX;
  final double scaleY;

  @override
  Widget build(BuildContext context) {
    final double iconSize = HomePage._iconSize * scaleX;

    return SizedBox(
      width: iconSize,
      height: iconSize,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: SvgPicture.asset(
              'assets/icons/Icon container.svg',
              width: iconSize,
              height: iconSize,
            ),
          ),
          Positioned(
            left: 69.23 * scaleX,
            top: 64.6 * scaleY,
            child: Text(
              'P',
              textAlign: TextAlign.center,
              style: AppTypography.captionMedium.copyWith(
                fontSize: 10.789 * scaleX,
                height: 1.334,
                letterSpacing: 0.272 * scaleX,
                color: Colors.white.withValues(alpha: 0.5),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionSection extends StatelessWidget {
  const _ActionSection({required this.xScale, required this.yScale});

  final double xScale;
  final double yScale;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: double.infinity,
          height: HomePage._buttonHeight * yScale,
          child: FilledButton(
            onPressed: () => context.push('/signup'),
            style: FilledButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: 13.486 * yScale),
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8 * xScale),
              ),
            ),
            child: Text(
              '부모 회원가입',
              style: AppTypography.headlineMedium.copyWith(
                color: AppColors.white,
                fontSize: 16.18 * xScale,
                fontWeight: FontWeight.w500,
                height: 1.445,
                letterSpacing: -0.0032 * xScale,
              ),
            ),
          ),
        ),
        SizedBox(height: HomePage._actionGap * yScale),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '이미 계정이 있나요?  ',
              style: AppTypography.labelMedium.copyWith(
                fontSize: 14.385 * xScale,
                fontWeight: FontWeight.w500,
                height: 1.5,
                letterSpacing: 0.082 * xScale,
                color: AppColors.gray400,
              ),
            ),
            GestureDetector(
              onTap: () => context.push('/login'),
              behavior: HitTestBehavior.opaque,
              child: Text(
                '로그인',
                style: AppTypography.labelMedium.copyWith(
                  fontSize: 14.385 * xScale,
                  fontWeight: FontWeight.w500,
                  height: 1.5,
                  letterSpacing: 0.082 * xScale,
                  color: AppColors.gray800,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
