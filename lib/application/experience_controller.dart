import 'dart:async';

import 'package:flutter/foundation.dart';

import '../domain/experience_event.dart';
import '../domain/experience_state.dart';
import '../domain/route_definition.dart';
import '../domain/scene_definition.dart';
import '../infrastructure/local_content_repository.dart';
import '../infrastructure/local_session_repository.dart';
import '../infrastructure/local_telemetry_repository.dart';
import '../shared/app_error.dart';
import '../shared/result.dart';

// ---------------------------------------------------------------------------
// SceneViewModel
// ---------------------------------------------------------------------------

/// Derived view model for the current scene, computed from the active
/// [ExperienceState] and its corresponding [SceneDefinition].
class SceneViewModel {

  const SceneViewModel({
    required this.state,
    required this.scene,
    required this.isWalking,
    required this.isSafetyMode,
    this.activeAudioAsset,
    required this.visualLayers,
  });
  final ExperienceState state;
  final SceneDefinition scene;
  final bool isWalking;
  final bool isSafetyMode;
  final String? activeAudioAsset;
  final List<VisualLayer> visualLayers;

  // -- computed delegates to SceneDefinition --------------------------------

  String get rendererType => scene.renderer;
  List<String> get allowedActions => scene.allowedActions;
  bool get autoAdvance => scene.autoAdvance;
  int get minimumDurationMs => scene.minimumDurationMs;

  // -- equality --------------------------------------------------------------

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SceneViewModel &&
          state == other.state &&
          scene.id == other.scene.id &&
          isWalking == other.isWalking &&
          isSafetyMode == other.isSafetyMode &&
          activeAudioAsset == other.activeAudioAsset;

  @override
  int get hashCode =>
      Object.hash(state, scene.id, isWalking, isSafetyMode, activeAudioAsset);
}

// ---------------------------------------------------------------------------
// ExperienceEngine — Central state machine (Project.md §5.1)
// ---------------------------------------------------------------------------

/// Drives the entire AR experience as a deterministic state machine.
///
/// Listens to [ExperienceEvent]s, validates them against the active route's
/// transition table, and exposes a reactive [SceneViewModel] for the UI layer.
///
/// All three repository dependencies are injected so the engine is fully
/// testable without I/O or platform code.
class ExperienceEngine extends ChangeNotifier {

  ExperienceEngine({
    required this.contentRepository,
    required this.telemetryRepository,
    required this.sessionRepository,
    this.enforceMinimumDuration = true,
  });
  final ContentRepository contentRepository;
  final TelemetryRepository telemetryRepository;
  final SessionRepository sessionRepository;
  final bool enforceMinimumDuration;

  // ---- internal state ------------------------------------------------------

  ExperienceState _currentState = ExperienceState.ready;
  ExperienceState _previousState = ExperienceState.ready;

  late RouteDefinition _normalRoute;
  late RouteDefinition _fallbackRoute;
  RouteDefinition _currentRoute = const RouteDefinition(
    id: 'normal',
    initialState: ExperienceState.ready,
    transitions: {},
  );

  Map<String, SceneDefinition> _scenes = {};
  String? _sessionId;
  String? _questionChoice;
  int _operatorTapCount = 0;
  bool _initialized = false;
  String? _lastError;
  int _restoredAudioPositionMs = 0;
  final Stopwatch _stateClock = Stopwatch()..start();

  // ---- public getters ------------------------------------------------------

  ExperienceState get currentState => _currentState;
  ExperienceState get previousState => _previousState;
  RouteDefinition get currentRoute => _currentRoute;
  Map<String, SceneDefinition> get allScenes => _scenes;
  String? get sessionId => _sessionId;
  String? get questionChoice => _questionChoice;
  String? get lastError => _lastError;
  bool get isInitialized => _initialized;
  int get restoredAudioPositionMs => _restoredAudioPositionMs;

  /// Whether the operator panel has been unlocked via 7 taps on the title.
  bool get isOperatorUnlocked => _operatorTapCount >= 7;

  // ---- lifecycle -----------------------------------------------------------

