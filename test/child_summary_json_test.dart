import 'package:bridge_p/data/models/child/child_summary.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ChildSummary.fromJson backend wire shape', () {
    test('coerces numeric childrenId (Long) to String without throwing', () {
      // Backend ChildrenInfoResponse serialises childrenId as a JSON number.
      // The previous `as String` cast threw a TypeError here, crashing both
      // GET /api/v1/parents/children and the POST register response.
      final ChildSummary summary = ChildSummary.fromJson(<String, dynamic>{
        'childrenId': 5,
        'name': '하늘',
        'profileImageUrl': 'https://bucket.s3.amazonaws.com/photos/profile/x.jpg',
      });

      expect(summary.childrenId, '5');
      expect(summary.name, '하늘');
      expect(summary.profileImageUrl,
          'https://bucket.s3.amazonaws.com/photos/profile/x.jpg');
      expect(summary.childCode, ''); // backend omits childCode
    });

    test('tolerates missing optional fields', () {
      final ChildSummary summary = ChildSummary.fromJson(<String, dynamic>{
        'childrenId': 12,
        'name': '바다',
      });
      expect(summary.childrenId, '12');
      expect(summary.profileImageUrl, isNull);
    });
  });
}
