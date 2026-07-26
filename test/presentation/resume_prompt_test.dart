import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ming_palace/presentation/widgets/resume_prompt.dart';

void main() {
  testWidgets('resume prompt exposes continue and discard choices', (
    tester,
  ) async {
    String? choice;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ResumePrompt(
            onResume: () => choice = 'resume',
            onDiscard: () => choice = 'discard',
          ),
        ),
      ),
    );

    expect(find.text('发现未完成的测试'), findsOneWidget);
    await tester.tap(find.text('继续上次测试'));
    expect(choice, 'resume');
    await tester.tap(find.text('放弃并创建新会话'));
    expect(choice, 'discard');
  });
}
