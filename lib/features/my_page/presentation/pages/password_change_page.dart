import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/auth/account_store.dart';
import '../../../../core/auth/auth_session.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

enum _PasswordChangeErrorType { currentMismatch }

class PasswordChangePage extends StatefulWidget {
  const PasswordChangePage({super.key});

  @override
  State<PasswordChangePage> createState() => _PasswordChangePageState();
}

class _PasswordChangePageState extends State<PasswordChangePage> {
  static final RegExp _passwordPattern = RegExp(
    r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[^A-Za-z0-9])[^\s]{12,15}$',
  );

  final TextEditingController _currentPasswordController =
      TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  final FocusNode _currentPasswordFocusNode = FocusNode();
  final FocusNode _newPasswordFocusNode = FocusNode();
  final FocusNode _confirmPasswordFocusNode = FocusNode();

  _PasswordChangeErrorType? _currentPasswordError;
  ParentAccount? _account;
  bool _showNewPasswordRuleError = false;
  bool _showSameAsCurrentError = false;
  bool _showConfirmMismatchError = false;

  String get _currentPassword => _currentPasswordController.text;
  String get _newPassword => _newPasswordController.text;
  String get _confirmPassword => _confirmPasswordController.text;

  bool get _isCurrentPasswordValid =>
      _account?.passwordHash ==
      AccountStore.passwordHashForLocalMock(_currentPassword);
  bool get _isNewPasswordValid => _passwordPattern.hasMatch(_newPassword);
  bool get _isSameAsCurrentPassword =>
      _newPassword.isNotEmpty &&
      _account?.passwordHash ==
          AccountStore.passwordHashForLocalMock(_newPassword);
  bool get _isConfirmMatched =>
      _newPassword.isNotEmpty &&
      _confirmPassword.isNotEmpty &&
      _newPassword == _confirmPassword;

  bool get _canSubmit =>
      _isCurrentPasswordValid &&
      _isNewPasswordValid &&
      !_isSameAsCurrentPassword &&
      _isConfirmMatched;

  String? get _currentPasswordHelperText {
    if (_currentPasswordError != _PasswordChangeErrorType.currentMismatch) {
      return null;
    }
    return '기존 비밀번호가 일치하지 않습니다.';
  }

  String? get _newPasswordHelperText {
    if (_showSameAsCurrentError) {
      return '새 비밀번호는 기존 비밀번호와 달라야 합니다.';
    }
    if (_showNewPasswordRuleError) {
      return '영문 대문자, 소문자, 숫자, 특수문자 모두 혼합 (12~15자)';
    }
    return null;
  }

  String? get _confirmPasswordHelperText {
    if (!_showConfirmMismatchError) {
      return null;
    }
    return '비밀번호가 일치하지 않습니다.';
  }

  @override
  void initState() {
    super.initState();
    _loadAccount();
  }

  Future<void> _loadAccount() async {
    final String? parentId = await AuthSession.getCurrentParentId();
    final ParentAccount? account = parentId == null
        ? null
        : await AccountStore.getAccountById(parentId);
    if (!mounted) {
      return;
    }
    setState(() {
      _account = account;
    });
  }

  void _handleCurrentPasswordChanged(String value) {
    setState(() {
      _currentPasswordError = null;
    });
  }

  void _handleNewPasswordChanged(String value) {
    setState(() {
      _showNewPasswordRuleError = value.isNotEmpty && !_isNewPasswordValid;
      _showSameAsCurrentError = value.isNotEmpty && _isSameAsCurrentPassword;
      _showConfirmMismatchError =
          _confirmPassword.isNotEmpty && !_isConfirmMatched;
    });
  }

  void _handleConfirmPasswordChanged(String value) {
    setState(() {
      _showConfirmMismatchError = value.isNotEmpty && !_isConfirmMatched;
    });
  }

  void _clearField(
    TextEditingController controller,
    ValueChanged<String> onChanged,
  ) {
    controller.clear();
    onChanged('');
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();

    setState(() {
      _currentPasswordError = _isCurrentPasswordValid
          ? null
          : _PasswordChangeErrorType.currentMismatch;
      _showNewPasswordRuleError =
          _newPassword.isNotEmpty && !_isNewPasswordValid;
      _showSameAsCurrentError =
          _newPassword.isNotEmpty && _isSameAsCurrentPassword;
      _showConfirmMismatchError =
          _confirmPassword.isNotEmpty && !_isConfirmMatched;
    });

    if (!_canSubmit) {
      return;
    }

    final ParentAccount? account = _account;
    if (account == null) {
      return;
    }
    await AccountStore.updatePassword(
      parentId: account.parentId,
      password: _newPassword,
    );
    if (!mounted) {
      return;
    }
    context.pop();
  }

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _currentPasswordFocusNode.dispose();
    _newPasswordFocusNode.dispose();
    _confirmPasswordFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.gray100,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            return Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 375),
                child: SingleChildScrollView(
                  padding: EdgeInsets.zero,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: IntrinsicHeight(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 22),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _PasswordChangeTopBar(onBack: context.pop),
                            const SizedBox(height: 20),
                            _PasswordChangeField(
                              label: '기존 비밀번호',
                              placeholder: '기존 비밀번호를 입력해주세요',
                              controller: _currentPasswordController,
                              focusNode: _currentPasswordFocusNode,
                              helperText: _currentPasswordHelperText,
                              borderColor: _currentPasswordHelperText != null
                                  ? AppColors.destructive
                                  : AppColors.gray200,
                              onChanged: _handleCurrentPasswordChanged,
                              onClear: () {
                                _clearField(
                                  _currentPasswordController,
                                  _handleCurrentPasswordChanged,
                                );
                              },
                            ),
                            const SizedBox(height: 24),
                            _PasswordChangeField(
                              label: '새 비밀번호',
                              placeholder: '새 비밀번호를 입력해주세요',
                              controller: _newPasswordController,
                              focusNode: _newPasswordFocusNode,
                              helperText: _newPasswordHelperText,
                              borderColor: _newPasswordHelperText != null
                                  ? AppColors.destructive
                                  : AppColors.gray200,
                              onChanged: _handleNewPasswordChanged,
                              onClear: () {
                                _clearField(
                                  _newPasswordController,
                                  _handleNewPasswordChanged,
                                );
                              },
                            ),
                            const SizedBox(height: 24),
                            _PasswordChangeField(
                              label: '새 비밀번호 확인',
                              placeholder: '새 비밀번호를 한번 더 입력해주세요',
                              controller: _confirmPasswordController,
                              focusNode: _confirmPasswordFocusNode,
                              helperText: _confirmPasswordHelperText,
                              borderColor: _confirmPasswordHelperText != null
                                  ? AppColors.destructive
                                  : AppColors.gray200,
                              onChanged: _handleConfirmPasswordChanged,
                              onClear: () {
                                _clearField(
                                  _confirmPasswordController,
                                  _handleConfirmPasswordChanged,
                                );
                              },
                            ),
                            const Spacer(),
                            _PasswordChangeButton(
                              enabled: _canSubmit,
                              onPressed: _submit,
                            ),
                            const SizedBox(height: 28),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _PasswordChangeTopBar extends StatelessWidget {
  const _PasswordChangeTopBar({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: Stack(
        children: [
          Positioned(
            left: 0,
            top: 14,
            width: 24,
            height: 24,
            child: GestureDetector(
              onTap: onBack,
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.all(2),
                child: SvgPicture.asset(
                  'assets/icons/cmp/btn/back.svg',
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
          Center(
            child: Text(
              '비밀번호 수정',
              style: AppTypography.headlineMedium.copyWith(
                fontSize: 16.18,
                height: 1.445,
                letterSpacing: -0.0032,
                color: const Color(0xFF050505),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PasswordChangeField extends StatefulWidget {
  const _PasswordChangeField({
    required this.label,
    required this.placeholder,
    required this.controller,
    required this.focusNode,
    required this.helperText,
    required this.borderColor,
    required this.onChanged,
    required this.onClear,
  });

  final String label;
  final String placeholder;
  final TextEditingController controller;
  final FocusNode focusNode;
  final String? helperText;
  final Color borderColor;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  State<_PasswordChangeField> createState() => _PasswordChangeFieldState();
}

class _PasswordChangeFieldState extends State<_PasswordChangeField> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_refresh);
    widget.focusNode.addListener(_refresh);
  }

  @override
  void didUpdateWidget(covariant _PasswordChangeField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_refresh);
      widget.controller.addListener(_refresh);
    }
    if (oldWidget.focusNode != widget.focusNode) {
      oldWidget.focusNode.removeListener(_refresh);
      widget.focusNode.addListener(_refresh);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_refresh);
    widget.focusNode.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool showClearButton =
        widget.focusNode.hasFocus && widget.controller.text.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: AppTypography.labelMedium.copyWith(
            fontSize: 14.39,
            height: 1.5,
            letterSpacing: 0.082,
            color: AppColors.gray600,
          ),
        ),
        const SizedBox(height: 9),
        Container(
          height: 44.954,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: widget.borderColor, width: 0.899),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14.385),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: widget.controller,
                  focusNode: widget.focusNode,
                  onChanged: widget.onChanged,
                  autocorrect: false,
                  enableSuggestions: false,
                  textCapitalization: TextCapitalization.none,
                  inputFormatters: <TextInputFormatter>[
                    FilteringTextInputFormatter.deny(RegExp(r'\s')),
                    LengthLimitingTextInputFormatter(15),
                  ],
                  cursorColor: AppColors.black,
                  style: AppTypography.labelMedium.copyWith(
                    fontSize: 14.39,
                    height: 1.5,
                    letterSpacing: 0.082,
                    color: const Color(0xFF050505),
                  ),
                  decoration: InputDecoration(
                    isDense: true,
                    filled: false,
                    fillColor: Colors.transparent,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    disabledBorder: InputBorder.none,
                    errorBorder: InputBorder.none,
                    focusedErrorBorder: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                    hintText: widget.placeholder,
                    hintStyle: AppTypography.labelMedium.copyWith(
                      fontSize: 14.39,
                      height: 1.5,
                      letterSpacing: 0.082,
                      color: AppColors.gray300,
                    ),
                  ),
                ),
              ),
              if (showClearButton) ...[
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: widget.onClear,
                  behavior: HitTestBehavior.opaque,
                  child: SvgPicture.asset(
                    'assets/icons/Clear button.svg',
                    width: 21.578,
                    height: 21.578,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (widget.helperText != null) ...[
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(left: 2),
            child: Text(
              widget.helperText!,
              style: AppTypography.captionMedium.copyWith(
                fontSize: 12,
                height: 1.334,
                letterSpacing: 0.12,
                color: AppColors.destructive,
              ),
            ),
          ),
        ] else
          const SizedBox(height: 16.183),
      ],
    );
  }
}

class _PasswordChangeButton extends StatelessWidget {
  const _PasswordChangeButton({required this.enabled, required this.onPressed});

  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48.55,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          elevation: 0,
          backgroundColor: enabled ? AppColors.primary : AppColors.gray200,
          foregroundColor: enabled ? AppColors.white : AppColors.gray300,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Text(
          '완료',
          style: AppTypography.headlineMedium.copyWith(
            fontSize: 16.18,
            height: 1.445,
            letterSpacing: -0.0032,
            color: enabled ? AppColors.white : AppColors.gray300,
          ),
        ),
      ),
    );
  }
}
