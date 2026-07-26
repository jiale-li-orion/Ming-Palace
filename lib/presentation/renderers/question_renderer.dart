import 'package:flutter/material.dart';

import '../../application/experience_controller.dart';
import '../../app/theme.dart';
import '../../domain/experience_event.dart';
import '../../domain/experience_state.dart';
import '../widgets/audio_controls.dart';
import 'scene_renderer.dart';

/// Renders the QUESTION, QUESTION_BRANCH_FEUDAL, and
/// QUESTION_BRANCH_CLASSICS states (Project.md §10.2).
///
/// - **QUESTION**: shows the binary choice with two large buttons.
/// - **Branch states**: shows audio playing with branch-specific context.
class QuestionRenderer implements SceneRenderer {

  const QuestionRenderer({
    required this.onEvent,
    required this.isPlaying,
    this.onPause,
    this.onResume,
    this.onReplay,
    this.currentPosition = Duration.zero,
    this.duration = Duration.zero,
  });
  final void Function(ExperienceEvent) onEvent;
  final bool isPlaying;
  final VoidCallback? onPause;
  final VoidCallback? onResume;
  final VoidCallback? onReplay;
  final Duration currentPosition;
  final Duration duration;

  @override
  Widget build(BuildContext context, SceneViewModel viewModel) {
    switch (viewModel.state) {
      case ExperienceState.question:
        return _QuestionChoice(onEvent: onEvent);
      case ExperienceState.questionBranchFeudal:
      case ExperienceState.questionBranchClassics:
        return _QuestionBranch(
          onEvent: onEvent,
          viewModel: viewModel,
          isPlaying: isPlaying,
          onPause: onPause,
          onResume: onResume,
          onReplay: onReplay,
          currentPosition: currentPosition,
          duration: duration,
        );
      default:
        return const SizedBox.shrink();
    }
  }
}

// ---------------------------------------------------------------------------
// Binary choice
// ---------------------------------------------------------------------------

class _QuestionChoice extends StatelessWidget {
  const _QuestionChoice({required this.onEvent});
  final void Function(ExperienceEvent) onEvent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
        child: Column(
          children: [
            const Spacer(),
            Text(
              '你同意他们吗？',
              style: theme.textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 48),
            SizedBox(
              width: double.infinity,
              height: 72,
              child: ElevatedButton(
                onPressed: () {
                  onEvent(const UserAction(UserActionType.chooseFeudal));
                },
                child: const Text(
                  '为什么急着削藩？',
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 72,
              child: ElevatedButton(
                onPressed: () {
                  onEvent(const UserAction(UserActionType.chooseClassics));
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.surfaceVariant,
                ),
                child: const Text(
                  '为什么太看重经典和文字？',
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Branch audio playback
// ---------------------------------------------------------------------------

class _QuestionBranch extends StatelessWidget {

  const _QuestionBranch({
    required this.onEvent,
    required this.viewModel,
    required this.isPlaying,
    this.onPause,
    this.onResume,
    this.onReplay,
    required this.currentPosition,
    required this.duration,
  });
  final void Function(ExperienceEvent) onEvent;
  final SceneViewModel viewModel;
  final bool isPlaying;
  final VoidCallback? onPause;
  final VoidCallback? onResume;
  final VoidCallback? onReplay;
  final Duration currentPosition;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    final hasAudio = viewModel.activeAudioAsset != null;
    final showContinue = viewModel.allowedActions.contains('continue');
    final label = viewModel.state == ExperienceState.questionBranchFeudal
        ? '削藩之辩'
        : '经典之辩';

    return SafeArea(
      child: Column(
        children: [
          // Branch label
          Padding(
            padding: const EdgeInsets.only(top: 24),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.primaryLight,
                    ),
              ),
            ),
          ),

          const Spacer(),

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

          // "继续" button
          if (showContinue)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 48),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    onEvent(const UserAction(UserActionType.continue_));
                  },
                  child: const Text('继续'),
                ),
              ),
            ),

          const SizedBox(height: 48),
        ],
      ),
    );
  }
}
