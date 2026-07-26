import 'package:flutter/material.dart';

import '../../application/experience_controller.dart';
import '../../domain/experience_event.dart';
import '../../domain/experience_state.dart';
import 'scene_renderer.dart';

/// Renders NORMAL_ASCEND and NORMAL_DESCEND (Project.md §10.3).
///
/// Black screen with no decorations, audio, or narrative content.
/// Only a large centered safety prompt and a direction hint.
/// "我已到达" button at the bottom advances the experience.
class SafetyRenderer implements SceneRenderer {
  final void Function(ExperienceEvent) onEvent;

  const SafetyRenderer({required this.onEvent});

  @override
  Widget build(BuildContext context, SceneViewModel viewModel) {
    final isAscending = viewModel.state == ExperienceState.normalAscend;
    final directionText = isAscending ? '上楼' : '下楼';
    final icon =
        isAscending ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded;

    return SafeArea(
      child: Container(
        color: Colors.black,
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      icon,
                      size: 64,
                      color: Colors.white.withOpacity(0.3),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      directionText,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w500,
                        color: Colors.white54,
                      ),
                    ),
                    const SizedBox(height: 32),
                    const Text(
                      '请看脚下',
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 4,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // "我已到达" button
            Padding(
              padding: const EdgeInsets.all(32),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    onEvent(const UserAction(UserActionType.arrived));
                  },
                  child: const Text('我已到达'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
