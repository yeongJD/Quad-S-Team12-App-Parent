import 'package:dio/dio.dart';

import '../../core/config/dio_config.dart';
import '../../core/models/result.dart';
import '../../core/network/api_error.dart';
import '../../features/today_time/presentation/models/daily_time_rule.dart';
import '../models/time_plan/daily_time_rule_dto.dart';
import 'time_plan_repository.dart';

/// Network-backed [TimePlanRepository] per `docs/api/04-time-plan.md`.
///
/// Endpoints sit under `/children/{childrenId}/time-plan/*` and accept
/// `parentId` as a query param for authorisation. Each sub-resource has
/// its own GET / PUT pair — backends that prefer a single aggregate GET
/// can implement that as an optimisation while still honouring the
/// individual PUTs (see contract doc for details).
class ApiTimePlanRepository implements TimePlanRepository {
  ApiTimePlanRepository({Dio? dio}) : _dio = dio ?? DioConfig.create();

  final Dio _dio;

  @override
  Future<Result<List<DailyTimeRule>>> loadDailyRules({
    required String parentId,
    required String childrenId,
  }) =>
      _loadRuleList(
        parentId: parentId,
        childrenId: childrenId,
        path: 'daily-rules',
      );

  @override
  Future<Result<void>> saveDailyRules({
    required String parentId,
    required String childrenId,
    required List<DailyTimeRule> rules,
  }) =>
      _saveRuleList(
        parentId: parentId,
        childrenId: childrenId,
        path: 'daily-rules',
        rules: rules,
      );

  @override
  Future<Result<List<DailyTimeRule>>> loadChildWeeklyRules({
    required String parentId,
    required String childrenId,
  }) =>
      _loadRuleList(
        parentId: parentId,
        childrenId: childrenId,
        path: 'weekly-rules',
      );

  @override
  Future<Result<void>> saveChildWeeklyRules({
    required String parentId,
    required String childrenId,
    required List<DailyTimeRule> rules,
  }) =>
      _saveRuleList(
        parentId: parentId,
        childrenId: childrenId,
        path: 'weekly-rules',
        rules: rules,
      );

  @override
  Future<Result<int?>> loadMonthlyTotal({
    required String parentId,
    required String childrenId,
  }) async {
    try {
      final Response<dynamic> response = await _dio.get<dynamic>(
        '/children/$childrenId/time-plan/monthly-total',
        queryParameters: <String, dynamic>{'parentId': parentId},
      );
      final dynamic data = response.data;
      if (data is! Map) {
        return Result<int?>.success(null);
      }
      final dynamic value = data['totalMinutes'];
      return Result<int?>.success(value is int ? value : null);
    } on DioException catch (e) {
      return failureFromDioException<int?>(e);
    }
  }

  @override
  Future<Result<void>> saveMonthlyTotal({
    required String parentId,
    required String childrenId,
    required int totalMinutes,
  }) async {
    try {
      await _dio.put<dynamic>(
        '/children/$childrenId/time-plan/monthly-total',
        queryParameters: <String, dynamic>{'parentId': parentId},
        data: <String, dynamic>{'totalMinutes': totalMinutes},
      );
      return Result<void>.success(null);
    } on DioException catch (e) {
      return failureFromDioException<void>(e);
    }
  }

  @override
  Future<Result<Set<String>>> loadWhitelist({
    required String parentId,
    required String childrenId,
  }) async {
    try {
      final Response<dynamic> response = await _dio.get<dynamic>(
        '/children/$childrenId/time-plan/whitelist',
        queryParameters: <String, dynamic>{'parentId': parentId},
      );
      final dynamic data = response.data;
      if (data is! Map) {
        return Result<Set<String>>.success(<String>{});
      }
      final dynamic appIds = data['appIds'];
      if (appIds is! List) {
        return Result<Set<String>>.success(<String>{});
      }
      return Result<Set<String>>.success(appIds.whereType<String>().toSet());
    } on DioException catch (e) {
      return failureFromDioException<Set<String>>(e);
    }
  }

  @override
  Future<Result<void>> saveWhitelist({
    required String parentId,
    required String childrenId,
    required Set<String> appIds,
  }) async {
    try {
      await _dio.put<dynamic>(
        '/children/$childrenId/time-plan/whitelist',
        queryParameters: <String, dynamic>{'parentId': parentId},
        data: <String, dynamic>{
          'appIds': (appIds.toList()..sort()),
        },
      );
      return Result<void>.success(null);
    } on DioException catch (e) {
      return failureFromDioException<void>(e);
    }
  }

  Future<Result<List<DailyTimeRule>>> _loadRuleList({
    required String parentId,
    required String childrenId,
    required String path,
  }) async {
    try {
      final Response<dynamic> response = await _dio.get<dynamic>(
        '/children/$childrenId/time-plan/$path',
        queryParameters: <String, dynamic>{'parentId': parentId},
      );
      final dynamic data = response.data;
      if (data is! Map) {
        return Result<List<DailyTimeRule>>.success(const <DailyTimeRule>[]);
      }
      final dynamic rulesValue = data['rules'];
      if (rulesValue is! List) {
        return Result<List<DailyTimeRule>>.success(const <DailyTimeRule>[]);
      }
      final List<DailyTimeRule> rules = rulesValue
          .whereType<Map<String, dynamic>>()
          .map(DailyTimeRuleDto.fromJson)
          .whereType<DailyTimeRule>()
          .toList(growable: false);
      return Result<List<DailyTimeRule>>.success(rules);
    } on DioException catch (e) {
      return failureFromDioException<List<DailyTimeRule>>(e);
    }
  }

  Future<Result<void>> _saveRuleList({
    required String parentId,
    required String childrenId,
    required String path,
    required List<DailyTimeRule> rules,
  }) async {
    try {
      await _dio.put<dynamic>(
        '/children/$childrenId/time-plan/$path',
        queryParameters: <String, dynamic>{'parentId': parentId},
        data: <String, dynamic>{
          'rules': rules.map(DailyTimeRuleDto.toJson).toList(growable: false),
        },
      );
      return Result<void>.success(null);
    } on DioException catch (e) {
      return failureFromDioException<void>(e);
    }
  }
}
