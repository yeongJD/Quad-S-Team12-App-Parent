import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/auth/auth_session.dart';
import '../../../../core/child/child_connection_store.dart';
import '../../../../core/models/result.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../data/models/child/child_summary.dart';
import '../../../../data/repositories/child_repository.dart';

abstract final class _ChildAddMetrics {
  static const double screenMaxWidth = 375;
  static const double horizontalPadding = AppTokens.mobileHorizontalPadding;
  static const double topBarHeight = AppTokens.topBarHeight;
  static const double photoTopGap = 50;
  static const double photoSize = 74;
  static const double photoInnerSize = 64;
  static const double photoLabelGap = 12;
  static const double photoToFormGap = 31;
  static const double formGap = 16;
  static const double labelToFieldGap = 10;
  static const double helperHeight = 18;
  static const double fieldHeight = 50;
  static const double fieldRadius = AppTokens.fieldRadius;
  static const double fieldHorizontalPadding = 16;
  static const double fieldVerticalPadding = 12;
  static const double buttonHeight = 54;
  static const double bottomButtonGap = 31;
  static const double sheetHeight = 397;
  static const double sheetRadius = AppTokens.bottomSheetTopRadius;
  static const double sheetTitleTop = 27;
  static const double sheetPickerTop = 82;
  static const double sheetPickerHeight = 168;
  static const double sheetPickerInset = 25.5;
  static const double sheetSelectionTop = 58.5;
  static const double sheetYearItemHeight = 50;
  static const double sheetYearSuffixOffset = 88;
  static const double sheetButtonBottom = 63;
}

class ChildAddPage extends StatefulWidget {
  const ChildAddPage({super.key});

  @override
  State<ChildAddPage> createState() => _ChildAddPageState();
}

class _ChildAddPageState extends State<ChildAddPage> {
  static const List<int> _birthYears = <int>[
    2014,
    2013,
    2012,
    2011,
    2010,
    2009,
    2008,
  ];

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _childCodeController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();
  final ChildRepository _childRepository = createChildRepository();

  Uint8List? _photoBytes;
  int? _selectedBirthYear;
  String? _nameErrorText;
  String? _childCodeErrorText;
  bool _showCodeTooltip = false;
  bool _isSubmitting = false;

  bool get _canSubmit =>
      _nameController.text.trim().isNotEmpty &&
      _selectedBirthYear != null &&
      _childCodeController.text.trim().isNotEmpty;

  bool get _isNameValid {
    final int length = _nameController.text.trim().characters.length;
    return length >= 2 && length <= 50;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _childCodeController.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final XFile? image = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 90,
    );
    if (image == null) {
      return;
    }

