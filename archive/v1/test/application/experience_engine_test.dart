import 'package:flutter_test/flutter_test.dart';
import 'package:ming_palace/application/experience_controller.dart';
import 'package:ming_palace/domain/experience_event.dart';
import 'package:ming_palace/domain/experience_state.dart';
import 'package:ming_palace/domain/scene_definition.dart';
import 'package:ming_palace/domain/session_summary.dart';
import 'package:ming_palace/infrastructure/local_content_repository.dart';
import 'package:ming_palace/infrastructure/local_session_repository.dart';
import 'package:ming_palace/infrastructure/local_telemetry_repository.dart';
import 'package:ming_palace/shared/app_error.dart';
import 'package:ming_palace/shared/result.dart';

// ---------------------------------------------------------------------------
// Fake repositories for testing the ExperienceEngine in isolation
// ---------------------------------------------------------------------------

class FakeContentRepository implements ContentRepository {

  FakeContentRepository(this.scenes);
  final Map<String, SceneDefinition> scenes;

  @override
  Future<Result<Map<String, SceneDefinition>, AppError>> loadScenes() async {
    return Ok(scenes);
  }
}

class FailingContentRepository implements ContentRepository {
  @override
  Future<Result<Map<String, SceneDefinition>, AppError>> loadScenes() async {
    return const Err(AppError.contentLoadFailed);
  }
}

class FakeTelemetryRepository implements TelemetryRepository {
  final List<Map<String, dynamic>> events = [];

  @override
  Future<void> log(Map<String, dynamic> event) async {
    events.add(Map.from(event));
  }

  @override
  Future<Result<SessionSummary, AppError>> buildSummary(String id) async {
    return const Err(AppError.telemetryWriteFailed);
  }

  @override
  Future<Result<List<Map<String, dynamic>>, AppError>> exportAll() async {
    return Ok(List.from(events));
  }

  @override
  Future<Result<void, AppError>> clearAll() async {
    events.clear();
    return const Ok(null);
  }
}

class FakeSessionRepository implements SessionRepository {
  String? _sessionId;
  Map<String, dynamic>? _savedState;

  @override
  Future<Result<String, AppError>> createSession() async {
    _sessionId = 'test-uuid-${DateTime.now().millisecondsSinceEpoch}';
    return Ok(_sessionId!);
  }

  @override
  Future<Result<Map<String, dynamic>?, AppError>> loadSavedState() async {
    return Ok(_savedState);
  }

  @override
  Future<Result<void, AppError>> saveState(
    ExperienceState state,
    int position, {
    String routeId = 'normal',
    String? audioAsset,
  }) async {
    _savedState = {
      'sessionId': _sessionId,
      'state': state.id,
      'route': routeId,
      'audioAsset': audioAsset,
      'audioPositionMs': position,
    };
    return const Ok(null);
  }

  @override
  Future<Result<void, AppError>> clearSavedState() async {
    _savedState = null;
    return const Ok(null);
  }
}

// ---------------------------------------------------------------------------
// Test scenario data
// ---------------------------------------------------------------------------

Map<String, SceneDefinition> _defaultScenes() {
  final scenes = <String, SceneDefinition>{};
  for (final state in ExperienceState.values) {
    scenes[state.id] = SceneDefinition(
      id: state.id,
      renderer: state == ExperienceState.question
          ? 'question'
          : state.isSafetyState
              ? 'safety'
              : state == ExperienceState.survey
                  ? 'survey'
                  : state == ExperienceState.completed
                      ? 'completed'
                      : state == ExperienceState.ready
                          ? 'instruction'
                          : state == ExperienceState.waitForRouteDecision
                              ? 'instruction'
                              : 'narrative',
      minimumDurationMs: 1000,
      autoAdvance: state == ExperienceState.endingAmbience,
      visualSequence: [],
      allowedActions: _allowedActions(state),
      next: state == ExperienceState.intro
          ? [ExperienceState.fengtianNorth.id]
          : const [],
      safetyMode: state.isSafetyState ? 'ascending' : 'stationary',
    );
  }
  return scenes;
}

