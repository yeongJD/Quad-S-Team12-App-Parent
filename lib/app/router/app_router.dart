import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../../features/signup/pages/signup_complete_page.dart';
import '../../features/signup/pages/signup_page.dart';
import '../../features/login/presentation/pages/login_complete_page.dart';
import '../../features/login/presentation/pages/login_page.dart';
import '../../features/home/presentation/pages/landing_page.dart';
import '../../features/my_page/presentation/pages/delete_account_complete_page.dart';
import '../../features/my_page/presentation/pages/my_page.dart';
import '../../features/my_page/presentation/pages/password_change_page.dart';
import '../../features/notifications/presentation/pages/notifications_page.dart';
import '../../features/child_add/presentation/pages/child_add_page.dart';
import '../../features/parent_home/presentation/pages/parent_home_page.dart';
import '../../features/today_time/presentation/data/today_time_mock_data.dart';
import '../../features/today_time/presentation/models/daily_time_rule.dart';
import '../../features/today_time/presentation/pages/monthly_time_setup_page.dart';
import '../../features/today_time/presentation/pages/today_time_complete_page.dart';
import '../../features/today_time/presentation/pages/today_time_confirmation_page.dart';
import '../../features/today_time/presentation/pages/today_time_setup_page.dart';
import '../../features/today_time/presentation/pages/whitelist_setup_page.dart';
import '../../features/today_time/presentation/routes/today_time_routes.dart';
import '../../features/today_mission/presentation/pages/today_mission_check_page.dart';
import '../../features/today_mission/presentation/pages/today_mission_edit_page.dart';
import '../../features/today_mission/presentation/pages/today_mission_list_page.dart';
import '../../features/usage_report/presentation/pages/weekly_usage_report_page.dart';

