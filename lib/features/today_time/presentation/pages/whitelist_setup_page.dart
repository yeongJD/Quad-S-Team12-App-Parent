import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/models/result.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../data/repositories/time_plan_repository.dart';
import '../data/whitelist_app_mock_data.dart';
import '../models/daily_time_rule.dart';
import '../models/whitelist_app.dart';
import '../routes/today_time_routes.dart';
import '../styles/time_setup_tokens.dart';
import '../widgets/time_setup_action_button.dart';
import '../widgets/time_setup_top_bar.dart';
import 'today_time_complete_page.dart';

class WhitelistSetupArgs {
  const WhitelistSetupArgs({
    required this.parentId,
    required this.childrenId,
    required this.total,
    required this.rules,
    this.initialSelectedAppIds,
  });

  final String? parentId;
  final String? childrenId;
  final TimeSelection total;
  final List<DailyTimeRule> rules;
  final Set<String>? initialSelectedAppIds;
}

class WhitelistSetupPage extends StatefulWidget {
  const WhitelistSetupPage({
    super.key,
    this.parentId,
    this.childrenId,
    required this.total,
    required this.rules,
    this.categories = WhitelistAppMockData.appleCategories,
    this.initialSelectedAppIds,
  });

  final String? parentId;
  final String? childrenId;
  final TimeSelection total;
  final List<DailyTimeRule> rules;
  final List<WhitelistAppCategory> categories;
  final Set<String>? initialSelectedAppIds;

  @override
  State<WhitelistSetupPage> createState() => _WhitelistSetupPageState();
}

class _WhitelistSetupPageState extends State<WhitelistSetupPage> {
  static const String _allCategoryId = 'all';

