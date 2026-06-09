import '../../../../core/auth/account_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract final class MonthlyTotalTimeStore {
  static const String _keyPrefix = 'bridge_p.monthly_total';

  static Future<void> save({
    required String parentId,
    required String childrenId,
    required int totalMinutes,
  }) async {
    if (parentId.isEmpty || childrenId.isEmpty) {
      return;
    }

    await AccountStore.updateChild(
      parentId: parentId,
      childrenId: childrenId,
      update: (AccountChildData child) {
        return child.copyWith(monthlyTotalMinutes: totalMinutes);
      },
    );
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    await preferences.setInt(_key(parentId, childrenId), totalMinutes);
  }

  static Future<int?> load({
    required String parentId,
    required String childrenId,
  }) async {
    if (parentId.isEmpty || childrenId.isEmpty) {
      return null;
    }

    final AccountChildData? child = await AccountStore.getChild(
      parentId: parentId,
      childrenId: childrenId,
    );
    if (child?.monthlyTotalMinutes case final int total) {
      return total;
    }
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    return preferences.getInt(_key(parentId, childrenId));
  }

  static String _key(String parentId, String childrenId) =>
      '$_keyPrefix.$parentId.$childrenId';
}