  /// Loads scene content and builds both route tables.
  ///
  /// Must be called once before any event processing.  Returns [AppError]
  /// when the content asset cannot be loaded or parsed.
  Future<Result<void, AppError>> initialize() async {
    final scenesResult = await contentRepository.loadScenes();
    if (scenesResult.isErr) {
      _lastError = scenesResult.errValue!.message;
      notifyListeners();
      return Err(scenesResult.errValue!);
    }

    _scenes = scenesResult.okValue!;
    _normalRoute = RouteDefinition(
      id: 'normal',
      initialState: ExperienceState.ready,
      transitions: buildNormalTransitions(),
    );
    _fallbackRoute = RouteDefinition(
      id: 'fallback',
      initialState: ExperienceState.ready,
      transitions: buildFallbackTransitions(),
    );
    _currentRoute = _normalRoute;
    _currentState = ExperienceState.ready;
    _initialized = true;
    notifyListeners();
    return const Ok(null);
  }

  /// Creates a new session via [SessionRepository] and resets to [ready].
  Future<Result<String, AppError>> startSession() async {
    final result = await sessionRepository.createSession();
    if (result.isOk) {
      _sessionId = result.okValue;
      _currentState = ExperienceState.ready;
      _previousState = ExperienceState.ready;
      _currentRoute = _normalRoute;
      _questionChoice = null;
      _operatorTapCount = 0;
      _lastError = null;
      _restoredAudioPositionMs = 0;
      _stateClock.reset();
      await _persistState(0);
      _logTelemetry({
        'event': 'session_created',
        'sessionId': _sessionId,
      });
      notifyListeners();
    }
    return result;
  }

  /// Returns the unfinished local snapshot, if one exists.
  Future<Result<Map<String, dynamic>?, AppError>> loadSavedState() =>
      sessionRepository.loadSavedState();

  /// Restores an unfinished session after explicit user confirmation.
  Future<void> resumeSavedState(Map<String, dynamic> snapshot) async {
    final sessionId = snapshot['sessionId'] as String?;
    final stateId = snapshot['state'] as String?;
    if (sessionId == null || sessionId.isEmpty || stateId == null) {
      reportError('上次会话数据不完整，无法恢复');
      return;
    }
    try {
      _sessionId = sessionId;
      _currentState = ExperienceState.fromId(stateId);
      _previousState = _currentState;
      _currentRoute =
          snapshot['route'] == 'fallback' ? _fallbackRoute : _normalRoute;
      _restoredAudioPositionMs = snapshot['audioPositionMs'] as int? ?? 0;
      _lastError = null;
      _stateClock.reset();
      _logTelemetry({
        'event': 'session_resumed',
        'sessionId': _sessionId,
        'payload': {
          'route': _currentRoute.id,
          'audioPositionMs': _restoredAudioPositionMs,
        },
      });
      notifyListeners();
    } on FormatException {
      reportError('上次会话状态无效，无法恢复');
    }
  }

  /// Aborts an unfinished session and creates a clean replacement.
  Future<Result<String, AppError>> abandonSavedState() async {
    final saved = await sessionRepository.loadSavedState();
    final oldSessionId = saved.okValue?['sessionId'] as String?;
    if (oldSessionId != null && oldSessionId.isNotEmpty) {
      _logTelemetry({
        'event': 'session_aborted',
        'sessionId': oldSessionId,
        'payload': {'reason': 'user_discarded_saved_session'},
      });
    }
    await sessionRepository.clearSavedState();
    return startSession();
  }

  // ---- event dispatch ------------------------------------------------------

