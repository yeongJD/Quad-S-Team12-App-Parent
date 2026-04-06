import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/theme/app_typography.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final List<_ColorToken> systemColors = <_ColorToken>[
      const _ColorToken('black', AppColors.black, '#000000'),
      const _ColorToken('gray-900', AppColors.gray900, '#171818'),
      const _ColorToken('gray-800', AppColors.gray800, '#2F3032'),
      const _ColorToken('gray-700', AppColors.gray700, '#47484B'),
      const _ColorToken('gray-600', AppColors.gray600, '#5F6165'),
      const _ColorToken('gray-500', AppColors.gray500, '#777A7F'),
      const _ColorToken('gray-400', AppColors.gray400, '#91969E'),
      const _ColorToken('gray-300', AppColors.gray300, '#A7ACB2'),
      const _ColorToken('gray-200', AppColors.gray200, '#D5D8DE'),
      const _ColorToken('gray-100', AppColors.gray100, '#F5F7FA'),
      const _ColorToken('gray-050', AppColors.gray050, '#FAFBFC'),
      const _ColorToken('white', AppColors.white, '#FFFFFF'),
    ];
    final List<_TypeSpec> typeSpecs = <_TypeSpec>[
      const _TypeSpec(
        'Heading 1 / Bold',
        AppTypography.heading1Bold,
        24,
        1.364,
        -1.94,
      ),
      const _TypeSpec(
        'Heading 1 / Medium',
        AppTypography.heading1Medium,
        24,
        1.364,
        -1.94,
      ),
      const _TypeSpec(
        'Heading 1 / Regular',
        AppTypography.heading1Regular,
        24,
        1.364,
        -1.94,
      ),
      const _TypeSpec(
        'Heading 2 / Bold',
        AppTypography.heading2Bold,
        20,
        1.4,
        -1.2,
      ),
      const _TypeSpec(
        'Heading 2 / Medium',
        AppTypography.heading2Medium,
        20,
        1.4,
        -1.2,
      ),
      const _TypeSpec(
        'Heading 2 / Regular',
        AppTypography.heading2Regular,
        20,
        1.4,
        -1.2,
      ),
      const _TypeSpec(
        'Headline / Bold',
        AppTypography.headlineBold,
        18,
        1.445,
        -0.02,
      ),
      const _TypeSpec(
        'Headline / Medium',
        AppTypography.headlineMedium,
        18,
        1.445,
        -0.02,
      ),
      const _TypeSpec(
        'Headline / Regular',
        AppTypography.headlineRegular,
        18,
        1.445,
        -0.02,
      ),
      const _TypeSpec('Body / Bold', AppTypography.bodyBold, 16, 1.5, 0.57),
      const _TypeSpec('Body / Medium', AppTypography.bodyMedium, 16, 1.5, 0.57),
      const _TypeSpec(
        'Body / Regular',
        AppTypography.bodyRegular,
        16,
        1.5,
        0.57,
      ),
      const _TypeSpec('Label / Bold', AppTypography.labelBold, 14, 1.429, 1.45),
      const _TypeSpec(
        'Label / Medium',
        AppTypography.labelMedium,
        14,
        1.429,
        1.45,
      ),
      const _TypeSpec(
        'Label / Regular',
        AppTypography.labelRegular,
        14,
        1.429,
        1.45,
      ),
      const _TypeSpec(
        'Caption / Bold',
        AppTypography.captionBold,
        12,
        1.334,
        2.52,
      ),
      const _TypeSpec(
        'Caption / Medium',
        AppTypography.captionMedium,
        12,
        1.334,
        2.52,
      ),
      const _TypeSpec(
        'Caption / Regular',
        AppTypography.captionRegular,
        12,
        1.334,
        2.52,
      ),
    ];

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AppTokens.pageHorizontal,
                AppTokens.pageTop,
                AppTokens.pageHorizontal,
                AppTokens.pageHorizontal,
              ),
              sliver: SliverList.list(
                children: [
                  const _HeroSection(),
                  const SizedBox(height: AppTokens.sectionGap),
                  const _SectionTitle(
                    title: 'Role',
                    subtitle:
                        'Semantic status tokens extracted from the guide frame.',
                  ),
                  const SizedBox(height: AppTokens.itemGap),
                  LayoutBuilder(
                    builder:
                        (BuildContext context, BoxConstraints constraints) {
                          final bool compact = constraints.maxWidth < 720;
                          if (compact) {
                            return const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _SectionCard(child: _RoleSection()),
                                SizedBox(height: AppTokens.itemGap),
                                _SectionCard(child: _PrimaryColorHero()),
                              ],
                            );
                          }

                          return const Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: _SectionCard(child: _RoleSection()),
                              ),
                              SizedBox(width: AppTokens.itemGap),
                              Expanded(
                                child: _SectionCard(child: _PrimaryColorHero()),
                              ),
                            ],
                          );
                        },
                  ),
                  const SizedBox(height: AppTokens.sectionGap),
                  const _SectionTitle(
                    title: 'System Colors',
                    subtitle:
                        'Core gray scale and neutral surfaces from Figma.',
                  ),
                  const SizedBox(height: AppTokens.itemGap),
                  _SectionCard(
                    child: LayoutBuilder(
                      builder:
                          (BuildContext context, BoxConstraints constraints) {
                            final int crossAxisCount =
                                constraints.maxWidth >= 1200
                                ? 6
                                : constraints.maxWidth >= 900
                                ? 4
                                : constraints.maxWidth >= 560
                                ? 3
                                : 2;

                            return GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: crossAxisCount,
                                    mainAxisSpacing: AppTokens.itemGap,
                                    crossAxisSpacing: AppTokens.itemGap,
                                    childAspectRatio: 0.92,
                                  ),
                              itemCount: systemColors.length,
                              itemBuilder: (BuildContext context, int index) {
                                return _ColorSwatchCard(
                                  token: systemColors[index],
                                );
                              },
                            );
                          },
                    ),
                  ),
                  const SizedBox(height: AppTokens.sectionGap),
                  const _SectionTitle(
                    title: 'Typography',
                    subtitle:
                        'Pretendard styles mirrored from Heading, Headline, Body, Label, Caption.',
                  ),
                  const SizedBox(height: AppTokens.itemGap),
                  _SectionCard(
                    child: Column(
                      children: typeSpecs
                          .map((_TypeSpec spec) => _TypeSpecRow(spec: spec))
                          .toList(),
                    ),
                  ),
                  const SizedBox(height: AppTokens.sectionGap),
                  const _SectionTitle(
                    title: 'Layout',
                    subtitle: 'Mobile baseline from the guide frame.',
                  ),
                  const SizedBox(height: AppTokens.itemGap),
                  _SectionCard(
                    child: LayoutBuilder(
                      builder:
                          (BuildContext context, BoxConstraints constraints) {
                            final bool compact = constraints.maxWidth < 860;
                            if (compact) {
                              return const Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _LayoutMetrics(),
                                  SizedBox(height: AppTokens.sectionGap),
                                  _MobileFramePreview(),
                                ],
                              );
                            }

                            return const Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(child: _LayoutMetrics()),
                                SizedBox(width: AppTokens.sectionGap),
                                Expanded(child: _MobileFramePreview()),
                              ],
                            );
                          },
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

