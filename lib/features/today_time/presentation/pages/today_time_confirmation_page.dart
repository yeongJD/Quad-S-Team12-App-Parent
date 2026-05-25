import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../data/daily_time_rule_store.dart';
import '../data/today_time_mock_data.dart';
import '../models/daily_time_rule.dart';
import '../models/time_plan_confirmation.dart';
import '../styles/time_setup_tokens.dart';
import '../widgets/time_plan_confirmation_widgets.dart';
import '../widgets/time_setup_top_bar.dart';

class TodayTimeConfirmationPage extends StatefulWidget {
  const TodayTimeConfirmationPage({
    super.key,
    this.parentId,
    this.childrenId,
    this.initialData,
  });

  final String? parentId;
  final String? childrenId;
  final TimePlanConfirmationData? initialData;

  @override
  State<TodayTimeConfirmationPage> createState() =>
      _TodayTimeConfirmationPageState();
}

class _TodayTimeConfirmationPageState extends State<TodayTimeConfirmationPage> {
  late final TimePlanConfirmationData _data;
  late bool _childRevisionAllowed;

  @override
  void initState() {
    super.initState();
    _data = widget.initialData ?? TodayTimeMockData.parentOnlyConfirmation;
    _childRevisionAllowed = _data.childRevisionAllowed;
  }

  void _handleBack(BuildContext context) {
    final GoRouter router = GoRouter.of(context);
    if (router.canPop()) {
      router.pop();
      return;
    }
    router.go('/parent-home');
  }

  Future<void> _openEditFlow() async {
    final String? parentId = widget.parentId;
    final String? childrenId = widget.childrenId;
    final List<DailyTimeRule> savedRules =
        parentId == null ||
            parentId.isEmpty ||
            childrenId == null ||
            childrenId.isEmpty
        ? <DailyTimeRule>[]
        : await DailyTimeRuleStore.load(
            parentId: parentId,
            childrenId: childrenId,
          );
    if (!mounted) {
      return;
    }

    final List<DailyTimeRule> rulesToEdit = savedRules.isNotEmpty
        ? savedRules
        : _data.weeklyRules;
    if (rulesToEdit.isEmpty) {
      context.push(_timeSetupLocation);
      return;
    }

    context.push(
      _timeSetupLocation,
      extra: List<DailyTimeRule>.from(rulesToEdit),
    );
  }

  String get _timeSetupLocation {
    final String? parentId = widget.parentId;
    final String? childrenId = widget.childrenId;
    return Uri(
      path: '/today-time/setup',
      queryParameters: <String, String>{
        if (parentId != null && parentId.isNotEmpty) 'parentId': parentId,
        if (childrenId != null && childrenId.isNotEmpty)
          'childrenId': childrenId,
      },
    ).toString();
  }

  @override
  Widget build(BuildContext context) {
    final TimePlanConfirmationData data = _data;
    final TimeSelection? monthlyTotal = data.monthlyTotal;

    return Scaffold(
      backgroundColor: AppColors.gray050,
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: TimeSetupSpacing.screenMaxWidth,
            ),
            child: Column(
              children: [
                TimeSetupTopBar(
                  title: '시간 확인',
                  onBack: () => _handleBack(context),
                ),
                Expanded(
                  child: monthlyTotal == null
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 21.58),
                            child: _EmptyNotice(
                              message: '이번달 시간규칙이 설정되지 않았습니다.',
                            ),
                          ),
                        )
                      : SingleChildScrollView(
                          padding: const EdgeInsets.only(bottom: 32),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  21.58,
                                  7.64,
                                  21.58,
                                  0,
                                ),
                                child: _MonthlyTimeSection(
                                  title: data.monthLabel,
                                  total: monthlyTotal,
                                  onEditTap: _openEditFlow,
                                ),
                              ),
                              const SizedBox(height: 30.09),
                              Container(
                                width: double.infinity,
                                height: 6.294,
                                color: const Color(0xFFEDEEF1),
                              ),
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  21.58,
                                  26.33,
                                  21.58,
                                  0,
                                ),
                                child: _WeeklyPlanSection(
                                  title: data.weekLabel,
                                  total: data.weeklyTotal,
                                  rules: data.weeklyRules,
                                  revisionAllowed: _childRevisionAllowed,
                                  onRevisionChanged: (bool value) {
                                    setState(() {
                                      _childRevisionAllowed = value;
                                    });
                                  },
                                ),
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

class _MonthlyTimeSection extends StatelessWidget {
  const _MonthlyTimeSection({
    required this.title,
    required this.total,
    required this.onEditTap,
  });

  final String title;
  final TimeSelection total;
  final VoidCallback onEditTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TimePlanSectionHeader(
          title: title,
          trailing: EditTimeButton(onTap: onEditTap),
        ),
        const SizedBox(height: 20),
        TimeAmountBox(time: total),
      ],
    );
  }
}

class _WeeklyPlanSection extends StatelessWidget {
  const _WeeklyPlanSection({
    required this.title,
    required this.total,
    required this.rules,
    required this.revisionAllowed,
    required this.onRevisionChanged,
  });

  final String title;
  final TimeSelection? total;
  final List<DailyTimeRule> rules;
  final bool revisionAllowed;
  final ValueChanged<bool> onRevisionChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TimePlanSectionHeader(
          title: title,
          trailing: RevisionToggle(
            value: revisionAllowed,
            onChanged: onRevisionChanged,
          ),
        ),
        const SizedBox(height: 20),
        if (total case final TimeSelection totalTime) ...[
          TimeAmountBox(time: totalTime),
          const SizedBox(height: 13.486),
          DailyPlanRuleList(rules: rules),
        ] else
          const Padding(
            padding: EdgeInsets.only(top: 105.192),
            child: _EmptyNotice(message: '아직 자녀가 이번주 사용계획을\n설정하지 않았어요.'),
          ),
      ],
    );
  }
}

class _EmptyNotice extends StatelessWidget {
  const _EmptyNotice({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: AppTypography.bodyMedium.copyWith(
          fontSize: 16.183,
          height: 1.445,
          letterSpacing: -0.0032,
          color: AppColors.gray300,
        ),
      ),
    );
  }
}
