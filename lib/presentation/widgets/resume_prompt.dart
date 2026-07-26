import 'package:flutter/material.dart';

import '../../app/theme.dart';

/// Explicit recovery gate shown before replacing an unfinished local session.
class ResumePrompt extends StatelessWidget {

  const ResumePrompt({
    required this.onResume,
    required this.onDiscard,
    super.key,
  });
  final VoidCallback onResume;
  final VoidCallback onDiscard;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.restore_rounded,
              color: AppColors.primaryLight,
              size: 64,
            ),
            const SizedBox(height: 24),
            Text(
              '发现未完成的测试',
              style: Theme.of(context).textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            const Text(
              '可以从上次停下的位置继续，或放弃记录并创建新会话。',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: onResume,
                child: const Text('继续上次测试'),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: OutlinedButton(
                onPressed: onDiscard,
                child: const Text('放弃并创建新会话'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
