import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ming_palace/infrastructure/local_content_repository.dart';

void main() {
  test('bundled content defines all required states and fields', () {
    final source = File('assets/content/experience.json').readAsStringSync();
    final result = parseExperienceJson(source);

    expect(result.isOk, isTrue);
    expect(result.okValue, hasLength(21));
    for (final scene in result.okValue!.values) {
      expect(scene.id, isNotEmpty);
      expect(scene.next, isNotEmpty);
      expect(scene.operatorActions, isNotEmpty);
    }
  });

  test('content parser rejects a missing required scene field', () {
    final data = json.decode(
      File('assets/content/experience.json').readAsStringSync(),
    ) as Map<String, dynamic>;
    final scenes = data['scenes'] as Map<String, dynamic>;
    (scenes['READY'] as Map<String, dynamic>).remove('next');

    final result = parseExperienceJson(json.encode(data));

    expect(result.isErr, isTrue);
  });
}
