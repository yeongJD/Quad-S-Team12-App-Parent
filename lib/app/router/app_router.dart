import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../../core/child/child_connection_store.dart';
import '../../features/common/presentation/pages/placeholder_page.dart';
import '../../features/signup/pages/signup_page.dart';
import '../../features/login/presentation/pages/login_page.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/my_page/presentation/pages/delete_account_complete_page.dart';
import '../../features/my_page/presentation/pages/my_page.dart';
import '../../features/my_page/presentation/pages/password_change_page.dart';
import '../../features/notifications/presentation/pages/notifications_page.dart';
import '../../features/child_add/presentation/pages/child_add_page.dart';
import '../../features/parent_home/presentation/pages/parent_home_page.dart';
import '../../features/today_time/presentation/data/today_time_mock_data.dart';
import '../../features/today_time/presentation/pages/today_time_confirmation_page.dart';
import '../../features/today_time/presentation/pages/today_time_setup_page.dart';
import '../../features/today_mission/presentation/pages/today_mission_edit_page.dart';
import '../../features/today_mission/presentation/pages/today_mission_list_page.dart';

final GoRouter appRouter = GoRouter(
  routes: <RouteBase>[
    GoRoute(path: '/signup', builder: (context, state) => const SignupPage()),
    GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
    GoRoute(path: '/', builder: (context, state) => const HomePage()),
    GoRoute(
      path: '/parent-home',
      builder: (context, state) => ParentHomePage(
        showFilledPreview: state.uri.queryParameters['demo'] == 'filled',
        showTimeEmptyPreview: state.uri.queryParameters['demo'] == 'time-empty',
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
      path: '/child/add',
      builder: (context, state) => const ChildAddPage(),
    ),
    GoRoute(
      path: '/today-time',
      builder: (context, state) => TodayTimeConfirmationPage(
        initialData: TodayTimeMockData.confirmationForDemo(
          state.uri.queryParameters['demo'],
        ),
      ),
    ),
    GoRoute(
      path: '/today-time/setup',
      redirect: _redirectToHomeWithoutLinkedChild,
      builder: (context, state) => const TodayTimeSetupPage(),
    ),
    GoRoute(
      path: '/today-time/monthly',
      builder: (context, state) => const PlaceholderPage(title: '이번달 시간 설정'),
    ),
    GoRoute(
      path: '/today-mission',
      builder: (context, state) =>
          TodayMissionListPage(demo: state.uri.queryParameters['demo']),
    ),
    GoRoute(
      path: '/today-mission/setup',
      redirect: _redirectToHomeWithoutLinkedChild,
      builder: (context, state) => const TodayMissionEditPage(),
    ),
  ],
);

Future<String?> _redirectToHomeWithoutLinkedChild(
  BuildContext context,
  GoRouterState state,
) async {
  final bool hasLinkedChild = await ChildConnectionStore.hasLinkedChild();
  return hasLinkedChild ? null : '/parent-home';
}
