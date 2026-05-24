import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/auth/account_store.dart';
import '../../../../core/auth/auth_session.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

class MyPage extends StatefulWidget {
  const MyPage({super.key});

  @override
  State<MyPage> createState() => _MyPageState();
}

class _MyPageState extends State<MyPage> {
  String _name = AuthSession.fallbackName;
  String _email = '';

  @override
  void initState() {
    super.initState();
    _loadUsername();
  }

  Future<void> _loadUsername() async {
    final String? parentId = await AuthSession.getCurrentParentId();
    final ParentAccount? account = parentId == null
        ? null
        : await AccountStore.getAccountById(parentId);
    if (!mounted) {
      return;
    }
    setState(() {
      _name = account?.name ?? AuthSession.fallbackName;
      _email = account?.email ?? '';
    });
  }

  Future<void> _showDeleteAccountDialog(BuildContext context) {
    return showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'delete-account-dialog',
      barrierColor: const Color.fromRGBO(68, 68, 68, 0.6),
      pageBuilder: (context, animation, secondaryAnimation) {
        return Material(
          type: MaterialType.transparency,
          child: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 375),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 21),
                  child: _DeleteAccountDialog(),
                ),
              ),
            ),
          ),
        );
      },
      transitionDuration: const Duration(milliseconds: 160),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          ),
          child: child,
        );
      },
    );
  }

  Future<void> _logout() async {
    await AuthSession.logout();
    if (!mounted) {
      return;
    }
    context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.gray100,
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 375),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: _MyPageTopBar(onBack: context.pop),
                ),
                const SizedBox(height: 57),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: _InfoRow(label: '이름', value: _name),
                ),
                const SizedBox(height: 31),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: _InfoRow(label: '이메일', value: _email),
                ),
                const SizedBox(height: 31),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: _PasswordRow(
                    onEditTap: () => context.push('/mypage/password'),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  height: 6.294,
                  color: const Color(0xFFEDEEF1),
                ),
                const SizedBox(height: 29),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _MyPageActionButton(
                          label: '로그아웃',
                          width: 89,
                          backgroundColor: const Color(0xFFEDEEF1),
                          foregroundColor: AppColors.gray600,
                          onTap: _logout,
                        ),
                        const SizedBox(width: 12),
                        _MyPageActionButton(
                          label: '탈퇴하기',
                          width: 80,
                          backgroundColor: const Color(0xFFFFD3D3),
                          foregroundColor: AppColors.destructive,
                          onTap: () => _showDeleteAccountDialog(context),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MyPageActionButton extends StatelessWidget {
  const _MyPageActionButton({
    required this.label,
    required this.width,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.onTap,
  });

  final String label;
  final double width;
  final Color backgroundColor;
  final Color foregroundColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: width,
        height: 37,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: AppTypography.bodyMedium.copyWith(
            color: foregroundColor,
            height: 1.5,
            letterSpacing: 0.091,
          ),
        ),
      ),
    );
  }
}

class _DeleteAccountDialog extends StatelessWidget {
  const _DeleteAccountDialog();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 294.897,
        height: 189.705,
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 33, 18, 27),
          child: Column(
            children: [
              Container(
                width: 28.77,
                height: 28.77,
                decoration: const BoxDecoration(
                  color: AppColors.destructive,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: SizedBox(
                    width: 8,
                    height: 16,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Positioned(
                          top: 1.5,
                          child: Container(
                            width: 2.4,
                            height: 9.6,
                            decoration: BoxDecoration(
                              color: AppColors.white,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 0.5,
                          child: Container(
                            width: 2.4,
                            height: 2.4,
                            decoration: const BoxDecoration(
                              color: AppColors.white,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '탈퇴하시겠습니까?',
                style: AppTypography.labelBold.copyWith(
                  fontSize: 14.39,
                  height: 1.5,
                  letterSpacing: 0.082,
                  color: AppColors.gray800,
                  decoration: TextDecoration.none,
                ),
              ),
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _DeleteDialogButton(
                    label: '취소',
                    filled: false,
                    onTap: context.pop,
                  ),
                  const SizedBox(width: 13.486),
                  _DeleteDialogButton(
                    label: '확인',
                    filled: true,
                    onTap: () {
                      final GoRouter router = GoRouter.of(context);
                      context.pop();
                      router.go('/mypage/delete-complete');
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DeleteDialogButton extends StatelessWidget {
  const _DeleteDialogButton({
    required this.label,
    required this.filled,
    required this.onTap,
  });

  final String label;
  final bool filled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 107.889,
        height: 37.761,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: filled ? AppColors.primary : const Color(0xFFEBF5FE),
          borderRadius: BorderRadius.circular(8),
          border: filled
              ? null
              : Border.all(color: AppColors.primary, width: 0.899),
        ),
        child: Text(
          label,
          style: AppTypography.labelMedium.copyWith(
            fontSize: 12.59,
            height: 1.429,
            letterSpacing: 0.1826,
            color: filled ? AppColors.white : AppColors.primary,
            decoration: TextDecoration.none,
          ),
        ),
      ),
    );
  }
}

class _MyPageTopBar extends StatelessWidget {
  const _MyPageTopBar({required this.onBack});

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
              '마이페이지',
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

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 24,
      child: Row(
        children: [
          SizedBox(
            width: 68,
            child: Text(
              label,
              style: AppTypography.bodyMedium.copyWith(
                height: 1.5,
                letterSpacing: 0.082,
                color: AppColors.gray600,
              ),
            ),
          ),
          Container(width: 1, height: 19.78, color: AppColors.gray200),
          const SizedBox(width: 24),
          Expanded(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.bodyMedium.copyWith(
                height: 1.5,
                letterSpacing: 0.082,
                color: const Color(0xFF050505),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PasswordRow extends StatelessWidget {
  const _PasswordRow({required this.onEditTap});

  final VoidCallback onEditTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 37,
      child: Row(
        children: [
          Text(
            '비밀번호',
            style: AppTypography.bodyMedium.copyWith(
              height: 1.5,
              letterSpacing: 0.082,
              color: AppColors.gray600,
            ),
          ),
          const SizedBox(width: 13),
          GestureDetector(
            onTap: onEditTap,
            behavior: HitTestBehavior.opaque,
            child: Container(
              height: 37,
              padding: const EdgeInsets.symmetric(horizontal: 13),
              decoration: BoxDecoration(
                color: AppColors.gray600,
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              child: Text(
                '수정하기',
                style: AppTypography.bodyMedium.copyWith(
                  height: 1.5,
                  letterSpacing: 0.082,
                  color: AppColors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
