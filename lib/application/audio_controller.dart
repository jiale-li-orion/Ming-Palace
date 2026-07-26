import 'dart:async';

import 'package:just_audio/just_audio.dart';

/// Audio playback controller (Project.md §5.3).
///
/// Wraps the `just_audio` [AudioPlayer] and exposes a simple API driven by
/// asset paths like `"audio/01_fengtian_north.mp3"`.  All paths are resolved
/// to Flutter asset-bundle paths automatically.
///
/// ## Lifecycle hooks
///
/// Assign [onPauseCallback] to persist the current position before the
/// player is paused; the UI layer can supply the saved position back
/// via [seek] when the app resumes.
///
/// ## Completion detection
///
/// Subscribe to [onCompleted] to trigger auto-advance in the experience
/// engine when a narration track finishes.
class AudioController {

  // ---- construction / disposal -------------------------------------------

  AudioController() {
    _processingSubscription = _player.processingStateStream.listen((state) {
      if (state == ProcessingState.completed && !_disposed) {
        _completionController.add(null);
      }
    });
  }
  final AudioPlayer _player = AudioPlayer();
  final StreamController<void> _completionController =
      StreamController<void>.broadcast();
  StreamSubscription<ProcessingState>? _processingSubscription;
  bool _disposed = false;

  // ---- lifecycle callback ------------------------------------------------

  /// Called before the player pauses; receives the current [Duration] so
  /// the caller can persist it for app-resume restoration.
  void Function(Duration position)? onPauseCallback;

  // ---- public streams & properties ----------------------------------------

  /// Stream of playback-state changes (playing, paused, completed, …).
  Stream<PlayerState> get playerStateStream => _player.playerStateStream;
  Stream<Duration> get positionStream => _player.positionStream;

  /// Whether audio is currently playing.
  bool get isPlaying => _player.playing;

  /// Current playback position.
  Duration get currentPosition => _player.position;

  /// Total duration of the loaded audio, or [Duration.zero] when unknown.
  Duration get duration => _player.duration ?? Duration.zero;

  /// Broadcast stream that fires once each time a track finishes playback.
  Stream<void> get onCompleted => _completionController.stream;

  /// Releases all resources.  After calling this the instance must not be
  /// used again.
  Future<void> dispose() async {
    _disposed = true;
    await _processingSubscription?.cancel();
    await _completionController.close();
    await _player.dispose();
  }

  // ---- public API ---------------------------------------------------------

  /// Loads and starts playback of [assetPath].
  ///
  /// Path resolution rules:
  /// - `"assets/audio/…"`  — used as-is
  /// - `"audio/…"`         — prepends `assets/`
  /// - anything else       — prepends `assets/audio/`
  Future<void> play(String assetPath, {bool autoplay = true}) async {
    final resolved = _resolveAssetPath(assetPath);
    await _player.setAsset(resolved);
    if (autoplay) await _player.play();
  }

  /// Pauses playback and fires [onPauseCallback] if set.
  Future<void> pause() async {
    onPauseCallback?.call(_player.position);
    await _player.pause();
  }

  /// Resumes playback from the current position.
  Future<void> resume() async => _player.play();

  /// Stops playback and resets to the beginning.
  Future<void> stop() async {
    await _player.stop();
  }

  /// Seeks to the beginning and starts playing.
  Future<void> replay() async {
    await _player.seek(Duration.zero);
    await _player.play();
  }

  /// Seeks to an arbitrary [position].
  Future<void> seek(Duration position) async {
    await _player.seek(position);
  }

  // ---- helpers ------------------------------------------------------------

  /// Converts a short asset path to a full Flutter asset-bundle path.
  String _resolveAssetPath(String path) {
    if (path.startsWith('assets/')) return path;
    if (path.startsWith('audio/')) return 'assets/$path';
    return 'assets/audio/$path';
  }
}
