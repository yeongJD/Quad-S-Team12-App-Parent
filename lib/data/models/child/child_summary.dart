/// Lightweight projection of a child account that the parent app shows in
/// child-selector / child-add flows.
///
/// Heavier child-scoped data (mission list, time-rule list, whitelist) is
/// fetched per-domain via the respective repository — this DTO carries only
/// the identifying fields plus the optional avatar.
class ChildSummary {
  const ChildSummary({
    required this.childrenId,
    required this.childCode,
    required this.name,
    this.photoBase64,
  });

  final String childrenId;
  final String childCode;
  final String name;
  final String? photoBase64;

  ChildSummary copyWith({
    String? name,
    String? photoBase64,
  }) {
    return ChildSummary(
      childrenId: childrenId,
      childCode: childCode,
      name: name ?? this.name,
      photoBase64: photoBase64 ?? this.photoBase64,
    );
  }

  factory ChildSummary.fromJson(Map<String, dynamic> json) => ChildSummary(
        childrenId: json['childrenId'] as String,
        childCode: json['childCode'] as String,
        name: json['name'] as String,
        photoBase64: json['photoBase64'] as String?,
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'childrenId': childrenId,
        'childCode': childCode,
        'name': name,
        if (photoBase64 case final String photoBase64) 'photoBase64': photoBase64,
      };
}
