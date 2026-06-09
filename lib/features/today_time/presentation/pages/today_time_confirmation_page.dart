import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/models/result.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../data/repositories/time_plan_repository.dart';
import '../data/today_time_mock_data.dart';
import '../models/daily_time_rule.dart';
import '../models/time_plan_confirmation.dart';
import '../styles/time_setup_tokens.dart';
import '../widgets/time_plan_confirmation_widgets.dart';
import '../widgets/time_setup_top_bar.dart';
import 'today_time_setup_page.dart';

class TodayTimeConfirmationPage extends StatefulWidget {
  const TodayTimeConfirmationPage({
    super.key,
    this.parentId,
    this.childrenId,
    this.demo,
    this.initialData,
  });

  final String? parentId;
  final String? childrenId;
  final String? demo;
  final TimePlanConfirmationData? initialData;

  @override
  State<TodayTimeConfirmationPage> createState() =>
      _TodayTimeConfirmationPageState();
}

class _TodayTimeConfirmationPageState extends State<TodayTimeConfirmationPage> {
  final TimePlanRepository _timePlanRepository = createTimePlanRepository();
  late TimePlanConfirmationData _data;
  late bool _childRevisionAllowed;

  Future<List<DailyTimeRule>> _loadRules({
    required String parentId,
    required String childrenId,
    required Future<Result<List<DailyTimeRule>>> Function({
      required String parentId,
      required String childrenId,
    })
    loader,
  }) async {
    final Result<List<DailyTimeRule>> result = await loader(
      parentId: parentId,
      childrenId: childrenId,
    );
    return switch (result) {
      Success<List<DailyTimeRule>>(:final data) => data,
      Failure<List<DailyTimeRule>>() => const <DailyTimeRule>[],
    };
  }

  Future<int?> _loadMonthlyTotal({
    required String parentId,
    required String childrenId,
  }) async {
    final Result<int?> result = await _timePlanRepository.loadMonthlyTotal(
      parentId: parentId,
      childrenId: childrenId,
    );
    return switch (result) {
      Success<int?>(:final data) => data,
      Failure<int?>() => null,
    };
  }

  Future<Set<String>> _loadWhitelist({
    required String parentId,
    required String childrenId,
  }) async {
    final Result<Set<String>> result = await _timePlanRepository.loadWhitelist(
      parentId: parentId,
      childrenId: childrenId,
    );
    return switch (result) {
      Success<Set<String>>(:final data) => data,
      Failure<Set<String>>() => const <String>{},
    };
  }

  @override
  void initState() {
    super.initState();
    _data = widget.initialData ?? TodayTimeMockData.parentOnlyConfirmation;
    _childRevisionAllowed = _data.childRevisionAllowed;
    if (widget.demo == 'filled') {
      return;
    }
    _loadStoredTimePlan();
  }

