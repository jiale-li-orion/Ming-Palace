import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ming_palace/infrastructure/project_content_repository.dart';

void main() {
  test('bundled content defines all required states and fields', () {
    final source = File('assets/content/experience.json').readAsStringSync();
    final result = parseProjectExperience(source);

    expect(result.scenes, hasLength(24));
    expect(result.validate(), isEmpty);
    for (final scene in result.scenes.values) {
      expect(scene.id, isNotEmpty);
      if (scene.id == 'COMPLETED') {
        expect(scene.next, isEmpty);
      } else {
        expect(scene.next, isNotEmpty);
      }
    }
  });

  test('content parser rejects a missing required scene field', () {
    final data = json.decode(
      File('assets/content/experience.json').readAsStringSync(),
    ) as Map<String, dynamic>;
    final scenes = data['scenes'] as Map<String, dynamic>;
    (scenes['READY'] as Map<String, dynamic>).remove('next');

    expect(
      () => parseProjectExperience(json.encode(data)),
      throwsA(anything),
    );
  });
}
