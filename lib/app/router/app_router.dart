import 'package:go_router/go_router.dart';

import '../../features/common/presentation/pages/placeholder_page.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/login/presentation/pages/login_page.dart';
import '../../features/my_page/presentation/pages/delete_account_complete_page.dart';
import '../../features/my_page/presentation/pages/my_page.dart';
import '../../features/my_page/presentation/pages/password_change_page.dart';
import '../../features/parent_home/presentation/pages/parent_home_page.dart';
import '../../features/signup/presentation/pages/signup_page.dart';

final GoRouter appRouter = GoRouter(
  routes: <RouteBase>[
    GoRoute(path: '/', builder: (context, state) => const HomePage()),
    GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
    GoRoute(path: '/signup', builder: (context, state) => const SignupPage()),
    GoRoute(
      path: '/parent-home',
      builder: (context, state) => ParentHomePage(
        showFilledPreview: state.uri.queryParameters['demo'] == 'filled',
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
      builder: (context, state) => const PlaceholderPage(title: '알림창'),
    ),
    GoRoute(
      path: '/child/add',
      builder: (context, state) => const PlaceholderPage(title: '자녀 추가'),
    ),
    GoRoute(
      path: '/today-time',
      builder: (context, state) => const PlaceholderPage(title: '오늘의 시간'),
    ),
    GoRoute(
      path: '/today-time/setup',
      builder: (context, state) => const PlaceholderPage(title: '오늘의 시간 설정'),
    ),
    GoRoute(
      path: '/today-mission',
      builder: (context, state) => const PlaceholderPage(title: '오늘의 미션'),
    ),
    GoRoute(
      path: '/today-mission/setup',
      builder: (context, state) => const PlaceholderPage(title: '오늘의 미션 설정'),
    ),
  ],
);
