import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../application/experience_controller.dart';
import '../../application/operator_controller.dart';
import '../../domain/experience_state.dart';

/// Operator panel (Project.md §5.6) — hidden panel accessible via 7-tap
/// on the title bar.
///
/// Renders as an overlay card positioned at the bottom of the screen.
/// Allows test operators to navigate the experience, switch routes, replay
/// audio, and export logs.
///
/// Takes both an [OperatorController] (for tap detection and action dispatch)
/// and the [ExperienceEngine] (for read-only state display), keeping the
/// controller as the single mutation path to the engine.
class OperatorPanel extends StatelessWidget {
  final OperatorController controller;
  final ExperienceEngine engine;

  const OperatorPanel({
    required this.controller,
    required this.engine,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        return Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: SafeArea(
            top: false,
            child: Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.6,
              ),
              decoration: BoxDecoration(
                color: AppColors.surface.withOpacity(0.97),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16)),
                border: Border(
                  top: BorderSide(
                      color: AppColors.primary.withOpacity(0.4), width: 1),
                ),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header
                    _SectionHeader(title: '操作员面板'),
                    const Divider(color: AppColors.divider),
                    const SizedBox(height: 8),

                    // Current state
                    _InfoRow(label: '当前状态', value: engine.currentState.id),
                    _InfoRow(
                      label: '会话',
                      value: engine.sessionId?.substring(0, 8) ?? '—',
                    ),
                    _InfoRow(label: '路线', value: engine.currentRoute.id),
                    _InfoRow(
                      label: '帮助标记',
                      value: '${controller.helpRequestCount}',
                    ),
                    const SizedBox(height: 12),

                    // Route toggle
                    _SectionHeader(title: '路线选择'),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _SmallButton(
                            label: '正常路线',
                            selected: engine.currentRoute.id == 'normal',
                            onTap: controller.switchToNormalRoute,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _SmallButton(
                            label: '替代路线',
                            selected: engine.currentRoute.id == 'fallback',
                            onTap: controller.switchToFallbackRoute,
                          ),
                        ),
                      ],
                    ),
                    if (engine.currentState !=
                        ExperienceState.waitForRouteDecision)
                      const Padding(
                        padding: EdgeInsets.only(top: 6),
                        child: Text(
                          '仅在路线决策节点可切换',
                          style: TextStyle(
                            color: AppColors.textDisabled,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    const SizedBox(height: 16),

                    // Navigation
                    _SectionHeader(title: '导航'),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _SmallButton(
                            label: '上一步',
                            icon: Icons.skip_previous_rounded,
                            onTap: controller.previousStep,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _SmallButton(
                            label: '下一步',
                            icon: Icons.skip_next_rounded,
                            onTap: controller.nextStep,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<ExperienceState>(
                      value: engine.currentState,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: '跳转到指定状态',
                        isDense: true,
                      ),
                      items: ExperienceState.values
                          .map(
                            (state) => DropdownMenuItem(
                              value: state,
                              child: Text(
                                state.id,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (state) {
                        if (state != null && state != engine.currentState) {
                          controller.jumpToState(state);
                        }
                      },
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _SmallButton(
                            label: '重播音频',
                            icon: Icons.replay_rounded,
                            onTap: controller.replayAudio,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _SmallButton(
                            label: '标记帮助',
                            icon: Icons.help_outline_rounded,
                            onTap: controller.markNeedsHelp,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Session
                    _SectionHeader(title: '会话'),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _SmallButton(
                            label: '结束会话',
                            color: AppColors.error,
                            onTap: () async {
                              final confirmed = await showDialog<bool>(
                                context: context,
                                builder: (dialogContext) => AlertDialog(
                                  title: const Text('确认结束当前会话？'),
                                  content: const Text('会话将标记为中止并进入完成页。'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(
                                        dialogContext,
                                        false,
                                      ),
                                      child: const Text('取消'),
                                    ),
                                    FilledButton(
                                      onPressed: () => Navigator.pop(
                                        dialogContext,
                                        true,
                                      ),
                                      child: const Text('确认结束'),
                                    ),
                                  ],
                                ),
                              );
                              if (confirmed ?? false) {
                                controller.endSession();
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _SmallButton(
                            label: '新会话',
                            onTap: controller.createNewSession,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Data
                    _SectionHeader(title: '数据'),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _SmallButton(
                            label: '查看日志',
                            onTap: () => controller.viewLog(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _SmallButton(
                            label: '清空数据',
                            color: AppColors.error,
                            onTap: () async {
                              final confirmed = await showDialog<bool>(
                                context: context,
                                builder: (dialogContext) => AlertDialog(
                                  title: const Text('确认清空测试数据？'),
                                  content: const Text('此操作不可撤销。'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(
                                        dialogContext,
                                        false,
                                      ),
                                      child: const Text('取消'),
                                    ),
                                    FilledButton(
                                      onPressed: () => Navigator.pop(
                                        dialogContext,
                                        true,
                                      ),
                                      child: const Text('确认清空'),
                                    ),
                                  ],
                                ),
                              );
                              if (confirmed ?? false) {
                                await controller.clearData();
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: _SmallButton(
                        label: '导出全部日志',
                        onTap: () => controller.exportLog(),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: AppColors.primaryLight,
            fontWeight: FontWeight.w600,
          ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text(
            '$label: ',
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

class _SmallButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onTap;
  final bool selected;
  final Color? color;

  const _SmallButton({
    required this.label,
    this.icon,
    this.onTap,
    this.selected = false,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = selected
        ? (color ?? AppColors.primary).withOpacity(0.2)
        : AppColors.surfaceVariant;
    final borderColor =
        selected ? (color ?? AppColors.primaryLight) : AppColors.divider;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: borderColor, width: 0.5),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 16, color: color ?? AppColors.textPrimary),
                const SizedBox(width: 6),
              ],
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    color: color ?? AppColors.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
