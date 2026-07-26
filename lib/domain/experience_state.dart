/// All possible experience states in the Ming Palace narrative flow.
///
/// States match the state machine defined in Project.md §4.
enum ExperienceState {
  ready,
  intro,
  fengtianNorth,
  walkToWumen,
  wumenNorth,
  waitForRouteDecision,
  normalAscend,
  normalPlatformObserve,
  normalPlatformNarration,
  question,
  questionBranchFeudal,
  questionBranchClassics,
  questionMerge,
  normalDescend,
  walkThroughWumen,
  fallbackGroundObserve,
  fallbackGroundNarration,
  wumenSouthEnding,
  endingAmbience,
  survey,
  completed;

  String get id => name
      .replaceAllMapped(
        RegExp(r'([a-z0-9])([A-Z])'),
        (match) => '${match.group(1)}_${match.group(2)}',
      )
      .toUpperCase();

  static ExperienceState fromId(String id) => ExperienceState.values.firstWhere(
        (state) => state.id == id,
        orElse: () => throw FormatException('未知体验状态: $id'),
      );

  bool get isWalkingState =>
      this == ExperienceState.walkToWumen ||
      this == ExperienceState.normalAscend ||
      this == ExperienceState.normalDescend ||
      this == ExperienceState.walkThroughWumen;

  bool get isSafetyState =>
      this == ExperienceState.normalAscend ||
      this == ExperienceState.normalDescend;

  bool get isPlatformState =>
      this == ExperienceState.normalPlatformObserve ||
      this == ExperienceState.normalPlatformNarration ||
      this == ExperienceState.question ||
      this == ExperienceState.questionBranchFeudal ||
      this == ExperienceState.questionBranchClassics ||
      this == ExperienceState.questionMerge;

  bool get isFallbackState =>
      this == ExperienceState.fallbackGroundObserve ||
      this == ExperienceState.fallbackGroundNarration;

  bool get isTerminalState =>
      this == ExperienceState.completed;
}
