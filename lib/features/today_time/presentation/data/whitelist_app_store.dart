import '../../../../core/auth/account_store.dart';

abstract final class WhitelistAppStore {
  static Future<void> save({
    required String parentId,
    required String childrenId,
    required Set<String> appIds,
  }) async {
    if (parentId.isEmpty || childrenId.isEmpty) {
      return;
    }

    final List<String> sortedAppIds = appIds.toList()..sort();
    await AccountStore.updateChild(
      parentId: parentId,
      childrenId: childrenId,
      update: (AccountChildData child) {
        return child.copyWith(whitelistAppIds: sortedAppIds);
      },
    );
  }

  static Future<Set<String>> load({
    required String parentId,
    required String childrenId,
  }) async {
    if (parentId.isEmpty || childrenId.isEmpty) {
      return <String>{};
    }

    final AccountChildData? child = await AccountStore.getChild(
      parentId: parentId,
      childrenId: childrenId,
    );
    return child == null ? <String>{} : child.whitelistAppIds.toSet();
  }
}
