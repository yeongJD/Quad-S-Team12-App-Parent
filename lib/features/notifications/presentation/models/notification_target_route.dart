import 'notification_item.dart';

String? parentNotificationTargetRoute(
  NotificationItem item, {
  required String? parentId,
}) {
  final Map<String, Object?>? payload = item.payload;
  if (payload == null) {
    return null;
  }

  for (final String key in <String>['targetRoute', 'deeplink']) {
    final Object? value = payload[key];
    final String? route = value?.toString();
    if (route != null && route.startsWith('/')) {
      return normalizeParentNotificationRoute(
        route,
        parentId: parentId,
        childrenId: _childRefFromPayload(payload),
      );
    }
  }
  return null;
}

String normalizeParentNotificationRoute(
  String route, {
  required String? parentId,
  String? childrenId,
}) {
  final Uri? uri = Uri.tryParse(route);
  if (uri == null || !route.startsWith('/')) {
    return route;
  }
  if (!_requiresParentContext(uri.path)) {
    return route;
  }

  final Map<String, String> queryParameters = Map<String, String>.from(
    uri.queryParameters,
  );
  if (_isPresent(parentId) && !_isPresent(queryParameters['parentId'])) {
    queryParameters['parentId'] = parentId!;
  }
  if (_isPresent(childrenId) && !_isPresent(queryParameters['childrenId'])) {
    queryParameters['childrenId'] = childrenId!;
  }

  return uri
      .replace(
        queryParameters: queryParameters.isEmpty ? null : queryParameters,
      )
      .toString();
}

bool _requiresParentContext(String path) {
  return path == '/today-time' ||
      path == '/today-mission' ||
      path == '/usage-report';
}

String? _childRefFromPayload(Map<String, Object?> payload) {
  for (final String key in <String>['childrenId', 'childId', 'childCode']) {
    final Object? value = payload[key];
    final String? childRef = value?.toString();
    if (_isPresent(childRef)) {
      return childRef;
    }
  }
  return null;
}

bool _isPresent(String? value) => value != null && value.isNotEmpty;
