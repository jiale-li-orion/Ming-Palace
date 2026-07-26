import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../domain/experience_state.dart';
import '../shared/app_error.dart';
import '../shared/result.dart';

/// Repository contract for session lifecycle management.
///
/// Each session gets a UUID; state is persisted to a local JSON file so the
/// experience can be resumed after the app is backgrounded or restarted.
abstract interface class SessionRepository {
  /// Creates a new session, writes a `session_created` telemetry event, and
  /// returns the session ID.
  Future<Result<String, AppError>> createSession();

  /// Reads the saved session state, or returns `null` if none exists.
  Future<Result<Map<String, dynamic>?, AppError>> loadSavedState();

  /// Persists the current experience state + audio position.
  Future<Result<void, AppError>> saveState(
    ExperienceState state,
    int audioPositionMs,
  );

  /// Deletes the saved state file (e.g. after a clean session end).
  Future<Result<void, AppError>> clearSavedState();
}

/// Local-filesystem implementation backed by two files in the app documents
/// directory:
///   - `telemetry.jsonl` — shared with [LocalTelemetryRepository]
///   - `saved_state.json` — session resume data
class LocalSessionRepository implements SessionRepository {
  static const String _stateFileName = 'saved_state.json';
  static const String _telemetryFileName = 'telemetry.jsonl';

  final Uuid _uuid = const Uuid();

  // --- public API -----------------------------------------------------------

  @override
  Future<Result<String, AppError>> createSession() async {
    try {
      final sessionId = _uuid.v4();
      final now = DateTime.now().toUtc().toIso8601String();

      final event = <String, dynamic>{
        'schemaVersion': 1,
        'sessionId': sessionId,
        'timestamp': now,
        'event': 'session_created',
        'state': null,
        'payload': <String, dynamic>{},
      };

      final file = await _telemetryFile;
      await file.writeAsString(
        '${json.encode(event)}\n',
        mode: FileMode.append,
        flush: true,
      );

      return Ok(sessionId);
    } catch (_) {
      return Err(AppError.sessionCreationFailed);
    }
  }

  @override
  Future<Result<Map<String, dynamic>?, AppError>> loadSavedState() async {
    try {
      final file = await _stateFile;
      if (!await file.exists()) return Ok(null);

      final content = await file.readAsString();
      final decoded = json.decode(content) as Map<String, dynamic>;
      return Ok(decoded);
    } catch (_) {
      // Corrupted or unreadable state → treat as no saved state.
      return Ok(null);
    }
  }

  @override
  Future<Result<void, AppError>> saveState(
    ExperienceState state,
    int audioPositionMs,
  ) async {
    try {
      // Preserve the sessionId from any previously saved state.
      final existing = await loadSavedState();
      final sessionId = existing.okValue?['sessionId'] as String? ?? '';

      final stateData = <String, dynamic>{
        'state': state.id,
        'audioPositionMs': audioPositionMs,
        'sessionId': sessionId,
        'timestamp': DateTime.now().toUtc().toIso8601String(),
      };

      final file = await _stateFile;
      await file.writeAsString(json.encode(stateData));
      return Ok(null);
    } catch (_) {
      return Err(AppError.unknown);
    }
  }

  @override
  Future<Result<void, AppError>> clearSavedState() async {
    try {
      final file = await _stateFile;
      if (await file.exists()) await file.delete();
      return Ok(null);
    } catch (_) {
      return Err(AppError.unknown);
    }
  }

  // --- helpers --------------------------------------------------------------

  Future<File> get _stateFile async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$_stateFileName');
  }

  Future<File> get _telemetryFile async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$_telemetryFileName');
  }
}