    final Uint8List bytes = await image.readAsBytes();
    if (!mounted) {
      return;
    }
    setState(() {
      _photoBytes = bytes;
    });
  }

  void _toggleTooltip() {
    setState(() {
      _showCodeTooltip = !_showCodeTooltip;
    });
  }

  Future<void> _openBirthYearSheet() async {
    final int initialYear = _selectedBirthYear ?? 2018;
    int pendingYear = initialYear;
    final int initialIndex = _birthYears.indexOf(initialYear);

    final int? selectedYear = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: AppColors.scrim,
      builder: (BuildContext context) {
        return _BirthYearBottomSheet(
          years: _birthYears,
          initialIndex: initialIndex < 0 ? 1 : initialIndex,
          onChanged: (int year) {
            pendingYear = year;
          },
          onConfirm: () => Navigator.of(context).pop(pendingYear),
        );
      },
    );

    if (selectedYear == null || !mounted) {
      return;
    }
    setState(() {
      _selectedBirthYear = selectedYear;
    });
  }

  Future<void> _submit() async {
    if (!_canSubmit || _isSubmitting) {
      return;
    }
    if (!_isNameValid) {
      setState(() {
        _nameErrorText = '이름은 2자 이상 10자 이내로 입력해주세요';
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _childCodeErrorText = null;
    });

    final String? parentId = await AuthSession.getCurrentParentId();
    if (parentId == null || parentId.isEmpty) {
      if (!mounted) {
        return;
      }
      context.go('/login');
      return;
    }

    final Result<ChildSummary> result = await _childRepository.addChild(
      parentId: parentId,
      childCode: _childCodeController.text.trim(),
      name: _nameController.text.trim(),
      birthYear: _selectedBirthYear,
      photoBase64: _photoBytes == null ? null : base64Encode(_photoBytes!),
    );
    if (!mounted) {
      return;
    }
    switch (result) {
      case Success<ChildSummary>():
        context.pop();
      case Failure<ChildSummary>(:final String message):
        setState(() {
          _isSubmitting = false;
          _childCodeErrorText = _mapAddChildFailure(message);
        });
        if (_childCodeErrorText == null) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(message)));
        }
    }
  }

  String? _mapAddChildFailure(String message) {
    if (message == ChildFailureMessages.invalidCode) {
      return '유효하지 않은 자녀코드입니다';
    }
    if (message == ChildFailureMessages.duplicateChild) {
      return '이미 등록된 자녀예요';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.gray100,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: _ChildAddMetrics.screenMaxWidth,
            ),
            child: Stack(
              children: [
                Column(
                  children: [
                    _ChildAddTopBar(onBack: context.pop),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(
                          _ChildAddMetrics.horizontalPadding,
                          _ChildAddMetrics.photoTopGap,
                          _ChildAddMetrics.horizontalPadding,
                          24,
                        ),
                        child: Column(
                          children: [
                            _PhotoPicker(
                              photoBytes: _photoBytes,
                              onTap: _pickPhoto,
                            ),
                            const SizedBox(
                              height: _ChildAddMetrics.photoToFormGap,
                            ),
                            Column(
                              children: [
                                _ChildAddTextField(
                                  label: '이름',
                                  controller: _nameController,
                                  hintText: '자녀의 이름을 입력해주세요',
                                  errorText: _nameErrorText,
                                  showClear: _nameErrorText != null,
                                  onClear: () {
                                    _nameController.clear();
                                    setState(() {
                                      _nameErrorText = null;
                                    });
                                  },
                                  onChanged: (_) {
                                    setState(() {
                                      _nameErrorText = null;
                                    });
                                  },
                                ),
                                const SizedBox(
                                  height: _ChildAddMetrics.formGap,
                                ),
                                _BirthYearField(
                                  selectedYear: _selectedBirthYear,
                                  onTap: _openBirthYearSheet,
                                ),
                                const SizedBox(
                                  height: _ChildAddMetrics.formGap,
                                ),
                                _ChildAddTextField(
                                  label: '자녀코드',
                                  controller: _childCodeController,
                                  hintText: '자녀 코드를 입력해주세요',
                                  errorText: _childCodeErrorText,
                                  showClear: _childCodeErrorText != null,
                                  onClear: () {
                                    _childCodeController.clear();
                                    setState(() {
                                      _childCodeErrorText = null;
                                    });
                                  },
                                  onChanged: (_) {
                                    setState(() {
                                      _childCodeErrorText = null;
                                    });
                                  },
                                  trailingLabel: GestureDetector(
                                    onTap: _toggleTooltip,
                                    behavior: HitTestBehavior.opaque,
                                    child: const Padding(
                                      padding: EdgeInsets.only(left: 4),
                                      child: Icon(
                                        Icons.help_outline_rounded,
                                        size: 16,
                                        color: AppColors.gray400,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        _ChildAddMetrics.horizontalPadding,
                        0,
                        _ChildAddMetrics.horizontalPadding,
                        _ChildAddMetrics.bottomButtonGap,
                      ),
                      child: _RegisterButton(
                        enabled: _canSubmit && !_isSubmitting,
                        onTap: _submit,
                      ),
                    ),
                  ],
                ),
                if (_showCodeTooltip)
                  Positioned(
                    left: 74,
                    top: _selectedBirthYear == null ? 536 : 520,
                    child: _ChildCodeTooltip(onClose: _toggleTooltip),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ChildAddTopBar extends StatelessWidget {
  const _ChildAddTopBar({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _ChildAddMetrics.topBarHeight,
      child: Stack(
        children: [
          Center(
            child: Text(
              '자녀등록',
              style: AppTypography.headlineMedium.copyWith(
                color: AppColors.inkBlack,
              ),
            ),
          ),
          Positioned(
            left: 20,
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
                    child: SvgPicture.asset('assets/icons/cmp/btn/back.svg'),
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

class _PhotoPicker extends StatefulWidget {
  const _PhotoPicker({required this.photoBytes, required this.onTap});

  final Uint8List? photoBytes;
  final VoidCallback onTap;

  @override
  State<_PhotoPicker> createState() => _PhotoPickerState();
}

class _PhotoPickerState extends State<_PhotoPicker> {
  bool _isHovered = false;
  bool _isPressed = false;

  bool get _isActive => _isHovered || _isPressed;

  void _setHovered(bool value) {
    if (_isHovered == value) {
      return;
    }
    setState(() {
      _isHovered = value;
      if (!value) {
        _isPressed = false;
      }
    });
  }

  void _setPressed(bool value) {
    if (_isPressed == value) {
      return;
    }
    setState(() {
      _isPressed = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    final Color borderColor = _isActive
        ? AppColors.gray400.withValues(alpha: _isPressed ? 0.72 : 0.55)
        : AppColors.gray200;
    final Color photoBackground = _isPressed
        ? AppColors.gray300
        : _isHovered
        ? AppColors.gray200
        : const Color(0xFFE1E4E9);
    final Color iconColor = _isActive ? AppColors.gray700 : AppColors.white;
    final Color labelColor = _isActive ? AppColors.gray800 : AppColors.gray600;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => _setHovered(true),
      onExit: (_) => _setHovered(false),
      child: GestureDetector(
        onTap: widget.onTap,
        onTapDown: (_) => _setPressed(true),
        onTapUp: (_) => _setPressed(false),
        onTapCancel: () => _setPressed(false),
        behavior: HitTestBehavior.opaque,
        child: AnimatedScale(
          scale: _isPressed ? 0.97 : 1,
          duration: const Duration(milliseconds: 90),
          curve: Curves.easeOut,
          child: Column(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 120),
                curve: Curves.easeOut,
                width: _ChildAddMetrics.photoSize,
                height: _ChildAddMetrics.photoSize,
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: borderColor, width: 2),
                  boxShadow: _isActive
                      ? <BoxShadow>[
                          BoxShadow(
                            color: AppColors.gray500.withValues(alpha: 0.14),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ]
                      : null,
                ),
                child: ClipOval(
                  child: widget.photoBytes == null
                      ? AnimatedContainer(
                          duration: const Duration(milliseconds: 120),
                          curve: Curves.easeOut,
                          color: photoBackground,
                          alignment: Alignment.center,
                          child: Icon(
                            Icons.image_outlined,
                            size: 24,
                            color: iconColor,
                          ),
                        )
                      : Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.memory(
                              widget.photoBytes!,
                              fit: BoxFit.cover,
                              width: _ChildAddMetrics.photoInnerSize,
                              height: _ChildAddMetrics.photoInnerSize,
                            ),
                            if (_isActive)
                              DecoratedBox(
                                decoration: BoxDecoration(
                                  color: AppColors.gray700.withValues(
                                    alpha: _isPressed ? 0.24 : 0.14,
                                  ),
                                ),
                                child: Icon(
                                  Icons.image_outlined,
                                  size: 24,
                                  color: AppColors.white.withValues(
                                    alpha: 0.92,
                                  ),
                                ),
                              ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: _ChildAddMetrics.photoLabelGap),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 120),
                curve: Curves.easeOut,
                style: AppTypography.bodyMedium.copyWith(color: labelColor),
                child: const Text('사진등록'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChildAddTextField extends StatelessWidget {
  const _ChildAddTextField({
    required this.label,
    required this.controller,
    required this.onChanged,
    required this.hintText,
    this.trailingLabel,
    this.errorText,
    this.showClear = false,
    this.onClear,
  });

  final String label;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final String hintText;
  final Widget? trailingLabel;
  final String? errorText;
  final bool showClear;
  final VoidCallback? onClear;

  bool get _hasError => errorText != null;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.gray600,
              ),
            ),
            ?trailingLabel,
          ],
        ),
        const SizedBox(height: _ChildAddMetrics.labelToFieldGap),
        SizedBox(
          height: _ChildAddMetrics.fieldHeight,
          child: TextField(
            controller: controller,
            onChanged: onChanged,
            cursorColor: AppColors.gray200,
            textAlignVertical: TextAlignVertical.center,
            style: AppTypography.bodyMedium.copyWith(color: AppColors.inkBlack),
            decoration: InputDecoration(
              isDense: true,
              filled: true,
              fillColor: AppColors.gray100,
              hintText: hintText,
              hintStyle: AppTypography.bodyMedium.copyWith(
                color: AppColors.gray300,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: _ChildAddMetrics.fieldHorizontalPadding,
                vertical: _ChildAddMetrics.fieldVerticalPadding,
              ),
              suffixIconConstraints: const BoxConstraints.tightFor(
                width: 36,
                height: 36,
              ),
              suffixIcon: showClear
                  ? GestureDetector(
                      onTap: onClear,
                      behavior: HitTestBehavior.opaque,
                      child: const Icon(
                        Icons.cancel,
                        size: 24,
                        color: AppColors.gray600,
                      ),
                    )
                  : null,
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(
                  _ChildAddMetrics.fieldRadius,
                ),
                borderSide: BorderSide(
                  color: _hasError ? AppColors.destructive : AppColors.gray200,
                  width: 1,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(
                  _ChildAddMetrics.fieldRadius,
                ),
                borderSide: BorderSide(
                  color: _hasError ? AppColors.destructive : AppColors.gray200,
                  width: 1,
                ),
              ),
            ),
          ),
        ),
        SizedBox(
          height: _ChildAddMetrics.helperHeight,
          child: _hasError
              ? Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    errorText!,
                    style: AppTypography.captionMedium.copyWith(
                      color: AppColors.destructive,
                    ),
                  ),
                )
              : null,
        ),
      ],
    );
  }
}

class _BirthYearField extends StatelessWidget {
  const _BirthYearField({required this.selectedYear, required this.onTap});

  final int? selectedYear;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '출생연도',
          style: AppTypography.bodyMedium.copyWith(color: AppColors.gray600),
        ),
        const SizedBox(height: _ChildAddMetrics.labelToFieldGap),
        GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: Container(
            height: _ChildAddMetrics.fieldHeight,
            width: double.infinity,
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(
              horizontal: _ChildAddMetrics.fieldHorizontalPadding,
            ),
            decoration: BoxDecoration(
              color: AppColors.gray100,
              borderRadius: BorderRadius.circular(_ChildAddMetrics.fieldRadius),
              border: Border.all(color: AppColors.gray200),
            ),
            child: Text(
              selectedYear?.toString() ?? '자녀가 태어난 연도를 입력해주세요',
              style: AppTypography.bodyMedium.copyWith(
                color: selectedYear == null
                    ? AppColors.gray300
                    : AppColors.inkBlack,
              ),
            ),
          ),
        ),
        const SizedBox(height: _ChildAddMetrics.helperHeight),
      ],
    );
  }
}

class _ChildCodeTooltip extends StatelessWidget {
  const _ChildCodeTooltip({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 249,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 16),
            child: CustomPaint(
              size: const Size(18, 8),
              painter: _TooltipCaretPainter(),
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.gray600,
              borderRadius: BorderRadius.circular(AppTokens.errorBannerRadius),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '자녀코드는 어디에서 확인하나요?',
                        style: AppTypography.captionBold.copyWith(
                          color: AppColors.white,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: onClose,
                      behavior: HitTestBehavior.opaque,
                      child: const Icon(
                        Icons.close_rounded,
                        size: 16,
                        color: AppColors.gray300,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '자녀 회원가입 이후,\n자녀앱의 마이페이지 창에서 확인가능합니다.',
                  style: AppTypography.captionRegular.copyWith(
                    color: AppColors.gray150,
                  ),
                ),
                if (ChildConnectionStore.usesLocalTestValidator) ...[
                  const SizedBox(height: 8),
                  Text(
                    '테스트 코드: ${ChildConnectionStore.testChildCodes.join(', ')}',
                    style: AppTypography.captionBold.copyWith(
                      color: AppColors.white,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BirthYearBottomSheet extends StatefulWidget {
  const _BirthYearBottomSheet({
    required this.years,
    required this.initialIndex,
    required this.onChanged,
    required this.onConfirm,
  });

  final List<int> years;
  final int initialIndex;
  final ValueChanged<int> onChanged;
  final VoidCallback onConfirm;

  @override
  State<_BirthYearBottomSheet> createState() => _BirthYearBottomSheetState();
}

class _BirthYearBottomSheetState extends State<_BirthYearBottomSheet> {
  late int _selectedIndex;
  late final FixedExtentScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
    _scrollController = FixedExtentScrollController(
      initialItem: widget.initialIndex,
    );
    widget.onChanged(widget.years[_selectedIndex]);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double bottomInset = MediaQuery.paddingOf(context).bottom;

    return Container(
      height: _ChildAddMetrics.sheetHeight + bottomInset,
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(_ChildAddMetrics.sheetRadius),
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: _ChildAddMetrics.sheetTitleTop,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                '출생연도',
                style: AppTypography.headlineMedium.copyWith(
                  color: AppColors.inkBlack,
                ),
              ),
            ),
          ),
          Positioned(
            top: _ChildAddMetrics.sheetPickerTop,
            left: 0,
            right: 0,
            height: _ChildAddMetrics.sheetPickerHeight,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned(
                  left: _ChildAddMetrics.sheetPickerInset,
                  right: _ChildAddMetrics.sheetPickerInset,
                  top: _ChildAddMetrics.sheetSelectionTop,
                  child: Container(
                    height: _ChildAddMetrics.fieldHeight,
                    decoration: const BoxDecoration(
                      border: Border(
                        top: BorderSide(color: AppColors.primary, width: 2),
                        bottom: BorderSide(color: AppColors.primary, width: 2),
                      ),
                    ),
                  ),
                ),
                CupertinoPicker(
                  scrollController: _scrollController,
                  itemExtent: _ChildAddMetrics.sheetYearItemHeight,
                  diameterRatio: 10,
                  squeeze: 1,
                  selectionOverlay: const SizedBox.shrink(),
                  onSelectedItemChanged: (int index) {
                    setState(() {
                      _selectedIndex = index;
                    });
                    widget.onChanged(widget.years[index]);
                  },
                  children: [
                    for (int index = 0; index < widget.years.length; index++)
                      Center(
                        child: Text(
                          widget.years[index].toString(),
                          style: AppTypography.headlineMedium.copyWith(
                            fontSize: 24,
                            height: 1.445,
                            letterSpacing: 0,
                            color: index == _selectedIndex
                                ? AppColors.inkBlack
                                : AppColors.gray200,
                          ),
                        ),
                      ),
                  ],
                ),
                IgnorePointer(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.only(
                        left: _ChildAddMetrics.sheetYearSuffixOffset,
                      ),
                      child: Text(
                        '년',
                        style: AppTypography.headlineMedium.copyWith(
                          fontSize: 24,
                          height: 1.445,
                          letterSpacing: 0,
                          color: AppColors.inkBlack,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            left: _ChildAddMetrics.horizontalPadding,
            right: _ChildAddMetrics.horizontalPadding,
            bottom: _ChildAddMetrics.sheetButtonBottom + bottomInset,
            child: _BottomSheetConfirmButton(onTap: widget.onConfirm),
          ),
        ],
      ),
    );
  }
}

class _BottomSheetConfirmButton extends StatelessWidget {
  const _BottomSheetConfirmButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.primary,
      borderRadius: BorderRadius.circular(AppTokens.buttonRadius),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        hoverColor: AppColors.primary.withValues(alpha: 0.12),
        highlightColor: AppColors.primary.withValues(alpha: 0.18),
        splashColor: AppColors.primary.withValues(alpha: 0.20),
        borderRadius: BorderRadius.circular(AppTokens.buttonRadius),
        child: SizedBox(
          height: _ChildAddMetrics.buttonHeight,
          child: Center(
            child: Text(
              '확인',
              style: AppTypography.headlineMedium.copyWith(
                color: AppColors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TooltipCaretPainter extends CustomPainter {
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

class _RegisterButton extends StatelessWidget {
  const _RegisterButton({required this.enabled, required this.onTap});

  final bool enabled;
  final VoidCallback onTap;

  void _handleDisabledTap(BuildContext context) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('자녀 코드를 먼저 입력해주세요.')));
  }

  @override
  Widget build(BuildContext context) {
    final Color backgroundColor = enabled
        ? AppColors.primary
        : AppColors.gray200;
    final Color feedbackColor = enabled ? AppColors.primary : AppColors.gray400;

    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(AppTokens.buttonRadius),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: enabled ? onTap : () => _handleDisabledTap(context),
        hoverColor: feedbackColor.withValues(alpha: enabled ? 0.12 : 0.06),
        highlightColor: feedbackColor.withValues(alpha: enabled ? 0.18 : 0.08),
        splashColor: feedbackColor.withValues(alpha: enabled ? 0.20 : 0.10),
        borderRadius: BorderRadius.circular(AppTokens.buttonRadius),
        child: SizedBox(
          height: _ChildAddMetrics.buttonHeight,
          width: double.infinity,
          child: Center(
            child: Text(
              '등록',
              style: AppTypography.headlineMedium.copyWith(
                color: enabled ? AppColors.white : AppColors.gray300,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
