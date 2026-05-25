import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/auth/account_store.dart';
import '../../../../core/auth/auth_session.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../common/presentation/widgets/confirmation_dialog.dart';

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
    return showAppConfirmationDialog(
      context: context,
      barrierLabel: 'delete-account-dialog',
      message: '탈퇴하시겠습니까?',
      onConfirm: () {
        final GoRouter router = GoRouter.of(context);
        context.pop();
        router.go('/mypage/delete-complete');
      },
    );
  }

  Future<void> _showLogoutDialog(BuildContext context) {
    return showAppConfirmationDialog(
      context: context,
      barrierLabel: 'logout-dialog',
      message: '로그아웃하시겠습니까?',
      onConfirm: () async {
        final GoRouter router = GoRouter.of(context);
        context.pop();
        await AuthSession.logout();
        if (!mounted) {
          return;
        }
        router.go('/');
      },
    );
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
                const SizedBox(height: 20),
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
                          onTap: () => _showLogoutDialog(context),
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
    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(8),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        hoverColor: foregroundColor.withValues(alpha: 0.08),
        highlightColor: foregroundColor.withValues(alpha: 0.12),
        splashColor: foregroundColor.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          width: width,
          height: 37,
          child: Center(
            child: Text(
              label,
              style: AppTypography.bodyMedium.copyWith(
                color: foregroundColor,
                height: 1.5,
                letterSpacing: 0.091,
              ),
            ),
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
          Material(
            color: const Color(0xFFEDEEF1),
            borderRadius: BorderRadius.circular(8),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onEditTap,
              hoverColor: AppColors.gray600.withValues(alpha: 0.08),
              highlightColor: AppColors.gray600.withValues(alpha: 0.12),
              splashColor: AppColors.gray600.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                height: 37,
                padding: const EdgeInsets.symmetric(horizontal: 13),
                alignment: Alignment.center,
                child: Text(
                  '수정하기',
                  style: AppTypography.bodyMedium.copyWith(
                    height: 1.5,
                    letterSpacing: 0.082,
                    color: AppColors.gray600,
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
