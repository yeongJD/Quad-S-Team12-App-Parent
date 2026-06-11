import 'dart:convert';
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
              key: ValueKey<String>('child-selector-card-$index'),
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
    super.key,
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
    final Color feedbackColor = isDeleteVisible
        ? AppColors.destructive
        : isSelected
        ? AppColors.primary
        : AppColors.gray700;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: Colors.transparent,
          shape: const CircleBorder(),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: isDeleteVisible ? onDeleteTap : onTap,
            hoverColor: feedbackColor.withValues(alpha: 0.06),
            highlightColor: feedbackColor.withValues(alpha: 0.10),
            splashColor: feedbackColor.withValues(alpha: 0.12),
            customBorder: const CircleBorder(),
            child: _ChildAvatar(
              isSelected: isSelected || isDeleteVisible,
              isDeleteVisible: isDeleteVisible,
              photoBase64: child.photoBase64,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          child.name,
          style: AppTypography.labelMedium.copyWith(color: AppColors.gray700),
        ),
      ],
    );
  }
}

class _ChildAvatar extends StatelessWidget {
  const _ChildAvatar({
    required this.isSelected,
    required this.isDeleteVisible,
    this.photoBase64,
  });

  static const double _childAvatarSize = 74;
  static const String _unselectedAsset = 'assets/icons/속성 1=미선택.png';
  static const String _selectedAsset = 'assets/icons/속성 1=선택.png';
  static const String _deleteAsset = 'assets/icons/속성 1=삭제.png';

  final bool isSelected;
  final bool isDeleteVisible;
  final String? photoBase64;

  String get _assetPath {
    if (isDeleteVisible) {
      return _deleteAsset;
    }
    return isSelected ? _selectedAsset : _unselectedAsset;
  }

  @override
  Widget build(BuildContext context) {
    final ImageProvider? photoImage = _resolvePhotoImage();
    if (!isDeleteVisible && photoImage != null) {
      return Container(
        width: _childAvatarSize,
        height: _childAvatarSize,
        padding: EdgeInsets.all(isSelected ? 3 : 0),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: isSelected
              ? Border.all(color: AppColors.primary, width: 3)
              : null,
        ),
        child: ClipOval(
          child: Image(
            image: photoImage,
            width: _childAvatarSize,
            height: _childAvatarSize,
            fit: BoxFit.cover,
            errorBuilder: (BuildContext context, Object error, StackTrace? _) =>
                Image.asset(_assetPath, fit: BoxFit.contain),
          ),
        ),
      );
    }

    return SizedBox(
      width: _childAvatarSize,
      height: _childAvatarSize,
      child: Image.asset(_assetPath, fit: BoxFit.contain),
    );
  }

  /// Resolves the avatar source: a presigned HTTP(S) URL from the backend
  /// (`profileImageUrl`) renders via [NetworkImage]; a base64 payload (mock /
  /// local pick) via [MemoryImage]. Returns null when neither applies.
  ImageProvider? _resolvePhotoImage() {
    final String? value = photoBase64;
    if (value == null || value.isEmpty) {
      return null;
    }
    if (value.startsWith('http://') || value.startsWith('https://')) {
      return NetworkImage(value);
    }
    try {
      return MemoryImage(base64Decode(value));
    } on FormatException {
      return null;
    }
  }
}

class _AddChildCard extends StatefulWidget {
  const _AddChildCard({required this.onTap, this.isEmptyState = false});

  final VoidCallback onTap;
  final bool isEmptyState;

  @override
  State<_AddChildCard> createState() => _AddChildCardState();
}

class _AddChildCardState extends State<_AddChildCard> {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final double size = widget.isEmptyState ? 74 : 67;
    final double innerSize = widget.isEmptyState ? 64 : 58;
    final Color dashColor = widget.isEmptyState
        ? const Color(0xFFC2DFFD)
        : AppColors.gray200;
    final Color fillColor = widget.isEmptyState
        ? AppColors.primaryLight
        : AppColors.gray100;
    final Color feedbackColor = widget.isEmptyState
        ? AppColors.primary
        : AppColors.gray500;
    final double overlayAlpha = _isPressed
        ? 0.14
        : _isHovered
        ? 0.08
        : 0;
    final Color interactiveFillColor = Color.alphaBlend(
      feedbackColor.withValues(alpha: overlayAlpha),
      fillColor,
    );
    final Color plusColor = widget.isEmptyState
        ? AppColors.primary
        : AppColors.gray400;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: Colors.transparent,
          shape: const CircleBorder(),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: widget.onTap,
            onHover: (bool isHovered) => setState(() => _isHovered = isHovered),
            onHighlightChanged: (bool isPressed) =>
                setState(() => _isPressed = isPressed),
            hoverColor: feedbackColor.withValues(alpha: 0.04),
            highlightColor: feedbackColor.withValues(alpha: 0.06),
            splashColor: feedbackColor.withValues(alpha: 0.10),
            customBorder: const CircleBorder(),
            child: SizedBox(
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
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 120),
                    width: innerSize,
                    height: innerSize,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: interactiveFillColor,
                    ),
                    child: Center(child: _PlusIcon(color: plusColor, size: 22)),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '추가',
          style:
              (widget.isEmptyState
                      ? AppTypography.bodyMedium
                      : AppTypography.labelMedium)
                  .copyWith(color: AppColors.gray400),
        ),
      ],
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
    final BorderRadius strokeRadius = BorderRadius.circular(stroke / 2);

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: stroke,
            height: size * 0.75,
            decoration: BoxDecoration(color: color, borderRadius: strokeRadius),
          ),
          Container(
            width: size * 0.75,
            height: stroke,
            decoration: BoxDecoration(color: color, borderRadius: strokeRadius),
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
