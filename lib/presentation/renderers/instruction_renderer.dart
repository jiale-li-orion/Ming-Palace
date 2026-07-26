import 'package:flutter/material.dart';

import '../../application/experience_controller.dart';
import '../../app/theme.dart';
import '../../domain/experience_event.dart';
import '../../domain/experience_state.dart';
import 'scene_renderer.dart';

/// Renders the INTRO and WAIT_FOR_ROUTE_DECISION states (Project.md §10.1).
///
/// - **INTRO** / **READY**: welcome screen with experience summary and a
///   "开始测试" button that fires [UserAction.startTest].
/// - **WAIT_FOR_ROUTE_DECISION**: operator-only route selection screen
///   (normal ascend vs. fallback ground-level).
class InstructionRenderer implements SceneRenderer {
  final void Function(ExperienceEvent) onEvent;

  const InstructionRenderer({required this.onEvent});

  @override
  Widget build(BuildContext context, SceneViewModel viewModel) {
    switch (viewModel.state) {
      case ExperienceState.ready:
      case ExperienceState.intro:
        return _WelcomeScreen(onStartTest: () {
          onEvent(const UserAction(UserActionType.startTest));
        });
      case ExperienceState.waitForRouteDecision:
        return _RouteDecisionScreen(onEvent: onEvent);
      default:
        return const SizedBox.shrink();
    }
  }
}

// ---------------------------------------------------------------------------
// Welcome screen
// ---------------------------------------------------------------------------

class _WelcomeScreen extends StatelessWidget {
  final VoidCallback onStartTest;
  const _WelcomeScreen({required this.onStartTest});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
        child: Column(
          children: [
            const Spacer(),
            Icon(
              Icons.account_balance_rounded,
              size: 64,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 24),
            Text(
              '明故宫 · 朱允炆',
              style: theme.textTheme.displayLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              '建文四年不是空白',
              style: theme.textTheme.titleMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            _InfoRow(icon: Icons.timer_outlined, text: '体验约6-8分钟'),
            const SizedBox(height: 12),
            _InfoRow(icon: Icons.directions_walk_rounded, text: '需要步行和登楼'),
            const SizedBox(height: 12),
            _InfoRow(icon: Icons.headphones_rounded, text: '建议佩戴耳机'),
            const SizedBox(height: 12),
            _InfoRow(icon: Icons.warning_amber_rounded, text: '注意脚下安全'),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: onStartTest,
                child: const Text('开始测试'),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.textSecondary),
        const SizedBox(width: 12),
        Text(text, style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Route decision
// ---------------------------------------------------------------------------

class _RouteDecisionScreen extends StatelessWidget {
  final void Function(ExperienceEvent) onEvent;
  const _RouteDecisionScreen({required this.onEvent});

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
              '选择路线',
              style: theme.textTheme.headlineLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            _RouteCard(
              title: '正常路线',
              subtitle: '登楼 · 俯瞰午门',
              icon: Icons.arrow_upward_rounded,
              onTap: () => onEvent(
                const OperatorAction(OperatorActionType.switchToNormal),
              ),
            ),
            const SizedBox(height: 20),
            _RouteCard(
              title: '替代路线',
              subtitle: '地面 · 仰望午门',
              icon: Icons.remove_red_eye_rounded,
              onTap: () => onEvent(
                const OperatorAction(OperatorActionType.switchToFallback),
              ),
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}

class _RouteCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _RouteCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: double.infinity,
      child: Card(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: AppColors.primary, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: AppColors.textDisabled),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