  /// Processes an incoming [ExperienceEvent] through the state machine.
  ///
  /// Illegal transitions are logged as telemetry events and silently ignored
  /// — the engine never crashes on an unexpected input.
  void handleEvent(ExperienceEvent event) {
    if (!_initialized) return;

    // Special handling for app resume — it carries saved state rather than
    // consulting the transition table.
    if (event is AppResumed) {
      _handleAppResumed(event);
      return;
    }

    final eventType = _mapEventToType(event);
    if (eventType == null) {
      _logTelemetry({
        'event': 'unhandled_event_type',
        'sessionId': _sessionId,
        'state': _currentState.id,
        'eventRuntimeType': event.runtimeType.toString(),
        'detail': event.toString(),
      });
      return;
    }

    if (event is UserAction) {
      _logTelemetry({
        'event': 'user_action',
        'sessionId': _sessionId,
        'payload': {'action': event.action.apiName},
      });
    }

    final scene = sceneViewModel?.scene;
    final isObservationAdvance = event is UserAction &&
        event.action == UserActionType.continue_ &&
        scene?.renderer == 'layered_reconstruction' &&
        scene?.audio == null;
    if (enforceMinimumDuration &&
        isObservationAdvance &&
        _stateClock.elapsedMilliseconds < (scene?.minimumDurationMs ?? 0)) {
      _logTelemetry({
        'event': 'user_action_rejected',
        'sessionId': _sessionId,
        'payload': {
          'action': event.action.apiName,
          'reason': 'minimum_duration',
          'remainingMs':
              scene!.minimumDurationMs - _stateClock.elapsedMilliseconds,
        },
      });
      return;
    }

    final next = _currentRoute.nextState(_currentState, eventType);
    if (next == null) {
      _lastError = '无有效转换: ${_currentState.id} -> ${eventType.name}';
      _logTelemetry({
        'event': 'invalid_transition',
        'sessionId': _sessionId,
        'fromState': _currentState.id,
        'eventType': eventType.name,
        'error': _lastError,
      });
      notifyListeners();
      return;
    }

    if (event is SubmitSurvey) {
      _logTelemetry({
        'event': 'survey_submitted',
        'sessionId': _sessionId,
        'payload': event.answers.toJson(),
      });
    }

    // Track the user's branching choice for the final summary.
    if (event is UserAction) {
      if (event.action == UserActionType.chooseFeudal) {
        _questionChoice = 'feudal';
        _logTelemetry({
          'event': 'question_choice',
          'sessionId': _sessionId,
          'choice': 'feudal',
        });
      } else if (event.action == UserActionType.chooseClassics) {
        _questionChoice = 'classics';
        _logTelemetry({
          'event': 'question_choice',
          'sessionId': _sessionId,
          'choice': 'classics',
        });
      }
    }

    _transitionTo(next, eventType);
  }

  /// Internal state transition with logging and persistence.
  void _transitionTo(ExperienceState next, ExperienceEventType eventType) {
    final elapsedMs = _stateClock.elapsedMilliseconds;
    _previousState = _currentState;
    _currentState = next;
    _stateClock.reset();

    // Auto-switch route at the decision point.
    if (_previousState == ExperienceState.waitForRouteDecision) {
      if (eventType == ExperienceEventType.operatorSelectNormal) {
        _currentRoute = _normalRoute;
      } else if (eventType == ExperienceEventType.operatorSelectFallback) {
        _currentRoute = _fallbackRoute;
        _logTelemetry({
          'event': 'fallback_route_used',
          'sessionId': _sessionId,
        });
      }
    }

    _logTelemetry({
      'event': 'state_exited',
      'sessionId': _sessionId,
      'payload': {
        'state': _previousState.id,
        'durationMs': elapsedMs,
        'route': _currentRoute.id,
      },
    });
    _logTelemetry({
      'event': 'state_transition',
      'sessionId': _sessionId,
      'fromState': _previousState.id,
      'toState': _currentState.id,
      'eventType': eventType.name,
      'route': _currentRoute.id,
    });
    _logTelemetry({
      'event': 'state_entered',
      'sessionId': _sessionId,
      'payload': {'state': _currentState.id, 'route': _currentRoute.id},
    });

    if (_currentState == ExperienceState.completed) {
      _logTelemetry({
        'event': 'session_completed',
        'sessionId': _sessionId,
      });
      unawaited(sessionRepository.clearSavedState());
    }

    notifyListeners();

    // Async fire-and-forget — persistence must never block the event loop.
    // State transitions persist immediately; lifecycle/audio callbacks replace
    // this zero with the exact playback position when it becomes available.
    unawaited(_persistState(0));
  }

  /// Sets a user-visible error message and notifies listeners.
  ///
  /// Used by the UI layer to propagate errors that occur outside the
  /// engine's own initialization flow (e.g. session creation failure).
  void reportError(String message) {
    _lastError = message;
    notifyListeners();
  }

  // ---- operator panel unlock (7-tap) ---------------------------------------

