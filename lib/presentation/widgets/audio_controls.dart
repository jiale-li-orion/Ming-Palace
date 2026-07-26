import 'package:flutter/material.dart';

import '../../app/theme.dart';

/// Reusable audio control bar (Project.md §10.2).
///
/// Renders a compact row with play/pause toggle, replay, and a thin progress
/// indicator.  Designed for outdoor tap accuracy — large hit targets.
class AudioControls extends StatelessWidget {
  final bool isPlaying;
  final VoidCallback? onPause;
  final VoidCallback? onResume;
  final VoidCallback? onReplay;
  final Duration currentPosition;
  final Duration duration;

  const AudioControls({
    required this.isPlaying,
    this.onPause,
    this.onResume,
    this.onReplay,
    this.currentPosition = Duration.zero,
    this.duration = Duration.zero,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final progress = (duration.inMilliseconds > 0)
        ? (currentPosition.inMilliseconds / duration.inMilliseconds)
            .clamp(0.0, 1.0)
        : 0.0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface.withOpacity(0.9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider, width: 0.5),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Replay
              _ControlButton(
                icon: Icons.replay_rounded,
                size: 40,
                onTap: onReplay,
              ),
              const SizedBox(width: 24),
              // Play / Pause
              _ControlButton(
                icon:
                    isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                size: 52,
                onTap: isPlaying ? onPause : onResume,
              ),
              const SizedBox(width: 24),
              // Dummy spacer for visual balance
              const SizedBox(width: 40),
            ],
          ),
          const SizedBox(height: 10),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: AppColors.surfaceVariant,
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppColors.primaryLight),
              minHeight: 3,
            ),
          ),
          const SizedBox(height: 4),
          // Timestamps
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formatDuration(currentPosition),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontSize: 12,
                    ),
              ),
              Text(
                _formatDuration(duration),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontSize: 12,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final double size;
  final VoidCallback? onTap;

  const _ControlButton({
    required this.icon,
    required this.size,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(size),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.12),
            borderRadius: BorderRadius.circular(size / 2),
          ),
          child: Icon(icon, size: size * 0.55, color: AppColors.primaryLight),
        ),
      ),
    );
  }
}
