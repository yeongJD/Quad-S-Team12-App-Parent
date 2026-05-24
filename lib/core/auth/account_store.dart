import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

enum AccountStatus {
  active,
  dormant;

  String get jsonValue => name;

  static AccountStatus fromJson(Object? value) {
    if (value is String) {
      for (final AccountStatus status in AccountStatus.values) {
        if (status.jsonValue == value) {
          return status;
        }
      }
    }
    return AccountStatus.active;
  }
}

class ParentAccount {
  const ParentAccount({
    required this.parentId,
    required this.email,
    required this.name,
    required this.passwordHash,
    this.status = AccountStatus.active,
    this.hiddenNotificationIds = const <String>[],
    this.children = const <AccountChildData>[],
  });

  final String parentId;
  final String email;
  final String name;
  final String passwordHash;
  final AccountStatus status;
  final List<String> hiddenNotificationIds;
  final List<AccountChildData> children;

  ParentAccount copyWith({
    String? name,
    String? passwordHash,
    AccountStatus? status,
    List<String>? hiddenNotificationIds,
    List<AccountChildData>? children,
  }) {
    return ParentAccount(
      parentId: parentId,
      email: email,
      name: name ?? this.name,
      passwordHash: passwordHash ?? this.passwordHash,
      status: status ?? this.status,
      hiddenNotificationIds:
          hiddenNotificationIds ?? this.hiddenNotificationIds,
      children: children ?? this.children,
    );
  }

  Map<String, Object> toJson() {
    return <String, Object>{
      'parentId': parentId,
      'email': email,
      'name': name,
      'passwordHash': passwordHash,
      'status': status.jsonValue,
      'hiddenNotificationIds': hiddenNotificationIds,
      'children': children
          .map((AccountChildData child) => child.toJson())
          .toList(),
    };
  }

  static ParentAccount? fromJson(Object? json) {
    if (json is! Map<String, Object?>) {
      return null;
    }

    final Object? parentId = json['parentId'];
    final Object? email = json['email'];
    final Object? name = json['name'];
    final Object? passwordHash = json['passwordHash'];
    final Object? hiddenNotificationIdsValue = json['hiddenNotificationIds'];
    final Object? childrenValue = json['children'];
    if (parentId is! String ||
        email is! String ||
        name is! String ||
        passwordHash is! String) {
      return null;
    }

    final List<AccountChildData> children = childrenValue is List<Object?>
        ? childrenValue
              .map(AccountChildData.fromJson)
              .whereType<AccountChildData>()
              .toList()
        : <AccountChildData>[];

    return ParentAccount(
      parentId: parentId,
      email: email,
      name: name,
      passwordHash: passwordHash,
      status: AccountStatus.fromJson(json['status']),
      hiddenNotificationIds: hiddenNotificationIdsValue is List<Object?>
          ? hiddenNotificationIdsValue.whereType<String>().toList()
          : const <String>[],
      children: children,
    );
  }
}

class AccountChildData {
  const AccountChildData({
    required this.childrenId,
    required this.childCode,
    required this.name,
    this.dailyRules = const <Map<String, Object?>>[],
    this.missions = const <Map<String, Object?>>[],
  });

  final String childrenId;
  final String childCode;
  final String name;
  final List<Map<String, Object?>> dailyRules;
  final List<Map<String, Object?>> missions;

  AccountChildData copyWith({
    String? name,
    List<Map<String, Object?>>? dailyRules,
    List<Map<String, Object?>>? missions,
  }) {
    return AccountChildData(
      childrenId: childrenId,
      childCode: childCode,
      name: name ?? this.name,
      dailyRules: dailyRules ?? this.dailyRules,
      missions: missions ?? this.missions,
    );
  }

  Map<String, Object> toJson() {
    return <String, Object>{
      'childrenId': childrenId,
      'childCode': childCode,
      'name': name,
      'dailyRules': dailyRules,
      'missions': missions,
    };
  }

  static AccountChildData? fromJson(Object? json) {
    if (json is! Map<String, Object?>) {
      return null;
    }

    final Object? childrenId = json['childrenId'];
    final Object? childCode = json['childCode'];
    final Object? name = json['name'];
    if (childrenId is! String || childCode is! String || name is! String) {
      return null;
    }

    return AccountChildData(
      childrenId: childrenId,
      childCode: childCode,
      name: name,
      dailyRules: _decodeMapList(json['dailyRules']),
      missions: _decodeMapList(json['missions']),
    );
  }

  static List<Map<String, Object?>> _decodeMapList(Object? value) {
    if (value is! List<Object?>) {
      return <Map<String, Object?>>[];
    }
    return value.whereType<Map<String, Object?>>().toList();
  }
}

abstract final class AccountStore {
  static const String accountsKey = 'bridge_p.accounts';

  static Future<void> saveAccount(ParentAccount account) async {
    final List<ParentAccount> accounts = await getAllAccounts();
    final int existingIndex = accounts.indexWhere(
      (ParentAccount candidate) => candidate.parentId == account.parentId,
    );
    if (existingIndex < 0) {
      accounts.add(account);
    } else {
      accounts[existingIndex] = account;
    }
    final bool didSave = await _saveAccounts(accounts);
    if (!didSave) {
      throw StateError('Failed to persist account data.');
    }
  }

  static Future<ParentAccount?> getAccountByEmail(String email) async {
    final String normalizedEmail = _normalizeEmail(email);
    final List<ParentAccount> accounts = await getAllAccounts();
    for (final ParentAccount account in accounts) {
      if (_normalizeEmail(account.email) == normalizedEmail) {
        return account;
      }
    }
    return null;
  }