  void incrementOperatorTap() {
    if (!_initialized) return;
    _operatorTapCount++;
    notifyListeners();
  }

  void resetOperatorTap() {
    if (!_initialized) return;
    _operatorTapCount = 0;
    notifyListeners();
  }

  // ---- route switching -----------------------------------------------------

  /// Switches the active route definition (normal ↔ fallback).
  ///
  /// This does NOT change the current state — it only affects future
  /// transition lookups.  Typically called by the operator panel before
  /// the route-decision event is dispatched.
  bool setRoute(String routeId) {
    if (!_initialized ||
        _currentState != ExperienceState.waitForRouteDecision) {
      _logTelemetry({
        'event': 'operator_action_rejected',
        'sessionId': _sessionId,
        'payload': {
          'action': 'switch_route',
          'requestedRoute': routeId,
          'reason': 'not_at_route_decision',
        },
      });
      return false;
    }
    _currentRoute = (routeId == 'fallback') ? _fallbackRoute : _normalRoute;
    _logTelemetry({
      'event': 'route_switched',
      'sessionId': _sessionId,
      'route': routeId,
      'state': _currentState.id,
    });
    notifyListeners();
    return true;
  }

  // ---- operator use cases -------------------------------------------------

  void operatorNext() {
    final candidates = sceneViewModel?.scene.next ?? const <String>[];
    if (candidates.isEmpty) return;
    String target = candidates.first;
    if (_currentState == ExperienceState.waitForRouteDecision) {
      target = _currentRoute.isFallback
          ? ExperienceState.fallbackGroundObserve.id
          : ExperienceState.normalAscend.id;
    } else if (_currentState == ExperienceState.questionMerge &&
        _currentRoute.isFallback) {
      target = ExperienceState.wumenSouthEnding.id;
    }
    operatorJump(ExperienceState.fromId(target), action: 'next_step');
  }

  void operatorPrevious() {
    if (_previousState == _currentState) return;
    operatorJump(_previousState, action: 'previous_step');
  }

  void operatorJump(
    ExperienceState target, {
    String action = 'jump_to_state',
  }) {
    _logTelemetry({
      'event': 'operator_action',
      'sessionId': _sessionId,
      'payload': {'action': action, 'targetState': target.id},
    });
    _transitionTo(target, ExperienceEventType.operatorNextStep);
  }

  void markNeedsHelp() {
    _logTelemetry({
      'event': 'operator_action',
      'sessionId': _sessionId,
      'payload': {'action': 'mark_help'},
    });
    _logTelemetry({
      'event': 'help_requested',
      'sessionId': _sessionId,
    });
  }

  void recordOperatorAction(String action) {
    _logTelemetry({
      'event': 'operator_action',
      'sessionId': _sessionId,
      'payload': {'action': action},
    });
  }

  void recordAudioEvent(String event, {Map<String, dynamic>? payload}) {
    _logTelemetry({
      'event': event,
      'sessionId': _sessionId,
      'payload': payload ?? const <String, dynamic>{},
    });
  }

  void recordAppError(String code, {String? detail}) {
    _logTelemetry({
      'event': 'app_error',
      'sessionId': _sessionId,
      'payload': {
        'code': code,
        if (detail != null) 'detail': detail,
      },
    });
  }

  Future<Result<List<Map<String, dynamic>>, AppError>> loadTelemetry() =>
      telemetryRepository.exportAll();

  Future<void> clearAllData() async {
    recordOperatorAction('clear_data');
    await telemetryRepository.clearAll();
    await sessionRepository.clearSavedState();
  }

  Future<void> endSession() async {
    _logTelemetry({
      'event': 'operator_action',
      'sessionId': _sessionId,
      'payload': {'action': 'end_session'},
    });
    _logTelemetry({
      'event': 'session_aborted',
      'sessionId': _sessionId,
      'payload': {'reason': 'operator_ended_session'},
    });
    _previousState = _currentState;
    _currentState = ExperienceState.completed;
    await sessionRepository.clearSavedState();
    notifyListeners();
  }

  // ---- reset ---------------------------------------------------------------

  /// Resets the engine to its uninitialised state (for testing or restart).
  void reset() {
    _currentState = ExperienceState.ready;
    _previousState = ExperienceState.ready;
    _currentRoute = _normalRoute;
    _questionChoice = null;
    _operatorTapCount = 0;
    _sessionId = null;
    _lastError = null;
    notifyListeners();
  }

