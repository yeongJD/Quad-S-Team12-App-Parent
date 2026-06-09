import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bridge_p/app/app.dart';
import 'package:bridge_p/core/auth/account_store.dart';
import 'package:bridge_p/core/auth/auth_session.dart';
import 'package:bridge_p/core/child/child_connection_store.dart';
import 'package:bridge_p/core/models/result.dart';
import 'package:bridge_p/data/repositories/time_plan_repository.dart';
import 'package:bridge_p/features/child_add/presentation/pages/child_add_page.dart';
import 'package:bridge_p/features/home/presentation/pages/landing_page.dart';
import 'package:bridge_p/features/login/presentation/pages/login_complete_page.dart';
import 'package:bridge_p/features/my_page/presentation/pages/my_page.dart';
import 'package:bridge_p/features/notifications/presentation/data/notification_store.dart';
import 'package:bridge_p/features/notifications/presentation/models/notification_item.dart';
import 'package:bridge_p/features/parent_home/presentation/pages/parent_home_page.dart';
import 'package:bridge_p/features/parent_home/presentation/widgets/today_time_section.dart';
import 'package:bridge_p/features/today_mission/presentation/data/today_mission_store.dart';
import 'package:bridge_p/features/today_mission/presentation/models/today_mission.dart';
import 'package:bridge_p/features/today_mission/presentation/pages/today_mission_check_page.dart';
import 'package:bridge_p/features/today_mission/presentation/pages/today_mission_list_page.dart';
import 'package:bridge_p/features/today_time/presentation/data/daily_time_rule_store.dart';
import 'package:bridge_p/features/today_time/presentation/data/child_weekly_time_plan_store.dart';
import 'package:bridge_p/features/today_time/presentation/data/monthly_total_time_store.dart';
import 'package:bridge_p/features/today_time/presentation/data/whitelist_app_store.dart';
import 'package:bridge_p/features/today_time/presentation/models/daily_time_rule.dart';
import 'package:bridge_p/features/today_time/presentation/models/whitelist_app.dart';
import 'package:bridge_p/features/today_time/presentation/pages/today_time_complete_page.dart';
import 'package:bridge_p/features/today_time/presentation/pages/today_time_setup_page.dart';
import 'package:bridge_p/features/today_time/presentation/pages/whitelist_setup_page.dart';
import 'package:bridge_p/features/today_time/presentation/routes/today_time_routes.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test(
    'stores parent and child data independently by account structure',
    () async {
      for (final String code in ChildConnectionStore.testChildCodes) {
        expect(await ChildConnectionStore.validateChildCode(code), isTrue);
      }

      const String firstParentId = 'first@example.com';
      const String secondParentId = 'second@example.com';
      await AccountStore.saveAccount(
        const ParentAccount(
          parentId: firstParentId,
          email: firstParentId,
          name: 'first',
          passwordHash: 'Password1234!',
        ),
      );
      await AccountStore.saveAccount(
        const ParentAccount(
          parentId: secondParentId,
          email: secondParentId,
          name: 'second',
          passwordHash: 'Password1234!',
        ),
      );

      await ChildConnectionStore.addChild(
        parentId: firstParentId,
        child: ChildConnectionStore.childFromCode(
          name: '첫째',
          childCode: 'GDG12-1',
        ),
      );
      await ChildConnectionStore.addChild(
        parentId: firstParentId,
        child: ChildConnectionStore.childFromCode(
          name: '둘째',
          childCode: 'GDG12-2',
        ),
      );
      await ChildConnectionStore.addChild(
        parentId: secondParentId,
        child: ChildConnectionStore.childFromCode(
          name: '다른 계정 자녀',
          childCode: 'GDG12-1',
        ),
      );

      final List<ConnectedChild> children =
          await ChildConnectionStore.loadChildren(firstParentId);
      expect(children.map((ConnectedChild child) => child.childrenId), <String>[
        'GDG12-1',
        'GDG12-2',
      ]);

      await DailyTimeRuleStore.save(
        parentId: firstParentId,
        childrenId: 'GDG12-1',
        rules: const <DailyTimeRule>[
          DailyTimeRule(
            days: <int>{0},
            time: TimeSelection(hour: 1, minute: 0),
          ),
        ],
      );
      await DailyTimeRuleStore.save(
        parentId: firstParentId,
        childrenId: 'GDG12-2',
        rules: const <DailyTimeRule>[
          DailyTimeRule(
            days: <int>{1},
            time: TimeSelection(hour: 2, minute: 30),
          ),
        ],
      );

      final List<DailyTimeRule> firstRules = await DailyTimeRuleStore.load(
        parentId: firstParentId,
        childrenId: 'GDG12-1',
      );
      final List<DailyTimeRule> secondRules = await DailyTimeRuleStore.load(
        parentId: firstParentId,
        childrenId: 'GDG12-2',
      );
      final List<DailyTimeRule> otherAccountRules =
          await DailyTimeRuleStore.load(
            parentId: secondParentId,
            childrenId: 'GDG12-1',
          );
      expect(firstRules.single.time.hour, 1);
      expect(secondRules.single.time.hour, 2);
      expect(otherAccountRules, isEmpty);

      await TodayMissionStore.add(
        parentId: firstParentId,
        childrenId: 'GDG12-1',
        mission: const TodayMission(
          title: '첫째 미션',
          category: MissionCategory.cleaning,
          resetPeriod: MissionResetPeriod.daily,
          confirmationMethod: MissionConfirmationMethod.child,
          rewardMinutes: 30,
          description: '',
        ),
      );
      await TodayMissionStore.add(
        parentId: firstParentId,
        childrenId: 'GDG12-2',
        mission: const TodayMission(
          title: '둘째 미션',
          category: MissionCategory.study,
          resetPeriod: MissionResetPeriod.daily,
          confirmationMethod: MissionConfirmationMethod.child,
          rewardMinutes: 60,
          description: '',
        ),
      );

      final List<TodayMission> firstMissions = await TodayMissionStore.load(
        parentId: firstParentId,
        childrenId: 'GDG12-1',
      );
      final List<TodayMission> secondMissions = await TodayMissionStore.load(
        parentId: firstParentId,
        childrenId: 'GDG12-2',
      );
      final List<TodayMission> otherAccountMissions =
          await TodayMissionStore.load(
            parentId: secondParentId,
            childrenId: 'GDG12-1',
          );
      expect(firstMissions.single.title, '첫째 미션');
      expect(secondMissions.single.title, '둘째 미션');
      expect(otherAccountMissions, isEmpty);

      await WhitelistAppStore.save(
        parentId: firstParentId,
        childrenId: 'GDG12-1',
        appIds: <String>{'phone', 'messages'},
      );
      await WhitelistAppStore.save(
        parentId: firstParentId,
        childrenId: 'GDG12-2',
        appIds: <String>{'calendar'},
      );

      final Set<String> firstWhitelist = await WhitelistAppStore.load(
        parentId: firstParentId,
        childrenId: 'GDG12-1',
      );
      final Set<String> secondWhitelist = await WhitelistAppStore.load(
        parentId: firstParentId,
        childrenId: 'GDG12-2',
      );
      final Set<String> otherAccountWhitelist = await WhitelistAppStore.load(
        parentId: secondParentId,
        childrenId: 'GDG12-1',
      );
      expect(firstWhitelist, <String>{'phone', 'messages'});
      expect(secondWhitelist, <String>{'calendar'});
      expect(otherAccountWhitelist, isEmpty);
    },
  );

  test('serializes account status and blocks dormant account login', () async {
    await AccountStore.saveAccount(
      const ParentAccount(
        parentId: 'dormant@example.com',
        email: 'dormant@example.com',
        name: 'dormant',
        passwordHash: 'Password1234!',
        status: AccountStatus.dormant,
      ),
    );

    final ParentAccount? account = await AccountStore.getAccountById(
      'dormant@example.com',
    );
    expect(account?.status, AccountStatus.dormant);

    final bool isValidLogin = await AccountStore.validateLogin(
      email: 'dormant@example.com',
      password: 'Password1234!',
    );
    expect(isValidLogin, isFalse);
  });

  test('removes one account while preserving other local accounts', () async {
    const String deletedParentId = 'delete-me@example.com';
    const String keptParentId = 'keep-me@example.com';
    await AccountStore.saveAccount(
      const ParentAccount(
        parentId: deletedParentId,
        email: deletedParentId,
        name: 'delete-me',
        passwordHash: 'Password1234!',
      ),
    );
    await AccountStore.saveAccount(
      const ParentAccount(
        parentId: keptParentId,
        email: keptParentId,
        name: 'keep-me',
        passwordHash: 'Password1234!',
      ),
    );

    await ChildConnectionStore.addChild(
      parentId: deletedParentId,
      child: ChildConnectionStore.childFromCode(
        name: '삭제될 자녀',
        childCode: 'GDG12-1',
      ),
    );
    await TodayMissionStore.add(
      parentId: deletedParentId,
      childrenId: 'GDG12-1',
      mission: const TodayMission(
        title: '삭제될 미션',
        category: MissionCategory.study,
        resetPeriod: MissionResetPeriod.daily,
        confirmationMethod: MissionConfirmationMethod.parent,
        rewardMinutes: 10,
        description: '',
      ),
    );

    await AccountStore.removeAccount(deletedParentId);

    expect(await AccountStore.getAccountById(deletedParentId), isNull);
    expect(await AccountStore.getAccountById(keptParentId), isNotNull);
    expect(
      await TodayMissionStore.load(
        parentId: deletedParentId,
        childrenId: 'GDG12-1',
      ),
      isEmpty,
    );
  });

  test('resetAllData removes only Bridge cache keys safely', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      AccountStore.accountsKey: '[]',
      AuthSession.currentParentIdKey: 'parent@example.com',
      AuthSession.currentEmailKey: 'parent@example.com',
      'bridge_p.legacy_cache': 'legacy',
      'external.setting': 'keep',
    });

    await AuthSession.resetAllData();

    final SharedPreferences preferences = await SharedPreferences.getInstance();
    expect(preferences.getString(AccountStore.accountsKey), '[]');
    expect(
      preferences.getString(AuthSession.currentParentIdKey),
      'parent@example.com',
    );
    expect(
      preferences.getString(AuthSession.currentEmailKey),
      'parent@example.com',
    );
    expect(preferences.getString('bridge_p.legacy_cache'), isNull);
    expect(preferences.getString('external.setting'), 'keep');
  });

  test(
    'hides deleted notifications and clears unread state per account',
    () async {
      const String parentId = 'notification-parent@example.com';
      await AccountStore.saveAccount(
        const ParentAccount(
          parentId: parentId,
          email: parentId,
          name: 'notification-parent',
          passwordHash: 'Password1234!',
        ),
      );

      expect(await NotificationStore.hasUnread(parentId), isTrue);

      for (final NotificationItem item
          in NotificationStore.defaultNotifications) {
        await NotificationStore.hide(
          parentId: parentId,
          notificationId: item.id,
        );
      }

      expect(await NotificationStore.load(parentId), isEmpty);
      expect(await NotificationStore.hasUnread(parentId), isFalse);
    },
  );

  test(
    'stores mission verification status separately from legacy status',
    () async {
      const String parentId = 'mission-status@example.com';
      await AccountStore.saveAccount(
        const ParentAccount(
          parentId: parentId,
          email: parentId,
          name: 'mission-status',
          passwordHash: 'Password1234!',
        ),
      );
      await ChildConnectionStore.addChild(
        parentId: parentId,
        child: ChildConnectionStore.childFromCode(
          name: '상태 자녀',
          childCode: 'GDG12-1',
        ),
      );

      await TodayMissionStore.add(
        parentId: parentId,
        childrenId: 'GDG12-1',
        mission: const TodayMission(
          title: 'AI 확인 미션',
          category: MissionCategory.study,
          resetPeriod: MissionResetPeriod.daily,
          confirmationMethod: MissionConfirmationMethod.ai,
          rewardMinutes: 20,
          description: 'AI 확인 상태 저장',
          verificationStatus: MissionVerificationStatus.waitingAiVerification,
        ),
      );

      final TodayMission mission = (await TodayMissionStore.load(
        parentId: parentId,
        childrenId: 'GDG12-1',
      )).single;
      expect(mission.verificationType, MissionVerificationType.ai);
      expect(
        mission.effectiveVerificationStatus,
        MissionVerificationStatus.waitingAiVerification,
      );
      expect(mission.effectiveStatus, TodayMissionStatus.reviewing);
    },
  );

  testWidgets('parent verification waiting state shows approve and reject', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: TodayMissionCheckPage(
          parentId: 'parent@example.com',
          childrenId: 'GDG12-1',
          missionIndex: null,
          initialMission: TodayMission(
            title: '부모 확인 미션',
            category: MissionCategory.cleaning,
            resetPeriod: MissionResetPeriod.daily,
            confirmationMethod: MissionConfirmationMethod.parent,
            rewardMinutes: 30,
            description: '부모 확인 필요',
            verificationStatus: MissionVerificationStatus.waitingParentApproval,
            submittedAtText: '2025.1.21 오후 7:01',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('수행확인'));
    await tester.pumpAndSettle();

    expect(find.text('부모 확인 대기중'), findsOneWidget);
    expect(find.text('승인'), findsOneWidget);
    expect(find.text('반려'), findsOneWidget);
  });

  testWidgets('parent mission review can approve by performance id', (
    WidgetTester tester,
  ) async {
    const String parentId = 'review-by-performance@example.com';
    const String childrenId = 'GDG12-1';
    const TodayMission mission = TodayMission(
      missionId: 'mission-1',
      performanceId: 'performance-1',
      title: 'id 기반 미션',
      category: MissionCategory.cleaning,
      resetPeriod: MissionResetPeriod.daily,
      confirmationMethod: MissionConfirmationMethod.parent,
      rewardMinutes: 30,
      description: '알림 상세에서 바로 심사',
      verificationStatus: MissionVerificationStatus.waitingParentApproval,
      submittedAtText: '2025.1.21 오후 7:01',
    );

    await AccountStore.saveAccount(
      const ParentAccount(
        parentId: parentId,
        email: parentId,
        name: 'review',
        passwordHash: 'Password1234!',
      ),
    );
    await ChildConnectionStore.addChild(
      parentId: parentId,
      child: ChildConnectionStore.childFromCode(
        name: '자녀',
        childCode: childrenId,
      ),
    );
    await TodayMissionStore.add(
      parentId: parentId,
      childrenId: childrenId,
      mission: mission,
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: TodayMissionCheckPage(
          parentId: parentId,
          childrenId: childrenId,
          missionIndex: null,
          initialMission: mission,
          initialTab: MissionCheckTab.review,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('승인'));
    await tester.pumpAndSettle();

    expect(find.text('미션 수행완료!'), findsOneWidget);
    final TodayMission storedMission = (await TodayMissionStore.load(
      parentId: parentId,
      childrenId: childrenId,
    )).single;
    expect(storedMission.performanceId, 'performance-1');
    expect(
      storedMission.effectiveVerificationStatus,
      MissionVerificationStatus.approved,
    );
  });

  testWidgets('today mission route target opens matching review detail', (
    WidgetTester tester,
  ) async {
    const String parentId = 'route-mission@example.com';
    const String childrenId = 'GDG12-1';
    await AccountStore.saveAccount(
      const ParentAccount(
        parentId: parentId,
        email: parentId,
        name: 'route',
        passwordHash: 'Password1234!',
      ),
    );
    await ChildConnectionStore.addChild(
      parentId: parentId,
      child: ChildConnectionStore.childFromCode(
        name: '자녀',
        childCode: childrenId,
      ),
    );
    await TodayMissionStore.save(
      parentId: parentId,
      childrenId: childrenId,
      missions: const <TodayMission>[
        TodayMission(
          missionId: 'mission-1',
          performanceId: 'performance-1',
          title: '첫 미션',
          category: MissionCategory.cleaning,
          resetPeriod: MissionResetPeriod.daily,
          confirmationMethod: MissionConfirmationMethod.parent,
          rewardMinutes: 10,
          description: '첫 번째',
          verificationStatus: MissionVerificationStatus.waitingParentApproval,
          submittedAtText: '2025.1.21 오후 7:01',
        ),
        TodayMission(
          missionId: 'mission-2',
          performanceId: 'performance-2',
          title: '대상 미션',
          category: MissionCategory.study,
          resetPeriod: MissionResetPeriod.daily,
          confirmationMethod: MissionConfirmationMethod.parent,
          rewardMinutes: 20,
          description: '라우트 대상',
          verificationStatus: MissionVerificationStatus.waitingParentApproval,
          submittedAtText: '2025.1.21 오후 7:01',
        ),
      ],
    );

    final GoRouter router = GoRouter(
      initialLocation:
          '/today-mission?parentId=$parentId&childrenId=$childrenId'
          '&missionId=mission-2&tab=review',
      routes: <RouteBase>[
        GoRoute(
          path: '/today-mission',
          builder: (context, state) => TodayMissionListPage(
            parentId: state.uri.queryParameters['parentId'],
            childrenId: state.uri.queryParameters['childrenId'],
            initialMissionId: state.uri.queryParameters['missionId'],
            initialTab:
                state.uri.queryParameters['tab'] == MissionCheckTab.review.name
                ? MissionCheckTab.review
                : MissionCheckTab.info,
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
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    expect(find.text('대상 미션'), findsWidgets);
    expect(find.text('부모 확인 대기중'), findsOneWidget);
    expect(find.text('승인'), findsOneWidget);
    expect(find.text('첫 미션'), findsNothing);
  });

  testWidgets('parent mission review keeps waiting state when approve fails', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: TodayMissionCheckPage(
          parentId: 'parent@example.com',
          childrenId: 'GDG12-1',
          missionIndex: 0,
          initialMission: TodayMission(
            title: '저장되지 않은 미션',
            category: MissionCategory.cleaning,
            resetPeriod: MissionResetPeriod.daily,
            confirmationMethod: MissionConfirmationMethod.parent,
            rewardMinutes: 30,
            description: '저장소에는 없는 미션',
            verificationStatus: MissionVerificationStatus.waitingParentApproval,
            submittedAtText: '2025.1.21 오후 7:01',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('수행확인'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('승인'));
    await tester.pumpAndSettle();

    expect(find.text('미션을 찾을 수 없어요.'), findsOneWidget);
    expect(find.text('부모 확인 대기중'), findsOneWidget);
    expect(find.text('미션 수행완료!'), findsNothing);
  });

  testWidgets('AI verification waiting state hides manual action buttons', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: TodayMissionCheckPage(
          parentId: 'parent@example.com',
          childrenId: 'GDG12-1',
          missionIndex: null,
          initialMission: TodayMission(
            title: 'AI 확인 미션',
            category: MissionCategory.study,
            resetPeriod: MissionResetPeriod.daily,
            confirmationMethod: MissionConfirmationMethod.ai,
            rewardMinutes: 30,
            description: 'AI 확인 필요',
            verificationStatus: MissionVerificationStatus.waitingAiVerification,
            submittedAtText: '2025.1.21 오후 7:01',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('수행확인'));
    await tester.pump();

    expect(find.text('AI 확인 대기중입니다.'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('승인'), findsNothing);
    expect(find.text('반려'), findsNothing);
  });

  testWidgets('self-approved mission hides unsupported manual rejection', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: TodayMissionCheckPage(
          parentId: 'parent@example.com',
          childrenId: 'GDG12-1',
          missionIndex: null,
          initialTab: MissionCheckTab.review,
          initialMission: TodayMission(
            title: '자녀 확인 미션',
            category: MissionCategory.study,
            resetPeriod: MissionResetPeriod.daily,
            confirmationMethod: MissionConfirmationMethod.child,
            rewardMinutes: 30,
            description: '자녀 확인',
            verificationStatus: MissionVerificationStatus.approved,
            submittedAtText: '2025.1.21 오후 7:01',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('미션 수행완료!'), findsOneWidget);
    expect(find.text('보상 시간이 지급되었습니다.'), findsOneWidget);
    expect(find.text('승인'), findsNothing);
    expect(find.text('반려'), findsNothing);
  });

  testWidgets('home screen renders Bridge entry actions', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const BridgePApp());
    await tester.pumpAndSettle();

    expect(find.text('Bridge'), findsOneWidget);
    expect(find.text('로그인'), findsOneWidget);
    expect(find.text('부모 회원가입'), findsOneWidget);
  });

  testWidgets('cached parent login opens parent home', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      AuthSession.currentParentIdKey: 'gdg12@gmail.com',
      AuthSession.currentEmailKey: 'gdg12@gmail.com',
    });

    await tester.pumpWidget(const BridgePApp());
    await tester.pumpAndSettle();

    expect(find.byType(ParentHomePage), findsOneWidget);
    expect(find.text('부모 회원가입'), findsNothing);
  });

  testWidgets('my page logout clears parent session', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      AuthSession.currentParentIdKey: 'parent99@example.com',
      AuthSession.currentEmailKey: 'parent99@example.com',
    });
    await AccountStore.saveAccount(
      const ParentAccount(
        parentId: 'parent99@example.com',
        email: 'parent99@example.com',
        name: 'parent99',
        passwordHash: 'Password1234!',
      ),
    );
    final GoRouter router = GoRouter(
      initialLocation: '/mypage',
      routes: <RouteBase>[
        GoRoute(path: '/', builder: (context, state) => const LandingPage()),
        GoRoute(path: '/mypage', builder: (context, state) => const MyPage()),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    expect(find.text('parent99'), findsOneWidget);
    expect(find.text('로그아웃'), findsOneWidget);

    await tester.tap(find.text('로그아웃'));
    await tester.pumpAndSettle();

    // The logout button opens an AppConfirmationDialog; the user has to
    // confirm before AuthSession.logout() runs.
    expect(find.text('로그아웃하시겠습니까?'), findsOneWidget);
    await tester.tap(find.text('확인'));
    await tester.pumpAndSettle();

    expect(await AuthSession.isLoggedIn(), isFalse);
    expect(find.text('Bridge'), findsOneWidget);
  });

  testWidgets('login complete screen starts normal parent home', (
    WidgetTester tester,
  ) async {
    final GoRouter router = GoRouter(
      initialLocation: '/login/complete',
      routes: <RouteBase>[
        GoRoute(
          path: '/login/complete',
          builder: (context, state) => const LoginCompletePage(),
        ),
        GoRoute(
          path: '/parent-home',
          builder: (context, state) => const ParentHomePage(),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    expect(find.text('로그인이  완료되었습니다.'), findsOneWidget);
    expect(find.text('시작하기'), findsOneWidget);

    await tester.tap(find.text('시작하기'));
    await tester.pumpAndSettle();

    expect(find.text('오늘의 시간'), findsOneWidget);
  });

  testWidgets('parent home empty state shows service sections', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: ParentHomePage()));
    await tester.pumpAndSettle();

    expect(find.text('추가'), findsOneWidget);
    expect(find.textContaining('자녀추가'), findsNothing);
    expect(find.text('오늘의 시간'), findsOneWidget);
    expect(find.text('오늘의 미션'), findsOneWidget);
  });

  testWidgets('parent home filled state shows selected child dashboard', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: ParentHomePage(showFilledPreview: true)),
    );
    await tester.pumpAndSettle();

    expect(find.text('박진아'), findsNWidgets(2));
    expect(find.text('01:30'), findsOneWidget);
    expect(find.text('00:30'), findsOneWidget);
    expect(find.text('1개 완료'), findsOneWidget);
    expect(find.text('4'), findsOneWidget);
    expect(find.text('방청소 하기'), findsNWidgets(4));
  });

  testWidgets('parent home time-empty state can show time setup entry', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: ParentHomePage(showTimeEmptyPreview: true)),
    );
    await tester.pumpAndSettle();

    expect(find.text('박진아'), findsOneWidget);
    expect(find.text('오늘의 시간'), findsOneWidget);
    expect(find.text('01:30'), findsNothing);
    expect(find.text('00:30'), findsNothing);
  });

  testWidgets(
    'parent home shows waiting state after only monthly time is set',
    (WidgetTester tester) async {
      const String parentId = 'waiting-parent@example.com';
      const String childrenId = 'GDG12-1';
      await AccountStore.saveAccount(
        const ParentAccount(
          parentId: parentId,
          email: parentId,
          name: 'waiting-parent',
          passwordHash: 'Password1234!',
        ),
      );
      await AuthSession.login(parentId: parentId, email: parentId);
      await ChildConnectionStore.addChild(
        parentId: parentId,
        child: ChildConnectionStore.childFromCode(
          name: '대기 자녀',
          childCode: childrenId,
        ),
      );
      await MonthlyTotalTimeStore.save(
        parentId: parentId,
        childrenId: childrenId,
        totalMinutes: 600,
      );

      await tester.pumpWidget(const MaterialApp(home: ParentHomePage()));
      await tester.pumpAndSettle();

      expect(find.text('대기 자녀'), findsOneWidget);
      expect(find.text('자녀가 아직 시간 설정 이전입니다.'), findsOneWidget);
      expect(find.text('01:30'), findsNothing);
      expect(find.text('00:30'), findsNothing);
    },
  );

  testWidgets(
    'parent home shows today template missing without falling back to monthly time',
    (WidgetTester tester) async {
      const String parentId = 'template-missing-parent@example.com';
      const String childrenId = 'GDG12-1';
      final int todayIndex = DateTime.now().weekday - 1;
      final int nonTodayIndex = (todayIndex + 1) % weekdayLabels.length;
      await AccountStore.saveAccount(
        const ParentAccount(
          parentId: parentId,
          email: parentId,
          name: 'template-parent',
          passwordHash: 'Password1234!',
        ),
      );
      await AuthSession.login(parentId: parentId, email: parentId);
      await ChildConnectionStore.addChild(
        parentId: parentId,
        child: ChildConnectionStore.childFromCode(
          name: '템플릿 자녀',
          childCode: childrenId,
        ),
      );
      await MonthlyTotalTimeStore.save(
        parentId: parentId,
        childrenId: childrenId,
        totalMinutes: 600,
      );
      await ChildWeeklyTimePlanStore.save(
        parentId: parentId,
        childrenId: childrenId,
        rules: <DailyTimeRule>[
          DailyTimeRule(
            days: <int>{nonTodayIndex},
            time: const TimeSelection(hour: 1, minute: 30),
          ),
        ],
      );

      await tester.pumpWidget(const MaterialApp(home: ParentHomePage()));
      await tester.pumpAndSettle();

      expect(find.text('템플릿 자녀'), findsOneWidget);
      expect(find.text('오늘 배정 시간이 없습니다.'), findsOneWidget);
      expect(find.text('01:30'), findsNothing);
      expect(find.text('10:00'), findsNothing);
    },
  );

  testWidgets('today time section can show load failure message', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TodayTimeSection(
            timeSummary: null,
            emptyMessage: '시간 정보를 불러오지 못했습니다.',
            onSetup: () {},
            onAdd: () {},
          ),
        ),
      ),
    );

    expect(find.text('시간 정보를 불러오지 못했습니다.'), findsOneWidget);
  });

  testWidgets('today time setup screen toggles tip content', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: TodayTimeSetupPage()));
    await tester.pumpAndSettle();

    expect(find.text('시간설정'), findsOneWidget);
    expect(find.text('일간 시간 설정'), findsOneWidget);
    expect(find.text('Tip'), findsOneWidget);
    expect(find.text('확인'), findsOneWidget);
    expect(find.text('적절한 사용 시간이 고민되시나요?'), findsNothing);

    await tester.tap(find.text('Tip'));
    await tester.pumpAndSettle();
    expect(find.text('적절한 사용 시간이 고민되시나요?'), findsOneWidget);
    expect(find.textContaining('초등 고학년 권장 스마트폰 사용 시간'), findsOneWidget);
    expect(find.textContaining('위 기준을 참고해'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pumpAndSettle();
    expect(find.text('적절한 사용 시간이 고민되시나요?'), findsNothing);
  });

  testWidgets('today time setup adds a daily time entry', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: TodayTimeSetupPage()));
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey<String>('daily-time-add-button')),
    );
    await tester.pumpAndSettle();

    expect(find.text('요일 선택'), findsOneWidget);
    expect(find.text('시간 선택'), findsOneWidget);

    for (final String day in <String>['월', '화', '수', '목', '금']) {
      await tester.tap(find.text(day).last);
      await tester.pumpAndSettle();
    }

    await tester.tap(
      find.byKey(const ValueKey<String>('daily-time-selector-field')),
    );
    await tester.pumpAndSettle();
    expect(find.text('시간 선택'), findsNWidgets(2));

    // BridgeTimeBottomSheet renders two ListWheelScrollViews — hour, minute.
    // itemHeight is 50, so scrolling up by 50px moves the selection down by
    // one row. Pick 1 hour, 5 minutes.
    final Finder wheels = find.byType(ListWheelScrollView);
    await tester.drag(wheels.first, const Offset(0, -50));
    await tester.pumpAndSettle();
    await tester.drag(wheels.last, const Offset(0, -50));
    await tester.pumpAndSettle();

    await tester.tap(find.text('확인').last);
    await tester.pumpAndSettle();

    await tester.tap(find.text('확인').last);
    await tester.pumpAndSettle();

    expect(find.text('주중'), findsOneWidget);
    expect(find.text('1시간 5분'), findsOneWidget);
  });

  testWidgets('whitelist save failure does not block completion', (
    WidgetTester tester,
  ) async {
    final GoRouter router = GoRouter(
      initialLocation: TodayTimeRoutes.whitelist,
      routes: <RouteBase>[
        GoRoute(
          path: TodayTimeRoutes.whitelist,
          builder: (context, state) => WhitelistSetupPage(
            parentId: 'parent-1',
            childrenId: 'child-1',
            total: const TimeSelection(hour: 1, minute: 0),
            rules: const <DailyTimeRule>[],
            categories: const <WhitelistAppCategory>[],
            timePlanRepository: _ThrowingWhitelistRepository(),
          ),
        ),
        GoRoute(
          path: TodayTimeRoutes.complete,
          builder: (context, state) => TodayTimeCompletePage(
            data: state.extra as TodayTimeCompleteData?,
          ),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    await tester.tap(find.text('확인'));
    await tester.pumpAndSettle();

    expect(find.text('시간 설정 완료!'), findsOneWidget);
  });

  testWidgets('child add screen toggles tooltip and enables submit', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: ChildAddPage()));
    await tester.pumpAndSettle();

    expect(find.text('자녀등록'), findsOneWidget);
    expect(find.text('사진등록'), findsOneWidget);
    expect(find.text('이름'), findsOneWidget);
    expect(find.text('출생연도'), findsOneWidget);
    expect(find.text('자녀코드'), findsOneWidget);
    expect(find.text('자녀코드는 어디에서 확인하나요?'), findsNothing);

    await tester.tap(find.byIcon(Icons.help_outline_rounded));
    await tester.pumpAndSettle();
    expect(find.text('자녀코드는 어디에서 확인하나요?'), findsOneWidget);

    final Iterable<Widget> disabledButtons = tester.widgetList(
      find.byWidgetPredicate((Widget widget) {
        return widget is Material && widget.color == const Color(0xFFD5D8DE);
      }),
    );
    expect(disabledButtons, isNotEmpty);

    await tester.tap(find.text('자녀가 태어난 연도를 입력해주세요'));
    await tester.pumpAndSettle();
    expect(find.text('출생연도'), findsNWidgets(2));
    expect(find.text('확인'), findsOneWidget);

    await tester.tap(find.text('확인'));
    await tester.pumpAndSettle();
    expect(find.text('2013'), findsOneWidget);

    await tester.enterText(find.byType(TextField).at(0), '박진아');
    await tester.enterText(find.byType(TextField).at(1), 'XY785eZ');
    await tester.pumpAndSettle();

    final Iterable<Widget> enabledButtons = tester.widgetList(
      find.byWidgetPredicate((Widget widget) {
        return widget is Material && widget.color == const Color(0xFF3A99F8);
      }),
    );
    expect(enabledButtons, isNotEmpty);
  });

  testWidgets('child add screen validates short names', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: ChildAddPage()));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).at(0), '홍');
    await tester.tap(find.text('자녀가 태어난 연도를 입력해주세요'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('확인'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).at(1), 'XYz089');
    await tester.pumpAndSettle();

    await tester.tap(find.text('등록'));
    await tester.pumpAndSettle();

    expect(find.text('이름은 2자 이상 10자 이내로 입력해주세요'), findsOneWidget);
    expect(find.byIcon(Icons.cancel), findsOneWidget);
  });
}

