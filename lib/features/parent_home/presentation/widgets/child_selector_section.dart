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
    required this.onChildDelete,
    required this.onAddChildTap,
    this.deleteIndex,
  });

  final List<ParentHomeChild> children;
  final int selectedIndex;
  final int? deleteIndex;
  final ValueChanged<int> onChildTap;
  final ValueChanged<int> onChildDelete;
  final VoidCallback onAddChildTap;

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.zero,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [_AddChildCard(onTap: onAddChildTap, isEmptyState: true)],
        ),
      );
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
              isDeleteVisible: index == deleteIndex,
              onTap: () => onChildTap(index),
              onDeleteTap: () => onChildDelete(index),
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
    required this.isDeleteVisible,
    required this.onTap,
    required this.onDeleteTap,
  });

  final ParentHomeChild child;
  final bool isSelected;
  final bool isDeleteVisible;
  final VoidCallback onTap;
  final VoidCallback onDeleteTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isDeleteVisible ? onDeleteTap : onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ChildAvatar(
            isSelected: isSelected || isDeleteVisible,
            isDeleteVisible: isDeleteVisible,
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

class _ChildAvatar extends StatelessWidget {
  const _ChildAvatar({required this.isSelected, required this.isDeleteVisible});

  static const double _childAvatarSize = 74;
  static const String _unselectedAsset = 'assets/icons/속성 1=미선택.png';
  static const String _selectedAsset = 'assets/icons/속성 1=선택.png';
  static const String _deleteAsset = 'assets/icons/속성 1=삭제.png';

  final bool isSelected;
  final bool isDeleteVisible;

  String get _assetPath {
    if (isDeleteVisible) {
      return _deleteAsset;
    }
    return isSelected ? _selectedAsset : _unselectedAsset;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _childAvatarSize,
      height: _childAvatarSize,
      child: Image.asset(_assetPath, fit: BoxFit.contain),
    );
  }
}

class _AddChildCard extends StatelessWidget {
  const _AddChildCard({required this.onTap, this.isEmptyState = false});

  final VoidCallback onTap;
  final bool isEmptyState;

  @override
  Widget build(BuildContext context) {
    final double size = isEmptyState ? 74 : 66.532;
    final double innerSize = isEmptyState ? 64 : 57.541;
    final Color dashColor = isEmptyState
        ? const Color(0xFFC2DFFD)
        : AppColors.gray200;
    final Color fillColor = isEmptyState
        ? const Color(0xFFEBF5FE)
        : const Color(0xFFF0F2F5);
    final Color plusColor = isEmptyState
        ? AppColors.primary
        : AppColors.gray400;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: Size.square(size),
                  painter: _DashedCirclePainter(
                    color: dashColor,
                    strokeWidth: 2,
                  ),
                ),
                Container(
                  width: innerSize,
                  height: innerSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: fillColor,
                  ),
                  child: Center(
                    child: _PlusIcon(color: plusColor, size: 21.578),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '추가',
            style: AppTypography.labelMedium.copyWith(
              fontSize: isEmptyState ? 16 : 14.4,
              height: 1.5,
              letterSpacing: isEmptyState ? 0.0912 : 0.08,
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