  final TextEditingController _searchController = TextEditingController();
  final Set<String> _expandedCategoryIds = <String>{};
  final TimePlanRepository _timePlanRepository = createTimePlanRepository();
  late final Set<String> _selectedAppIds;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _selectedAppIds = <String>{...?widget.initialSelectedAppIds};
    _restoreSavedWhitelistIfNeeded();
  }

  Future<void> _restoreSavedWhitelistIfNeeded() async {
    if (widget.initialSelectedAppIds != null) {
      return;
    }
    final String? parentId = widget.parentId;
    final String? childrenId = widget.childrenId;
    if (parentId == null ||
        parentId.isEmpty ||
        childrenId == null ||
        childrenId.isEmpty) {
      return;
    }

    final Result<Set<String>> result = await _timePlanRepository.loadWhitelist(
      parentId: parentId,
      childrenId: childrenId,
    );
    if (!mounted) {
      return;
    }
    final Set<String> savedAppIds = switch (result) {
      Success<Set<String>>(:final data) => data,
      Failure<Set<String>>() => const <String>{},
    };
    if (savedAppIds.isEmpty) {
      return;
    }
    setState(() {
      _selectedAppIds
        ..clear()
        ..addAll(savedAppIds);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<WhitelistAppCategory> get _filteredCategories {
    final String query = _query.trim().toLowerCase();
    if (query.isEmpty) {
      return _resolvedCategories;
    }

    return _resolvedCategories
        .map((WhitelistAppCategory category) {
          final List<WhitelistApp> apps = category.apps
              .where(
                (WhitelistApp app) => app.name.toLowerCase().contains(query),
              )
              .toList();
          return WhitelistAppCategory(
            id: category.id,
            name: category.name,
            apps: apps,
          );
        })
        .where((WhitelistAppCategory category) => category.apps.isNotEmpty)
        .toList();
  }

  List<WhitelistAppCategory> get _resolvedCategories {
    return widget.categories.map((WhitelistAppCategory category) {
      if (category.id != _allCategoryId) {
        return category;
      }
      return WhitelistAppCategory(
        id: category.id,
        name: category.name,
        apps: _allDescendantApps,
      );
    }).toList();
  }

  List<WhitelistApp> get _allDescendantApps {
    final Set<String> seenIds = <String>{};
    final List<WhitelistApp> apps = <WhitelistApp>[];
    for (final WhitelistAppCategory category in widget.categories) {
      if (category.id == _allCategoryId) {
        continue;
      }
      for (final WhitelistApp app in category.apps) {
        if (seenIds.add(app.id)) {
          apps.add(app);
        }
      }
    }
    return apps;
  }

  void _handleBack(BuildContext context) {
    final GoRouter router = GoRouter.of(context);
    if (router.canPop()) {
      router.pop();
      return;
    }
    router.go(TodayTimeRoutes.monthly);
  }

  void _toggleCategoryOpen(String categoryId) {
    setState(() {
      if (!_expandedCategoryIds.add(categoryId)) {
        _expandedCategoryIds.remove(categoryId);
      }
    });
  }

  void _toggleApp(String appId) {
    setState(() {
      if (!_selectedAppIds.add(appId)) {
        _selectedAppIds.remove(appId);
      }
    });
  }

  void _toggleCategoryApps(WhitelistAppCategory category) {
    if (category.apps.isEmpty) {
      return;
    }
    setState(() {
      final bool allSelected = category.apps.every(
        (WhitelistApp app) => _selectedAppIds.contains(app.id),
      );
      for (final WhitelistApp app in category.apps) {
        if (allSelected) {
          _selectedAppIds.remove(app.id);
        } else {
          _selectedAppIds.add(app.id);
        }
      }
    });
  }

  Future<void> _confirm() async {
    final String? parentId = widget.parentId;
    final String? childrenId = widget.childrenId;
    if (parentId != null &&
        parentId.isNotEmpty &&
        childrenId != null &&
        childrenId.isNotEmpty) {
      await _timePlanRepository.saveWhitelist(
        parentId: parentId,
        childrenId: childrenId,
        appIds: Set<String>.from(_selectedAppIds),
      );
    }
    if (!mounted) {
      return;
    }
    context.go(
      TodayTimeRoutes.complete,
      extra: TodayTimeCompleteData(
        parentId: widget.parentId,
        childrenId: widget.childrenId,
        total: widget.total,
        rules: List<DailyTimeRule>.from(widget.rules),
        whitelistAppIds: Set<String>.from(_selectedAppIds),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<WhitelistAppCategory> categories = _filteredCategories;

    return Scaffold(
      backgroundColor: AppColors.gray050,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: TimeSetupSpacing.screenMaxWidth,
            ),
            child: Column(
              children: [
                TimeSetupTopBar(
                  title: '시간설정',
                  onBack: () => _handleBack(context),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(21, 17, 21, 24),
                    children: [
                      Text(
                        '화이트 리스트 설정',
                        style: AppTypography.heading1Bold.copyWith(
                          fontSize: 24,
                          height: 1.364,
                          letterSpacing: 0,
                          color: AppColors.black,
                        ),
                      ),
                      const SizedBox(height: 28),
                      Text(
                        '자녀가 시간을 다 사용하고 나서도\n'
                        '사용가능한 필수앱(ex. 전화, 메모앱)을 선택해주세요.',
                        style: AppTypography.labelMedium.copyWith(
                          fontSize: 14,
                          height: 1.429,
                          letterSpacing: 0,
                          color: AppColors.gray500,
                        ),
                      ),
                      const SizedBox(height: 34),
                      _WhitelistSearchField(
                        controller: _searchController,
                        onChanged: (String value) {
                          setState(() {
                            _query = value;
                          });
                        },
                      ),
                      const SizedBox(height: 35),
                      if (categories.isEmpty)
                        const _WhitelistEmptyResult()
                      else
                        for (final WhitelistAppCategory category in categories)
                          _WhitelistCategoryTile(
                            category: category,
                            expanded:
                                _expandedCategoryIds.contains(category.id) ||
                                _query.trim().isNotEmpty,
                            selectedAppIds: _selectedAppIds,
                            onExpandTap: () => _toggleCategoryOpen(category.id),
                            onAppTap: _toggleApp,
                            onCategoryCheckTap: () =>
                                _toggleCategoryApps(category),
                          ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 31),
                  child: TimeSetupActionButton(
                    label: '확인',
                    enabled: true,
                    onTap: _confirm,
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

class _WhitelistSearchField extends StatelessWidget {
  const _WhitelistSearchField({
    required this.controller,
    required this.onChanged,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        textInputAction: TextInputAction.search,
        style: AppTypography.headlineMedium.copyWith(
          fontSize: 18,
          height: 1.445,
          letterSpacing: 0,
          color: AppColors.gray800,
        ),
        decoration: InputDecoration(
          hintText: '찾기',
          hintStyle: AppTypography.headlineMedium.copyWith(
            fontSize: 18,
            height: 1.445,
            letterSpacing: 0,
            color: AppColors.gray300,
          ),
          prefixIcon: const Padding(
            padding: EdgeInsets.only(left: 14, right: 10),
            child: Icon(Icons.search_rounded, size: 24),
          ),
          prefixIconConstraints: const BoxConstraints(
            minWidth: 48,
            minHeight: 24,
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 8),
          filled: true,
          fillColor: AppColors.gray050,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.gray200, width: 2),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.primary, width: 2),
          ),
        ),
      ),
    );
  }
}

class _WhitelistCategoryTile extends StatelessWidget {
  const _WhitelistCategoryTile({
    required this.category,
    required this.expanded,
    required this.selectedAppIds,
    required this.onExpandTap,
    required this.onAppTap,
    required this.onCategoryCheckTap,
  });

  final WhitelistAppCategory category;
  final bool expanded;
  final Set<String> selectedAppIds;
  final VoidCallback onExpandTap;
  final ValueChanged<String> onAppTap;
  final VoidCallback onCategoryCheckTap;

  bool get _hasSelectedApps =>
      category.apps.isNotEmpty &&
      category.apps.every(
        (WhitelistApp app) => selectedAppIds.contains(app.id),
      );

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 19),
      child: Column(
        children: [
          SizedBox(
            height: 52,
            child: Row(
              children: [
                const _AppIconPlaceholder(),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    category.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.headlineBold.copyWith(
                      fontSize: 18,
                      height: 1.445,
                      letterSpacing: 0,
                      color: AppColors.gray800,
                    ),
                  ),
                ),
                _ExpandButton(expanded: expanded, onTap: onExpandTap),
                const SizedBox(width: 52),
                _WhitelistCheckButton(
                  selected: _hasSelectedApps,
                  onTap: onCategoryCheckTap,
                ),
              ],
            ),
          ),
          if (expanded)
            Padding(
              padding: const EdgeInsets.only(top: 15, left: 53),
              child: Column(
                children: [
                  for (final WhitelistApp app in category.apps)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 15),
                      child: _WhitelistAppTile(
                        app: app,
                        selected: selectedAppIds.contains(app.id),
                        onTap: () => onAppTap(app.id),
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

class _WhitelistAppTile extends StatelessWidget {
  const _WhitelistAppTile({
    required this.app,
    required this.selected,
    required this.onTap,
  });

  final WhitelistApp app;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: Row(
        children: [
          const _AppIconPlaceholder(size: 31),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              app.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.headlineBold.copyWith(
                fontSize: 18,
                height: 1.445,
                letterSpacing: 0,
                color: AppColors.gray800,
              ),
            ),
          ),
          _WhitelistCheckButton(selected: selected, onTap: onTap),
        ],
      ),
    );
  }
}

class _AppIconPlaceholder extends StatelessWidget {
  const _AppIconPlaceholder({this.size = 33});

  final double size;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFD5D8DE),
        borderRadius: BorderRadius.circular(8),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x1F000000),
            blurRadius: 2,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: SizedBox(width: size, height: size),
    );
  }
}

class _ExpandButton extends StatelessWidget {
  const _ExpandButton({required this.expanded, required this.onTap});

  final bool expanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: expanded ? '앱 리스트 닫기' : '앱 리스트 열기',
      button: true,
      child: InkResponse(
        onTap: onTap,
        radius: 24,
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(
            expanded
                ? Icons.keyboard_arrow_down_rounded
                : Icons.chevron_right_rounded,
            size: 33,
            color: AppColors.gray800,
          ),
        ),
      ),
    );
  }
}

class _WhitelistCheckButton extends StatelessWidget {
  const _WhitelistCheckButton({required this.selected, required this.onTap});

  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      checked: selected,
      button: true,
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          hoverColor: (selected ? AppColors.primary : AppColors.gray400)
              .withValues(alpha: 0.18),
          highlightColor: (selected ? AppColors.primary : AppColors.gray500)
              .withValues(alpha: 0.24),
          splashColor: (selected ? AppColors.primary : AppColors.gray500)
              .withValues(alpha: 0.28),
          customBorder: const CircleBorder(),
          child: Container(
            width: 31,
            height: 31,
            decoration: BoxDecoration(
              color: selected ? AppColors.primary : AppColors.gray200,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_rounded,
              size: 24,
              color: AppColors.white,
            ),
          ),
        ),
      ),
    );
  }
}

class _WhitelistEmptyResult extends StatelessWidget {
  const _WhitelistEmptyResult();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 52),
      child: Text(
        '검색 결과가 없어요.',
        textAlign: TextAlign.center,
        style: AppTypography.bodyMedium.copyWith(
          fontSize: 16,
          height: 1.5,
          letterSpacing: 0,
          color: AppColors.gray500,
        ),
      ),
    );
  }
}
