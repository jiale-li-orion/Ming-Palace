import 'package:flutter/foundation.dart';

import '../domain/experience_session_state.dart';

abstract interface class ExperienceClock {
  Duration get elapsed;
  void reset();
}

class SystemExperienceClock implements ExperienceClock {
  final Stopwatch _watch = Stopwatch()..start();
  @override
  Duration get elapsed => _watch.elapsed;
  @override
  void reset() => _watch.reset();
}

class FakeExperienceClock implements ExperienceClock {
  Duration _elapsed = Duration.zero;
  @override
  Duration get elapsed => _elapsed;
  void elapse(Duration duration) => _elapsed += duration;
  @override
  void reset() => _elapsed = Duration.zero;
}

class ProjectExperienceEngine extends ChangeNotifier {
  ProjectExperienceEngine({ExperienceClock? clock})
      : _clock = clock ?? SystemExperienceClock();

  final ExperienceClock _clock;
  ExperienceSessionState _state = const ExperienceSessionState();
  final List<ExperiencePhase> _visited = [ExperiencePhase.ready];
  bool _continuePromptVisible = false;
  bool _firstObservationPromptArmed = false;
  int _observationPromptCount = 0;
  void Function(Duration delay)? onObservationWaitRequested;

  ExperienceSessionState get state => _state;
  List<ExperiencePhase> get visitedPhases => List.unmodifiable(_visited);
  bool get continuePromptVisible => _continuePromptVisible;
  bool get canShowEvidence =>
      _state.narrationMode == NarrationMode.userPaused &&
      _state.safetyInterruption == null;

  void advance() {
    final phase = _state.phase;
    final route = _state.routeMode;
    final next = switch (phase) {
      ExperiencePhase.welcome => ExperiencePhase.userRouteChoice,
      ExperiencePhase.systemCheck => ExperiencePhase.userRouteChoice,
      ExperiencePhase.fengtianStart => ExperiencePhase.walkToWumen,
      ExperiencePhase.walkToWumen => ExperiencePhase.wumenApproach,
      ExperiencePhase.wumenArrival => route == RouteMode.ground
          ? ExperiencePhase.groundArrival
          : ExperiencePhase.towerAscend,
      ExperiencePhase.towerAscend => ExperiencePhase.platformArrival,
      ExperiencePhase.platformArrival => ExperiencePhase.platformObserve,
      ExperiencePhase.platformObserve => ExperiencePhase.platformRestored,
      ExperiencePhase.platformRestored => ExperiencePhase.question,
      ExperiencePhase.questionAnswer => route == RouteMode.tower
          ? ExperiencePhase.platformSouthView
          : ExperiencePhase.continueDecision,
      ExperiencePhase.platformSouthView => ExperiencePhase.continueDecision,
      ExperiencePhase.continueDecision => route == RouteMode.tower
          ? ExperiencePhase.towerDescend
          : ExperiencePhase.walkToEnding,
      ExperiencePhase.towerDescend => ExperiencePhase.walkToEnding,
      ExperiencePhase.groundArrival => ExperiencePhase.groundObserve,
      ExperiencePhase.groundObserve => ExperiencePhase.groundRestored,
      ExperiencePhase.groundRestored => ExperiencePhase.question,
      ExperiencePhase.wumenSouthEnding => ExperiencePhase.survey,
      ExperiencePhase.survey => ExperiencePhase.completed,
      _ => null,
    };
    if (next != null) {
      _transition(next);
    }
  }

  void answerQuestion(String choice) {
    if (_state.phase != ExperiencePhase.question) return;
    _transition(ExperiencePhase.questionAnswer);
    setCurrentSegment(
        choice == 'feudal' ? 'answer-feudal-s01' : 'answer-classics-s01');
  }

  void useManualNavigation() {
    _state = _state.copyWith(navigationMode: NavigationMode.manualMode);
    notifyListeners();
  }

  void updateNavigation(NavigationMode mode) {
    if (mode == NavigationMode.offRoute) {
      _state = _state.copyWith(
        navigationMode: mode,
        narrationMode: NarrationMode.systemPaused,
        resumeSegmentId: _state.currentSegmentId,
        clearEvidence: true,
      );
    } else {
      _state = _state.copyWith(navigationMode: mode);
    }
    notifyListeners();
  }

