import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../domain/session_summary.dart';
import '../shared/app_error.dart';
import '../shared/result.dart';

/// Repository contract for telemetry / event logging.
///
/// All events are written to a local JSONL file (one JSON object per line).
/// No network calls are made — this is purely offline-first.
abstract interface class TelemetryRepository {
  /// Appends a single event to the telemetry log.
  ///
  /// The caller should provide at minimum `event` (string) and `sessionId`.
  /// The repository automatically injects `schemaVersion` and `timestamp`
  /// (ISO-8601 UTC) if they are not already present.
  Future<void> log(Map<String, dynamic> event);

  /// Reads all events for [sessionId] and computes a [SessionSummary].
  Future<Result<SessionSummary, AppError>> buildSummary(String sessionId);

  /// Returns every event in the telemetry file as a list of parsed maps.
  Future<Result<List<Map<String, dynamic>>, AppError>> exportAll();

  /// Deletes the entire telemetry file.  Irreversible.
  Future<Result<void, AppError>> clearAll();
}

/// Local-filesystem implementation backed by a JSONL file in the app
/// documents directory (`telemetry.jsonl`).
class LocalTelemetryRepository implements TelemetryRepository {
  static const String _fileName = 'telemetry.jsonl';

  // --- public API -----------------------------------------------------------

  @override
  Future<void> log(Map<String, dynamic> event) async {
    try {
      const envelopeKeys = {
        'schemaVersion',
        'sessionId',
        'timestamp',
        'event',
        'state',
        'payload',
      };
      final payload = <String, dynamic>{
        ...?event['payload'] as Map<String, dynamic>?,
      };
      for (final entry in event.entries) {
        if (!envelopeKeys.contains(entry.key)) {
          payload[entry.key] = entry.value;
        }
      }
      final enriched = <String, dynamic>{
        'schemaVersion': event['schemaVersion'] ?? 1,
        'sessionId': event['sessionId'],
        'timestamp': event['timestamp'] ??
            DateTime.now().toUtc().toIso8601String(),
        'event': event['event'],
        'state': event['state'],
        'payload': payload,
      };

      final file = await _telemetryFile;
      await file.writeAsString(
        '${json.encode(enriched)}\n',
        mode: FileMode.append,
        flush: true,
      );
    } catch (_) {
      // Telemetry must never crash the caller.  Swallow write errors.
    }
  }

  @override
  Future<Result<SessionSummary, AppError>> buildSummary(
    String sessionId,
  ) async {
    try {
      final events = await _readEventsForSession(sessionId);
      if (events.isEmpty) {
        return Err(AppError.telemetryWriteFailed);
      }

      final startedAt =
          _parseDateTime(events.first['timestamp'] as String?);
      final endedAt =
          _parseDateTime(events.last['timestamp'] as String?);

      String route = 'normal';
      int helpCount = 0;
      String? questionChoice;
      bool interrupted = false;
      bool completed = false;
      SurveyAnswers? survey;

      for (final e in events) {
        final eventType = e['event'] as String?;
        if (eventType == null) continue;

        switch (eventType) {
          case 'fallback_route_used':
            route = 'fallback';
            break;
          case 'help_requested':
            helpCount++;
            break;
          case 'session_aborted':
            interrupted = true;
            break;
          case 'session_completed':
            completed = true;
            break;
          case 'question_choice':
            final payload = e['payload'] as Map<String, dynamic>?;
            questionChoice = payload?['choice'] as String?;
            break;
          case 'survey_submitted':
            survey = _parseSurvey(e['payload'] as Map<String, dynamic>?);
            break;
        }
      }

      final durationSeconds = (startedAt != null && endedAt != null)
          ? endedAt.difference(startedAt).inSeconds
          : 0;

      return Ok(SessionSummary(
        sessionId: sessionId,
        startedAt: startedAt ?? DateTime.now(),
        endedAt: endedAt,
        completed: completed,
        route: route,
        durationSeconds: durationSeconds,
        questionChoice: questionChoice,
        helpCount: helpCount,
        interrupted: interrupted,
        survey: survey,
      ));
    } catch (_) {
      return Err(AppError.telemetryWriteFailed);
    }
  }

  @override
  Future<Result<List<Map<String, dynamic>>, AppError>> exportAll() async {
    try {
      final file = await _telemetryFile;
      if (!await file.exists()) return Ok([]);

      final lines = await file.readAsLines();
      final events = lines
          .where((l) => l.trim().isNotEmpty)
          .map((l) => json.decode(l) as Map<String, dynamic>)
          .toList();
      return Ok(events);
    } catch (_) {
      return Err(AppError.exportFailed);
    }
  }

  @override
  Future<Result<void, AppError>> clearAll() async {
    try {
      final file = await _telemetryFile;
      if (await file.exists()) await file.delete();
      return Ok(null);
    } catch (_) {
      return Err(AppError.telemetryWriteFailed);
    }
  }

  // --- helpers --------------------------------------------------------------

  Future<File> get _telemetryFile async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$_fileName');
  }

  /// Reads every event line from the JSONL file, parsing each as JSON.
  Future<List<Map<String, dynamic>>> _readAllEvents() async {
    final file = await _telemetryFile;
    if (!await file.exists()) return [];

    final lines = await file.readAsLines();
    return lines
        .where((l) => l.trim().isNotEmpty)
        .map((l) => json.decode(l) as Map<String, dynamic>)
        .toList();
  }

  /// Filters [_readAllEvents] to a single session.
  Future<List<Map<String, dynamic>>> _readEventsForSession(
    String sessionId,
  ) async {
    final all = await _readAllEvents();
    return all.where((e) => e['sessionId'] == sessionId).toList();
  }

  DateTime? _parseDateTime(String? iso) =>
      (iso != null) ? DateTime.tryParse(iso) : null;

  SurveyAnswers? _parseSurvey(Map<String, dynamic>? payload) {
    if (payload == null) return null;
    return SurveyAnswers(
      experienceDescription:
          payload['experienceDescription'] as String? ?? '',
      mostEngagingMoment: payload['mostEngagingMoment'] as String? ?? '',
      confusingMoment: payload['confusingMoment'] as String? ?? '',
      wantsLongerExperience:
          payload['wantsLongerExperience'] as bool? ?? false,
      wantsNextTest: payload['wantsNextTest'] as bool? ?? false,
    );
  }
}
