class WhitelistAppCategory {
  const WhitelistAppCategory({
    required this.id,
    required this.name,
    required this.apps,
  });

  final String id;
  final String name;
  final List<WhitelistApp> apps;
}

class WhitelistApp {
  const WhitelistApp({required this.id, required this.name});

  final String id;
  final String name;
}
