import 'dart:async';

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

import '../../app/theme.dart';
import '../../application/audio_controller.dart';
import '../../application/experience_controller.dart';
import '../../application/operator_controller.dart';
import '../../domain/experience_event.dart';
import '../../infrastructure/local_content_repository.dart';
import '../../infrastructure/local_session_repository.dart';
import '../../infrastructure/local_telemetry_repository.dart';
import '../operator/operator_panel.dart';
import '../renderers/completed_renderer.dart';
import '../renderers/instruction_renderer.dart';
import '../renderers/layered_reconstruction_renderer.dart';
import '../renderers/narrative_renderer.dart';
import '../renderers/question_renderer.dart';
import '../renderers/safety_renderer.dart';
import '../renderers/survey_renderer.dart';
import 'error_screen.dart';

// ============================================================================
// ExperienceScreen — main controller screen
// ============================================================================

/// Observes [ExperienceEngine] via [ListenableBuilder] and swaps its child
/// content per the current [SceneViewModel.rendererType].
///
/// Wires audio lifecycle (play on state enter, pause/resume/replay) and
/// auto-advance timers.  Also provides 7-tap operator-panel access.
class ExperienceScreen extends StatefulWidget {
  final ExperienceEngine engine;
  final AudioController audioController;

  const ExperienceScreen({
    required this.engine,
    required this.audioController,
    super.key,
  });

  @override
  State<ExperienceScreen> createState() => _ExperienceScreenState();
}

class _ExperienceScreenState extends State<ExperienceScreen> {
  // -- operator panel ----------------------------------------------------------
  late final OperatorController _operatorController;

  // -- audio tracking ---------------------------------------------------------
  String? _lastAudioAsset;
  bool _isPlaying = false;
  Duration _audioPosition = Duration.zero;
  Duration _audioDuration = Duration.zero;

  StreamSubscription<PlayerState>? _playerStateSub;
  StreamSubscription<void>? _audioCompleteSub;
  Timer? _autoTimer;

  @override
  void initState() {
    super.initState();

    _operatorController = OperatorController(widget.engine);

    // Wire engine change listener for audio + timer side effects.
    widget.engine.addListener(_onEngineChanged);

    // Listen to audio player state for UI updates.
    _playerStateSub = widget.audioController.playerStateStream.listen((ps) {
      if (!mounted) return;
      setState(() {
        _isPlaying = ps.playing;
        _audioPosition = widget.audioController.currentPosition;
        _audioDuration = widget.audioController.duration;
      });
    });

    // Wire audio completion → engine.
    _audioCompleteSub = widget.audioController.onCompleted.listen((_) {
      if (!mounted) return;
      widget.engine.handleEvent(const AudioCompleted());
    });

    _initialize();
  }

  @override
  void dispose() {
    _autoTimer?.cancel();
    _playerStateSub?.cancel();
    _audioCompleteSub?.cancel();
    _operatorController.dispose();
    widget.engine.removeListener(_onEngineChanged);
    super.dispose();
  }

  // --------------------------------------------------------------------------
  // Initialisation
  // --------------------------------------------------------------------------

  Future<void> _initialize() async {
    if (!widget.engine.isInitialized) {
      await widget.engine.initialize();
    }
    if (widget.engine.isInitialized && widget.engine.lastError == null) {
      final sessionResult = await widget.engine.startSession();
      if (sessionResult.isErr && mounted) {
        widget.engine.reportError(sessionResult.errValue!.message);
      }
    }
  }

  // --------------------------------------------------------------------------
  // Audio side effects  (fire-and-forget)
  // --------------------------------------------------------------------------

  void _onEngineChanged() {
    final vm = widget.engine.sceneViewModel;
    if (vm == null) return;

    // Play new audio when the asset changes.
    final asset = vm.activeAudioAsset;
    if (asset != null && asset != _lastAudioAsset) {
      _lastAudioAsset = asset;
      widget.audioController.play(asset);
    }

    // Manage auto-advance timer.
    _autoTimer?.cancel();
    _autoTimer = null;
    if (vm.autoAdvance && vm.minimumDurationMs > 0) {
      _autoTimer = Timer(Duration(milliseconds: vm.minimumDurationMs), () {
        if (mounted) {
          widget.engine.handleEvent(const TimerElapsed());
        }
      });
    }
  }

  // Called by audio-control callbacks on the question renderer.  These are
  // late-bound via the renderer's direct parameters; we also update the
  // question renderer every frame so the `_isPlaying` values are current.
  void _audioPause() => widget.audioController.pause();
  void _audioResume() => widget.audioController.resume();
  void _audioReplay() => widget.audioController.replay();

