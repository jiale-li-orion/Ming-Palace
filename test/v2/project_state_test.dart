import 'package:flutter_test/flutter_test.dart';
import 'package:ming_palace/application/project_experience_engine.dart';
import 'package:ming_palace/application/navigation_controller.dart';
import 'package:ming_palace/domain/experience_session_state.dart';
import 'package:ming_palace/domain/route_config.dart';

void main() {
  group('ProjectExperienceEngine', () {
    test('tower and ground routes both complete without sharing stair phases',
        () {
      final tower = ProjectExperienceEngine()..start();
      tower.chooseRoute(RouteMode.tower);
      tower.runToCompletionForTest();
      expect(tower.state.phase, ExperiencePhase.completed);
      expect(tower.visitedPhases, contains(ExperiencePhase.towerAscend));

      final ground = ProjectExperienceEngine()..start();
      ground.chooseRoute(RouteMode.ground);
      ground.runToCompletionForTest();
      expect(ground.state.phase, ExperiencePhase.completed);
      expect(
          ground.visitedPhases, isNot(contains(ExperiencePhase.towerAscend)));
      expect(
          ground.visitedPhases, isNot(contains(ExperiencePhase.towerDescend)));
    });

    test('orientation changes never advance the phase', () {
      final engine = ProjectExperienceEngine()..start();
      final before = engine.state.phase;
      engine.updatePhysicalOrientation(isLandscape: true);
      expect(engine.state.phase, before);
    });

    test('arrival suggestion waits for explicit user confirmation', () {
      final engine = ProjectExperienceEngine()..start();
      engine.chooseRoute(RouteMode.tower);
      engine.jumpTo(ExperiencePhase.walkToWumen);
      engine.suggestArrival();
      expect(engine.state.phase, ExperiencePhase.walkToWumen);
      expect(engine.state.navigationMode, NavigationMode.arrivalSuggested);
      engine.confirmArrival();
      expect(engine.state.phase, ExperiencePhase.wumenArrival);
    });

    test('safety interruption restores phase at a complete sentence boundary',
        () {
      final engine = ProjectExperienceEngine()..start();
      engine.jumpTo(ExperiencePhase.platformRestored);
      engine.setCurrentSegment('platform-04-s02');
      engine.interruptForSafety(SafetyKind.crowd);
      expect(engine.state.narrationMode, NarrationMode.systemPaused);
      expect(engine.state.safetyInterruption, isNotNull);
      engine.confirmSafeGround();
      expect(engine.state.phase, ExperiencePhase.platformRestored);
      expect(engine.state.currentSegmentId, 'platform-04-s02');
      expect(engine.state.narrationMode, NarrationMode.userPaused);
    });

    test('evidence is visible only after user pause', () {
      final engine = ProjectExperienceEngine()..start();
      engine.jumpTo(ExperiencePhase.platformRestored);
      engine.playNarration();
      expect(engine.canShowEvidence, isFalse);
      engine.userPauseNarration();
      expect(engine.canShowEvidence, isTrue);
      engine.systemPauseNarration();
      expect(engine.canShowEvidence, isFalse);
    });

    test('90 and 120 second continuation prompts follow touch rule', () {
      final clock = FakeExperienceClock();
      final engine = ProjectExperienceEngine(clock: clock)..start();
      engine.chooseRoute(RouteMode.tower);
      engine.jumpTo(ExperiencePhase.platformSouthView);
      clock.elapse(const Duration(seconds: 90));
      engine.onObservationTimer();
      expect(engine.state.evidenceOverlay, isNull);
      expect(engine.continuePromptVisible, isFalse);
      engine.tapObservation();
      expect(engine.continuePromptVisible, isTrue);
      engine.keepLooking();
      clock.elapse(const Duration(seconds: 120));
      engine.onObservationTimer();
      expect(engine.continuePromptVisible, isTrue);
      engine.keepLooking();
      clock.elapse(const Duration(seconds: 120));
      engine.onObservationTimer();
      expect(engine.continuePromptVisible, isFalse);
    });
  });

  group('NavigationController', () {
    test('filters stale/inaccurate samples and requires consecutive arrivals',
        () {
      final now = DateTime.utc(2026, 7, 27, 2);
      final route = RouteConfig.temporaryDemo();
      final navigation = NavigationController(route: route, now: () => now);

      expect(
        navigation.evaluate(LocationSample(
          latitude: 32.04018,
          longitude: 118.81245,
          accuracyM: 50,
          timestamp: now,
        )),
        NavigationMode.manualMode,
      );

      for (var i = 0; i < 2; i++) {
        expect(
          navigation.evaluate(LocationSample(
            latitude: 32.04018,
            longitude: 118.81245,
            accuracyM: 5,
            timestamp: now,
          )),
          isNot(NavigationMode.arrivalSuggested),
        );
      }
      expect(
        navigation.evaluate(LocationSample(
          latitude: 32.04018,
          longitude: 118.81245,
          accuracyM: 5,
          timestamp: now,
        )),
        NavigationMode.arrivalSuggested,
      );
    });
  });
}
