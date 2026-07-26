import 'dart:async';

import '../domain/experience_session_state.dart';
import '../domain/narration_segment.dart';
import 'audio_controller.dart';
import 'project_experience_engine.dart';

class NarrationTimeline {
  const NarrationTimeline(this.segments);
  final List<NarrationSegment> segments;

  NarrationSegment? segmentAt(Duration position) {
    final milliseconds = position.inMilliseconds;
    for (final segment in segments) {
      if (milliseconds >= segment.startMs && milliseconds < segment.endMs) {
        return segment;
      }
    }
    return segments.isEmpty ? null : segments.last;
  }

  Duration boundaryFor(Duration position) => Duration(
        milliseconds: segmentAt(position)?.startMs ?? 0,
      );
}

class ProjectAudioCoordinator {
  ProjectAudioCoordinator({required this.engine, required this.audio});
  final ProjectExperienceEngine engine;
  final AudioController audio;
  StreamSubscription<Duration>? _position;
  StreamSubscription<void>? _completed;
  ExperiencePhase? _phase;
  NarrationMode? _mode;
  String? _loadedAsset;
  bool _handling = false;

  static const _tracks = <ExperiencePhase, _NarrationTrack>{
    ExperiencePhase.fengtianStart: _NarrationTrack(
      'audio/temp_v1/01_fengtian_start.mp3',
      NarrationTimeline([
        NarrationSegment(
            id: 'fengtian-s01',
            startMs: 0,
            endMs: 5904,
            subtitle: '你现在站的地方，从前在我的宫城里。',
            evidenceIds: ['E-A-001', 'E-C-001'])
      ]),
    ),
    ExperiencePhase.walkToWumen: _NarrationTrack(
      'audio/temp_v1/02_walk_to_wumen.mp3',
      NarrationTimeline([
        NarrationSegment(
            id: 'walk-s01',
            startMs: 0,
            endMs: 4776,
            subtitle: '沿着宫城正中的御道，一座接一座排开。',
            evidenceIds: ['E-A-002', 'E-C-002'])
      ]),
    ),
    ExperiencePhase.wumenArrival: _NarrationTrack(
      'audio/temp_v1/03_wumen_arrival.mp3',
      NarrationTimeline([
        NarrationSegment(
            id: 'arrival-s01',
            startMs: 0,
            endMs: 6360,
            subtitle: '前面是午门。我在位时，它曾改称端门。',
            evidenceIds: ['E-A-003'])
      ]),
    ),
    ExperiencePhase.platformRestored: _NarrationTrack(
      'audio/temp_v1/04_platform_restored.mp3',
      NarrationTimeline([
        NarrationSegment(
            id: 'platform-s01',
            startMs: 0,
            endMs: 6200,
            subtitle: '中间最大的是奉天殿。两侧有楼，右边是文楼，左边是武楼。',
            evidenceIds: ['E-A-004', 'E-B-001']),
        NarrationSegment(
            id: 'platform-s02',
            startMs: 6200,
            endMs: 12168,
            subtitle: '我很喜欢在较小的便殿里，召来学士讨论《周礼》。',
            evidenceIds: ['E-B-002', 'E-C-003']),
      ]),
    ),
    ExperiencePhase.questionAnswer: _NarrationTrack(
      'audio/temp_v1/05_question_answer.mp3',
      NarrationTimeline([
        NarrationSegment(
            id: 'answer-s01',
            startMs: 0,
            endMs: 6480,
            subtitle: '决定仍归我。我的本意，不能替结果开脱。',
            evidenceIds: ['E-B-003'])
      ]),
    ),
    ExperiencePhase.groundRestored: _NarrationTrack(
      'audio/temp_v1/06_ground_restored.mp3',
      NarrationTimeline([
        NarrationSegment(
            id: 'ground-s01',
            startMs: 0,
            endMs: 6624,
            subtitle: '这是地面固定视点的绘画化空间复原，不模拟城台俯视。',
            evidenceIds: ['E-C-004'])
      ]),
    ),
    ExperiencePhase.wumenSouthEnding: _NarrationTrack(
      'audio/temp_v1/07_wumen_south_ending.mp3',
      NarrationTimeline([
        NarrationSegment(
            id: 'ending-s01',
            startMs: 0,
            endMs: 8112,
            subtitle: '不必把你刚才走过的路，当作我的逃路。',
            evidenceIds: ['E-C-005'])
      ]),
    ),
  };

  void start() {
    engine.addListener(_onEngineChanged);
    _position = audio.positionStream.listen((position) {
      final segment = _tracks[engine.state.phase]?.timeline.segmentAt(position);
      if (segment != null) engine.setCurrentSegment(segment.id);
    });
    _completed = audio.onCompleted.listen((_) {
      engine.advance();
    });
    _onEngineChanged();
  }

  void _onEngineChanged() {
    if (_handling) return;
    final state = engine.state;
    final track = _tracks[state.phase];
    if (_phase != state.phase) {
      _phase = state.phase;
      _mode = null;
      if (track == null) {
        unawaited(audio.stop());
        _loadedAsset = null;
        return;
      }
    }
    if (_mode == state.narrationMode) return;
    _mode = state.narrationMode;
    _handling = true;
    unawaited(
        _applyAudioState(state, track).whenComplete(() => _handling = false));
  }

  Future<void> _applyAudioState(
    ExperienceSessionState state,
    _NarrationTrack? track,
  ) async {
    if (track == null) return;
    try {
      if (state.narrationMode == NarrationMode.playing) {
        if (_loadedAsset != track.asset) {
          _loadedAsset = track.asset;
          await audio.play(track.asset);
        } else {
          await audio.resume();
        }
      } else if (state.narrationMode == NarrationMode.userPaused ||
          state.narrationMode == NarrationMode.systemPaused) {
        if (audio.isPlaying) await audio.pause();
      }
    } on Object {
      engine.systemPauseNarration();
    }
  }

  Future<void> dispose() async {
    engine.removeListener(_onEngineChanged);
    await _position?.cancel();
    await _completed?.cancel();
    await audio.dispose();
  }
}

class _NarrationTrack {
  const _NarrationTrack(this.asset, this.timeline);
  final String asset;
  final NarrationTimeline timeline;
}
