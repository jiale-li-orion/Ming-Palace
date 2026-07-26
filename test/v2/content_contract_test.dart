import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ming_palace/infrastructure/project_content_repository.dart';

void main() {
  test('project content has all 24 phases and both routes reach completed', () {
    final content = parseProjectExperience(
      File('assets/content/experience.json').readAsStringSync(),
    );
    expect(content.scenes, hasLength(24));
    expect(content.validate(), isEmpty);
    expect(content.routeReachesCompleted('tower'), isTrue);
    expect(content.routeReachesCompleted('ground'), isTrue);
    expect(content.routePhases('ground'), isNot(contains('TOWER_ASCEND')));
    expect(content.routePhases('ground'), isNot(contains('TOWER_DESCEND')));
  });

  test('all configured image assets exist and use ai_v1', () {
    final content = parseProjectExperience(
      File('assets/content/experience.json').readAsStringSync(),
    );
    final backgrounds = content.scenes.values
        .map((scene) => scene.background)
        .whereType<String>()
        .toSet();
    expect(backgrounds, hasLength(7));
    for (final asset in backgrounds) {
      expect(asset, startsWith('images/ai_v1/'));
      expect(File('assets/$asset').existsSync(), isTrue, reason: asset);
    }
  });

  test('evidence index exposes only equally weighted A B C categories', () {
    final evidence = parseEvidenceIndex(
      File('assets/content/evidence-index.json').readAsStringSync(),
    );
    expect(evidence.categoryKeys, ['A', 'B', 'C']);
    expect(evidence.entries, isNotEmpty);
  });
}
