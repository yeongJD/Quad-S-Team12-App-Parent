import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';

/// A single-column wheel picker used inside the time bottom sheet.
///
/// Renders pre-formatted [values] in a vertical `ListWheelScrollView` where
/// the centered (selected) item is styled with [AppColors.gray800] and the
/// rest fade to [AppColors.gray200]. The selection band overlay (primary-
/// bordered viewport that spans both wheels) is drawn by the parent bottom
/// sheet, not by this widget.
class BridgeWheelPicker extends StatefulWidget {
  const BridgeWheelPicker({
    super.key,
    required this.values,
    required this.selectedIndex,
    required this.onChanged,
    this.itemWidth = 56,
    this.itemHeight = 50,
    this.visibleItems = 5,
  });

  final List<String> values;
  final int selectedIndex;
  final ValueChanged<int> onChanged;
  final double itemWidth;
  final double itemHeight;
  final int visibleItems;

  @override
  State<BridgeWheelPicker> createState() => _BridgeWheelPickerState();
}

class _BridgeWheelPickerState extends State<BridgeWheelPicker> {
  late FixedExtentScrollController _controller;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.selectedIndex;
    _controller = FixedExtentScrollController(initialItem: _currentIndex);
  }

  @override
  void didUpdateWidget(covariant BridgeWheelPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedIndex != _currentIndex) {
      _currentIndex = widget.selectedIndex;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (_controller.hasClients &&
            _controller.selectedItem != _currentIndex) {
          _controller.jumpToItem(_currentIndex);
        }
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleChanged(int index) {
    if (index == _currentIndex) return;
    setState(() => _currentIndex = index);
    widget.onChanged(index);
  }

  @override
  Widget build(BuildContext context) {
    assert(
      widget.visibleItems.isOdd,
      'visibleItems must be odd so one row is centered.',
    );

    return SizedBox(
      width: widget.itemWidth,
      height: widget.itemHeight * widget.visibleItems,
      child: ListWheelScrollView.useDelegate(
        controller: _controller,
        itemExtent: widget.itemHeight,
        physics: const FixedExtentScrollPhysics(),
        useMagnifier: false,
        diameterRatio: 1.6,
        perspective: 0.003,
        onSelectedItemChanged: _handleChanged,
        childDelegate: ListWheelChildBuilderDelegate(
          childCount: widget.values.length,
          builder: (context, index) {
            if (index < 0 || index >= widget.values.length) return null;
            final bool isSelected = index == _currentIndex;
            return Center(
              child: Text(
                widget.values[index],
                style: AppTypography.heading1Bold.copyWith(
                  color: isSelected ? AppColors.gray800 : AppColors.gray200,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
