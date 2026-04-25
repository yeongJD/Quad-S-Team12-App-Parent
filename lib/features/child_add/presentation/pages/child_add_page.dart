import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

class ChildAddPage extends StatefulWidget {
  const ChildAddPage({super.key});

  @override
  State<ChildAddPage> createState() => _ChildAddPageState();
}

class _ChildAddPageState extends State<ChildAddPage> {
  static const List<int> _birthYears = <int>[
    2019,
    2018,
    2017,
    2016,
    2015,
    2014,
    2013,
    2012,
    2011,
    2010,
    2009,
    2008,
    2007,
  ];

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _childCodeController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();

  Uint8List? _photoBytes;
  int? _selectedBirthYear;
  String? _nameErrorText;
  bool _showCodeTooltip = false;

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
      barrierColor: const Color.fromRGBO(68, 68, 68, 0.6),
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

  void _submit() {
    if (!_canSubmit) {
      return;
    }
    if (!_isNameValid) {
      setState(() {
        _nameErrorText = '이름은 2자 이상 50자 이내로 입력해주세요';
      });
      return;
    }
    context.go('/parent-home?demo=filled');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.gray100,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 375),
            child: Stack(
              children: [
                Column(
                  children: [
                    const SizedBox(height: 4),
                    _ChildAddTopBar(onBack: context.pop),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(
                          21.58,
                          41,
                          21.58,
                          24,
                        ),
                        child: Column(
                          children: [
                            _PhotoPicker(
                              photoBytes: _photoBytes,
                              onTap: _pickPhoto,
                            ),
                            const SizedBox(height: 32),
                            SizedBox(
                              width: 293.998,
                              child: Column(
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
                                  const SizedBox(height: 14.385),
                                  _BirthYearField(
                                    selectedYear: _selectedBirthYear,
                                    onTap: _openBirthYearSheet,
                                  ),
                                  const SizedBox(height: 14.385),
                                  _ChildAddTextField(
                                    label: '자녀코드',
                                    controller: _childCodeController,
                                    hintText: '자녀 코드를 입력해주세요',
                                    onChanged: (_) => setState(() {}),
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
                            ),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(21.58, 0, 21.58, 28),
                      child: Align(
                        alignment: Alignment.center,
                        child: SizedBox(
                          width: 293.998,
                          child: _RegisterButton(
                            enabled: _canSubmit,
                            onTap: _submit,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                if (_showCodeTooltip)
                  Positioned(
                    left: 66,
                    top: _selectedBirthYear == null ? 482 : 468,
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
      height: 52,
      child: Stack(
        children: [
          Center(
            child: Text(
              '자녀등록',
              style: AppTypography.headlineMedium.copyWith(
                fontSize: 16.18,
                height: 1.445,
                letterSpacing: -0.0036,
                color: const Color(0xFF050505),
              ),
            ),
          ),
          Positioned(
            left: 21.58,
            top: 12.59,
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

class _PhotoPicker extends StatelessWidget {
  const _PhotoPicker({required this.photoBytes, required this.onTap});

  final Uint8List? photoBytes;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        children: [
          Container(
            width: 66.532,
            height: 66.532,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.gray200, width: 2),
            ),
            child: ClipOval(
              child: photoBytes == null
                  ? Container(
                      color: const Color(0xFFE1E4E9),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.image_outlined,
                        size: 24,
                        color: AppColors.white,
                      ),
                    )
                  : Image.memory(
                      photoBytes!,
                      fit: BoxFit.cover,
                      width: 57.541,
                      height: 57.541,
                    ),
            ),
          ),
          const SizedBox(height: 10.79),
          Text(
            '사진등록',
            style: AppTypography.bodyMedium.copyWith(
              fontSize: 14.385,
              height: 1.5,
              letterSpacing: 0.0912,
              color: AppColors.gray600,
            ),
          ),
        ],
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
                fontSize: 14.385,
                height: 1.5,
                letterSpacing: 0.082,
                color: AppColors.gray600,
              ),
            ),
            ?trailingLabel,
          ],
        ),
        const SizedBox(height: 8.991),
        SizedBox(
          height: 44.954,
          child: TextField(
            controller: controller,
            onChanged: onChanged,
            cursorColor: AppColors.gray200,
            style: AppTypography.bodyMedium.copyWith(
              fontSize: 14.385,
              height: 1.5,
              letterSpacing: 0.082,
              color: const Color(0xFF050505),
            ),
            decoration: InputDecoration(
              filled: true,
              fillColor: AppColors.gray100,
              hintText: hintText,
              hintStyle: AppTypography.bodyMedium.copyWith(
                fontSize: 14.385,
                height: 1.5,
                letterSpacing: 0.082,
                color: AppColors.gray300,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14.385,
                vertical: 10.789,
              ),
              suffixIcon: showClear
                  ? GestureDetector(
                      onTap: onClear,
                      behavior: HitTestBehavior.opaque,
                      child: const Icon(
                        Icons.cancel,
                        size: 21.578,
                        color: AppColors.gray600,
                      ),
                    )
                  : null,
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: _hasError ? AppColors.destructive : AppColors.gray200,
                  width: 0.899,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: _hasError ? AppColors.destructive : AppColors.gray200,
                  width: 0.899,
                ),
              ),
            ),
          ),
        ),
        SizedBox(
          height: 16.183,
          child: _hasError
              ? Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    errorText!,
                    style: AppTypography.captionMedium.copyWith(
                      fontSize: 10.79,
                      height: 1.334,
                      letterSpacing: 0.2719,
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
          style: AppTypography.bodyMedium.copyWith(
            fontSize: 14.385,
            height: 1.5,
            letterSpacing: 0.082,
            color: AppColors.gray600,
          ),
        ),
        const SizedBox(height: 8.991),
        GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: Container(
            height: 44.954,
            width: double.infinity,
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 14.385),
            decoration: BoxDecoration(
              color: AppColors.gray100,
              borderRadius: BorderRadius.circular(10.789),
              border: Border.all(color: AppColors.gray200, width: 0.899),
            ),
            child: Text(
              selectedYear?.toString() ?? '자녀가 태어난 연도를 입력해주세요',
              style: AppTypography.bodyMedium.copyWith(
                fontSize: 14.385,
                height: 1.5,
                letterSpacing: 0.082,
                color: selectedYear == null
                    ? AppColors.gray300
                    : const Color(0xFF050505),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16.183),
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
              borderRadius: BorderRadius.circular(8),
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
                          fontSize: 12,
                          height: 1.334,
                          letterSpacing: 0.3024,
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
                    fontSize: 12,
                    height: 1.334,
                    letterSpacing: 0.3024,
                    color: const Color(0xFFEDEEF1),
                  ),
                ),
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
    return SafeArea(
      top: false,
      child: Container(
        height: 356.933,
        decoration: const BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(21.578)),
        ),
        child: Stack(
          children: [
            Positioned(
              top: 24.276,
              left: 0,
              right: 0,
              child: Center(
                child: Text(
                  '출생연도',
                  style: AppTypography.headlineMedium.copyWith(
                    fontSize: 16.183,
                    height: 1.445,
                    letterSpacing: -0.0036,
                    color: const Color(0xFF050505),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 73.725,
              left: 0,
              right: 0,
              height: 151,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Positioned(
                    left: 22.926,
                    right: 22.926,
                    top: 52.5,
                    child: Container(
                      height: 45,
                      decoration: const BoxDecoration(
                        border: Border(
                          top: BorderSide(
                            color: AppColors.primary,
                            width: 1.798,
                          ),
                          bottom: BorderSide(
                            color: AppColors.primary,
                            width: 1.798,
                          ),
                        ),
                      ),
                    ),
                  ),
                  CupertinoPicker(
                    scrollController: _scrollController,
                    itemExtent: 45,
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
                              fontSize: 21.578,
                              height: 1.445,
                              letterSpacing: -0.0048,
                              color: index == _selectedIndex
                                  ? const Color(0xFF050505)
                                  : AppColors.gray200,
                            ),
                          ),
                        ),
                    ],
                  ),
                  IgnorePointer(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.only(left: 69),
                        child: Text(
                          '년',
                          style: AppTypography.headlineMedium.copyWith(
                            fontSize: 21.578,
                            height: 1.445,
                            letterSpacing: -0.0048,
                            color: const Color(0xFF050505),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              left: 21.578,
              right: 21.578,
              bottom: 56.641,
              child: _BottomSheetConfirmButton(onTap: widget.onConfirm),
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomSheetConfirmButton extends StatelessWidget {
  const _BottomSheetConfirmButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 48.55,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(7.193),
        ),
        child: Text(
          '확인',
          style: AppTypography.headlineMedium.copyWith(
            fontSize: 16.183,
            height: 1.445,
            letterSpacing: -0.0036,
            color: AppColors.white,
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

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: double.infinity,
        height: 48.55,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: enabled ? AppColors.primary : AppColors.gray200,
          borderRadius: BorderRadius.circular(7.193),
        ),
        child: Text(
          '등록',
          style: AppTypography.headlineMedium.copyWith(
            fontSize: 16.183,
            height: 1.445,
            letterSpacing: -0.0036,
            color: enabled ? AppColors.white : AppColors.gray300,
          ),
        ),
      ),
    );
  }
}
