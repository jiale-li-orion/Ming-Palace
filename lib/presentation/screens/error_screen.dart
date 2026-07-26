import 'package:flutter/material.dart';

import '../../app/theme.dart';

/// Error screen shown when content load fails or a critical error occurs.
///
/// Displays the error message and provides retry / export-log actions.
class ErrorScreen extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  final VoidCallback? onExportLog;

  const ErrorScreen({
    required this.message,
    this.onRetry,
    this.onExportLog,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 72,
              color: AppColors.error,
            ),
            const SizedBox(height: 24),
            Text(
              '加载失败',
              style: theme.textTheme.headlineMedium?.copyWith(
                color: AppColors.error,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: theme.textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            if (onRetry != null) ...[
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: onRetry,
                  child: const Text('重试'),
                ),
              ),
              const SizedBox(height: 12),
            ],
            if (onExportLog != null)
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton(
                  onPressed: onExportLog,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textSecondary,
                    side: const BorderSide(color: AppColors.divider),
                  ),
                  child: const Text('导出日志'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
