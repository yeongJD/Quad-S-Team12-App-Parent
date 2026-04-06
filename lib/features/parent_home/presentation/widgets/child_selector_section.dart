import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../models/parent_home_models.dart';

class ChildSelectorSection extends StatelessWidget {
  const ChildSelectorSection({
    super.key,
    required this.children,
    required this.selectedIndex,
    required this.onChildTap,
    required this.onAddChildTap,
  });

  final List<ParentHomeChild> children;
  final int selectedIndex;
  final ValueChanged<int> onChildTap;
  final VoidCallback onAddChildTap;

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) {
      return Row(children: [_AddChildCard(onTap: onAddChildTap)]);
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.zero,
      child: Row(
        children: [
          for (int index = 0; index < children.length; index++) ...[
            _ChildCard(
              child: children[index],
              isSelected: index == selectedIndex,
              onTap: () => onChildTap(index),
            ),
            const SizedBox(width: 18),
          ],
          _AddChildCard(onTap: onAddChildTap),
        ],
      ),
    );
  }
}

class _ChildCard extends StatelessWidget {
  const _ChildCard({
    required this.child,
    required this.isSelected,
    required this.onTap,
  });

  final ParentHomeChild child;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 66.532,
            height: 66.532,
            padding: const EdgeInsets.all(4.5),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? AppColors.primary : AppColors.gray200,
                width: isSelected ? 2 : 1.4,
              ),
            ),
            child: DecoratedBox(
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFFDADDE3),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Positioned(
                    top: 10,
                    child: Container(
                      width: 18,
                      height: 18,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFFF6F7F9),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 8,
                    child: Container(
                      width: 34,
                      height: 22,
                      decoration: const BoxDecoration(
                        color: Color(0xFFF6F7F9),
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(16),
                          bottom: Radius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            child.name,
            style: AppTypography.labelMedium.copyWith(
              fontSize: 14.4,
              height: 1.5,
              letterSpacing: 0.08,
              color: AppColors.gray700,
            ),
          ),
        ],
      ),
    );
  }
}

class _AddChildCard extends StatelessWidget {
  const _AddChildCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 66.532,
            height: 66.532,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: const Size.square(66.532),
                  painter: _DashedCirclePainter(
                    color: AppColors.gray200,
                    strokeWidth: 2,
                  ),
                ),
                Container(
                  width: 57.541,
                  height: 57.541,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFFF0F2F5),
                  ),
                  child: const Center(
                    child: _PlusIcon(color: AppColors.gray400, size: 21.578),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '추가',
            style: AppTypography.labelMedium.copyWith(
              fontSize: 14.4,
              height: 1.5,
              letterSpacing: 0.08,
              color: AppColors.gray400,
            ),
          ),
        ],
      ),
    );
  }
}

class _PlusIcon extends StatelessWidget {
  const _PlusIcon({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    final double stroke = size * 0.085;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: stroke,
            height: size * 0.75,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          Container(
            width: size * 0.75,
            height: stroke,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ],
      ),
    );
  }
}

class _DashedCirclePainter extends CustomPainter {
  const _DashedCirclePainter({required this.color, required this.strokeWidth});

  final Color color;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final Rect rect = Offset.zero & size;
    const double dashLength = 5;
    const double gapLength = 4;
    final double radius = size.width / 2;
    final double circumference = 2 * math.pi * radius;
    final double step = (dashLength + gapLength) / circumference * 2 * math.pi;
    final double sweep = dashLength / circumference * 2 * math.pi;

    for (double start = -math.pi / 2; start < 1.5 * math.pi; start += step) {
      canvas.drawArc(rect.deflate(strokeWidth / 2), start, sweep, false, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _DashedCirclePainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.strokeWidth != strokeWidth;
  }
}
