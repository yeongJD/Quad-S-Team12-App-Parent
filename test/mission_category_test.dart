import 'dart:io';

import 'package:bridge_p/features/today_mission/presentation/models/today_mission.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MissionCategory', () {
    test('icon assets point to existing bundled files', () {
      for (final MissionCategory category in MissionCategory.values) {
        expect(
          File(category.iconAsset).existsSync(),
          isTrue,
          reason: '${category.name} icon should exist at ${category.iconAsset}',
        );
      }
    });

    test('decodes backend and display category aliases', () {
      expect(missionCategoryFromWire('STUDY'), MissionCategory.study);
      expect(missionCategoryFromWire('EXERCISE'), MissionCategory.exercise);
      expect(missionCategoryFromWire('CLEANING'), MissionCategory.cleaning);
      expect(missionCategoryFromWire('ERRAND'), MissionCategory.errand);
      expect(missionCategoryFromWire('ROUTINE'), MissionCategory.routine);
      expect(missionCategoryFromWire('ETC'), MissionCategory.etc);
      expect(missionCategoryFromWire('방청소'), MissionCategory.cleaning);
      expect(missionCategoryFromWire('공부'), MissionCategory.study);
      expect(missionCategoryFromWire('기타'), MissionCategory.etc);
    });
  });
}
