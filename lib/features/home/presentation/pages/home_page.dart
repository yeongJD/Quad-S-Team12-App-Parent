import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppTokens.pageHorizontal,
            AppTokens.pageTop,
            AppTokens.pageHorizontal,
            AppTokens.pageHorizontal,
          ),
          children: [
            Text('Quad S Team12 App', style: textTheme.displayLarge),
            const SizedBox(height: 12),
            Text(
              'Figma MCP로 화면을 붙이기 전에 사용할 수 있는 앱 기본 골격입니다.',
              style: textTheme.bodyLarge,
            ),
            const SizedBox(height: AppTokens.sectionGap),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Ready for screens', style: textTheme.titleLarge),
                    const SizedBox(height: 12),
                    Text(
                      '공통 테마, 라우터, 홈 화면 엔트리가 준비되어 있어서 이후 디자인을 페이지 단위로 추가하기 좋습니다.',
                      style: textTheme.bodyMedium,
                    ),
                    const SizedBox(height: AppTokens.itemGap),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: const [
                        _TokenChip(label: 'Material 3'),
                        _TokenChip(label: 'go_router'),
                        _TokenChip(label: 'Google Fonts'),
                        _TokenChip(label: 'Feature-first'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppTokens.sectionGap),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFDBEAFE), Color(0xFFFFEDD5)],
                ),
                borderRadius: BorderRadius.circular(AppTokens.cardRadius),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Next step', style: textTheme.titleLarge),
                  const SizedBox(height: 8),
                  Text(
                    '피그마 링크나 노드를 주시면 이 구조 위에 실제 화면을 바로 구현해갈 수 있습니다.',
                    style: textTheme.bodyMedium?.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TokenChip extends StatelessWidget {
  const _TokenChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.surfaceMuted),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
