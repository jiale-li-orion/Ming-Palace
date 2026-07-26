import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ming_palace/application/project_experience_engine.dart';
import 'package:ming_palace/domain/experience_session_state.dart';
import 'package:ming_palace/presentation/screens/project_experience_screen.dart';

void main() {
  testWidgets('welcome and route choice follow handoff hierarchy',
      (tester) async {
    final engine = ProjectExperienceEngine()..start();
    await tester
        .pumpWidget(MaterialApp(home: ProjectExperienceScreen(engine: engine)));
    expect(find.text('走进一条消失的宫城'), findsOneWidget);
    expect(find.text('开始准备'), findsOneWidget);
    await tester.tap(find.text('开始准备'));
    await tester.pump();
    expect(find.text('城台路线'), findsOneWidget);
    expect(find.text('不走台阶'), findsOneWidget);
  });

  testWidgets('safety takeover hides historical image', (tester) async {
    final engine = ProjectExperienceEngine()..start();
    engine.jumpTo(ExperiencePhase.platformRestored);
    engine.interruptForSafety(SafetyKind.crowd);
    await tester
        .pumpWidget(MaterialApp(home: ProjectExperienceScreen(engine: engine)));
    expect(find.text('请留意'), findsOneWidget);
    expect(find.byType(Image), findsNothing);
    expect(find.text('我已站稳'), findsOneWidget);
  });

  testWidgets(
      'A B C evidence chips appear with equal size only after user pause',
      (tester) async {
    final engine = ProjectExperienceEngine()..start();
    engine.jumpTo(ExperiencePhase.platformRestored);
    engine.playNarration();
    await tester
        .pumpWidget(MaterialApp(home: ProjectExperienceScreen(engine: engine)));
    expect(find.text('A'), findsNothing);
    engine.userPauseNarration();
    await tester.pump();
    expect(find.text('A'), findsOneWidget);
    expect(find.text('B'), findsOneWidget);
    expect(find.text('C'), findsOneWidget);
    final a = tester.getSize(find.byKey(const Key('evidence-A')));
    final b = tester.getSize(find.byKey(const Key('evidence-B')));
    final c = tester.getSize(find.byKey(const Key('evidence-C')));
    expect(a, b);
    expect(b, c);
  });
}