  void confirmBackOnRoute() {
    if (_state.navigationMode != NavigationMode.offRoute) return;
    _state = _state.copyWith(
      navigationMode: NavigationMode.stableWalk,
      narrationMode: NarrationMode.userPaused,
      currentSegmentId: _state.resumeSegmentId,
    );
    notifyListeners();
  }

  void usePortraitFallback() {
    _state = _state.copyWith(orientationMode: OrientationMode.portraitFallback);
    notifyListeners();
    if (_state.phase == ExperiencePhase.platformArrival) {
      _transition(ExperiencePhase.platformObserve);
    } else if (_state.phase == ExperiencePhase.groundArrival) {
      _transition(ExperiencePhase.groundObserve);
    }
  }

  void start() => _transition(ExperiencePhase.welcome);

  void restoreState(ExperienceSessionState restored) {
    _state = restored.narrationMode == NarrationMode.playing
        ? restored.copyWith(narrationMode: NarrationMode.userPaused)
        : restored;
    _visited.add(_state.phase);
    notifyListeners();
  }

  void chooseRoute(RouteMode route) {
    _state = _state.copyWith(routeMode: route);
    _transition(ExperiencePhase.fengtianStart);
  }

  void jumpTo(ExperiencePhase phase) => _transition(phase);

  void updatePhysicalOrientation({required bool isLandscape}) {
    _state = _state.copyWith(
      orientationMode: isLandscape
          ? OrientationMode.landscapeRequired
          : OrientationMode.portraitRequired,
    );
    notifyListeners();
  }

  void suggestArrival() {
    _state = _state.copyWith(navigationMode: NavigationMode.arrivalSuggested);
    notifyListeners();
  }

  void confirmArrival() {
    if (_state.navigationMode != NavigationMode.arrivalSuggested &&
        _state.navigationMode != NavigationMode.manualMode) {
      return;
    }
    if (_state.phase == ExperiencePhase.walkToWumen ||
        _state.phase == ExperiencePhase.wumenApproach) {
      _transition(ExperiencePhase.wumenArrival);
    } else if (_state.phase == ExperiencePhase.walkToEnding) {
      _transition(ExperiencePhase.wumenSouthEnding);
    }
  }

  void setCurrentSegment(String id) {
    if (_state.currentSegmentId == id) return;
    _state = _state.copyWith(currentSegmentId: id);
    notifyListeners();
  }

  void interruptForSafety(SafetyKind kind) {
    _state = _state.copyWith(
      narrationMode: NarrationMode.systemPaused,
      resumeSegmentId: _state.currentSegmentId,
      safetyInterruption: SafetyInterruption(
        kind: kind,
        returnPhase: _state.phase,
        resumeSegmentId: _state.currentSegmentId,
      ),
      clearEvidence: true,
    );
    notifyListeners();
  }

  void confirmSafeGround() {
    final interruption = _state.safetyInterruption;
    if (interruption == null) {
      return;
    }
    _state = _state.copyWith(
      phase: interruption.returnPhase,
      narrationMode: NarrationMode.userPaused,
      currentSegmentId: interruption.resumeSegmentId,
      clearSafety: true,
    );
    notifyListeners();
  }

  void playNarration() {
    _state = _state.copyWith(
      narrationMode: NarrationMode.playing,
      clearEvidence: true,
    );
    notifyListeners();
  }

  void userPauseNarration() {
    _state = _state.copyWith(narrationMode: NarrationMode.userPaused);
    notifyListeners();
  }

  void systemPauseNarration() {
    _state = _state.copyWith(
      narrationMode: NarrationMode.systemPaused,
      clearEvidence: true,
    );
    notifyListeners();
  }