final GoRouter appRouter = GoRouter(
  routes: <RouteBase>[
    GoRoute(path: '/signup', builder: (context, state) => const SignupPage()),
    GoRoute(
      path: '/signup/complete',
      builder: (context, state) => const SignupCompletePage(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => LoginPage(
        initialName: state.uri.queryParameters['name'],
        initialEmail: state.uri.queryParameters['email'],
        showExistingAccountNotice:
            state.uri.queryParameters['notice'] == 'existing-account',
      ),
    ),
    GoRoute(
      path: '/login/complete',
      builder: (context, state) => const LoginCompletePage(),
    ),
    GoRoute(path: '/', builder: (context, state) => const LandingPage()),
    GoRoute(
      path: '/parent-home',
      builder: (context, state) => ParentHomePage(
        showFilledPreview: state.uri.queryParameters['demo'] == 'filled',
        showTimeEmptyPreview: state.uri.queryParameters['demo'] == 'time-empty',
        showLinkedChildPreview:
            state.uri.queryParameters['demo'] == 'linked-child',
      ),
    ),
    GoRoute(path: '/mypage', builder: (context, state) => const MyPage()),
    GoRoute(
      path: '/mypage/password',
      builder: (context, state) => const PasswordChangePage(),
    ),
    GoRoute(
      path: '/mypage/delete-complete',
      builder: (context, state) => const DeleteAccountCompletePage(),
    ),
    GoRoute(
      path: '/notifications',
      builder: (context, state) => const NotificationsPage(),
    ),
    GoRoute(
      path: '/usage-report',
      builder: (context, state) => WeeklyUsageReportPage(
        parentId: state.uri.queryParameters['parentId'],
        childrenId: state.uri.queryParameters['childrenId'],
      ),
    ),
    GoRoute(
      path: '/child/add',
      builder: (context, state) => const ChildAddPage(),
    ),
    GoRoute(
      path: TodayTimeRoutes.root,
      builder: (context, state) => TodayTimeConfirmationPage(
        parentId: state.uri.queryParameters['parentId'],
        childrenId: state.uri.queryParameters['childrenId'],
        demo: state.uri.queryParameters['demo'],
        initialData: TodayTimeMockData.confirmationForDemo(
          state.uri.queryParameters['demo'],
        ),
      ),
    ),
    GoRoute(
      path: TodayTimeRoutes.setup,
      builder: (context, state) {
        final Object? extra = state.extra;
        final TodayTimeSetupArgs? args = extra is TodayTimeSetupArgs
            ? extra
            : null;
        final List<DailyTimeRule> initialRules =
            args?.rules ??
            (extra is List<DailyTimeRule>
                ? extra
                : TodayTimeMockData.emptyDailyRules);
        return TodayTimeSetupPage(
          parentId: state.uri.queryParameters['parentId'],
          childrenId: state.uri.queryParameters['childrenId'],
          initialRules: initialRules,
          initialMonthlyTotalMinutes: args?.monthlyTotalMinutes,
          initialWhitelistAppIds: args?.whitelistAppIds,
        );
      },
    ),
    GoRoute(
      path: TodayTimeRoutes.monthly,
      builder: (context, state) {
        final Object? extra = state.extra;
        if (extra is MonthlyTimeSetupArgs) {
          return MonthlyTimeSetupPage(
            parentId: extra.parentId,
            childrenId: extra.childrenId,
            rules: extra.rules,
            initialMonthlyTotalMinutes: extra.initialMonthlyTotalMinutes,
            initialSelectedAppIds: extra.initialSelectedAppIds,
          );
        }
        final List<DailyTimeRule> rules = extra is List<DailyTimeRule>
            ? extra
            : const <DailyTimeRule>[
                DailyTimeRule(
                  days: <int>{0, 2, 4},
                  time: TimeSelection(hour: 1, minute: 30),
                ),
                DailyTimeRule(
                  days: <int>{1, 3, 5, 6},
                  time: TimeSelection(hour: 2, minute: 0),
                ),
              ];
        return MonthlyTimeSetupPage(
          parentId: state.uri.queryParameters['parentId'],
          childrenId: state.uri.queryParameters['childrenId'],
          rules: rules,
        );
      },
    ),
    GoRoute(
      path: TodayTimeRoutes.complete,
      builder: (context, state) {
        final Object? extra = state.extra;
        return TodayTimeCompletePage(
          data: extra is TodayTimeCompleteData ? extra : null,
        );
      },
    ),
    GoRoute(path: TodayTimeRoutes.whitelist, builder: _buildWhitelistSetupPage),
    GoRoute(
      path: TodayTimeRoutes.whitelistAlias,
      builder: _buildWhitelistSetupPage,
    ),
    GoRoute(
      path: '/today-mission',
      builder: (context, state) => TodayMissionListPage(
        parentId: state.uri.queryParameters['parentId'],
        childrenId: state.uri.queryParameters['childrenId'],
        demo: state.uri.queryParameters['demo'],
      ),
    ),
    GoRoute(
      path: '/today-mission/check',
      builder: (context, state) {
        final Object? extra = state.extra;
        if (extra is TodayMissionCheckArgs) {
          return TodayMissionCheckPage(
            parentId: extra.parentId,
            childrenId: extra.childrenId,
            missionIndex: extra.index,
            initialMission: extra.mission,
            initialTab: extra.initialTab,
          );
        }
        return const TodayMissionCheckPage(
          parentId: null,
          childrenId: null,
          missionIndex: null,
          initialMission: null,
        );
      },
    ),
    GoRoute(
      path: '/today-mission/setup',
      builder: (context, state) {
        final Object? extra = state.extra;
        if (extra is TodayMissionEditArgs) {
          return TodayMissionEditPage(
            parentId: extra.parentId,
            childrenId: extra.childrenId,
            initialMission: extra.mission,
            missionIndex: extra.index,
          );
        }
        return TodayMissionEditPage(
          parentId: state.uri.queryParameters['parentId'],
          childrenId: state.uri.queryParameters['childrenId'],
        );
      },
    ),
  ],
);

WhitelistSetupPage _buildWhitelistSetupPage(
  BuildContext context,
  GoRouterState state,
) {
  final Object? extra = state.extra;
  if (extra is WhitelistSetupArgs) {
    return WhitelistSetupPage(
      parentId: extra.parentId,
      childrenId: extra.childrenId,
      total: extra.total,
      rules: extra.rules,
      initialSelectedAppIds: extra.initialSelectedAppIds,
    );
  }
  return WhitelistSetupPage(
    parentId: state.uri.queryParameters['parentId'],
    childrenId: state.uri.queryParameters['childrenId'],
    total: const TimeSelection(hour: 0, minute: 0),
    rules: const <DailyTimeRule>[],
  );
}
