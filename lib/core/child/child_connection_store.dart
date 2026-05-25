import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../auth/account_store.dart';

class ConnectedChild {
  const ConnectedChild({
    required this.childrenId,
    required this.childCode,
    required this.name,
    this.photoBase64,
  });

  final String childrenId;
  final String childCode;
  final String name;
  final String? photoBase64;

  factory ConnectedChild.fromAccountChild(AccountChildData child) {
    return ConnectedChild(
      childrenId: child.childrenId,
      childCode: child.childCode,
      name: child.name,
      photoBase64: child.photoBase64,
    );
  }

  AccountChildData toAccountChild() {
    return AccountChildData(
      childrenId: childrenId,
      childCode: childCode,
      name: name,
      photoBase64: photoBase64,
    );
  }
}

abstract final class ChildConnectionStore {
  static const String validationEndpoint = String.fromEnvironment(
    'CHILD_CODE_VALIDATION_URL',
  );
  // Backend contract: docs/child-code-validation-api.md
  static const List<String> testChildCodes = <String>[
    'GDG12-1',
    'GDG12-2',
    'GDG12-3',
  ];
  static const String testChildCode = 'GDG12-1';

  static bool get usesLocalTestValidator => validationEndpoint.isEmpty;

  static Future<bool> validateChildCode(String code) async {
    final String trimmedCode = code.trim();
    if (trimmedCode.isEmpty) {
      return false;
    }

    if (usesLocalTestValidator) {
      return _validateWithTestCode(trimmedCode);
    }

    return _validateWithServer(trimmedCode);
  }

  static Future<List<ConnectedChild>> loadChildren(String parentId) async {
    final ParentAccount? account = await AccountStore.getAccountById(parentId);
    if (account == null) {
      return <ConnectedChild>[];
    }
    return account.children
        .map(ConnectedChild.fromAccountChild)
        .toList(growable: false);
  }

  static Future<void> addChild({
    required String parentId,
    required ConnectedChild child,
  }) async {
    await AccountStore.addChild(
      parentId: parentId,
      child: child.toAccountChild(),
    );
  }

  static Future<void> removeChild({
    required String parentId,
    required String childrenId,
  }) async {
    await AccountStore.removeChild(parentId: parentId, childrenId: childrenId);
  }

  static Future<ConnectedChild?> getSelectedChild(String parentId) async {
    final List<ConnectedChild> children = await loadChildren(parentId);
    return children.isEmpty ? null : children.first;
  }

  static ConnectedChild childFromCode({
    required String name,
    required String childCode,
    String? photoBase64,
  }) {
    final String normalizedCode = _normalizeCode(childCode);
    return ConnectedChild(
      childrenId: normalizedCode,
      childCode: normalizedCode,
      name: name.trim(),
      photoBase64: photoBase64,
    );
  }

  static bool _validateWithTestCode(String code) {
    return testChildCodes.contains(_normalizeCode(code));
  }

  static String _normalizeCode(String code) {
    return code.trim().toUpperCase();
  }

  static Future<bool> _validateWithServer(String code) async {
    final Uri endpoint = Uri.parse(validationEndpoint);
    final HttpClient client = HttpClient();

    try {
      final HttpClientRequest request = await client
          .postUrl(endpoint)
          .timeout(const Duration(seconds: 5));
      request.headers.contentType = ContentType.json;
      request.write(jsonEncode(<String, String>{'code': code}));

      final HttpClientResponse response = await request.close().timeout(
        const Duration(seconds: 5),
      );
      if (response.statusCode != HttpStatus.ok) {
        return false;
      }

      final String responseBody = await response.transform(utf8.decoder).join();
      final Object? decoded = jsonDecode(responseBody);
      if (decoded is! Map<String, Object?>) {
        return false;
      }

      return decoded['valid'] == true;
    } on FormatException {
      return false;
    } on TimeoutException {
      return false;
    } on SocketException {
      return false;
    } finally {
      client.close(force: true);
    }
  }
}