  Future<void> _loadStoredTimePlan() async {
    final String? parentId = widget.parentId;
    final String? childrenId = widget.childrenId;
    if (parentId == null ||
        parentId.isEmpty ||
        childrenId == null ||
        childrenId.isEmpty) {
      return;
    }

    final List<DailyTimeRule> parentRules = await _loadRules(
      parentId: parentId,
      childrenId: childrenId,
      loader: _timePlanRepository.loadDailyRules,
    );
    final List<DailyTimeRule> childWeeklyRules = await _loadRules(
      parentId: parentId,
      childrenId: childrenId,
      loader: _timePlanRepository.loadChildWeeklyRules,
    );
    final int? savedMonthlyMinutes = await _loadMonthlyTotal(
      parentId: parentId,
      childrenId: childrenId,
    );
    final int calculatedMonthlyMinutes = parentRules.isEmpty
        ? 0
        : _calculateMonthlyMinutes(parentRules);
    final int savedMinutes = savedMonthlyMinutes ?? 0;
    final int monthlyTotalMinutes = savedMinutes < calculatedMonthlyMinutes
        ? calculatedMonthlyMinutes
        : savedMinutes;
    if (monthlyTotalMinutes <= 0) {
      return;
    }
    if (!mounted) {
      return;
    }

    final _DateLabels labels = _DateLabels.current();
    final TimePlanConfirmationData storedData = childWeeklyRules.isEmpty
        ? TimePlanConfirmationData(
            monthLabel: labels.monthLabel,
            monthlyTotal: _timeFromMinutes(monthlyTotalMinutes),
            weekLabel: labels.weekLabel,
            weeklyRules: const <DailyTimeRule>[],
            childRevisionAllowed: false,
          )
        : TimePlanConfirmationData(
            monthLabel: labels.monthLabel,
            monthlyTotal: _timeFromMinutes(monthlyTotalMinutes),
            weekLabel: labels.weekLabel,
            weeklyTotal: _timeFromMinutes(
              _calculateWeeklyMinutes(childWeeklyRules),
            ),
            weeklyRules: childWeeklyRules,
            childRevisionAllowed: true,
          );

    setState(() {
      _data = storedData;
      _childRevisionAllowed = storedData.childRevisionAllowed;
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

  Future<void> _openEditFlow() async {
    final String? parentId = widget.parentId;
    final String? childrenId = widget.childrenId;
    final bool missingIds =
        parentId == null ||
        parentId.isEmpty ||
        childrenId == null ||
        childrenId.isEmpty;
    final List<DailyTimeRule> savedRules = missingIds
        ? <DailyTimeRule>[]
        : await _loadRules(
            parentId: parentId,
            childrenId: childrenId,
            loader: _timePlanRepository.loadDailyRules,
          );
    final Set<String> savedWhitelistAppIds = missingIds
        ? <String>{}
        : await _loadWhitelist(parentId: parentId, childrenId: childrenId);
    final int? savedMonthlyTotalMinutes = missingIds
        ? null
        : await _loadMonthlyTotal(parentId: parentId, childrenId: childrenId);
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
      extra: TodayTimeSetupArgs(
        rules: List<DailyTimeRule>.from(rulesToEdit),
        monthlyTotalMinutes: savedMonthlyTotalMinutes,
        whitelistAppIds: Set<String>.from(savedWhitelistAppIds),
      ),
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

  int _calculateMonthlyMinutes(List<DailyTimeRule> rules) {
    final DateTime now = DateTime.now();
    final int lastDay = DateTime(now.year, now.month + 1, 0).day;
    final List<int> weekdayCounts = List<int>.filled(DateTime.daysPerWeek, 0);
    for (int day = 1; day <= lastDay; day++) {
      final int weekdayIndex = DateTime(now.year, now.month, day).weekday - 1;
      weekdayCounts[weekdayIndex]++;
    }

    int total = 0;
    for (final DailyTimeRule rule in rules) {
      final int dailyMinutes = rule.time.hour * 60 + rule.time.minute;
      for (final int dayIndex in rule.days) {
        if (dayIndex < 0 || dayIndex >= weekdayCounts.length) {
          continue;
        }
        total += dailyMinutes * weekdayCounts[dayIndex];
      }
    }
    return total;
  }

  int _calculateWeeklyMinutes(List<DailyTimeRule> rules) {
    int total = 0;
    for (final DailyTimeRule rule in rules) {
      final int dailyMinutes = rule.time.hour * 60 + rule.time.minute;
      total += dailyMinutes * rule.days.length;
    }
    return total;
  }

  TimeSelection _timeFromMinutes(int minutes) {
    return TimeSelection(hour: minutes ~/ 60, minute: minutes % 60);
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

final class _DateLabels {
  const _DateLabels({required this.monthLabel, required this.weekLabel});

  factory _DateLabels.current() {
    final DateTime now = DateTime.now();
    final int weekOfMonth = _weekOfMonth(now);
    return _DateLabels(
      monthLabel: '${now.month}월달 총 시간',
      weekLabel: '${now.month}월 $weekOfMonth주 자녀의 사용 계획',
    );
  }

  final String monthLabel;
  final String weekLabel;

  static int _weekOfMonth(DateTime date) {
    final DateTime firstDayOfMonth = DateTime(date.year, date.month);
    final int leadingDays =
        (firstDayOfMonth.weekday - DateTime.monday) % DateTime.daysPerWeek;
    return ((date.day + leadingDays - 1) ~/ DateTime.daysPerWeek) + 1;
  }
}