  // --------------------------------------------------------------------------
  // Build
  // --------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.engine,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: GestureDetector(
              onTap: () => _operatorController.incrementTapCount(),
              child: const Text('明故宫 · 朱允炆'),
            ),
          ),
          body: Stack(
            fit: StackFit.expand,
            children: [
              _buildBody(),
              // Operator panel overlay
              if (_operatorController.isPanelVisible)
                OperatorPanel(
                  controller: _operatorController,
                  engine: widget.engine,
                ),
            ],
          ),
        );
      },
    );
  }

  // --------------------------------------------------------------------------
  // Body dispatch
  // --------------------------------------------------------------------------

  Widget _buildBody() {
    // Error — content load failed and no scene data is available.
    // Check this BEFORE the initialization spinner so a failed init
    // shows the error screen instead of a permanent spinner (C2).
    if (widget.engine.lastError != null &&
        widget.engine.sceneViewModel == null) {
      return ErrorScreen(
        message: widget.engine.lastError!,
        onRetry: _initialize,
        onExportLog: () {
          widget.engine.handleEvent(
            const OperatorAction(OperatorActionType.exportLog),
          );
        },
      );
    }

    // Loading — content has not finished loading.
    if (!widget.engine.isInitialized) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primaryLight),
      );
    }

    final vm = widget.engine.sceneViewModel;
    if (vm == null) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primaryLight),
      );
    }

    return _buildRendererFor(vm);
  }

  /// Instantiate (or update) the correct renderer for [vm.rendererType].
  Widget _buildRendererFor(SceneViewModel vm) {
    switch (vm.rendererType) {
      case 'instruction':
        return InstructionRenderer(
          onEvent: widget.engine.handleEvent,
        ).build(context, vm);

      case 'narrative':
        return NarrativeRenderer(
          onEvent: widget.engine.handleEvent,
          isPlaying: _isPlaying,
          onPause: _audioPause,
          onResume: _audioResume,
          onReplay: _audioReplay,
          currentPosition: _audioPosition,
          duration: _audioDuration,
        ).build(context, vm);

      case 'layered_reconstruction':
        return LayeredReconstructionRenderer(
          onEvent: widget.engine.handleEvent,
        ).build(context, vm);

      case 'question':
        // Re-create to pass fresh playback state.
        return QuestionRenderer(
          onEvent: widget.engine.handleEvent,
          isPlaying: _isPlaying,
          onPause: _audioPause,
          onResume: _audioResume,
          onReplay: _audioReplay,
          currentPosition: _audioPosition,
          duration: _audioDuration,
        ).build(context, vm);

      case 'survey':
        return SurveyRenderer(
          onEvent: widget.engine.handleEvent,
        ).build(context, vm);

      case 'safety':
        return SafetyRenderer(
          onEvent: widget.engine.handleEvent,
        ).build(context, vm);

      case 'completed':
        return CompletedRenderer(
          onEvent: widget.engine.handleEvent,
          routeName: widget.engine.currentRoute.isFallback ? '替代路线' : '正常路线',
          questionChoice: widget.engine.questionChoice,
          sessionId: widget.engine.sessionId,
        ).build(context, vm);

      default:
        return Center(
          child: Text(
            '未知渲染器: ${vm.rendererType}',
            style: const TextStyle(color: AppColors.textDisabled),
          ),
        );
    }
  }
}

// ============================================================================
// ExperienceApp — dependency-injection wrapper
// ============================================================================

/// Creates and owns the [ExperienceEngine] and [AudioController] lifecycle.
///
/// This wrapper is instantiated by [MingPalaceApp] as the app's home screen
/// so that the app.dart file stays clean.  The engine's repositories are
/// wired to their local-filesystem implementations here.
class ExperienceApp extends StatefulWidget {
  const ExperienceApp({super.key});

  @override
  State<ExperienceApp> createState() => _ExperienceAppState();
}

class _ExperienceAppState extends State<ExperienceApp> {
  late final ExperienceEngine _engine;
  late final AudioController _audioController;

  @override
  void initState() {
    super.initState();
    _engine = ExperienceEngine(
      contentRepository: LocalContentRepository(),
      telemetryRepository: LocalTelemetryRepository(),
      sessionRepository: LocalSessionRepository(),
    );
    _audioController = AudioController();
  }

  @override
  void dispose() {
    _audioController.dispose();
    _engine.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ExperienceScreen(
      engine: _engine,
      audioController: _audioController,
    );
  }
}