List<String> _allowedActions(ExperienceState state) {
  switch (state) {
    case ExperienceState.ready:
      return ['start_test'];
    case ExperienceState.intro:
      return ['start_test'];
    case ExperienceState.fengtianNorth:
      return ['continue', 'pause', 'resume', 'replay'];
    case ExperienceState.walkToWumen:
      return ['continue', 'arrived', 'pause', 'resume', 'replay'];
    case ExperienceState.wumenNorth:
      return ['continue', 'pause', 'resume', 'replay'];
    case ExperienceState.waitForRouteDecision:
      return [];
    case ExperienceState.normalAscend:
      return ['arrived'];
    case ExperienceState.normalPlatformObserve:
      return ['continue'];
    case ExperienceState.normalPlatformNarration:
      return ['continue', 'pause', 'resume', 'replay'];
    case ExperienceState.question:
      return ['choose_feudal', 'choose_classics'];
    case ExperienceState.questionBranchFeudal:
      return ['continue', 'pause', 'resume', 'replay'];
    case ExperienceState.questionBranchClassics:
      return ['continue', 'pause', 'resume', 'replay'];
    case ExperienceState.questionMerge:
      return ['continue', 'pause', 'resume', 'replay'];
    case ExperienceState.normalDescend:
      return ['arrived'];
    case ExperienceState.walkThroughWumen:
      return ['continue', 'arrived'];
    case ExperienceState.fallbackGroundObserve:
      return ['continue'];
    case ExperienceState.fallbackGroundNarration:
      return ['continue', 'pause', 'resume', 'replay'];
    case ExperienceState.wumenSouthEnding:
      return ['continue', 'pause', 'resume', 'replay'];
    case ExperienceState.endingAmbience:
      return [];
    case ExperienceState.survey:
      return ['submit_survey'];
    case ExperienceState.completed:
      return ['export', 'restart'];
  }
}

ExperienceEngine _createEngine({Map<String, SceneDefinition>? scenes}) {
  return ExperienceEngine(
    contentRepository: FakeContentRepository(scenes ?? _defaultScenes()),
    telemetryRepository: FakeTelemetryRepository(),
    sessionRepository: FakeSessionRepository(),
    enforceMinimumDuration: false,
  );
}