  // ---- SceneViewModel ------------------------------------------------------

  /// Computes a [SceneViewModel] for the current state, or `null` when the
  /// scene definition is missing from the loaded content.
  SceneViewModel? get sceneViewModel {
    final scene = _scenes[_currentState.id];
    if (scene == null) return null;
    return SceneViewModel(
      state: _currentState,
      scene: scene,
      isWalking: _currentState.isWalkingState,
      isSafetyMode: _currentState.isSafetyState,
      activeAudioAsset: scene.audio,
      visualLayers: scene.visualSequence,
    );
  }

  // ---- app resume support --------------------------------------------------

  /// Restores state from an [AppResumed] event without consulting the
  /// transition table.
  void _handleAppResumed(AppResumed event) {
    final previous = _currentState;
    _currentState = event.savedState;
    _previousState = previous;
    _logTelemetry({
      'event': 'app_resumed',
      'sessionId': _sessionId,
      'state': _currentState.id,
      'savedAudioPositionMs': event.savedAudioPositionMs,
    });
    notifyListeners();
  }

  /// Persists the current state + audio position to [SessionRepository].
  Future<void> saveCurrentState(int audioPositionMs) async {
    if (_sessionId == null) return;
    await _persistState(audioPositionMs);
  }

  Future<void> _persistState(int audioPositionMs) async {
    await sessionRepository.saveState(
      _currentState,
      audioPositionMs,
      routeId: _currentRoute.id,
      audioAsset: sceneViewModel?.activeAudioAsset,
    );
  }

  // ---- telemetry -----------------------------------------------------------

  void _logTelemetry(Map<String, dynamic> event) {
    telemetryRepository.log({...event, 'state': _currentState.id});
  }

  // ---- event-type mapping --------------------------------------------------

  /// Maps a concrete [ExperienceEvent] to its [ExperienceEventType] key for
  /// transition-table lookups.  Returns `null` for events that carry no
  /// transition semantics (e.g. utility operator actions).
  ExperienceEventType? _mapEventToType(ExperienceEvent event) {
    if (event is SubmitSurvey) {
      return ExperienceEventType.userSubmitSurvey;
    }

    if (event is UserAction) {
      switch (event.action) {
        case UserActionType.startTest:
          return ExperienceEventType.userStartTest;
        case UserActionType.continue_:
          return ExperienceEventType.userContinue;
        case UserActionType.pause:
          return ExperienceEventType.userPause;
        case UserActionType.resume:
          return ExperienceEventType.userResume;
        case UserActionType.replay:
          return ExperienceEventType.userReplay;
        case UserActionType.arrived:
          return ExperienceEventType.userArrived;
        case UserActionType.chooseFeudal:
          return ExperienceEventType.userChooseFeudal;
        case UserActionType.chooseClassics:
          return ExperienceEventType.userChooseClassics;
        case UserActionType.submitSurvey:
          return ExperienceEventType.userSubmitSurvey;
        case UserActionType.export_:
          return ExperienceEventType.userExport;
        case UserActionType.restart:
          return ExperienceEventType.userRestart;
      }
    }

    if (event is OperatorAction) {
      switch (event.action) {
        case OperatorActionType.nextStep:
          return ExperienceEventType.operatorNextStep;
        case OperatorActionType.previousStep:
          return ExperienceEventType.operatorPreviousStep;
        case OperatorActionType.switchToNormal:
          return ExperienceEventType.operatorSelectNormal;
        case OperatorActionType.switchToFallback:
          return ExperienceEventType.operatorSelectFallback;
        case OperatorActionType.endSession:
          return ExperienceEventType.operatorEndSession;
        default:
          return null; // createSession, replayAudio,
        // markNeedsHelp, viewLog, exportLog, clearData
      }
    }

    if (event is AudioCompleted) {
      return ExperienceEventType.audioCompleted;
    }

    if (event is TimerElapsed) {
      return ExperienceEventType.timerElapsed;
    }

    if (event is AppResumed) {
      return ExperienceEventType.appResumed;
    }

    return null;
  }
}
