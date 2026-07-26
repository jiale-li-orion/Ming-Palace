import 'package:flutter_test/flutter_test.dart';
import 'package:ming_palace/domain/experience_state.dart';
import 'package:ming_palace/domain/experience_event.dart';
import 'package:ming_palace/domain/route_definition.dart';
import 'package:ming_palace/domain/scene_definition.dart';
import 'package:ming_palace/domain/session_summary.dart';
import 'package:ming_palace/shared/result.dart';
import 'package:ming_palace/shared/app_error.dart';

void main() {
  group('ExperienceState', () {
    test('has correct state count', () {
      expect(ExperienceState.values.length, 21);
    });

    test('all states have id', () {
      for (final state in ExperienceState.values) {
        expect(state.id, isNotEmpty);
      }
    });

    test('classifies walking states correctly', () {
      expect(ExperienceState.walkToWumen.isWalkingState, isTrue);
      expect(ExperienceState.normalAscend.isWalkingState, isTrue);
      expect(ExperienceState.normalDescend.isWalkingState, isTrue);
      expect(ExperienceState.walkThroughWumen.isWalkingState, isTrue);
      expect(ExperienceState.ready.isWalkingState, isFalse);
      expect(ExperienceState.completed.isWalkingState, isFalse);
    });

    test('classifies safety states correctly', () {
      expect(ExperienceState.normalAscend.isSafetyState, isTrue);
      expect(ExperienceState.normalDescend.isSafetyState, isTrue);
      expect(ExperienceState.ready.isSafetyState, isFalse);
    });

    test('classifies platform states correctly', () {
      expect(ExperienceState.normalPlatformObserve.isPlatformState, isTrue);
      expect(ExperienceState.normalPlatformNarration.isPlatformState, isTrue);
      expect(ExperienceState.question.isPlatformState, isTrue);
      expect(ExperienceState.questionBranchFeudal.isPlatformState, isTrue);
      expect(ExperienceState.questionBranchClassics.isPlatformState, isTrue);
      expect(ExperienceState.questionMerge.isPlatformState, isTrue);
      expect(ExperienceState.ready.isPlatformState, isFalse);
    });

    test('classifies fallback states correctly', () {
      expect(ExperienceState.fallbackGroundObserve.isFallbackState, isTrue);
      expect(ExperienceState.fallbackGroundNarration.isFallbackState, isTrue);
      expect(ExperienceState.ready.isFallbackState, isFalse);
    });

    test('only completed is terminal', () {
      expect(ExperienceState.completed.isTerminalState, isTrue);
      expect(ExperienceState.ready.isTerminalState, isFalse);
      expect(ExperienceState.survey.isTerminalState, isFalse);
    });
  });

  test('state ids match Project.md uppercase snake case', () {
    expect(
      ExperienceState.normalPlatformObserve.id,
      'NORMAL_PLATFORM_OBSERVE',
    );
    expect(ExperienceState.ready.id, 'READY');
  });

  group('ExperienceEvent', () {
    test('UserAction carries correct ActionType', () {
      final event = UserAction(UserActionType.continue_);
      expect(event.action, UserActionType.continue_);
    });

    test('OperatorAction carries correct ActionType', () {
      final event = OperatorAction(OperatorActionType.nextStep);
      expect(event.action, OperatorActionType.nextStep);
    });

    test('UserActionType.fromApiName works', () {
      expect(UserActionType.fromApiName('continue'), UserActionType.continue_);
      expect(
          UserActionType.fromApiName('start_test'), UserActionType.startTest);
      expect(UserActionType.fromApiName('choose_feudal'),
          UserActionType.chooseFeudal);
      expect(UserActionType.fromApiName('submit_survey'),
          UserActionType.submitSurvey);
    });

    test('UserActionType.apiName roundtrip', () {
      for (final action in UserActionType.values) {
        expect(UserActionType.fromApiName(action.apiName), action);
      }
    });

    test('OperatorActionType.apiName roundtrip', () {
      expect(OperatorActionType.createSession.apiName, 'create_session');
      expect(OperatorActionType.replayAudio.apiName, 'replay_audio');
      expect(OperatorActionType.switchToFallback.apiName, 'switch_fallback');
    });
  });

  group('RouteDefinition — normal route', () {
    final transitions = buildNormalTransitions();
    final route = RouteDefinition(
      id: 'normal',
      initialState: ExperienceState.ready,
      transitions: transitions,
    );

    test('starts at READY', () {
      expect(route.initialState, ExperienceState.ready);
    });

    test('READY → INTRO on startTest', () {
      final next = route.nextState(
          ExperienceState.ready, ExperienceEventType.userStartTest);
      expect(next, ExperienceState.intro);
    });

    test('walkToWumen: arrived progresses, audioCompleted does not', () {
      final arrived = route.nextState(
          ExperienceState.walkToWumen, ExperienceEventType.userArrived);
      expect(arrived, ExperienceState.wumenNorth);

      final audioEnd = route.nextState(
          ExperienceState.walkToWumen, ExperienceEventType.audioCompleted);
      expect(audioEnd, isNull);
    });

    test('follows full normal route end-to-end', () {
      final expectedSequence = [
        (
          ExperienceState.ready,
          ExperienceEventType.userStartTest,
          ExperienceState.intro
        ),
        (
          ExperienceState.intro,
          ExperienceEventType.userStartTest,
          ExperienceState.fengtianNorth
        ),
        (
          ExperienceState.fengtianNorth,
          ExperienceEventType.userContinue,
          ExperienceState.walkToWumen
        ),
        (
          ExperienceState.walkToWumen,
          ExperienceEventType.userArrived,
          ExperienceState.wumenNorth
        ),
        (
          ExperienceState.wumenNorth,
          ExperienceEventType.userContinue,
          ExperienceState.waitForRouteDecision
        ),
        (
          ExperienceState.waitForRouteDecision,
          ExperienceEventType.operatorSelectNormal,
          ExperienceState.normalAscend
        ),
        (
          ExperienceState.normalAscend,
          ExperienceEventType.userArrived,
          ExperienceState.normalPlatformObserve
        ),
        (
          ExperienceState.normalPlatformObserve,
          ExperienceEventType.userContinue,
          ExperienceState.normalPlatformNarration
        ),
        (
          ExperienceState.normalPlatformNarration,
          ExperienceEventType.audioCompleted,
          ExperienceState.question
        ),
        (
          ExperienceState.question,
          ExperienceEventType.userChooseFeudal,
          ExperienceState.questionBranchFeudal
        ),
        (
          ExperienceState.questionBranchFeudal,
          ExperienceEventType.audioCompleted,
          ExperienceState.questionMerge
        ),
        (
          ExperienceState.questionMerge,
          ExperienceEventType.userContinue,
          ExperienceState.normalDescend
        ),
        (
          ExperienceState.normalDescend,
          ExperienceEventType.userArrived,
          ExperienceState.walkThroughWumen
        ),
        (
          ExperienceState.walkThroughWumen,
          ExperienceEventType.userArrived,
          ExperienceState.wumenSouthEnding
        ),
        (
          ExperienceState.wumenSouthEnding,
          ExperienceEventType.audioCompleted,
          ExperienceState.endingAmbience
        ),
        (
          ExperienceState.endingAmbience,
          ExperienceEventType.timerElapsed,
          ExperienceState.survey
        ),
        (
          ExperienceState.survey,
          ExperienceEventType.userSubmitSurvey,
          ExperienceState.completed
        ),
      ];

      for (final (from, event, expected) in expectedSequence) {
        final next = route.nextState(from, event);
        expect(next, expected,
            reason: 'Transition $from → $event should give $expected');
      }
    });

    test('normal: restart from completed goes to ready', () {
      final next = route.nextState(
          ExperienceState.completed, ExperienceEventType.userRestart);
      expect(next, ExperienceState.ready);
    });

    test('invalid transition returns null', () {
      final next = route.nextState(
          ExperienceState.ready, ExperienceEventType.audioCompleted);
      expect(next, isNull);
    });

    test('non-existent state returns null', () {
      // There is no transition table entry for non-terminal states.
      final next = route.nextState(ExperienceState.questionBranchFeudal,
          ExperienceEventType.userChooseFeudal);
      expect(next, isNull);
    });
  });

  group('RouteDefinition — fallback route', () {
    final transitions = buildFallbackTransitions();
    final route = RouteDefinition(
      id: 'fallback',
      initialState: ExperienceState.ready,
      transitions: transitions,
    );

    test('shares normal route until waitForRouteDecision', () {
      final next = route.nextState(
          ExperienceState.walkToWumen, ExperienceEventType.userArrived);
      expect(next, ExperienceState.wumenNorth);
    });

    test('waitForRouteDecision only accepts selectFallback', () {
      final fallback = route.nextState(
        ExperienceState.waitForRouteDecision,
        ExperienceEventType.operatorSelectFallback,
      );
      expect(fallback, ExperienceState.fallbackGroundObserve);

      final normal = route.nextState(
        ExperienceState.waitForRouteDecision,
        ExperienceEventType.operatorSelectNormal,
      );
      expect(normal, isNull);
    });

    test('fallback has no normal ascend/descend/platform states', () {
      final ascend = route.nextState(
          ExperienceState.normalAscend, ExperienceEventType.userArrived);
      expect(ascend, isNull);

      final observe = route.nextState(ExperienceState.normalPlatformObserve,
          ExperienceEventType.userContinue);
      expect(observe, isNull);
    });

    test('follows full fallback route end-to-end', () {
      final expectedSequence = [
        (
          ExperienceState.ready,
          ExperienceEventType.userStartTest,
          ExperienceState.intro
        ),
        (
          ExperienceState.intro,
          ExperienceEventType.userStartTest,
          ExperienceState.fengtianNorth
        ),
        (
          ExperienceState.fengtianNorth,
          ExperienceEventType.userContinue,
          ExperienceState.walkToWumen
        ),
        (
          ExperienceState.walkToWumen,
          ExperienceEventType.userArrived,
          ExperienceState.wumenNorth
        ),
        (
          ExperienceState.wumenNorth,
          ExperienceEventType.userContinue,
          ExperienceState.waitForRouteDecision
        ),
        (
          ExperienceState.waitForRouteDecision,
          ExperienceEventType.operatorSelectFallback,
          ExperienceState.fallbackGroundObserve
        ),
        (
          ExperienceState.fallbackGroundObserve,
          ExperienceEventType.userContinue,
          ExperienceState.fallbackGroundNarration
        ),
        (
          ExperienceState.fallbackGroundNarration,
          ExperienceEventType.audioCompleted,
          ExperienceState.question
        ),
        (
          ExperienceState.question,
          ExperienceEventType.userChooseClassics,
          ExperienceState.questionBranchClassics
        ),
        (
          ExperienceState.questionBranchClassics,
          ExperienceEventType.audioCompleted,
          ExperienceState.questionMerge
        ),
        (
          ExperienceState.questionMerge,
          ExperienceEventType.userContinue,
          ExperienceState.wumenSouthEnding
        ),
        (
          ExperienceState.wumenSouthEnding,
          ExperienceEventType.userContinue,
          ExperienceState.endingAmbience
        ),
        (
          ExperienceState.endingAmbience,
          ExperienceEventType.timerElapsed,
          ExperienceState.survey
        ),
        (
          ExperienceState.survey,
          ExperienceEventType.userSubmitSurvey,
          ExperienceState.completed
        ),
      ];

      for (final (from, event, expected) in expectedSequence) {
        final next = route.nextState(from, event);
        expect(next, expected,
            reason: 'Transition $from → $event should give $expected');
      }
    });

    test('fallback: branch merge works regardless of choice', () {
      // Feudal branch
      final feudalMerge = route.nextState(
        ExperienceState.questionBranchFeudal,
        ExperienceEventType.audioCompleted,
      );
      expect(feudalMerge, ExperienceState.questionMerge);

      // Classics branch
      final classicsMerge = route.nextState(
        ExperienceState.questionBranchClassics,
        ExperienceEventType.audioCompleted,
      );
      expect(classicsMerge, ExperienceState.questionMerge);
    });

    test('isFallback returns true', () {
      expect(route.isFallback, isTrue);
    });
  });

  group('SceneDefinition', () {
    test('parses from JSON correctly', () {
      final json = {
        'renderer': 'layered_reconstruction',
        'background': 'images/test/background.webp',
        'audio': 'audio/test.mp3',
        'minimumDurationMs': 10000,
        'autoAdvance': false,
        'visualSequence': [
          {'asset': 'images/test/layer1.webp', 'startMs': 0, 'fadeInMs': 1200},
          {
            'asset': 'images/test/layer2.webp',
            'startMs': 1500,
            'fadeInMs': 800
          },
        ],
        'allowedActions': ['continue', 'pause'],
        'safetyMode': 'stationary',
      };

      final scene = SceneDefinition.fromJson(json);

      expect(scene.renderer, 'layered_reconstruction');
      expect(scene.background, 'images/test/background.webp');
      expect(scene.audio, 'audio/test.mp3');
      expect(scene.minimumDurationMs, 10000);
      expect(scene.autoAdvance, isFalse);
      expect(scene.visualSequence.length, 2);
      expect(scene.allowedActions, ['continue', 'pause']);
      expect(scene.safetyMode, 'stationary');
    });

    test('parses minimal JSON with defaults', () {
      final json = {
        'renderer': 'instruction',
        'minimumDurationMs': 0,
        'autoAdvance': false,
        'visualSequence': [],
        'allowedActions': ['start_test'],
        'safetyMode': 'stationary',
      };

      final scene = SceneDefinition.fromJson(json);

      expect(scene.background, isNull);
      expect(scene.audio, isNull);
      expect(scene.visualSequence, isEmpty);
      expect(scene.hasLayers, isFalse);
    });

    test('rejects unsupported renderer', () {
      expect(
        () => SceneDefinition.fromJson({
          'id': 'BROKEN',
          'renderer': 'ar_scene',
          'minimumDurationMs': 0,
          'autoAdvance': false,
          'visualSequence': <dynamic>[],
          'allowedActions': <dynamic>[],
          'safetyMode': 'stationary',
        }),
        throwsFormatException,
      );
    });

    test('rejects negative timing values', () {
      expect(
        () => SceneDefinition.fromJson({
          'id': 'BROKEN',
          'renderer': 'instruction',
          'minimumDurationMs': -1,
          'autoAdvance': false,
          'visualSequence': <dynamic>[],
          'allowedActions': <dynamic>[],
          'safetyMode': 'stationary',
        }),
        throwsFormatException,
      );
    });

    test('hasLayers returns true only for multiple layers', () {
      final single = SceneDefinition(
        id: 'test',
        renderer: 'narrative',
        minimumDurationMs: 0,
        autoAdvance: false,
        visualSequence: [VisualLayer(asset: 'x.webp', startMs: 0, fadeInMs: 0)],
        allowedActions: [],
        safetyMode: 'stationary',
      );
      expect(single.hasLayers, isFalse);

      final multi = SceneDefinition(
        id: 'test',
        renderer: 'layered_reconstruction',
        minimumDurationMs: 0,
        autoAdvance: false,
        visualSequence: [
          VisualLayer(asset: 'a.webp', startMs: 0, fadeInMs: 0),
          VisualLayer(asset: 'b.webp', startMs: 100, fadeInMs: 500),
        ],
        allowedActions: [],
        safetyMode: 'stationary',
      );
      expect(multi.hasLayers, isTrue);
    });

    test('allowsAction checks correctly', () {
      final scene = SceneDefinition(
        id: 'test',
        renderer: 'narrative',
        minimumDurationMs: 0,
        autoAdvance: false,
        visualSequence: [],
        allowedActions: ['continue', 'pause'],
        safetyMode: 'stationary',
      );

      expect(scene.allowsAction('continue'), isTrue);
      expect(scene.allowsAction('pause'), isTrue);
      expect(scene.allowsAction('start_test'), isFalse);
      expect(scene.allowsAction('replay'), isFalse);
    });

    test('toJson roundtrip', () {
      final original = SceneDefinition(
        id: 'TEST',
        renderer: 'layered_reconstruction',
        background: 'images/test/bg.webp',
        audio: 'audio/test.mp3',
        minimumDurationMs: 5000,
        autoAdvance: true,
        visualSequence: [
          VisualLayer(asset: 'l1.webp', startMs: 0, fadeInMs: 1000),
          VisualLayer(asset: 'l2.webp', startMs: 2000, fadeInMs: 500),
        ],
        allowedActions: ['continue', 'replay'],
        safetyMode: 'stationary',
      );

      final json = original.toJson();
      final parsed = SceneDefinition.fromJson({'id': 'TEST', ...json});

      expect(parsed.renderer, original.renderer);
      expect(parsed.background, original.background);
      expect(parsed.audio, original.audio);
      expect(parsed.minimumDurationMs, original.minimumDurationMs);
      expect(parsed.autoAdvance, original.autoAdvance);
      expect(parsed.visualSequence.length, original.visualSequence.length);
      expect(parsed.visualSequence[0].asset, original.visualSequence[0].asset);
    });
  });

  group('SessionSummary', () {
    test('serializes to JSON correctly', () {
      final summary = SessionSummary(
        sessionId: 'test-uuid',
        startedAt: DateTime(2026, 7, 26, 12, 0, 0),
        endedAt: DateTime(2026, 7, 26, 12, 7, 18),
        completed: true,
        route: 'normal',
        durationSeconds: 438,
        questionChoice: 'feudal_princes',
        helpCount: 1,
        interrupted: false,
        survey: SurveyAnswers(
          experienceDescription: 'walking with Zhu Yunwen',
          mostEngagingMoment: 'platform narration',
          confusingMoment: 'none',
          wantsLongerExperience: true,
          wantsNextTest: true,
        ),
      );

      final json = summary.toJson();

      expect(json['sessionId'], 'test-uuid');
      expect(json['completed'], true);
      expect(json['route'], 'normal');
      expect(json['questionChoice'], 'feudal_princes');
      expect(json['survey']['wantsLongerExperience'], true);
    });

    test('serializes without survey', () {
      final summary = SessionSummary(
        sessionId: 'test-uuid-2',
        startedAt: DateTime(2026, 7, 26),
        completed: false,
        route: 'fallback',
        durationSeconds: 120,
        helpCount: 0,
        interrupted: true,
      );

      final json = summary.toJson();

      expect(json['completed'], false);
      expect(json['survey'], isNull);
    });
  });

  group('Result type', () {
    test('Ok returns value', () {
      final result = Ok<int, AppError>(42);
      expect(result.isOk, isTrue);
      expect(result.isErr, isFalse);
      expect(result.okValue, 42);
      expect(result.errValue, isNull);
    });

    test('Err returns error', () {
      final result = Err<int, AppError>(AppError.contentLoadFailed);
      expect(result.isOk, isFalse);
      expect(result.isErr, isTrue);
      expect(result.okValue, isNull);
      expect(result.errValue, AppError.contentLoadFailed);
    });

    test('fold dispatches correctly', () {
      final ok = Ok<int, AppError>(5);
      final err = Err<int, AppError>(AppError.unknown);

      expect(ok.fold((v) => '$v', (e) => 'err'), '5');
      expect(err.fold((v) => '$v', (e) => 'err'), 'err');
    });
  });

  group('AppError messages', () {
    test('all errors have Chinese messages', () {
      for (final error in AppError.values) {
        expect(error.message, isNotEmpty);
      }
    });
  });

  group('VisualLayer', () {
    test('parses from JSON', () {
      final json = {'asset': 'img.webp', 'startMs': 1000, 'fadeInMs': 500};
      final layer = VisualLayer.fromJson(json);

      expect(layer.asset, 'img.webp');
      expect(layer.startMs, 1000);
      expect(layer.fadeInMs, 500);
    });

    test('provides defaults for missing fields', () {
      final json = {'asset': 'img.webp'};
      final layer = VisualLayer.fromJson(json);

      expect(layer.asset, 'img.webp');
      expect(layer.startMs, 0);
      expect(layer.fadeInMs, 0);
    });

    test('toJson roundtrip', () {
      final layer =
          VisualLayer(asset: 'test.webp', startMs: 500, fadeInMs: 200);
      final json = layer.toJson();
      final parsed = VisualLayer.fromJson(json);

      expect(parsed.asset, layer.asset);
      expect(parsed.startMs, layer.startMs);
      expect(parsed.fadeInMs, layer.fadeInMs);
    });
  });
}