class _ThrowingWhitelistRepository implements TimePlanRepository {
  @override
  Future<Result<List<DailyTimeRule>>> loadDailyRules({
    required String parentId,
    required String childrenId,
  }) async {
    return Result<List<DailyTimeRule>>.success(const <DailyTimeRule>[]);
  }

  @override
  Future<Result<void>> saveDailyRules({
    required String parentId,
    required String childrenId,
    required List<DailyTimeRule> rules,
  }) async {
    return Result<void>.success(null);
  }

  @override
  Future<Result<List<DailyTimeRule>>> loadChildWeeklyRules({
    required String parentId,
    required String childrenId,
  }) async {
    return Result<List<DailyTimeRule>>.success(const <DailyTimeRule>[]);
  }

  @override
  Future<Result<void>> saveChildWeeklyRules({
    required String parentId,
    required String childrenId,
    required List<DailyTimeRule> rules,
  }) async {
    return Result<void>.success(null);
  }

  @override
  Future<Result<int?>> loadMonthlyTotal({
    required String parentId,
    required String childrenId,
  }) async {
    return Result<int?>.success(null);
  }

  @override
  Future<Result<void>> saveMonthlyTotal({
    required String parentId,
    required String childrenId,
    required int totalMinutes,
  }) async {
    return Result<void>.success(null);
  }

  @override
  Future<Result<ChildTimeSummary>> loadChildTimeSummary({
    required String parentId,
    required String childrenId,
    DateTime? date,
  }) async {
    return Result<ChildTimeSummary>.success(
      const ChildTimeSummary(
        parentPolicyExists: false,
        childPlanExists: false,
        todayScheduleStatus: 'noParentPolicy',
        basePolicyMinutes: 0,
        baseMinutes: 0,
        extendedMinutes: 0,
        totalAvailableMinutes: 0,
        rewardPoolMinutes: 0,
      ),
    );
  }

  @override
  Future<Result<Set<String>>> loadWhitelist({
    required String parentId,
    required String childrenId,
  }) async {
    return Result<Set<String>>.success(<String>{});
  }

  @override
  Future<Result<void>> saveWhitelist({
    required String parentId,
    required String childrenId,
    required Set<String> appIds,
  }) async {
    throw StateError('whitelist storage unavailable');
  }
}