  void onObservationTimer() {
    if (_state.phase != ExperiencePhase.platformSouthView &&
        _state.phase != ExperiencePhase.groundRestored) {
      return;
    }
    if (_observationPromptCount == 0 &&
        _clock.elapsed >= const Duration(seconds: 90)) {
      _firstObservationPromptArmed = true;
    } else if (_observationPromptCount == 1 &&
        _clock.elapsed >= const Duration(seconds: 120)) {
      _continuePromptVisible = true;
      _observationPromptCount = 2;
    }
    notifyListeners();
  }

  void tapObservation() {
    if (_firstObservationPromptArmed && _observationPromptCount == 0) {
      _firstObservationPromptArmed = false;
      _continuePromptVisible = true;
      _observationPromptCount = 1;
    } else {
      _state = _state.copyWith(
        chromeMode: _state.chromeMode == ChromeMode.visible
            ? ChromeMode.hidden
            : ChromeMode.visible,
      );
    }
    notifyListeners();
  }

  void keepLooking() {
    _continuePromptVisible = false;
    _clock.reset();
    if (_observationPromptCount == 1) {
      onObservationWaitRequested?.call(const Duration(seconds: 120));
    }
    notifyListeners();
  }

  void runToCompletionForTest() {
    final route = _state.routeMode;
    final phases = route == RouteMode.tower
        ? const [
            ExperiencePhase.walkToWumen,
            ExperiencePhase.wumenApproach,
            ExperiencePhase.wumenArrival,
            ExperiencePhase.towerAscend,
            ExperiencePhase.platformArrival,
            ExperiencePhase.platformObserve,
            ExperiencePhase.platformRestored,
            ExperiencePhase.question,
            ExperiencePhase.questionAnswer,
            ExperiencePhase.platformSouthView,
            ExperiencePhase.continueDecision,
            ExperiencePhase.towerDescend,
            ExperiencePhase.walkToEnding,
            ExperiencePhase.wumenSouthEnding,
            ExperiencePhase.survey,
            ExperiencePhase.completed,
          ]
        : const [
            ExperiencePhase.walkToWumen,
            ExperiencePhase.wumenApproach,
            ExperiencePhase.wumenArrival,
            ExperiencePhase.groundArrival,
            ExperiencePhase.groundObserve,
            ExperiencePhase.groundRestored,
            ExperiencePhase.question,
            ExperiencePhase.questionAnswer,
            ExperiencePhase.continueDecision,
            ExperiencePhase.walkToEnding,
            ExperiencePhase.wumenSouthEnding,
            ExperiencePhase.survey,
            ExperiencePhase.completed,
          ];
    for (final phase in phases) {
      _transition(phase, notify: false);
    }
    notifyListeners();
  }

  void _transition(ExperiencePhase phase, {bool notify = true}) {
    _state = _state.copyWith(
      phase: phase,
      navigationMode: _navigationFor(phase),
      orientationMode: _orientationFor(phase),
      clearEvidence: true,
    );
    _visited.add(phase);
    if (phase == ExperiencePhase.platformSouthView ||
        phase == ExperiencePhase.groundRestored) {
      _clock.reset();
      _continuePromptVisible = false;
      _firstObservationPromptArmed = false;
      _observationPromptCount = 0;
      onObservationWaitRequested?.call(const Duration(seconds: 90));
    }
    if (notify) notifyListeners();
  }

  static NavigationMode _navigationFor(ExperiencePhase phase) {
    if (phase == ExperiencePhase.fengtianStart) {
      return NavigationMode.startGuidance;
    }
    if (phase == ExperiencePhase.walkToWumen ||
        phase == ExperiencePhase.walkToEnding) {
      return NavigationMode.stableWalk;
    }
    if (phase == ExperiencePhase.wumenApproach) {
      return NavigationMode.approaching;
    }
    return NavigationMode.inactive;
  }

  static OrientationMode _orientationFor(ExperiencePhase phase) {
    const landscape = {
      ExperiencePhase.platformObserve,
      ExperiencePhase.platformRestored,
      ExperiencePhase.question,
      ExperiencePhase.questionAnswer,
      ExperiencePhase.platformSouthView,
      ExperiencePhase.groundObserve,
      ExperiencePhase.groundRestored,
    };
    return landscape.contains(phase)
        ? OrientationMode.requestLandscape
        : OrientationMode.portraitRequired;
  }
}
