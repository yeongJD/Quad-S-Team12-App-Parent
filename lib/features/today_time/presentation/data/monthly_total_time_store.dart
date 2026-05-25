import '../../../../core/auth/account_store.dart';

abstract final class MonthlyTotalTimeStore {
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
    return child?.monthlyTotalMinutes;
  }
}
