import 'package:flutter/material.dart';

import '../../application/experience_controller.dart';
import '../../app/theme.dart';
import '../../domain/experience_event.dart';
import '../../domain/experience_state.dart';
import '../widgets/audio_controls.dart';
import 'scene_renderer.dart';

/// Renders walking and stationary narrative states (Project.md §10.2).
///
/// Covers: FENGTIAN_NORTH, WALK_TO_WUMEN, WUMEN_NORTH, QUESTION_MERGE,
/// WALK_THROUGH_WUMEN, WUMEN_SOUTH_ENDING, ENDING_AMBIENCE.
///
/// Walking states show a location hint and "我已到达" button.
/// Stationary states show background + "继续" button.
/// Both show audio controls when an audio asset is assigned.
class NarrativeRenderer implements SceneRenderer {
  final void Function(ExperienceEvent) onEvent;
  final bool isPlaying;
  final VoidCallback? onPause;
  final VoidCallback? onResume;
  final VoidCallback? onReplay;
  final Duration currentPosition;
  final Duration duration;

  const NarrativeRenderer({
    required this.onEvent,
    required this.isPlaying,
    this.onPause,
    this.onResume,
    this.onReplay,
    this.currentPosition = Duration.zero,
    this.duration = Duration.zero,
  });

  @override
  Widget build(BuildContext context, SceneViewModel viewModel) {
    final rawBg = viewModel.scene.background;
    final bgPath = rawBg != null ? 'assets/$rawBg' : null;
    final hasAudio = viewModel.activeAudioAsset != null;
    final showArrived =
        viewModel.isWalking && viewModel.allowedActions.contains('arrived');
    final showContinue =
        !viewModel.isWalking && viewModel.allowedActions.contains('continue');

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

        // Dark overlay for readability
        Container(color: Colors.black.withOpacity(0.35)),

        // Content
        SafeArea(
          child: Column(
            children: [
              // Audio status indicator
              if (hasAudio) _AudioStatusBar(isPlaying: isPlaying),

              const Spacer(),

              // Location hint for walking
              if (viewModel.isWalking)
                _LocationHint(
                  text: viewModel.state.isWalkingState
                      ? _stateHint(viewModel)
                      : '',
                ),

              // Audio controls
              if (hasAudio)
                AudioControls(
                  isPlaying: isPlaying,
                  onPause: onPause,
                  onResume: onResume,
                  onReplay: onReplay,
                  currentPosition: currentPosition,
                  duration: duration,
                ),

              const SizedBox(height: 16),

              // Action buttons
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 48),
                child: Column(
                  children: [
                    if (showArrived)
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: () {
                            onEvent(const UserAction(UserActionType.arrived));
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryLight,
                          ),
                          child: const Text('我已到达'),
                        ),
                      ),
                    if (showContinue)
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: () {
                            onEvent(const UserAction(UserActionType.continue_));
                          },
                          child: const Text('继续'),
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 48),
            ],
          ),
        ),
      ],
    );
  }

  /// Returns a human-readable location hint for each walking state.
  String _stateHint(SceneViewModel viewModel) {
    switch (viewModel.state) {
      case ExperienceState.walkToWumen:
        return '请走向午门北侧';
      case ExperienceState.normalAscend:
        return '请上楼';
      case ExperienceState.normalDescend:
        return '请下楼';
      case ExperienceState.walkThroughWumen:
        return '请穿过午门门洞';
      default:
        return '';
    }
  }
}

// ---------------------------------------------------------------------------
// Helper widgets
// ---------------------------------------------------------------------------

class _AudioStatusBar extends StatelessWidget {
  final bool isPlaying;
  const _AudioStatusBar({required this.isPlaying});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color:
                  isPlaying ? AppColors.primaryLight : AppColors.textDisabled,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            isPlaying ? '音频播放中' : '音频已暂停',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: isPlaying
                      ? AppColors.primaryLight
                      : AppColors.textDisabled,
                ),
          ),
        ],
      ),
    );
  }
}

class _LocationHint extends StatelessWidget {
  final String text;
  const _LocationHint({required this.text});

  @override
  Widget build(BuildContext context) {
    if (text.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surface.withOpacity(0.85),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.primary.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.navigation_rounded,
              color: AppColors.primaryLight,
              size: 22,
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                text,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
