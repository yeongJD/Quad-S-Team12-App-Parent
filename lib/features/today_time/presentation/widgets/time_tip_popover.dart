import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

class TimeTipPopover extends StatelessWidget {
  const TimeTipPopover({super.key, required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Align(
          alignment: Alignment.topCenter,
          child: Transform.translate(
            offset: const Offset(0, -5),
            child: CustomPaint(
              size: const Size(12, 8),
              painter: TipCaretPainter(),
            ),
          ),
        ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
          decoration: BoxDecoration(
            color: AppColors.gray600,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Stack(
            children: [
              const Padding(
                padding: EdgeInsets.only(right: 16),
                child: _TipContent(),
              ),
              Positioned(
                right: 0,
                top: 0,
                child: GestureDetector(
                  onTap: onClose,
                  behavior: HitTestBehavior.opaque,
                  child: const Icon(
                    Icons.close_rounded,
                    size: 18,
                    color: AppColors.gray200,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TipContent extends StatelessWidget {
  const _TipContent();

  @override
  Widget build(BuildContext context) {
    final TextStyle titleStyle = AppTypography.bodyMedium.copyWith(
      fontSize: 16,
      height: 1.5,
      letterSpacing: 0,
      color: AppColors.gray100,
    );
    final TextStyle bodyStyle = AppTypography.captionRegular.copyWith(
      fontSize: 14,
      height: 1.429,
      letterSpacing: 0,
      color: AppColors.gray100,
    );
    final TextStyle boldStyle = AppTypography.labelBold.copyWith(
      fontSize: 14,
      height: 1.429,
      letterSpacing: 0,
      color: AppColors.gray100,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('적절한 사용 시간이 고민되시나요?', style: titleStyle),
        const SizedBox(height: 14),
        Text('1. 초등 고학년 권장 스마트폰 사용 시간', style: boldStyle),
        Text('주중 약 55분 / 주말 약 80분', style: bodyStyle),
        const SizedBox(height: 12),
        Text(
          '*대한소아청소년의학회의 정신건강의학과 전문의 121명\n'
          '대상 설문 조사 결과 (2014)\n'
          '*학습앱, 전화, 문자 기본앱 사용 제외',
          style: AppTypography.labelRegular.copyWith(
            fontSize: 12,
            height: 1.334,
            letterSpacing: 0,
            color: AppColors.gray100,
          ),
        ),
        const SizedBox(height: 22),
        Text('2. 또래 평균 스마트폰 사용 시간', style: boldStyle),
        Text('약 2시간', style: bodyStyle),
        const SizedBox(height: 24),
        Text(
          '위 기준을 참고해 자녀의 생활 패턴에 맞는\n'
          '사용 시간을 설정해 보세요.',
          style: bodyStyle,
        ),
        const SizedBox(height: 26),
        RichText(
          text: TextSpan(
            style: bodyStyle,
            children: const [
              TextSpan(text: '더 많은 정보 보기: 스마트쉼센터 '),
              TextSpan(
                text: 'https://www.iapc.or.kr',
                style: TextStyle(
                  decoration: TextDecoration.underline,
                  decorationColor: AppColors.gray100,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class TipCaretPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()..color = AppColors.gray600;
    final Path path = Path()
      ..moveTo(size.width / 2, 0)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
