import 'package:go_router/go_router.dart';

import '../../features/home/presentation/pages/home_page.dart';

final GoRouter appRouter = GoRouter(
  routes: <RouteBase>[
    GoRoute(path: '/', builder: (context, state) => const HomePage()),
  ],
);
