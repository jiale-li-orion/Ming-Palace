import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../domain/experience_session_state.dart';

class ProjectSessionSnapshot {

  factory ProjectSessionSnapshot.decode(Map<String, dynamic> json) {
    if (json['schemaVersion'] == 2) {
      final raw = json['state'] as Map<String, dynamic>;
      final phase = ExperiencePhase.fromId(raw['phase'] as String);
      final narration = NarrationMode.values.byName(
        raw['narrationMode'] as String? ?? NarrationMode.idle.name,
      );
      return ProjectSessionSnapshot(
        sessionId: json['sessionId'] as String,
        state: ExperienceSessionState(
          phase: phase,
          routeMode: RouteMode.values.byName(
            raw['routeMode'] as String? ?? RouteMode.undecided.name,
          ),
          navigationMode: NavigationMode.values.byName(
            raw['navigationMode'] as String? ?? NavigationMode.inactive.name,
          ),
          narrationMode: narration == NarrationMode.playing
              ? NarrationMode.userPaused
              : narration,
          orientationMode: OrientationMode.values.byName(
            raw['orientationMode'] as String? ??
                OrientationMode.portraitRequired.name,
          ),
          chromeMode: ChromeMode.values.byName(
            raw['chromeMode'] as String? ?? ChromeMode.visible.name,
          ),
          currentSegmentId: raw['currentSegmentId'] as String?,
          resumeSegmentId: raw['resumeSegmentId'] as String?,
        ),
      );
    }
    return _migrateLegacy(json);
  }
  const ProjectSessionSnapshot({required this.sessionId, required this.state});
  final String sessionId;
  final ExperienceSessionState state;

  static ProjectSessionSnapshot _migrateLegacy(Map<String, dynamic> json) {
    final legacy = json['state'] as String? ?? 'READY';
    const phases = {
      'READY': ExperiencePhase.ready,
      'INTRO': ExperiencePhase.welcome,
      'FENGTIAN_NORTH': ExperiencePhase.fengtianStart,
      'WALK_TO_WUMEN': ExperiencePhase.walkToWumen,
      'WUMEN_NORTH': ExperiencePhase.wumenArrival,
      'NORMAL_ASCEND': ExperiencePhase.towerAscend,
      'NORMAL_PLATFORM_OBSERVE': ExperiencePhase.platformObserve,
      'NORMAL_PLATFORM_NARRATION': ExperiencePhase.platformRestored,
      'QUESTION': ExperiencePhase.question,
      'NORMAL_DESCEND': ExperiencePhase.towerDescend,
      'FALLBACK_GROUND_OBSERVE': ExperiencePhase.groundObserve,
      'FALLBACK_GROUND_NARRATION': ExperiencePhase.groundRestored,
      'WUMEN_SOUTH_ENDING': ExperiencePhase.wumenSouthEnding,
      'SURVEY': ExperiencePhase.survey,
      'COMPLETED': ExperiencePhase.completed,
    };
    final phase = phases[legacy] ?? ExperiencePhase.ready;
    final dangerous = phase == ExperiencePhase.towerAscend ||
        phase == ExperiencePhase.towerDescend;
    return ProjectSessionSnapshot(
      sessionId: json['sessionId'] as String? ?? 'legacy-session',
      state: ExperienceSessionState(
        phase: phase,
        routeMode:
            json['route'] == 'fallback' ? RouteMode.ground : RouteMode.tower,
        narrationMode:
            dangerous ? NarrationMode.systemPaused : NarrationMode.userPaused,
        safetyInterruption: dangerous
            ? SafetyInterruption(
                kind: phase == ExperiencePhase.towerAscend
                    ? SafetyKind.ascending
                    : SafetyKind.descending,
                returnPhase: phase,
              )
            : null,
      ),
    );
  }

  Map<String, dynamic> toJson() => {
        'schemaVersion': 2,
        'sessionId': sessionId,
        'state': state.toJson(),
        'savedAt': DateTime.now().toUtc().toIso8601String(),
      };
}

abstract interface class ProjectSessionRepository {
  Future<void> save(ProjectSessionSnapshot snapshot);
  Future<ProjectSessionSnapshot?> load();
  Future<void> clear();
}

class LocalProjectSessionRepository implements ProjectSessionRepository {
  static const _name = 'project_session_v2.json';
  Future<File> get _file async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/$_name');
  }

  @override
  Future<void> save(ProjectSessionSnapshot snapshot) async {
    final file = await _file;
    await file.writeAsString(jsonEncode(snapshot.toJson()), flush: true);
  }

  @override
  Future<ProjectSessionSnapshot?> load() async {
    final file = await _file;
    if (!await file.exists()) return null;
    try {
      return ProjectSessionSnapshot.decode(
        jsonDecode(await file.readAsString()) as Map<String, dynamic>,
      );
    } on FormatException {
      return null;
    }
  }

  @override
  Future<void> clear() async {
    final file = await _file;
    if (await file.exists()) await file.delete();
  }
}
