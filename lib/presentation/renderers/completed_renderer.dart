import 'package:flutter/material.dart';

import '../../application/experience_controller.dart';
import '../../app/theme.dart';
import '../../domain/experience_event.dart';
import 'scene_renderer.dart';

/// Renders the COMPLETED state (Project.md §10.5).
///
/// Shows a session-end summary with export and restart options.
class CompletedRenderer implements SceneRenderer {
  final void Function(ExperienceEvent) onEvent;
  final String? routeName;
  final String? questionChoice;
  final String? sessionId;

  const CompletedRenderer({
    required this.onEvent,
    this.routeName,
    this.questionChoice,
    this.sessionId,
  });

  @override
  Widget build(BuildContext context, SceneViewModel viewModel) {
    final theme = Theme.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
        child: Column(
          children: [
            const Spacer(),
            // Checkmark icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_rounded,
                size: 44,
                color: AppColors.primaryLight,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              '体验完成',
              style: theme.textTheme.displayLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            // Session summary
            if (sessionId != null) _SummaryRow(label: '会话', value: _shortId(sessionId!)),
            if (routeName != null) _SummaryRow(label: '路线', value: routeName!),
            if (questionChoice != null)
              _SummaryRow(
                label: '选择',
                value: questionChoice == 'feudal' ? '削藩之辩' : '经典之辩',
              ),

            const Spacer(),

            // Export button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () {
                  onEvent(const UserAction(UserActionType.export_));
                },
                child: const Text('保存并导出'),
              ),
            ),
            const SizedBox(height: 12),
            // Restart button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: OutlinedButton(
                onPressed: () {
                  onEvent(const UserAction(UserActionType.restart));
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textSecondary,
                  side: const BorderSide(color: AppColors.divider),
                ),
                child: const Text('重新开始'),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  String _shortId(String id) => id.length > 8 ? id.substring(0, 8) : id;
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  const _SummaryRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Text(
            '$label：',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}