class _HeroSection extends StatelessWidget {
  const _HeroSection();

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Design System', style: textTheme.displayLarge),
          const SizedBox(height: AppTokens.mediumGap),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Text(
              'Figma 가이드 프레임을 기준으로 foundation을 먼저 정리했습니다. 이 화면은 색상, 의미 토큰, 타이포그래피, 모바일 레이아웃 기준을 한 번에 검증하기 위한 쇼케이스입니다.',
              style: textTheme.bodyLarge?.copyWith(
                color: AppColors.labelNormal,
              ),
            ),
          ),
          const SizedBox(height: AppTokens.itemGap),
          const Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _MetaChip(label: 'Pretendard'),
              _MetaChip(label: '18 text styles'),
              _MetaChip(label: '12 gray scales'),
              _MetaChip(label: '3 status roles'),
              _MetaChip(label: '375 mobile base'),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.headlineLarge),
        const SizedBox(height: AppTokens.smallGap),
        Text(
          subtitle,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTokens.cardPadding),
        child: child,
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppColors.labelStrong,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _RoleSection extends StatelessWidget {
  const _RoleSection();

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Status', style: textTheme.headlineLarge),
        const SizedBox(height: AppTokens.itemGap),
        const Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            _RoleToken(label: 'Positive', color: AppColors.positive),
            _RoleToken(label: 'Cautionary', color: AppColors.cautionary),
            _RoleToken(label: 'Destructive', color: AppColors.destructive),
          ],
        ),
      ],
    );
  }
}

class _RoleToken extends StatelessWidget {
  const _RoleToken({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 92,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          const SizedBox(height: 10),
          Text(label, style: Theme.of(context).textTheme.labelMedium),
        ],
      ),
    );
  }
}

