import 'dart:async';

import 'package:flutter/material.dart' hide NavigationMode;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../application/project_experience_engine.dart';
import '../application/audio_controller.dart';
import '../application/project_audio_coordinator.dart';
import '../application/experience_runtime_controller.dart';
import '../application/orientation_controller.dart';
import '../infrastructure/device_location_service.dart';
import '../infrastructure/project_session_repository.dart';
import '../infrastructure/local_telemetry_repository.dart';
import '../infrastructure/export_service.dart';
import '../domain/experience_session_state.dart';
import '../presentation/widgets/resume_prompt.dart';
import '../presentation/screens/project_experience_screen.dart';
import 'theme.dart';

/// The root widget of the Ming Palace AR experience.
///
/// Wires up the Material [ThemeData] and sets the home screen.
/// Routing is entirely state-driven (see [router.dart]), so no route table
/// is configured here.
class MingPalaceApp extends StatefulWidget {
  const MingPalaceApp({super.key});

  @override
  State<MingPalaceApp> createState() => _MingPalaceAppState();
}

class _MingPalaceAppState extends State<MingPalaceApp> {
  final ProjectExperienceEngine _engine = ProjectExperienceEngine();
  final ProjectSessionRepository _sessions = LocalProjectSessionRepository();
  final TelemetryRepository _telemetry = LocalTelemetryRepository();
  late final ExperienceRuntimeController _runtime;
  late final ProjectAudioCoordinator _audio;
  ProjectSessionSnapshot? _pendingSnapshot;
  String _sessionId = const Uuid().v4();
  bool _loading = true;
  ExperiencePhase? _loggedPhase;
  NavigationMode? _loggedNavigation;
  OrientationMode? _loggedOrientation;
  bool _loggedSafety = false;

  @override
  void initState() {
    super.initState();
    _runtime = ExperienceRuntimeController(
      engine: _engine,
      locationService: DeviceLocationService(),
      orientationService: OrientationController(),
    );
    _audio = ProjectAudioCoordinator(engine: _engine, audio: AudioController())
      ..start();
    _runtime.start();
    _engine.addListener(_persist);
    _loadSession();
  }

  Future<void> _loadSession() async {
    final snapshot = await _sessions.load();
    if (!mounted) return;
    setState(() {
      _pendingSnapshot = snapshot;
      _loading = false;
    });
    if (snapshot == null) _engine.start();
    unawaited(_telemetry.log({
      'event':
          snapshot == null ? 'session_created' : 'session_resume_available',
      'sessionId': snapshot?.sessionId ?? _sessionId,
    }));
  }

  void _persist() {
    final state = _engine.state;
    if (_loggedPhase != state.phase) {
      _loggedPhase = state.phase;
      unawaited(_telemetry.log({
        'event': 'phase_entered',
        'sessionId': _sessionId,
        'state': state.phase.id,
        'payload': {'route': state.routeMode.name},
      }));
    }
    if (_loggedNavigation != state.navigationMode) {
      _loggedNavigation = state.navigationMode;
      unawaited(_telemetry.log({
        'event': 'navigation_state_changed',
        'sessionId': _sessionId,
        'state': state.phase.id,
        'payload': {'mode': state.navigationMode.name},
      }));
    }
    if (_loggedOrientation != state.orientationMode) {
      _loggedOrientation = state.orientationMode;
      unawaited(_telemetry.log({
        'event': 'orientation_changed',
        'sessionId': _sessionId,
        'state': state.phase.id,
        'payload': {'mode': state.orientationMode.name},
      }));
    }
    final hasSafety = state.safetyInterruption != null;
    if (_loggedSafety != hasSafety) {
      _loggedSafety = hasSafety;
      unawaited(_telemetry.log({
        'event': hasSafety ? 'safety_interrupted' : 'safety_resumed',
        'sessionId': _sessionId,
        'state': state.phase.id,
      }));
    }
    if (_engine.state.phase == ExperiencePhase.completed) {
      unawaited(_telemetry.log({
        'event': 'session_completed',
        'sessionId': _sessionId,
        'state': state.phase.id,
      }));
      unawaited(_sessions.clear());
      return;
    }
    unawaited(_sessions.save(ProjectSessionSnapshot(
      sessionId: _sessionId,
      state: _engine.state,
    )));
  }

  Future<void> _resume() async {
    final snapshot = _pendingSnapshot;
    if (snapshot == null) return;
    _sessionId = snapshot.sessionId;
    _engine.restoreState(snapshot.state);
    setState(() => _pendingSnapshot = null);
  }

  Future<void> _discard() async {
    await _sessions.clear();
    _sessionId = const Uuid().v4();
    _engine.start();
    setState(() => _pendingSnapshot = null);
  }

  Future<bool> _exportLogs() async {
    final directory = await getApplicationDocumentsDirectory();
    final path = '${directory.path}/ming_palace_logs.json';
    final service = ExportService();
    final export = await service.exportAsJson(path);
    if (export.isErr) return false;
    final share = await service.shareExport(path);
    return share.isOk;
  }

  @override
  void dispose() {
    unawaited(_runtime.dispose());
    unawaited(_audio.dispose());
    _engine.removeListener(_persist);
    _engine.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ming Palace',
      theme: AppTheme.darkTheme,
      debugShowCheckedModeBanner: false,
      home: _loading
          ? const Scaffold(body: Center(child: CircularProgressIndicator()))
          : _pendingSnapshot != null
              ? ResumePrompt(onResume: _resume, onDiscard: _discard)
              : ProjectExperienceScreen(
                  engine: _engine,
                  onExportLogs: _exportLogs,
                ),
    );
  }
}
