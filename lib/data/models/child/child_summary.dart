/// Lightweight projection of a child account that the parent app shows in
/// child-selector / child-add flows.
///
/// Heavier child-scoped data (mission list, time-rule list, whitelist) is
/// fetched per-domain via the respective repository — this DTO carries only
/// the identifying fields plus the optional avatar.
class ChildSummary {
  const ChildSummary({
    required this.childrenId,
    this.childCode = '',
    required this.name,
    this.profileImageUrl,
  });

  final String childrenId;
  final String childCode;
  final String name;
  final String? profileImageUrl;

  ChildSummary copyWith({
    String? name,
    String? profileImageUrl,
  }) {
    return ChildSummary(
      childrenId: childrenId,
      childCode: childCode,
      name: name ?? this.name,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
    );
  }

  factory ChildSummary.fromJson(Map<String, dynamic> json) => ChildSummary(
        childrenId: json['childrenId'] as String,
        childCode: (json['childCode'] as String?) ?? '',
        name: json['name'] as String,
        profileImageUrl: json['profileImageUrl'] as String?,
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'childrenId': childrenId,
        'childCode': childCode,
        'name': name,
        if (profileImageUrl case final String profileImageUrl) 'profileImageUrl': profileImageUrl,
      };
}