class _PrimaryColorHero extends StatelessWidget {
  const _PrimaryColorHero();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTokens.cardPadding),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(AppTokens.cardRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'primary',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: AppColors.white.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '#3A99F8',
            style: Theme.of(
              context,
            ).textTheme.headlineLarge?.copyWith(color: AppColors.white),
          ),
          const SizedBox(height: 6),
          Text(
            'RGB 58 153 248',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.white.withValues(alpha: 0.9),
            ),
          ),
        ],
      ),
    );
  }
}

class _ColorSwatchCard extends StatelessWidget {
  const _ColorSwatchCard({required this.token});

  final _ColorToken token;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: token.color,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  token.name,
                  style: Theme.of(context).textTheme.labelMedium,
                ),
                const SizedBox(height: 6),
                Text(
                  token.hex,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.gray600,
                    letterSpacing: 0.4,
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

class _TypeSpecRow extends StatelessWidget {
  const _TypeSpecRow({required this.spec});

  final _TypeSpec spec;

  @override
  Widget build(BuildContext context) {
    final Widget meta = Wrap(
      spacing: 16,
      runSpacing: 8,
      children: [
        _MetricTag(label: spec.name),
        const _MetricTag(label: 'Pretendard'),
        _MetricTag(label: spec.fontSize.toStringAsFixed(0)),
        _MetricTag(label: '${(spec.lineHeight * 100).toStringAsFixed(1)}%'),
        _MetricTag(label: spec.letterSpacing.toStringAsFixed(2)),
      ],
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'The quick brown fox jumps over the lazy dog',
            style: spec.style,
          ),
          const SizedBox(height: 10),
          meta,
          const SizedBox(height: 14),
          const Divider(height: 1),
        ],
      ),
    );
  }
}

class _MetricTag extends StatelessWidget {
  const _MetricTag({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
        color: AppColors.gray600,
        letterSpacing: 0.2,
      ),
    );
  }
}

class _LayoutMetrics extends StatelessWidget {
  const _LayoutMetrics();

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Mobile Baseline', style: textTheme.headlineLarge),
        const SizedBox(height: AppTokens.itemGap),
        Text(
          'The guide frame defines a 375pt canvas with 24pt horizontal margin and a 327pt content width. These values are now available as layout tokens.',
          style: textTheme.bodyLarge?.copyWith(color: AppColors.labelNormal),
        ),
        const SizedBox(height: AppTokens.sectionGap),
        const _MetricLine(label: 'mobileFrameWidth', value: '375'),
        const _MetricLine(label: 'mobileCanvasHeight', value: '812'),
        const _MetricLine(label: 'mobileHorizontalPadding', value: '24'),
        const _MetricLine(label: 'mobileContentWidth', value: '327'),
      ],
    );
  }
}

class _MetricLine extends StatelessWidget {
  const _MetricLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.gray600),
            ),
          ),
          Text(value, style: Theme.of(context).textTheme.labelLarge),
        ],
      ),
    );
  }
}

class _MobileFramePreview extends StatelessWidget {
  const _MobileFramePreview();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: FittedBox(
        child: Container(
          width: AppTokens.mobileFrameWidth,
          height: AppTokens.mobileCanvasHeight,
          decoration: BoxDecoration(
            color: const Color(0xFFFFA8AF),
            borderRadius: BorderRadius.circular(36),
            border: Border.all(color: AppColors.gray200),
          ),
          child: Stack(
            children: [
              Positioned(
                top: 18,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        '9:41',
                        style: AppTypography.labelRegular.copyWith(
                          fontSize: 12,
                          letterSpacing: 0,
                        ),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 24),
                      child: Icon(Icons.signal_cellular_alt, size: 16),
                    ),
                  ],
                ),
              ),
              Positioned(
                left: AppTokens.mobileHorizontalPadding,
                top: 110,
                child: Container(
                  width: AppTokens.mobileContentWidth,
                  height: 120,
                  decoration: BoxDecoration(
                    color: AppColors.white.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: AppColors.white.withValues(alpha: 0.45),
                    ),
                  ),
                ),
              ),
              const Positioned(left: 121, bottom: 8, child: _HomeIndicator()),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeIndicator extends StatelessWidget {
  const _HomeIndicator();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 134,
      height: 5,
      decoration: BoxDecoration(
        color: AppColors.black,
        borderRadius: BorderRadius.circular(999),
      ),
    );
  }
}

class _ColorToken {
  const _ColorToken(this.name, this.color, this.hex);

  final String name;
  final Color color;
  final String hex;
}

class _TypeSpec {
  const _TypeSpec(
    this.name,
    this.style,
    this.fontSize,
    this.lineHeight,
    this.letterSpacing,
  );

  final String name;
  final TextStyle style;
  final double fontSize;
  final double lineHeight;
  final double letterSpacing;
}
