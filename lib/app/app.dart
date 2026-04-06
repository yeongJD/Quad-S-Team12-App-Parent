import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import 'router/app_router.dart';

class QuadSTeam12App extends StatelessWidget {
  const QuadSTeam12App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Quad S Team12',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      routerConfig: appRouter,
    );
  }
}
