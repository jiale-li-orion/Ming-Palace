import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ming_palace/infrastructure/project_content_repository.dart';
import 'package:ming_palace/infrastructure/export_service.dart';
import 'package:ming_palace/infrastructure/local_telemetry_repository.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

// ---------------------------------------------------------------------------
// Fake PathProvider — avoids needing real device directories in unit tests
// ---------------------------------------------------------------------------

class FakePathProvider extends PathProviderPlatform
    with MockPlatformInterfaceMixin {

  FakePathProvider(this.tempDir);
  final Directory tempDir;

  @override
  Future<String> getApplicationDocumentsPath() async => tempDir.path;

  @override
  Future<String> getApplicationSupportPath() async => tempDir.path;

  @override
  Future<String> getTemporaryPath() async => tempDir.path;
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  late Directory tempDir;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('telemetry_test_');
    PathProviderPlatform.instance = FakePathProvider(tempDir);
  });

  tearDown(() {
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  group('LocalContentRepository', () {
    test('loads the bundled, validated 24-phase package', () async {
      final source =
          await File('assets/content/experience.json').readAsString();
      final result = parseProjectExperience(source);
      expect(result.validate(), isEmpty);
      expect(result.scenes, hasLength(24));
    });
  });

  group('LocalTelemetryRepository', () {
    test('writes and reads events', () async {
      final repo = LocalTelemetryRepository();

      await repo.log({'event': 'test_event', 'sessionId': 's1'});
      await repo.log({'event': 'test_event2', 'sessionId': 's1'});

      final result = await repo.exportAll();
      expect(result.isOk, isTrue);
      expect(result.okValue!.length, 2);
      expect(result.okValue![0]['event'], 'test_event');
      expect(result.okValue![0]['schemaVersion'], 1);
      expect(result.okValue![0]['timestamp'], isNotEmpty);
    });

    test('auto-enriches with schemaVersion and timestamp', () async {
      final repo = LocalTelemetryRepository();
      await repo.log({'event': 'raw', 'sessionId': 's1'});

      final result = await repo.exportAll();
      final event = result.okValue!.first;
      expect(event['schemaVersion'], 1);
      expect(event['timestamp'], isA<String>());
    });

    test('buildSummary for normal route with feudal choice', () async {
      final repo = LocalTelemetryRepository();
      const sessionId = 'summary-test-1';

      await repo.log({'event': 'session_created', 'sessionId': sessionId});
      await repo.log(
          {'event': 'state_entered', 'sessionId': sessionId, 'state': 'INTRO'});
      await repo.log({
        'event': 'question_choice',
        'sessionId': sessionId,
        'payload': {'choice': 'feudal_princes'}
      });
      await repo.log({'event': 'session_completed', 'sessionId': sessionId});

      final result = await repo.buildSummary(sessionId);
      expect(result.isOk, isTrue);
      final summary = result.okValue!;
      expect(summary.sessionId, sessionId);
      expect(summary.completed, isTrue);
      expect(summary.questionChoice, 'feudal_princes');
      expect(summary.helpCount, 0);
      expect(summary.interrupted, isFalse);
      expect(summary.route, 'normal');
      expect(summary.durationSeconds, greaterThanOrEqualTo(0));
    });

    test('buildSummary for fallback route with help', () async {
      final repo = LocalTelemetryRepository();
      const sessionId = 'summary-test-2';

      await repo.log({'event': 'session_created', 'sessionId': sessionId});
      await repo.log({
        'event': 'state_entered',
        'sessionId': sessionId,
        'state': 'WALK_TO_WUMEN'
      });
      await repo.log({'event': 'fallback_route_used', 'sessionId': sessionId});
      await repo.log({'event': 'help_requested', 'sessionId': sessionId});
      await repo.log({'event': 'help_requested', 'sessionId': sessionId});
      await repo.log({'event': 'session_completed', 'sessionId': sessionId});

      final result = await repo.buildSummary(sessionId);
      expect(result.isOk, isTrue);
      final summary = result.okValue!;
      expect(summary.route, 'fallback');
      expect(summary.helpCount, 2);
      expect(summary.questionChoice, isNull);
    });

    test('buildSummary for aborted session', () async {
      final repo = LocalTelemetryRepository();
      const sessionId = 'summary-test-3';

      await repo.log({'event': 'session_created', 'sessionId': sessionId});
      await repo.log({
        'event': 'state_entered',
        'sessionId': sessionId,
        'state': 'FENGTIAN_NORTH'
      });
      await repo.log({'event': 'session_aborted', 'sessionId': sessionId});

      final result = await repo.buildSummary(sessionId);
      expect(result.isOk, isTrue);
      final summary = result.okValue!;
      expect(summary.completed, isFalse);
      expect(summary.interrupted, isTrue);
    });

    test('buildSummary with survey answers', () async {
      final repo = LocalTelemetryRepository();
      const sessionId = 'summary-test-4';

      await repo.log({'event': 'session_created', 'sessionId': sessionId});
      await repo.log({'event': 'session_completed', 'sessionId': sessionId});
      await repo.log({
        'event': 'survey_submitted',
        'sessionId': sessionId,
        'payload': {
          'experienceDescription': 'walking with Emperor',
          'mostEngagingMoment': 'platform view',
          'confusingMoment': 'none',
          'wantsLongerExperience': true,
          'wantsNextTest': true,
        },
      });

      final result = await repo.buildSummary(sessionId);
      expect(result.isOk, isTrue);
      final summary = result.okValue!;
      expect(summary.survey, isNotNull);
      expect(summary.survey!.experienceDescription, 'walking with Emperor');
      expect(summary.survey!.wantsLongerExperience, isTrue);
      expect(summary.survey!.wantsNextTest, isTrue);
    });

    test('exportAll returns empty list for no data', () async {
      final repo = LocalTelemetryRepository();
      final result = await repo.exportAll();
      expect(result.isOk, isTrue);
      expect(result.okValue, isEmpty);
    });

    test('clearAll removes all data', () async {
      final repo = LocalTelemetryRepository();
      await repo.log({'event': 'test', 'sessionId': 's1'});
      await repo.clearAll();
      final result = await repo.exportAll();
      expect(result.isOk, isTrue);
      expect(result.okValue, isEmpty);
    });

    test('multiple sessions do not interfere', () async {
      final repo = LocalTelemetryRepository();

      await repo.log({'event': 'session_created', 'sessionId': 'sess-a'});
      await repo.log({'event': 'session_created', 'sessionId': 'sess-b'});
      await repo.log({
        'event': 'question_choice',
        'sessionId': 'sess-a',
        'payload': {'choice': 'feudal_princes'}
      });

      final summaryA = await repo.buildSummary('sess-a');
      expect(summaryA.okValue!.questionChoice, 'feudal_princes');

      final summaryB = await repo.buildSummary('sess-b');
      expect(summaryB.okValue!.questionChoice, isNull);
    });

    test('normalizes event details into payload', () async {
      final repo = LocalTelemetryRepository();
      await repo.log({
        'event': 'session_created',
        'sessionId': 'normalized-session',
      });
      await repo.log({
        'event': 'question_choice',
        'sessionId': 'normalized-session',
        'choice': 'feudal_princes',
      });

      final events = (await repo.exportAll()).okValue!;
      expect(events.last['payload'], {'choice': 'feudal_princes'});
      final summary = await repo.buildSummary('normalized-session');
      expect(summary.okValue!.questionChoice, 'feudal_princes');
    });
  });

  group('ExportService', () {
    test('exports only the requested session when sessionId is provided',
        () async {
      final telemetry = LocalTelemetryRepository();
      await telemetry.log({'event': 'a', 'sessionId': 'session-a'});
      await telemetry.log({'event': 'b', 'sessionId': 'session-b'});
      final output = '${tempDir.path}/session-a.json';

      final result = await ExportService().exportAsJson(
        output,
        sessionId: 'session-a',
      );

      expect(result.isOk, isTrue);
      final events = json.decode(File(output).readAsStringSync()) as List;
      expect(events, hasLength(1));
      expect((events.single as Map<String, dynamic>)['sessionId'], 'session-a');
    });
  });
}