  static Future<ParentAccount?> getAccountById(String parentId) async {
    final List<ParentAccount> accounts = await getAllAccounts();
    for (final ParentAccount account in accounts) {
      if (account.parentId == parentId) {
        return account;
      }
    }
    return null;
  }

  static Future<bool> validateLogin({
    required String email,
    required String password,
  }) async {
    final ParentAccount? account = await getAccountByEmail(email);
    if (account == null) {
      return false;
    }
    return account.status == AccountStatus.active &&
        account.passwordHash == _hashPassword(password);
  }

  static Future<void> updatePassword({
    required String parentId,
    required String password,
  }) async {
    final ParentAccount? account = await getAccountById(parentId);
    if (account == null) {
      return;
    }
    await saveAccount(account.copyWith(passwordHash: _hashPassword(password)));
  }

  static Future<void> updateStatus({
    required String parentId,
    required AccountStatus status,
  }) async {
    final ParentAccount? account = await getAccountById(parentId);
    if (account == null) {
      throw StateError('Cannot update status because account does not exist.');
    }
    await saveAccount(account.copyWith(status: status));
  }

  static Future<List<ParentAccount>> getAllAccounts() async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    final String? encodedAccounts = preferences.getString(accountsKey);
    if (encodedAccounts == null || encodedAccounts.isEmpty) {
      return <ParentAccount>[_defaultMockAccount];
    }

    try {
      final Object? decoded = jsonDecode(encodedAccounts);
      if (decoded is! List<Object?>) {
        return <ParentAccount>[_defaultMockAccount];
      }
      final List<ParentAccount> accounts = decoded
          .map(ParentAccount.fromJson)
          .whereType<ParentAccount>()
          .toList();
      return accounts;
    } on FormatException {
      return <ParentAccount>[_defaultMockAccount];
    }
  }

  static Future<void> removeAccount(String parentId) async {
    final List<ParentAccount> accounts = await getAllAccounts();
    final bool accountExists = accounts.any(
      (ParentAccount account) => account.parentId == parentId,
    );
    if (!accountExists) {
      throw StateError('Cannot remove account because it does not exist.');
    }

    final List<ParentAccount> remainingAccounts = accounts
        .where((ParentAccount account) => account.parentId != parentId)
        .toList(growable: false);
    final bool didSave = await _saveAccounts(remainingAccounts);
    if (!didSave) {
      throw StateError('Failed to persist account deletion.');
    }

    final List<ParentAccount> verifiedAccounts = await getAllAccounts();
    final bool stillExists = verifiedAccounts.any(
      (ParentAccount account) => account.parentId == parentId,
    );
    if (stillExists) {
      throw StateError('Account deletion verification failed.');
    }
  }

  static Future<AccountChildData?> getChild({
    required String parentId,
    required String childrenId,
  }) async {
    final ParentAccount? account = await getAccountById(parentId);
    if (account == null) {
      return null;
    }

    for (final AccountChildData child in account.children) {
      if (child.childrenId == childrenId) {
        return child;
      }
    }
    return null;
  }

  static Future<void> updateChild({
    required String parentId,
    required String childrenId,
    required AccountChildData Function(AccountChildData child) update,
  }) async {
    final ParentAccount? account = await getAccountById(parentId);
    if (account == null) {
      return;
    }

    final List<AccountChildData> children = <AccountChildData>[
      for (final AccountChildData child in account.children)
        child.childrenId == childrenId ? update(child) : child,
    ];
    await saveAccount(account.copyWith(children: children));
  }

  static Future<void> updateNotifications({
    required String parentId,
    required ParentAccount Function(ParentAccount account) update,
  }) async {
    final ParentAccount? account = await getAccountById(parentId);
    if (account == null) {
      return;
    }

    await saveAccount(update(account));
  }

  static Future<void> addChild({
    required String parentId,
    required AccountChildData child,
  }) async {
    final ParentAccount? account = await getAccountById(parentId);
    if (account == null) {
      return;
    }

    final List<AccountChildData> children = account.children
        .where(
          (AccountChildData candidate) =>
              candidate.childrenId != child.childrenId,
        )
        .toList();
    children.add(child);
    await saveAccount(account.copyWith(children: children));
  }

  static Future<void> removeChild({
    required String parentId,
    required String childrenId,
  }) async {
    final ParentAccount? account = await getAccountById(parentId);
    if (account == null) {
      return;
    }

    await saveAccount(
      account.copyWith(
        children: account.children
            .where((AccountChildData child) => child.childrenId != childrenId)
            .toList(),
      ),
    );
  }

  static Future<bool> _saveAccounts(List<ParentAccount> accounts) async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    return preferences.setString(
      accountsKey,
      jsonEncode(
        accounts.map((ParentAccount account) => account.toJson()).toList(),
      ),
    );
  }

  static String passwordHashForLocalMock(String password) {
    return _hashPassword(password);
  }

  static String parentIdFromEmail(String email) {
    return _normalizeEmail(email);
  }

  static String _hashPassword(String password) {
    // Local-only mock hash. Backend integration should replace this layer.
    return password;
  }

  static String _normalizeEmail(String email) {
    return email.trim().toLowerCase();
  }

  static const ParentAccount _defaultMockAccount = ParentAccount(
    parentId: 'gdg12@gmail.com',
    email: 'gdg12@gmail.com',
    name: 'parent',
    passwordHash: 'Gdg1234@',
  );
}
