import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../data/daily_time_rule_store.dart';
import '../data/today_time_mock_data.dart';
import '../models/daily_time_rule.dart';
import '../routes/today_time_routes.dart';
import '../styles/time_setup_tokens.dart';
import '../widgets/daily_time_rule_card.dart';
import '../widgets/daily_time_rule_sheet.dart';
import '../widgets/time_setup_action_button.dart';
import '../widgets/time_setup_header.dart';
import '../widgets/time_setup_top_bar.dart';
import '../widgets/time_tip_popover.dart';
import 'monthly_time_setup_page.dart';

class TodayTimeSetupPage extends StatefulWidget {
  const TodayTimeSetupPage({
    super.key,
    this.parentId,
    this.childrenId,
    this.initialRules = TodayTimeMockData.emptyDailyRules,
    this.initialMonthlyTotalMinutes,
    this.initialWhitelistAppIds,
  });

  final String? parentId;
  final String? childrenId;
  final List<DailyTimeRule> initialRules;
  final int? initialMonthlyTotalMinutes;
  final Set<String>? initialWhitelistAppIds;

  @override
  State<TodayTimeSetupPage> createState() => _TodayTimeSetupPageState();
}

class TodayTimeSetupArgs {
  const TodayTimeSetupArgs({
    required this.rules,
    this.monthlyTotalMinutes,
    this.whitelistAppIds,
  });

  final List<DailyTimeRule> rules;
  final int? monthlyTotalMinutes;
  final Set<String>? whitelistAppIds;
}

class _TodayTimeSetupPageState extends State<TodayTimeSetupPage> {
  late final List<DailyTimeRule> _rules;

  bool _showTip = false;

  bool get _hasRules => _rules.isNotEmpty;
  bool get _canContinue => coversEveryWeekday(_rules);

  @override
  void initState() {
    super.initState();
    _rules = <DailyTimeRule>[...widget.initialRules];
    _restoreSavedRulesIfNeeded();
  }

  Future<void> _restoreSavedRulesIfNeeded() async {
    if (_rules.isNotEmpty) {
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

    final List<DailyTimeRule> savedRules = await DailyTimeRuleStore.load(
      parentId: parentId,
      childrenId: childrenId,
    );
    if (!mounted || savedRules.isEmpty) {
      return;
    }

    setState(() {
      _rules
        ..clear()
        ..addAll(savedRules);
    });
  }

  void _toggleTip() {
    setState(() {
      _showTip = !_showTip;
    });
  }

  void _closeTip() {
    if (!_showTip) {
      return;
    }
    setState(() {
      _showTip = false;
    });
  }

  void _handleBack(BuildContext context) {
    final GoRouter router = GoRouter.of(context);
    if (router.canPop()) {
      router.pop();
      return;
    }
    router.go('/parent-home');
  }

  Future<void> _openRuleSheet({DailyTimeRule? initialRule, int? index}) async {
    final Set<int> unavailableDays = <int>{};
    for (int ruleIndex = 0; ruleIndex < _rules.length; ruleIndex++) {
      if (ruleIndex == index) {
        continue;
      }
      unavailableDays.addAll(_rules[ruleIndex].days);
    }

    final DailyTimeRule? result = await showModalBottomSheet<DailyTimeRule>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: const Color.fromRGBO(68, 68, 68, 0.6),
      builder: (BuildContext context) {
        return DailyTimeRuleSheet(
          initialRule: initialRule,
          unavailableDays: unavailableDays,
        );
      },
    );

    if (result == null || !mounted) {
      return;
    }
    setState(() {
      if (index == null) {
        _rules.add(result);
      } else {
        _rules[index] = result;
      }
    });
  }

  Future<void> _continueToMonthlySetup() async {
    if (!_canContinue) {
      return;
    }
    final String? parentId = widget.parentId;
    final String? childrenId = widget.childrenId;
    if (parentId != null &&
        parentId.isNotEmpty &&
        childrenId != null &&
        childrenId.isNotEmpty) {
      await DailyTimeRuleStore.save(
        parentId: parentId,
        childrenId: childrenId,
        rules: List<DailyTimeRule>.from(_rules),
      );
    }
    if (!mounted) {
      return;
    }
    context.push(
      TodayTimeRoutes.monthly,
      extra: MonthlyTimeSetupArgs(
        parentId: parentId,
        childrenId: childrenId,
        rules: List<DailyTimeRule>.from(_rules),
        initialMonthlyTotalMinutes: widget.initialMonthlyTotalMinutes,
        initialSelectedAppIds: widget.initialWhitelistAppIds,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.gray050,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: TimeSetupSpacing.screenMaxWidth,
            ),
            child: Stack(
              children: [
                Column(
                  children: [
                    TimeSetupTopBar(
                      title: '시간설정',
                      onBack: () => _handleBack(context),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(
                          TimeSetupSpacing.horizontalPadding,
                          TimeSetupSpacing.contentTopGap,
                          TimeSetupSpacing.horizontalPadding,
                          24,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TimeSetupHeader(
                              title: '일간 시간 설정',
                              description:
                                  '자녀가 하루에 사용했으면 하는 시간을 설정해주세요!\n'
                                  '이 시간을 이용해서 주간 총시간이 자동 계산 됩니다.',
                              showTip: _showTip,
                              onTipTap: _toggleTip,
                            ),
                            SizedBox(
                              height: _hasRules
                                  ? TimeSetupSpacing.listTopGap
                                  : TimeSetupSpacing.emptyAddTopGap,
                            ),
                            if (_hasRules)
                              DailyTimeRuleList(
                                rules: _rules,
                                onEdit: (int index) {
                                  _openRuleSheet(
                                    initialRule: _rules[index],
                                    index: index,
                                  );
                                },
                                onAdd: () => _openRuleSheet(),
                              )
                            else
                              Center(
                                child: TimeSetupAddButton(
                                  onTap: () => _openRuleSheet(),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        TimeSetupSpacing.horizontalPadding,
                        0,
                        TimeSetupSpacing.horizontalPadding,
                        TimeSetupSpacing.bottomButtonGap,
                      ),
                      child: TimeSetupActionButton(
                        label: '확인',
                        enabled: _canContinue,
                        onTap: _continueToMonthlySetup,
                      ),
                    ),
                  ],
                ),
                if (_showTip)
                  Positioned(
                    left: 42,
                    right: 38,
                    top: 111,
                    child: TimeTipPopover(onClose: _closeTip),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
