import 'dart:async';

import 'package:flutter/material.dart';

import '../../application/experience_controller.dart';
import '../../app/theme.dart';
import '../../domain/experience_event.dart';
import '../../domain/scene_definition.dart';
import 'scene_renderer.dart';

/// Renders NORMAL_PLATFORM_OBSERVE, NORMAL_PLATFORM_NARRATION,
/// FALLBACK_GROUND_OBSERVE, and FALLBACK_GROUND_NARRATION (Project.md §10.4).
///
/// Displays the scene background image and animates through [VisualLayer]s
/// with staggered fade-ins driven by [VisualLayer.startMs] delays.
///
/// Auto-advances after [SceneDefinition.minimumDurationMs] if
/// [SceneDefinition.autoAdvance] is true; otherwise a "继续" button is
/// shown when `allowedActions` includes `"continue"`.
class LayeredReconstructionRenderer implements SceneRenderer {
  final void Function(ExperienceEvent) onEvent;

  const LayeredReconstructionRenderer({required this.onEvent});

  @override
  Widget build(BuildContext context, SceneViewModel viewModel) {
    return _LayeredView(
      viewModel: viewModel,
      onEvent: onEvent,
    );
  }
}

class _LayeredView extends StatefulWidget {
  final SceneViewModel viewModel;
  final void Function(ExperienceEvent) onEvent;
  const _LayeredView({required this.viewModel, required this.onEvent});

  @override
  State<_LayeredView> createState() => _LayeredViewState();
}

class _LayeredViewState extends State<_LayeredView>
    with TickerProviderStateMixin {
  Timer? _autoAdvanceTimer;
  final Map<int, AnimationController> _controllers = {};
  final Map<int, Animation<double>> _animations = {};

  @override
  void initState() {
    super.initState();
    _setupLayers();
    _setupAutoAdvance();
  }

  @override
  void didUpdateWidget(covariant _LayeredView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.viewModel.scene.id != widget.viewModel.scene.id ||
        oldWidget.viewModel.visualLayers.length !=
            widget.viewModel.visualLayers.length) {
      _clearControllers();
      _setupLayers();
      _cancelAutoAdvance();
      _setupAutoAdvance();
    }
  }

  void _setupLayers() {
    final layers = widget.viewModel.visualLayers;
    for (var i = 0; i < layers.length; i++) {
      final layer = layers[i];
      final controller = AnimationController(
        vsync: this,
        duration: Duration(milliseconds: layer.fadeInMs.clamp(100, 5000)),
      );
      final animation = CurvedAnimation(
        parent: controller,
        curve: Curves.easeIn,
      );
      _controllers[i] = controller;
      _animations[i] = animation;

      // Staggered start
      Future.delayed(Duration(milliseconds: layer.startMs), () {
        if (mounted && _controllers[i] != null) {
          _controllers[i]!.forward();
        }
      });
    }
  }

  void _setupAutoAdvance() {
    final vm = widget.viewModel;
    if (vm.autoAdvance && vm.minimumDurationMs > 0) {
      _autoAdvanceTimer = Timer(
        Duration(milliseconds: vm.minimumDurationMs),
        () {
          if (mounted) {
            widget.onEvent(const TimerElapsed());
          }
        },
      );
    }
  }

  void _cancelAutoAdvance() {
    _autoAdvanceTimer?.cancel();
    _autoAdvanceTimer = null;
  }

  void _clearControllers() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    _controllers.clear();
    _animations.clear();
  }

  @override
  void dispose() {
    _cancelAutoAdvance();
    _clearControllers();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = widget.viewModel;
    final rawBg = vm.scene.background;
    final bgPath = rawBg != null ? 'assets/$rawBg' : null;
    final layers = vm.visualLayers;
    final showContinue = vm.allowedActions.contains('continue');

    return Stack(
      fit: StackFit.expand,
      children: [
        // Background
        if (bgPath != null)
          Image.asset(
            bgPath,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) =>
                Container(color: AppColors.background),
          )
        else
          Container(color: AppColors.background),

        // Layer overlay
        Positioned.fill(
          child: Stack(
            children: [
              for (var i = 0; i < layers.length; i++)
                _buildLayer(context, layers[i], i),
            ],
          ),
        ),

        // "继续" button
        if (showContinue)
          Positioned(
            bottom: 60,
            left: 48,
            right: 48,
            child: SafeArea(
              child: SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    widget.onEvent(
                      const UserAction(UserActionType.continue_),
                    );
                  },
                  child: const Text('继续'),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildLayer(BuildContext context, VisualLayer layer, int index) {
    final animation = _animations[index];
    if (animation == null) return const SizedBox.shrink();

    return Positioned.fill(
      child: FadeTransition(
        opacity: animation,
        child: Image.asset(
          'assets/${layer.asset}',
          fit: BoxFit.cover,
          errorBuilder: (_, error, __) {
            // Graceful fallback: show a placeholder with the asset name.
            return Container(
              color: AppColors.surface.withOpacity(0.6),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.broken_image_rounded,
                      size: 32,
                      color: AppColors.textDisabled,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      layer.asset.split('/').last,
                      style: const TextStyle(
                        color: AppColors.textDisabled,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
