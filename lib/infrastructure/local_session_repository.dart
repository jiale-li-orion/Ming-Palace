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

  final Uuid _uuid = const Uuid();
  String? _currentSessionId;

  // --- public API -----------------------------------------------------------

  @override
  Future<Result<String, AppError>> createSession() async {
    try {
      final sessionId = _uuid.v4();
      _currentSessionId = sessionId;
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
      _currentSessionId = decoded['sessionId'] as String?;
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
      if (_currentSessionId == null) {
        final existing = await loadSavedState();
        _currentSessionId = existing.okValue?['sessionId'] as String?;
      }
      if (_currentSessionId == null || _currentSessionId!.isEmpty) {
        return Err(AppError.sessionCreationFailed);
      }

      final stateData = <String, dynamic>{
        'state': state.id,
        'audioPositionMs': audioPositionMs,
        'sessionId': _currentSessionId,
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

}