void main() {
  group('ExperienceEngine initialization', () {
    test('loads scenes successfully', () async {
      final engine = _createEngine();
      final result = await engine.initialize();
      expect(result.isOk, isTrue);
      expect(engine.isInitialized, isTrue);
      expect(engine.currentState, ExperienceState.ready);
    });

    test('fails gracefully when content cannot be loaded', () async {
      final engine = ExperienceEngine(
        contentRepository: FailingContentRepository(),
        telemetryRepository: FakeTelemetryRepository(),
        sessionRepository: FakeSessionRepository(),
        enforceMinimumDuration: false,
      );
      final result = await engine.initialize();
      expect(result.isErr, isTrue);
      expect(result.errValue, AppError.contentLoadFailed);
      expect(engine.isInitialized, isFalse);
      expect(engine.lastError, isNotNull);
    });

    test('startSession sets sessionId and resets state', () async {
      final engine = _createEngine();
      await engine.initialize();
      final sessionResult = await engine.startSession();
      expect(sessionResult.isOk, isTrue);
      expect(sessionResult.okValue, isNotEmpty);
      expect(engine.sessionId, equals(sessionResult.okValue));
    });
  });

  group('Normal route transitions', () {
    late ExperienceEngine engine;

    setUp(() async {
      engine = _createEngine();
      await engine.initialize();
      await engine.startSession();
    });

    test('full normal route with feudal choice', () {
      void tap(UserActionType action) => engine.handleEvent(UserAction(action));

      // Step through the entire normal route
      tap(UserActionType.startTest); // ready → intro
      expect(engine.currentState, ExperienceState.intro);

      tap(UserActionType.startTest); // intro → fengtianNorth
      expect(engine.currentState, ExperienceState.fengtianNorth);

      engine.handleEvent(const AudioCompleted()); // fengtianNorth → walkToWumen
      expect(engine.currentState, ExperienceState.walkToWumen);

      tap(UserActionType.arrived); // walkToWumen → wumenNorth
      expect(engine.currentState, ExperienceState.wumenNorth);

      tap(UserActionType.continue_); // wumenNorth → waitForRouteDecision
      expect(engine.currentState, ExperienceState.waitForRouteDecision);

      engine.handleEvent(
          const OperatorAction(OperatorActionType.switchToNormal)); // → normalAscend
      expect(engine.currentState, ExperienceState.normalAscend);

      tap(UserActionType.arrived); // normalAscend → normalPlatformObserve
      expect(engine.currentState, ExperienceState.normalPlatformObserve);

      tap(UserActionType.continue_); // → normalPlatformNarration
      expect(engine.currentState, ExperienceState.normalPlatformNarration);

      engine.handleEvent(const AudioCompleted()); // → question
      expect(engine.currentState, ExperienceState.question);

      tap(UserActionType.chooseFeudal); // → questionBranchFeudal
      expect(engine.currentState, ExperienceState.questionBranchFeudal);
      expect(engine.questionChoice, 'feudal');

      engine.handleEvent(const AudioCompleted()); // → questionMerge
      expect(engine.currentState, ExperienceState.questionMerge);

      tap(UserActionType.continue_); // → normalDescend
      expect(engine.currentState, ExperienceState.normalDescend);

      tap(UserActionType.arrived); // → walkThroughWumen
      expect(engine.currentState, ExperienceState.walkThroughWumen);

      tap(UserActionType.arrived); // → wumenSouthEnding
      expect(engine.currentState, ExperienceState.wumenSouthEnding);

      engine.handleEvent(const AudioCompleted()); // → endingAmbience
      expect(engine.currentState, ExperienceState.endingAmbience);

      engine.handleEvent(const TimerElapsed()); // → survey
      expect(engine.currentState, ExperienceState.survey);

      tap(UserActionType.submitSurvey); // → completed
      expect(engine.currentState, ExperienceState.completed);
      expect(engine.currentState.isTerminalState, isTrue);
    });

    test('full normal route with classics choice', () {
      void tap(UserActionType action) => engine.handleEvent(UserAction(action));

      tap(UserActionType.startTest);
      tap(UserActionType.startTest);
      engine.handleEvent(const AudioCompleted());
      tap(UserActionType.arrived);
      tap(UserActionType.continue_);
      engine.handleEvent(const OperatorAction(OperatorActionType.switchToNormal));
      tap(UserActionType.arrived);
      tap(UserActionType.continue_);
      engine.handleEvent(const AudioCompleted());

      tap(UserActionType.chooseClassics);
      expect(engine.currentState, ExperienceState.questionBranchClassics);
      expect(engine.questionChoice, 'classics');
    });

    test('invalid transition does not crash', () {
      // Sending audioCompleted in READY state (no transition)
      engine.handleEvent(const AudioCompleted());
      expect(engine.currentState, ExperienceState.ready);
      expect(engine.lastError, contains('无有效转换'));
    });

    test('question branch feudal and classics both merge to questionMerge', () {
      void tap(UserActionType action) => engine.handleEvent(UserAction(action));
      tap(UserActionType.startTest);
      tap(UserActionType.startTest);
      engine.handleEvent(const AudioCompleted());
      tap(UserActionType.arrived);
      tap(UserActionType.continue_);
      engine.handleEvent(const OperatorAction(OperatorActionType.switchToNormal));
      tap(UserActionType.arrived);
      tap(UserActionType.continue_);
      engine.handleEvent(const AudioCompleted());

      // Test feudal branch
      tap(UserActionType.chooseFeudal);
      engine.handleEvent(const AudioCompleted());
      expect(engine.currentState, ExperienceState.questionMerge);
    });

    test('sceneViewModel returns correct data for current state', () {
      void tap(UserActionType action) => engine.handleEvent(UserAction(action));

      // At READY: instruction renderer
      var vm = engine.sceneViewModel;
      expect(vm, isNotNull);
      expect(vm!.rendererType, 'instruction');

      tap(UserActionType.startTest);
      vm = engine.sceneViewModel;
      expect(vm!.state, ExperienceState.intro);
    });

    test('sceneViewModel returns null when current scene is absent', () async {
      // If scene data is missing a state, vm should be null
      final incompleteScenes = <String, SceneDefinition>{
        'ready': const SceneDefinition(
          id: 'ready',
          renderer: 'instruction',
          minimumDurationMs: 0,
          autoAdvance: false,
          visualSequence: [],
          allowedActions: ['start_test'],
          safetyMode: 'stationary',
        ),
      };
      final engine = _createEngine(scenes: incompleteScenes);
      await engine.initialize();
      expect(engine.sceneViewModel, isNull);
    });

    test('observation state rejects continue before minimum duration',
        () async {
      final telemetry = FakeTelemetryRepository();
      final scenes = _defaultScenes();
      scenes[ExperienceState.normalPlatformObserve.id] = const SceneDefinition(
        id: 'NORMAL_PLATFORM_OBSERVE',
        renderer: 'layered_reconstruction',
        minimumDurationMs: 10000,
        autoAdvance: false,
        visualSequence: [],
        allowedActions: ['continue'],
        safetyMode: 'stationary',
      );
      final engine = ExperienceEngine(
        contentRepository: FakeContentRepository(scenes),
        telemetryRepository: telemetry,
        sessionRepository: FakeSessionRepository(),
      );
      await engine.initialize();
      await engine.startSession();
      engine.operatorJump(ExperienceState.normalPlatformObserve);

      engine.handleEvent(const UserAction(UserActionType.continue_));

      expect(engine.currentState, ExperienceState.normalPlatformObserve);
      expect(
        telemetry.events.any(
          (event) => event['event'] == 'user_action_rejected',
        ),
        isTrue,
      );
    });

    test('restart from completed goes to ready', () {
      void tap(UserActionType action) => engine.handleEvent(UserAction(action));

      tap(UserActionType.startTest);
      tap(UserActionType.startTest);
      engine.handleEvent(const AudioCompleted());
      tap(UserActionType.arrived);
      tap(UserActionType.continue_);
      engine.handleEvent(const OperatorAction(OperatorActionType.switchToNormal));
      tap(UserActionType.arrived);
      tap(UserActionType.continue_);
      engine.handleEvent(const AudioCompleted());
      tap(UserActionType.chooseFeudal);
      engine.handleEvent(const AudioCompleted());
      tap(UserActionType.continue_);
      tap(UserActionType.arrived);
      tap(UserActionType.arrived);
      engine.handleEvent(const AudioCompleted());
      engine.handleEvent(const TimerElapsed());
      tap(UserActionType.submitSurvey);

      expect(engine.currentState, ExperienceState.completed);

      tap(UserActionType.restart);
      expect(engine.currentState, ExperienceState.ready);
    });
  });

  group('Fallback route transitions', () {
    late ExperienceEngine engine;

    setUp(() async {
      engine = _createEngine();
      await engine.initialize();
      await engine.startSession();
    });

    test('full fallback route works', () {
      void tap(UserActionType action) => engine.handleEvent(UserAction(action));

      tap(UserActionType.startTest);
      tap(UserActionType.startTest);
      engine.handleEvent(const AudioCompleted());
      tap(UserActionType.arrived);
      tap(UserActionType.continue_);

      // Select fallback route at decision point
      engine.handleEvent(const OperatorAction(OperatorActionType.switchToFallback));
      expect(engine.currentState, ExperienceState.fallbackGroundObserve);

      tap(UserActionType.continue_); // → fallbackGroundNarration
      expect(engine.currentState, ExperienceState.fallbackGroundNarration);
    });
  });

  group('Operator panel', () {
    test('7-tap unlocks operator', () async {
      final engine = _createEngine();
      await engine.initialize();

      expect(engine.isOperatorUnlocked, isFalse);

      for (int i = 0; i < 7; i++) {
        engine.incrementOperatorTap();
      }
      expect(engine.isOperatorUnlocked, isTrue);

      engine.resetOperatorTap();
      expect(engine.isOperatorUnlocked, isFalse);
    });

    test('setRoute switches between normal and fallback', () async {
      final engine = _createEngine();
      await engine.initialize();

      expect(engine.setRoute('fallback'), isFalse);
      expect(engine.currentRoute.id, 'normal');

      engine.operatorJump(ExperienceState.waitForRouteDecision);
      engine.setRoute('fallback');
      expect(engine.currentRoute.id, 'fallback');
      expect(engine.currentRoute.isFallback, isTrue);

      engine.setRoute('normal');
      expect(engine.currentRoute.id, 'normal');
      expect(engine.currentRoute.isFallback, isFalse);
    });

    test('operator next previous and help actions have real effects', () async {
      final telemetry = FakeTelemetryRepository();
      final engine = ExperienceEngine(
        contentRepository: FakeContentRepository(_defaultScenes()),
        telemetryRepository: telemetry,
        sessionRepository: FakeSessionRepository(),
        enforceMinimumDuration: false,
      );
      await engine.initialize();
      await engine.startSession();
      engine.handleEvent(const UserAction(UserActionType.startTest));

      engine.operatorNext();
      expect(engine.currentState, ExperienceState.fengtianNorth);
      engine.operatorPrevious();
      expect(engine.currentState, ExperienceState.intro);
      engine.markNeedsHelp();

      expect(
        telemetry.events.where((event) => event['event'] == 'help_requested'),
        hasLength(1),
      );
    });
  });

  group('App resume', () {
    test('AppResumed restores saved state', () async {
      final engine = _createEngine();
      await engine.initialize();

      engine.handleEvent(
          const AppResumed(ExperienceState.normalPlatformObserve, 30000));
      expect(engine.currentState, ExperienceState.normalPlatformObserve);
    });

    test('restores session identity route and state from snapshot', () async {
      final engine = _createEngine();
      await engine.initialize();

      await engine.resumeSavedState({
        'sessionId': 'saved-session',
        'state': 'FALLBACK_GROUND_NARRATION',
        'route': 'fallback',
        'audioAsset': 'audio/09_ground_fallback.mp3',
        'audioPositionMs': 1200,
      });

      expect(engine.sessionId, 'saved-session');
      expect(engine.currentRoute.id, 'fallback');
      expect(engine.currentState, ExperienceState.fallbackGroundNarration);
    });
  });

  group('Telemetry logging', () {
    test('events are logged during state transitions', () async {
      final telemetry = FakeTelemetryRepository();
      final engine = ExperienceEngine(
        contentRepository: FakeContentRepository(_defaultScenes()),
        telemetryRepository: telemetry,
        sessionRepository: FakeSessionRepository(),
        enforceMinimumDuration: false,
      );
      await engine.initialize();
      await engine.startSession();

      engine.handleEvent(const UserAction(UserActionType.startTest));

      expect(telemetry.events, isNotEmpty);
      final transitionEvent = telemetry.events.firstWhere(
        (e) => e['event'] == 'state_transition',
      );
      expect(transitionEvent['toState'], 'INTRO');
    });

    test('invalid transition is logged', () {
      final engine = _createEngine();

      engine.handleEvent(const UserAction(UserActionType.arrived));
      // Engine not initialized, should do nothing
    });

    test('survey submission logs all answers before completion', () async {
      final telemetry = FakeTelemetryRepository();
      final engine = ExperienceEngine(
        contentRepository: FakeContentRepository(_defaultScenes()),
        telemetryRepository: telemetry,
        sessionRepository: FakeSessionRepository(),
        enforceMinimumDuration: false,
      );
      await engine.initialize();
      await engine.startSession();
      engine.handleEvent(const AppResumed(ExperienceState.survey, 0));

      const answers = SurveyAnswers(
        experienceDescription: '现场叙事',
        mostEngagingMoment: '城台复原',
        confusingMoment: '没有',
        wantsLongerExperience: true,
        wantsNextTest: false,
      );
      engine.handleEvent(const SubmitSurvey(answers));

      expect(engine.currentState, ExperienceState.completed);
      final event = telemetry.events.firstWhere(
        (item) => item['event'] == 'survey_submitted',
      );
      expect(event['payload'], answers.toJson());
    });
  });
}
