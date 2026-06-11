/// Snapshot of the logged-in parent's profile.
///
/// Sourced from the backend on login and refreshed by ParentProfileRepository
/// on demand. The mock implementation projects [ParentAccount] (minus the
/// password hash) into this DTO so feature pages can rely on a single
/// presentation-friendly type.
enum ParentProfileStatus { active, dormant }

class ParentProfile {
  const ParentProfile({
    required this.parentId,
    required this.email,
    required this.name,
    this.status = ParentProfileStatus.active,
  });

  final String parentId;
  final String email;
  final String name;
  final ParentProfileStatus status;

  ParentProfile copyWith({String? name, ParentProfileStatus? status}) {
    return ParentProfile(
      parentId: parentId,
      email: email,
      name: name ?? this.name,
      status: status ?? this.status,
    );
  }

  factory ParentProfile.fromJson(Map<String, dynamic> json) {
    return ParentProfile(
      parentId: json['parentId'] as String,
      email: json['email'] as String,
      name: json['name'] as String,
      status: _statusFromJson(json['status']),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'parentId': parentId,
        'email': email,
        'name': name,
        'status': status.name,
      };

  static ParentProfileStatus _statusFromJson(Object? value) {
    if (value is String) {
      for (final ParentProfileStatus s in ParentProfileStatus.values) {
        if (s.name == value) {
          return s;
        }
      }
    }
    return ParentProfileStatus.active;
  }
}
