import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:shared_preferences/shared_preferences.dart';

abstract final class ChildConnectionStore {
  static const String linkedKey = 'bridge_p.child.is_linked';
  static const String nameKey = 'bridge_p.child.name';
  static const String birthYearKey = 'bridge_p.child.birth_year';
  static const String codeKey = 'bridge_p.child.code';

  static const String validationEndpoint = String.fromEnvironment(
    'CHILD_CODE_VALIDATION_URL',
  );
  // Backend contract: docs/child-code-validation-api.md
  static const String testChildCode = 'GDG12-CHILD';

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

  static Future<void> saveLinkedChild({
    required String name,
    required int birthYear,
    required String code,
  }) async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    await preferences.setBool(linkedKey, true);
    await preferences.setString(nameKey, name.trim());
    await preferences.setInt(birthYearKey, birthYear);
    await preferences.setString(codeKey, code.trim());
  }

  static Future<bool> hasLinkedChild() async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    return preferences.getBool(linkedKey) ?? false;
  }

  static Future<String?> linkedChildName() async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    return preferences.getString(nameKey);
  }

  static Future<void> clearLinkedChild() async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    await preferences.remove(linkedKey);
    await preferences.remove(nameKey);
    await preferences.remove(birthYearKey);
    await preferences.remove(codeKey);
  }

  static bool _validateWithTestCode(String code) {
    return code.toUpperCase() == testChildCode;
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
