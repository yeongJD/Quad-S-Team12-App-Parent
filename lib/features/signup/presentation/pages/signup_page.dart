import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

enum _SignupErrorType {
  invalidUsername,
  duplicatedUsername,
  invalidPassword,
  passwordMismatch,
}

enum _CheckState { hidden, inactive, active }

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  static final RegExp _usernamePattern = RegExp(
    r'^(?=.*[a-z])(?=.*\d)[a-z\d]{6,12}$',
  );
  static final RegExp _passwordPattern = RegExp(
    r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[^A-Za-z0-9])[^\s]{12,15}$',
  );

  // Temporary duplicate-check stub until API wiring is added.
  static const Set<String> _takenUsernames = <String>{'gdg12'};

  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _passwordConfirmController =
      TextEditingController();

  _SignupErrorType? _activeError;

  String get _username => _usernameController.text;
  String get _password => _passwordController.text;
  String get _passwordConfirm => _passwordConfirmController.text;

  bool get _isUsernameFormatValid => _usernamePattern.hasMatch(_username);
  bool get _isUsernameDuplicate =>
      _username.isNotEmpty && _takenUsernames.contains(_username);
  bool get _isPasswordValid => _passwordPattern.hasMatch(_password);
  bool get _isPasswordMatched =>
      _password.isNotEmpty &&
      _passwordConfirm.isNotEmpty &&
      _password == _passwordConfirm;

  bool get _hasAllFields =>
      _username.isNotEmpty &&
      _password.isNotEmpty &&
      _passwordConfirm.isNotEmpty;

  bool get _hasUsernameError => _usernameInlineMessage != null;

  bool get _hasPasswordError => _passwordInlineMessage != null;

  bool get _hasPasswordConfirmError => _passwordConfirmInlineMessage != null;

  bool get _canSubmit =>
      _hasAllFields &&
      _isUsernameFormatValid &&
      !_isUsernameDuplicate &&
      _isPasswordValid &&
      _isPasswordMatched;

  String? get _usernameInlineMessage {
    if (_username.isEmpty) {
      return null;
    }
    if (!_isUsernameFormatValid) {
      return '영문 소문자, 숫자 조합 6~12자 / 빈칸, 공백 불가';
    }
    if (_isUsernameDuplicate) {
      return '이미 사용 중인 아이디입니다.';
    }
    return null;
  }

  String? get _passwordInlineMessage {
    if (_password.isEmpty || _isPasswordValid) {
      return null;
    }
    return '영문 대/소문자, 숫자, 특수문자 혼합 12~15자 / 빈칸, 공백 불가';
  }

  String? get _passwordConfirmInlineMessage {
    if (_passwordConfirm.isEmpty) {
      return null;
    }
    if (_isPasswordMatched) {
      return null;
    }
    return '비밀번호가 일치하지 않습니다.';
  }

  String? get _errorMessage {
    switch (_activeError) {
      case _SignupErrorType.invalidUsername:
        return '아이디 규칙에 어긋납니다. 수정해주세요.';
      case _SignupErrorType.duplicatedUsername:
        return '아이디가 중복됩니다. 수정해주세요!';
      case _SignupErrorType.invalidPassword:
        return '비밀번호 규칙에 어긋납니다. 수정해주세요.';
      case _SignupErrorType.passwordMismatch:
        return '비밀번호가 일치하지 않습니다. 확인해주세요.';
      case null:
        return null;
    }
  }

  _CheckState get _usernameCheckState {
    if (_isUsernameFormatValid && !_isUsernameDuplicate) {
      return _CheckState.active;
    }
    return _CheckState.inactive;
  }

  _CheckState get _passwordConfirmCheckState {
    if (_isPasswordValid && _isPasswordMatched) {
      return _CheckState.active;
    }
    return _CheckState.inactive;
  }

  void _onUsernameChanged(String value) {
    setState(() {
      if (_activeError == _SignupErrorType.invalidUsername ||
          _activeError == _SignupErrorType.duplicatedUsername) {
        _activeError = null;
      }
    });
  }

  void _onPasswordChanged(String value) {
    setState(() {
      if (_activeError == _SignupErrorType.invalidPassword ||
          _activeError == _SignupErrorType.passwordMismatch) {
        _activeError = null;
      }
    });
  }

  void _onPasswordConfirmChanged(String value) {
    setState(() {
      if (_activeError == _SignupErrorType.passwordMismatch) {
        _activeError = null;
      }
    });
  }

  void _submit() {
    FocusScope.of(context).unfocus();

    if (!_isUsernameFormatValid) {
      setState(() {
        _activeError = _SignupErrorType.invalidUsername;
      });
      return;
    }

    if (_isUsernameDuplicate) {
      setState(() {
        _activeError = _SignupErrorType.duplicatedUsername;
      });
      return;
    }

    if (!_isPasswordValid) {
      setState(() {
        _activeError = _SignupErrorType.invalidPassword;
      });
      return;
    }

    if (!_isPasswordMatched) {
      setState(() {
        _activeError = _SignupErrorType.passwordMismatch;
      });
      return;
    }

    setState(() {
      _activeError = null;
    });
    context.go('/');
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _passwordConfirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.gray100,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            return Center(
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
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          children: [
                            _SignupTopBar(onBack: () => context.go('/')),
                            const SizedBox(height: 25),
                            _SignupField(
                              label: '아이디',
                              controller: _usernameController,
                              borderColor: _hasUsernameError
                                  ? AppColors.destructive
                                  : AppColors.gray200,
                              checkState: _usernameCheckState,
                              helperText: _usernameInlineMessage,
                              onChanged: _onUsernameChanged,
                              inputFormatters: <TextInputFormatter>[
                                FilteringTextInputFormatter.deny(RegExp(r'\s')),
                                LengthLimitingTextInputFormatter(12),
                              ],
                              keyboardType: TextInputType.text,
                              labelBottomSpacing: 10,
                            ),
                            const SizedBox(height: 35),
                            _SignupField(
                              label: '비밀번호',
                              controller: _passwordController,
                              borderColor: _hasPasswordError
                                  ? AppColors.destructive
                                  : AppColors.gray200,
                              checkState: _CheckState.hidden,
                              helperText: _passwordInlineMessage,
                              onChanged: _onPasswordChanged,
                              inputFormatters: <TextInputFormatter>[
                                FilteringTextInputFormatter.deny(RegExp(r'\s')),
                                LengthLimitingTextInputFormatter(15),
                              ],
                              keyboardType: TextInputType.visiblePassword,
                              labelBottomSpacing: 12,
                            ),
                            const SizedBox(height: 35),
                            _SignupField(
                              label: '비밀번호 재확인',
                              controller: _passwordConfirmController,
                              borderColor: _hasPasswordConfirmError
                                  ? AppColors.destructive
                                  : AppColors.gray200,
                              checkState: _passwordConfirmCheckState,
                              helperText: _passwordConfirmInlineMessage,
                              onChanged: _onPasswordConfirmChanged,
                              inputFormatters: <TextInputFormatter>[
                                FilteringTextInputFormatter.deny(RegExp(r'\s')),
                                LengthLimitingTextInputFormatter(15),
                              ],
                              keyboardType: TextInputType.visiblePassword,
                              labelBottomSpacing: 10,
                            ),
                            const Spacer(),
                            if (_errorMessage case final String message) ...[
                              _SignupToast(message: message),
                              const SizedBox(height: 15),
                            ],
                            _SignupButton(
                              label: '확인',
                              enabled: _canSubmit,
                              onPressed: _canSubmit ? _submit : null,
                            ),
                            const SizedBox(height: 29),
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

class _SignupTopBar extends StatelessWidget {
  const _SignupTopBar({required this.onBack});

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
              '회원가입',
              style: AppTypography.headlineMedium.copyWith(
                fontSize: 18,
                height: 1.445,
                letterSpacing: -0.0036,
                color: const Color(0xFF050505),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SignupField extends StatelessWidget {
  const _SignupField({
    required this.label,
    required this.controller,
    required this.borderColor,
    required this.checkState,
    required this.helperText,
    required this.onChanged,
    required this.inputFormatters,
    required this.keyboardType,
    required this.labelBottomSpacing,
  });

  final String label;
  final TextEditingController controller;
  final Color borderColor;
  final _CheckState checkState;
  final String? helperText;
  final ValueChanged<String> onChanged;
  final List<TextInputFormatter> inputFormatters;
  final TextInputType keyboardType;
  final double labelBottomSpacing;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.bodyMedium.copyWith(
            fontSize: 16,
            height: 1.5,
            letterSpacing: 0.0912,
            color: AppColors.gray600,
          ),
        ),
        SizedBox(height: labelBottomSpacing),
        Container(
          height: 50,
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: TextField(
                    controller: controller,
                    onChanged: onChanged,
                    keyboardType: keyboardType,
                    autocorrect: false,
                    enableSuggestions: false,
                    textCapitalization: TextCapitalization.none,
                    inputFormatters: inputFormatters,
                    cursorColor: AppColors.black,
                    style: AppTypography.bodyMedium.copyWith(
                      fontSize: 16,
                      height: 1.5,
                      letterSpacing: 0.0912,
                      color: AppColors.black,
                    ),
                    decoration: const InputDecoration(
                      isDense: true,
                      filled: false,
                      fillColor: Colors.transparent,
                      contentPadding: EdgeInsets.zero,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      disabledBorder: InputBorder.none,
                      errorBorder: InputBorder.none,
                      focusedErrorBorder: InputBorder.none,
                    ),
                  ),
                ),
              ),
              if (checkState != _CheckState.hidden) ...[
                const SizedBox(width: 12),
                _FieldCheck(state: checkState),
              ],
            ],
          ),
        ),
        if (helperText != null) ...[
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Text(
              helperText!,
              style: AppTypography.captionMedium.copyWith(
                fontSize: 12,
                height: 1.334,
                letterSpacing: 0.12,
                color: AppColors.destructive,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _FieldCheck extends StatelessWidget {
  const _FieldCheck({required this.state});

  final _CheckState state;

  @override
  Widget build(BuildContext context) {
    final Color color = switch (state) {
      _CheckState.active => AppColors.primary,
      _CheckState.inactive => AppColors.gray200,
      _CheckState.hidden => Colors.transparent,
    };

    return SizedBox(
      width: 30,
      height: 30,
      child: Center(child: Icon(Icons.check_rounded, size: 20, color: color)),
    );
  }
}

class _SignupToast extends StatelessWidget {
  const _SignupToast({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.gray500,
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          const _ToastWarningIcon(),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: AppTypography.labelMedium.copyWith(
                fontSize: 14,
                height: 1.429,
                letterSpacing: 0.203,
                color: AppColors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ToastWarningIcon extends StatelessWidget {
  const _ToastWarningIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 20,
      decoration: const BoxDecoration(
        color: AppColors.destructive,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          '!',
          style: AppTypography.captionBold.copyWith(
            fontSize: 12,
            height: 1,
            letterSpacing: 0,
            color: AppColors.white,
          ),
        ),
      ),
    );
  }
}

class _SignupButton extends StatelessWidget {
  const _SignupButton({
    required this.label,
    required this.enabled,
    required this.onPressed,
  });

  final String label;
  final bool enabled;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          elevation: 0,
          backgroundColor: AppColors.primary,
          disabledBackgroundColor: AppColors.gray200,
          foregroundColor: AppColors.white,
          disabledForegroundColor: AppColors.gray300,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Text(
          label,
          style: AppTypography.headlineMedium.copyWith(
            fontSize: 18,
            height: 1.445,
            letterSpacing: -0.0036,
            fontWeight: FontWeight.w500,
            color: enabled ? AppColors.white : AppColors.gray300,
          ),
        ),
      ),
    );
  }
}
