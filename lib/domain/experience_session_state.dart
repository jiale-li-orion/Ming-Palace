enum ExperiencePhase {
  ready,
  welcome,
  systemCheck,
  userRouteChoice,
  fengtianStart,
  walkToWumen,
  wumenApproach,
  wumenArrival,
  towerAscend,
  platformArrival,
  platformObserve,
  platformRestored,
  question,
  questionAnswer,
  platformSouthView,
  continueDecision,
  towerDescend,
  groundArrival,
  groundObserve,
  groundRestored,
  walkToEnding,
  wumenSouthEnding,
  survey,
  completed;

  String get id => name
      .replaceAllMapped(
        RegExp('[A-Z]'),
        (match) => '_${match.group(0)}',
      )
      .toUpperCase();

  static ExperiencePhase fromId(String id) => values.firstWhere(
        (value) => value.id == id,
        orElse: () => throw FormatException('未知体验阶段: $id'),
      );
}

enum RouteMode { undecided, tower, ground }

enum NavigationMode {
  inactive,
  startGuidance,
  stableWalk,
  approaching,
  offRoute,
  arrivalSuggested,
  manualMode,
}

enum NarrationMode {
  idle,
  playing,
  userPaused,
  systemPaused,
  loadError,
  completed
}

enum OrientationMode {
  portraitRequired,
  requestLandscape,
  landscapeRequired,
  portraitFallback,
  requestPortrait,
}

enum ChromeMode { visible, hidden }

enum SafetyKind { ascending, descending, roughSurface, crowd, operator }

class SafetyInterruption {
  const SafetyInterruption({
    required this.kind,
    required this.returnPhase,
    this.resumeSegmentId,
  });

  final SafetyKind kind;
  final ExperiencePhase returnPhase;
  final String? resumeSegmentId;

  Map<String, dynamic> toJson() => {
        'kind': kind.name,
        'returnPhase': returnPhase.id,
        'resumeSegmentId': resumeSegmentId,
      };
}

class EvidenceOverlay {
  const EvidenceOverlay(this.evidenceId);
  final String evidenceId;
}

class ExperienceSessionState {
  const ExperienceSessionState({
    this.phase = ExperiencePhase.ready,
    this.routeMode = RouteMode.undecided,
    this.navigationMode = NavigationMode.inactive,
    this.narrationMode = NarrationMode.idle,
    this.orientationMode = OrientationMode.portraitRequired,
    this.chromeMode = ChromeMode.visible,
    this.safetyInterruption,
    this.evidenceOverlay,
    this.currentSegmentId,
    this.resumeSegmentId,
  });

  final ExperiencePhase phase;
  final RouteMode routeMode;
  final NavigationMode navigationMode;
  final NarrationMode narrationMode;
  final OrientationMode orientationMode;
  final ChromeMode chromeMode;
  final SafetyInterruption? safetyInterruption;
  final EvidenceOverlay? evidenceOverlay;
  final String? currentSegmentId;
  final String? resumeSegmentId;

  ExperienceSessionState copyWith({
    ExperiencePhase? phase,
    RouteMode? routeMode,
    NavigationMode? navigationMode,
    NarrationMode? narrationMode,
    OrientationMode? orientationMode,
    ChromeMode? chromeMode,
    SafetyInterruption? safetyInterruption,
    bool clearSafety = false,
    EvidenceOverlay? evidenceOverlay,
    bool clearEvidence = false,
    String? currentSegmentId,
    String? resumeSegmentId,
  }) =>
      ExperienceSessionState(
        phase: phase ?? this.phase,
        routeMode: routeMode ?? this.routeMode,
        navigationMode: navigationMode ?? this.navigationMode,
        narrationMode: narrationMode ?? this.narrationMode,
        orientationMode: orientationMode ?? this.orientationMode,
        chromeMode: chromeMode ?? this.chromeMode,
        safetyInterruption:
            clearSafety ? null : safetyInterruption ?? this.safetyInterruption,
        evidenceOverlay:
            clearEvidence ? null : evidenceOverlay ?? this.evidenceOverlay,
        currentSegmentId: currentSegmentId ?? this.currentSegmentId,
        resumeSegmentId: resumeSegmentId ?? this.resumeSegmentId,
      );

  Map<String, dynamic> toJson() => {
        'schemaVersion': 2,
        'phase': phase.id,
        'routeMode': routeMode.name,
        'navigationMode': navigationMode.name,
        'narrationMode': narrationMode.name,
        'orientationMode': orientationMode.name,
        'chromeMode': chromeMode.name,
        'safetyInterruption': safetyInterruption?.toJson(),
        'currentSegmentId': currentSegmentId,
        'resumeSegmentId': resumeSegmentId,
      };
}
