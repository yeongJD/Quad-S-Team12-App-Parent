import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/auth/auth_session.dart';
import '../../../../core/models/result.dart';
import '../../../../core/services/device_registration.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../data/models/auth/auth_token.dart';
import '../../../../data/repositories/auth_repository.dart';

enum _SignupErrorType {
  invalidName,
  invalidEmail,
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
  static final RegExp _emailPattern = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
  static final RegExp _passwordPattern = RegExp(
    r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[^A-Za-z0-9])[^\s]{8,15}$',
  );

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _passwordConfirmController =
      TextEditingController();
  final AuthRepository _authRepository = createAuthRepository();

  _SignupErrorType? _activeError;
  bool _submitting = false;

  String get _name => _nameController.text;
  String get _email => _emailController.text;
  String get _password => _passwordController.text;
  String get _passwordConfirm => _passwordConfirmController.text;

  bool get _isNameValid => _name.trim().isNotEmpty;
  bool get _isEmailValid => _emailPattern.hasMatch(_email);
  bool get _isPasswordValid => _passwordPattern.hasMatch(_password);
  bool get _isPasswordMatched =>
      _password.isNotEmpty &&
      _passwordConfirm.isNotEmpty &&
      _password == _passwordConfirm;

  bool get _hasAllFields =>
      _name.isNotEmpty &&
      _email.isNotEmpty &&
      _password.isNotEmpty &&
      _passwordConfirm.isNotEmpty;

  bool get _hasNameError => _nameInlineMessage != null;

  bool get _hasEmailError => _emailInlineMessage != null;

  bool get _hasPasswordError => _passwordInlineMessage != null;

  bool get _hasPasswordConfirmError => _passwordConfirmInlineMessage != null;

  bool get _canSubmit =>
      _hasAllFields &&
      _isNameValid &&
      _isEmailValid &&
      _isPasswordValid &&
      _isPasswordMatched;

  String? get _nameInlineMessage {
    if (_name.isEmpty) {
      return null;
    }
    if (!_isNameValid) {
      return '이름을 입력해주세요.';
    }
    return null;
  }

  String? get _emailInlineMessage {
    if (_email.isEmpty || _isEmailValid) {
      return null;
    }
    return '올바른 이메일 형식으로 입력해주세요.';
  }

  String? get _passwordInlineMessage {
    if (_password.isEmpty || _isPasswordValid) {
      return null;
    }
    return '영문 대/소문자, 숫자, 특수문자 혼합 8자 / 빈칸, 공백 불가';
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
      case _SignupErrorType.invalidName:
        return '이름을 입력해주세요.';
      case _SignupErrorType.invalidEmail:
        return '이메일 형식을 확인해주세요.';
      case _SignupErrorType.invalidPassword:
        return '비밀번호 규칙에 어긋납니다. 수정해주세요.';
      case _SignupErrorType.passwordMismatch:
        return '비밀번호가 일치하지 않습니다. 확인해주세요.';
      case null:
        return null;
    }
  }

  _CheckState get _nameCheckState {
    if (_isNameValid) {
      return _CheckState.active;
    }
    return _CheckState.inactive;
  }

  _CheckState get _emailCheckState {
    if (_isEmailValid) {
      return _CheckState.active;
    }
    return _CheckState.inactive;
  }

  _CheckState get _passwordCheckState {
    if (_isPasswordValid) {
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

  void _onNameChanged(String value) {
    setState(() {
      if (_activeError == _SignupErrorType.invalidName) {
        _activeError = null;
      }
    });
  }

  void _onEmailChanged(String value) {
    setState(() {
      if (_activeError == _SignupErrorType.invalidEmail) {
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

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();

    if (_submitting) {
      return;
    }

    if (!_isNameValid) {
      setState(() {
        _activeError = _SignupErrorType.invalidName;
      });
      return;
    }

    if (!_isEmailValid) {
      setState(() {
        _activeError = _SignupErrorType.invalidEmail;
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
      _submitting = true;
    });

    final Result<AuthToken> result = await _authRepository.signup(
      email: _email.trim(),
      name: _name.trim(),
      password: _password,
    );
    if (!mounted) {
      return;
    }

    switch (result) {
      case Success<AuthToken>(:final AuthToken data):
        // The backend creates the account but issues no session on signup
        // (no tokens). When no access token comes back, send the user to the
        // login screen with their details prefilled instead of persisting an
        // empty session and landing on a home that would immediately 401.
        if (data.accessToken.isEmpty) {
          if (!mounted) {
            return;
          }
          setState(() {
            _submitting = false;
          });
          context.go(
            Uri(
              path: '/login',
              queryParameters: <String, String>{
                'name': _name.trim(),
                'email': _email.trim(),
              },
            ).toString(),
          );
          return;
        }
        await AuthSession.login(parentId: data.parentId, email: data.email);
        final String? refresh = data.refreshToken;
        await AuthSession.saveTokens(
          accessToken: data.accessToken,
          refreshToken: refresh,
        );
        unawaited(DeviceRegistration.registerCurrent());
        if (!mounted) {
          return;
        }
        setState(() {
          _submitting = false;
        });
        context.go('/signup/complete');
      case Failure<AuthToken>(:final String message):
        setState(() {
          _submitting = false;
        });
        if (message == AuthFailureMessages.duplicatedEmail) {
          context.go(
            Uri(
              path: '/login',
              queryParameters: <String, String>{
                'name': _name.trim(),
                'email': _email.trim(),
                'notice': 'existing-account',
              },
            ).toString(),
          );
          return;
        }
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
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
                              label: '이름',
                              controller: _nameController,
                              borderColor: _hasNameError
                                  ? AppColors.destructive
                                  : AppColors.gray200,
                              checkState: _nameCheckState,
                              helperText: _nameInlineMessage,
                              onChanged: _onNameChanged,
                              inputFormatters: <TextInputFormatter>[
                                FilteringTextInputFormatter.deny(RegExp(r'\s')),
                                LengthLimitingTextInputFormatter(20),
                              ],
                              keyboardType: TextInputType.text,
                              labelBottomSpacing: 10,
                              labelFontSize: 14.385,
                            ),
                            const SizedBox(height: 35),
                            _SignupField(
                              label: '이메일',
                              controller: _emailController,
                              borderColor: _hasEmailError
                                  ? AppColors.destructive
                                  : AppColors.gray200,
                              checkState: _emailCheckState,
                              helperText: _emailInlineMessage,
                              onChanged: _onEmailChanged,
                              inputFormatters: <TextInputFormatter>[
                                FilteringTextInputFormatter.deny(RegExp(r'\s')),
                                LengthLimitingTextInputFormatter(50),
                              ],
                              keyboardType: TextInputType.emailAddress,
                              labelBottomSpacing: 10,
                            ),
                            const SizedBox(height: 35),
                            _SignupField(
                              label: '비밀번호',
                              controller: _passwordController,
                              borderColor: _hasPasswordError
                                  ? AppColors.destructive
                                  : AppColors.gray200,
                              checkState: _passwordCheckState,
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
                              enabled: _canSubmit && !_submitting,
                              onPressed: (_canSubmit && !_submitting)
                                  ? _submit
                                  : null,
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
                    child: SvgPicture.asset(
                      'assets/icons/cmp/btn/back.svg',
                      fit: BoxFit.contain,
                    ),
                  ),
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
    this.labelFontSize = 16,
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
  final double labelFontSize;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.bodyMedium.copyWith(
            fontSize: labelFontSize,
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
