import 'experience_state.dart';

/// Route configuration loaded from experience.json.
class RouteDefinition {
  final String id;
  final ExperienceState initialState;
  final Map<ExperienceState, Map<ExperienceEventType, ExperienceState?>> transitions;

  const RouteDefinition({
    required this.id,
    required this.initialState,
    required this.transitions,
  });

  /// Look up the next state for a given event; returns null if invalid.
  ExperienceState? nextState(ExperienceState current, ExperienceEventType event) {
    final stateTransitions = transitions[current];
    if (stateTransitions == null) return null;
    return stateTransitions[event];
  }

  /// Whether this route is the fallback (ground-level) route.
  bool get isFallback => id == 'fallback';
}

/// Discriminated event types for use as transition map keys.
enum ExperienceEventType {
  userStartTest,
  userContinue,
  userPause,
  userResume,
  userReplay,
  userArrived,
  userChooseFeudal,
  userChooseClassics,
  userSubmitSurvey,
  userExport,
  userRestart,
  operatorSelectNormal,
  operatorSelectFallback,
  operatorNextStep,
  operatorPreviousStep,
  operatorEndSession,
  audioCompleted,
  timerElapsed,
  appResumed,
}

/// Builds the normal-route transition table.
Map<ExperienceState, Map<ExperienceEventType, ExperienceState?>> buildNormalTransitions() {
  return {
    ExperienceState.ready: {
      ExperienceEventType.userStartTest: ExperienceState.intro,
    },
    ExperienceState.intro: {
      ExperienceEventType.userStartTest: ExperienceState.fengtianNorth,
    },
    ExperienceState.fengtianNorth: {
      ExperienceEventType.userContinue: ExperienceState.walkToWumen,
      ExperienceEventType.audioCompleted: ExperienceState.walkToWumen,
    },
    ExperienceState.walkToWumen: {
      ExperienceEventType.userArrived: ExperienceState.wumenNorth,
      ExperienceEventType.audioCompleted: null, // keep waiting for arrival
    },
    ExperienceState.wumenNorth: {
      ExperienceEventType.userContinue: ExperienceState.waitForRouteDecision,
      ExperienceEventType.audioCompleted: ExperienceState.waitForRouteDecision,
    },
    ExperienceState.waitForRouteDecision: {
      ExperienceEventType.operatorSelectNormal: ExperienceState.normalAscend,
      ExperienceEventType.operatorSelectFallback: ExperienceState.fallbackGroundObserve,
    },
    ExperienceState.normalAscend: {
      ExperienceEventType.userArrived: ExperienceState.normalPlatformObserve,
    },
    ExperienceState.normalPlatformObserve: {
      ExperienceEventType.userContinue: ExperienceState.normalPlatformNarration,
      ExperienceEventType.timerElapsed: ExperienceState.normalPlatformNarration,
    },
    ExperienceState.normalPlatformNarration: {
      ExperienceEventType.userContinue: ExperienceState.question,
      ExperienceEventType.audioCompleted: ExperienceState.question,
    },
    ExperienceState.question: {
      ExperienceEventType.userChooseFeudal: ExperienceState.questionBranchFeudal,
      ExperienceEventType.userChooseClassics: ExperienceState.questionBranchClassics,
    },
    ExperienceState.questionBranchFeudal: {
      ExperienceEventType.userContinue: ExperienceState.questionMerge,
      ExperienceEventType.audioCompleted: ExperienceState.questionMerge,
    },
    ExperienceState.questionBranchClassics: {
      ExperienceEventType.userContinue: ExperienceState.questionMerge,
      ExperienceEventType.audioCompleted: ExperienceState.questionMerge,
    },
    ExperienceState.questionMerge: {
      ExperienceEventType.userContinue: ExperienceState.normalDescend,
      ExperienceEventType.audioCompleted: ExperienceState.normalDescend,
    },
    ExperienceState.normalDescend: {
      ExperienceEventType.userArrived: ExperienceState.walkThroughWumen,
    },
    ExperienceState.walkThroughWumen: {
      ExperienceEventType.userArrived: ExperienceState.wumenSouthEnding,
    },
    ExperienceState.fallbackGroundObserve: {
      ExperienceEventType.userContinue: ExperienceState.fallbackGroundNarration,
      ExperienceEventType.timerElapsed: ExperienceState.fallbackGroundNarration,
    },
    ExperienceState.fallbackGroundNarration: {
      ExperienceEventType.userContinue: ExperienceState.question,
      ExperienceEventType.audioCompleted: ExperienceState.question,
    },
    ExperienceState.wumenSouthEnding: {
      ExperienceEventType.userContinue: ExperienceState.endingAmbience,
      ExperienceEventType.audioCompleted: ExperienceState.endingAmbience,
    },
    ExperienceState.endingAmbience: {
      ExperienceEventType.timerElapsed: ExperienceState.survey,
    },
    ExperienceState.survey: {
      ExperienceEventType.userSubmitSurvey: ExperienceState.completed,
    },
    ExperienceState.completed: {
      ExperienceEventType.userExport: null,   // stay on completed
      ExperienceEventType.userRestart: ExperienceState.ready,
    },
  };
}

/// Builds the fallback-route transition table (shares most states with normal).
Map<ExperienceState, Map<ExperienceEventType, ExperienceState?>> buildFallbackTransitions() {
  final t = buildNormalTransitions();

  // Override: waitForRouteDecision goes directly to fallback ground.
  t[ExperienceState.waitForRouteDecision] = {
    ExperienceEventType.operatorSelectFallback: ExperienceState.fallbackGroundObserve,
  };

  // Override: remove normal ascend/descend paths from fallback route.
  t.remove(ExperienceState.normalAscend);
  t.remove(ExperienceState.normalPlatformObserve);
  t.remove(ExperienceState.normalPlatformNarration);
  t.remove(ExperienceState.normalDescend);

  // The ground-level route rejoins the shared ending without presenting
  // climb/descent instructions that do not apply to this route.
  t[ExperienceState.questionMerge] = {
    ExperienceEventType.userContinue: ExperienceState.wumenSouthEnding,
    ExperienceEventType.audioCompleted: ExperienceState.wumenSouthEnding,
  };

  return t;
}
