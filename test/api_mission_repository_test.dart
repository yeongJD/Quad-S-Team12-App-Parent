import 'package:bridge_p/core/models/result.dart';
import 'package:bridge_p/data/repositories/api_mission_repository.dart';
import 'package:bridge_p/features/today_mission/presentation/models/today_mission.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ApiMissionRepository', () {
    test('maps pending performances by verification type', () async {
      final Dio dio = Dio(BaseOptions(baseUrl: 'https://test.local'));
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest:
              (RequestOptions options, RequestInterceptorHandler handler) {
                final Response<dynamic> response = Response<dynamic>(
                  requestOptions: options,
                  statusCode: 200,
                  data: _missionResponseFor(options.path),
                );
                handler.resolve(response);
              },
        ),
      );
      final ApiMissionRepository repository = ApiMissionRepository(dio: dio);

      final Result<List<TodayMission>> result = await repository.loadMissions(
        parentId: 'parent-1',
        childrenId: 'child-1',
      );

      expect(result, isA<Success<List<TodayMission>>>());
      final List<TodayMission> missions =
          (result as Success<List<TodayMission>>).data;
      final Map<String, TodayMission> byId = <String, TodayMission>{
        for (final TodayMission mission in missions)
          mission.missionId!: mission,
      };

      expect(
        byId['parent-mission']!.effectiveVerificationStatus,
        MissionVerificationStatus.waitingParentApproval,
      );
      expect(
        byId['parent-mission']!.resetPeriod,
        MissionResetPeriod.weekly,
      );
      expect(
        byId['parent-mission']!.effectiveStatus,
        TodayMissionStatus.reviewing,
      );
      expect(
        byId['ai-mission']!.effectiveVerificationStatus,
        MissionVerificationStatus.waitingAiVerification,
      );
      expect(byId['ai-mission']!.effectiveStatus, TodayMissionStatus.reviewing);
      expect(
        byId['child-mission']!.effectiveVerificationStatus,
        MissionVerificationStatus.approved,
      );
      expect(
        byId['child-mission']!.effectiveStatus,
        TodayMissionStatus.completed,
      );
    });
  });
}

dynamic _missionResponseFor(String path) {
  if (path == '/api/v1/missions') {
    return <Map<String, dynamic>>[
      _missionJson('parent-mission', 'PARENT'),
      _missionJson('ai-mission', 'AI'),
      _missionJson('child-mission', 'CHILD'),
    ];
  }

  final RegExpMatch? performanceMatch = RegExp(
    r'^/api/v1/missions/([^/]+)/performance$',
  ).firstMatch(path);
  if (performanceMatch != null) {
    return <String, dynamic>{
      'performanceId': '${performanceMatch.group(1)}-performance',
      'status': 'PENDING',
      'proofImageUrl': 'https://test.local/proof.jpg',
    };
  }

  final RegExpMatch? detailMatch = RegExp(
    r'^/api/v1/missions/([^/]+)$',
  ).firstMatch(path);
  if (detailMatch != null) {
    final String missionId = detailMatch.group(1)!;
    final String verificationType = switch (missionId) {
      'ai-mission' => 'AI',
      'child-mission' => 'CHILD',
      _ => 'PARENT',
    };
    return _missionJson(missionId, verificationType);
  }

  throw StateError('Unexpected request path: $path');
}

Map<String, dynamic> _missionJson(String missionId, String verificationType) {
  return <String, dynamic>{
    'missionId': missionId,
    'title': '$missionId title',
    'category': 'STUDY',
    'resetCycle': 'WEEKLY',
    'verificationType': verificationType,
    'reward': 30,
    'description': '$missionId description',
  };
}
