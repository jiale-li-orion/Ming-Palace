import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';

import '../../app/theme.dart';
import '../../application/audio_controller.dart';
import '../../application/experience_controller.dart';
import '../../application/operator_controller.dart';
import '../../domain/experience_event.dart';
import '../../infrastructure/local_content_repository.dart';
import '../../infrastructure/export_service.dart';
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
import '../widgets/resume_prompt.dart';
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

  const ExperienceScreen({
    required this.engine,
    required this.audioController,
    super.key,
  });
  final ExperienceEngine engine;
  final AudioController audioController;

  @override
  State<ExperienceScreen> createState() => _ExperienceScreenState();
}

class _ExperienceScreenState extends State<ExperienceScreen>
    with WidgetsBindingObserver {
  // -- operator panel ----------------------------------------------------------
  late final OperatorController _operatorController;
  final ExportService _exportService = ExportService();

  // -- audio tracking ---------------------------------------------------------
  String? _lastAudioAsset;
  bool _isPlaying = false;
  Duration _audioPosition = Duration.zero;
  Duration _audioDuration = Duration.zero;

  StreamSubscription<PlayerState>? _playerStateSub;
  StreamSubscription<void>? _audioCompleteSub;
  Timer? _autoTimer;
  Map<String, dynamic>? _pendingSnapshot;
  String? _audioError;
  bool _suppressAutoplay = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _operatorController = OperatorController(
      widget.engine,
      onReplayAudio: _audioReplay,
      onExportLog: _exportLogs,
      onViewLog: _viewLogs,
      onClearData: widget.engine.clearAllData,
    );
    widget.audioController.onPauseCallback = (position) {
      unawaited(widget.engine.saveCurrentState(position.inMilliseconds));
    };

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
      widget.engine.recordAudioEvent('audio_completed', payload: {
        'asset': _lastAudioAsset,
      });
      widget.engine.handleEvent(const AudioCompleted());
    });

    _initialize();
  }

  @override
  void dispose() {
    _autoTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
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
      final result = await widget.engine.initialize();
      if (result.isErr) {
        widget.engine.recordAppError(
          'content_load_failed',
          detail: result.errValue!.message,
        );
      }
    }
    if (widget.engine.isInitialized && widget.engine.lastError == null) {
      final saved = await widget.engine.loadSavedState();
      if (saved.isOk && saved.okValue != null) {
        if (mounted) {
          setState(() => _pendingSnapshot = saved.okValue);
        }
      } else {
        final sessionResult = await widget.engine.startSession();
        if (sessionResult.isErr && mounted) {
          widget.engine.reportError(sessionResult.errValue!.message);
        }
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      unawaited(_pauseAndPersist());
    }
  }

  Future<void> _pauseAndPersist() async {
    if (widget.audioController.isPlaying) {
      widget.engine.recordAudioEvent('audio_paused', payload: {
        'asset': _lastAudioAsset,
        'positionMs': widget.audioController.currentPosition.inMilliseconds,
        'reason': 'app_lifecycle',
      });
      await widget.audioController.pause();
    }
    await widget.engine.saveCurrentState(
      widget.audioController.currentPosition.inMilliseconds,
    );
  }

  Future<void> _resumeSavedSession() async {
    final snapshot = _pendingSnapshot;
    if (snapshot == null) return;
    _suppressAutoplay = true;
    await widget.engine.resumeSavedState(snapshot);
    if (mounted) setState(() => _pendingSnapshot = null);
    final asset = snapshot['audioAsset'] as String?;
    if (asset != null) {
      await _playAudio(asset, autoplay: false);
      await widget.audioController.seek(
        Duration(milliseconds: widget.engine.restoredAudioPositionMs),
      );
    }
    _suppressAutoplay = false;
  }

  Future<void> _discardSavedSession() async {
    final result = await widget.engine.abandonSavedState();
    if (result.isErr) {
      widget.engine.reportError(result.errValue!.message);
      return;
    }
    if (mounted) setState(() => _pendingSnapshot = null);
  }

  // --------------------------------------------------------------------------
  // Audio side effects  (fire-and-forget)
  // --------------------------------------------------------------------------

  void _onEngineChanged() {
    final vm = widget.engine.sceneViewModel;
    if (vm == null) return;

    // Play new audio when the asset changes.
    final asset = vm.activeAudioAsset;
    if (!_suppressAutoplay && asset != null && asset != _lastAudioAsset) {
      _lastAudioAsset = asset;
      unawaited(_playAudio(asset));
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

  Future<void> _playAudio(String asset, {bool autoplay = true}) async {
    try {
      await widget.audioController.play(asset, autoplay: autoplay);
      widget.engine.recordAudioEvent(
        autoplay ? 'audio_started' : 'audio_loaded',
        payload: {'asset': asset},
      );
      if (mounted && _audioError != null) {
        setState(() => _audioError = null);
      }
    } catch (error) {
      widget.engine.recordAppError(
        'audio_load_failed',
        detail: '$asset: $error',
      );
      if (mounted) {
        setState(() {
          _audioError = '音频暂缺，可继续体验';
          _isPlaying = false;
        });
      }
    }
  }

  void _handleEvent(ExperienceEvent event) {
    if (event is UserAction && event.action == UserActionType.export_) {
      unawaited(_exportLogs(sessionOnly: true));
      return;
    }
    if (event is UserAction && event.action == UserActionType.restart) {
      unawaited(widget.engine.startSession());
      return;
    }
    widget.engine.handleEvent(event);
  }

  Future<void> _exportLogs({bool sessionOnly = false}) async {
    final dir = await getApplicationDocumentsDirectory();
    final stamp = DateTime.now()
        .toUtc()
        .toIso8601String()
        .replaceAll(RegExp(r'[:.]'), '-');
    final suffix = sessionOnly && widget.engine.sessionId != null
        ? '-${widget.engine.sessionId!.substring(0, 8)}'
        : '-all';
    final path = '${dir.path}/ming-palace$suffix-$stamp.json';
    final result = await _exportService.exportAsJson(
      path,
      sessionId: sessionOnly ? widget.engine.sessionId : null,
    );
    if (!mounted) return;
    if (result.isErr) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('导出失败，请重试')),
      );
      return;
    }
    final shareResult = await _exportService.shareExport(path);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          shareResult.isOk ? '导出文件已生成' : '文件已保存，但无法打开分享面板',
        ),
      ),
    );
  }

  Future<void> _viewLogs() async {
    final result = await widget.engine.loadTelemetry();
    if (!mounted) return;
    final events = result.okValue ?? const <Map<String, dynamic>>[];
    final recent =
        events.length > 12 ? events.sublist(events.length - 12) : events;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('最近日志（${events.length} 条）'),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: SelectableText(
              recent.isEmpty
                  ? '暂无日志'
                  : const JsonEncoder.withIndent('  ').convert(recent),
              style: const TextStyle(fontSize: 11),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  // Called by audio-control callbacks on the question renderer.  These are
  // late-bound via the renderer's direct parameters; we also update the
  // question renderer every frame so the `_isPlaying` values are current.
  void _audioPause() {
    widget.engine.recordAudioEvent('audio_paused', payload: {
      'asset': _lastAudioAsset,
      'positionMs': widget.audioController.currentPosition.inMilliseconds,
      'reason': 'user',
    });
    unawaited(widget.audioController.pause());
  }

  void _audioResume() {
    widget.engine.recordAudioEvent('audio_resumed', payload: {
      'asset': _lastAudioAsset,
      'positionMs': widget.audioController.currentPosition.inMilliseconds,
    });
    unawaited(widget.audioController.resume());
  }

  void _audioReplay() {
    widget.engine.recordAudioEvent('audio_replayed', payload: {
      'asset': _lastAudioAsset,
    });
    unawaited(widget.audioController.replay());
  }

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
              if (_audioError != null)
                Positioned(
                  top: 8,
                  left: 16,
                  right: 16,
                  child: Material(
                    color: AppColors.error,
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(
                        _audioError!,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
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
    if (_pendingSnapshot != null) {
      return ResumePrompt(
        onResume: () => unawaited(_resumeSavedSession()),
        onDiscard: () => unawaited(_discardSavedSession()),
      );
    }
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
          onEvent: _handleEvent,
        ).build(context, vm);

      case 'narrative':
        return NarrativeRenderer(
          onEvent: _handleEvent,
          isPlaying: _isPlaying,
          onPause: _audioPause,
          onResume: _audioResume,
          onReplay: _audioReplay,
          currentPosition: _audioPosition,
          duration: _audioDuration,
        ).build(context, vm);

      case 'layered_reconstruction':
        return LayeredReconstructionRenderer(
          onEvent: _handleEvent,
          onAssetError: (asset) => widget.engine.recordAppError(
            'image_load_failed',
            detail: asset,
          ),
        ).build(context, vm);

      case 'question':
        // Re-create to pass fresh playback state.
        return QuestionRenderer(
          onEvent: _handleEvent,
          isPlaying: _isPlaying,
          onPause: _audioPause,
          onResume: _audioResume,
          onReplay: _audioReplay,
          currentPosition: _audioPosition,
          duration: _audioDuration,
        ).build(context, vm);

      case 'survey':
        return SurveyRenderer(
          onEvent: _handleEvent,
        ).build(context, vm);

      case 'safety':
        return SafetyRenderer(
          onEvent: _handleEvent,
        ).build(context, vm);

      case 'completed':
        return CompletedRenderer(
          onEvent: _handleEvent,
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
