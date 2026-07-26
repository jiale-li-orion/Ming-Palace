import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ming_palace/application/experience_controller.dart';
import 'package:ming_palace/domain/experience_event.dart';
import 'package:ming_palace/domain/experience_state.dart';
import 'package:ming_palace/domain/scene_definition.dart';
import 'package:ming_palace/presentation/renderers/completed_renderer.dart';
import 'package:ming_palace/presentation/renderers/layered_reconstruction_renderer.dart';
import 'package:ming_palace/presentation/renderers/question_renderer.dart';
import 'package:ming_palace/presentation/renderers/safety_renderer.dart';
import 'package:ming_palace/presentation/renderers/survey_renderer.dart';
import 'package:ming_palace/presentation/screens/error_screen.dart';

SceneViewModel vm(
  ExperienceState state,
  String renderer, {
  int minimumDurationMs = 0,
  List<String> actions = const [],
  String? background,
  List<VisualLayer> layers = const [],
}) {
  final scene = SceneDefinition(
    id: state.id,
    renderer: renderer,
    background: background,
    minimumDurationMs: minimumDurationMs,
    autoAdvance: false,
    visualSequence: layers,
    allowedActions: actions,
    safetyMode: state.isSafetyState ? 'walking' : 'stationary',
  );
  return SceneViewModel(
    state: state,
    scene: scene,
    isWalking: state.isWalkingState,
    isSafetyMode: state.isSafetyState,
    visualLayers: layers,
  );
}

Future<void> pumpRenderer(WidgetTester tester, Widget child) =>
    tester.pumpWidget(MaterialApp(home: Scaffold(body: child)));

void main() {
  testWidgets('safety screen presents the field warning and arrival action',
      (tester) async {
    ExperienceEvent? event;
    await pumpRenderer(
      tester,
      Builder(
        builder: (context) => SafetyRenderer(onEvent: (e) => event = e)
            .build(context, vm(ExperienceState.normalAscend, 'safety')),
      ),
    );
    expect(find.text('请看脚下'), findsOneWidget);
    await tester.tap(find.text('我已到达'));
    expect((event as UserAction).action, UserActionType.arrived);
  });

  testWidgets('question sends each explicit branch choice', (tester) async {
    ExperienceEvent? event;
    await pumpRenderer(
      tester,
      Builder(
        builder: (context) => QuestionRenderer(
          onEvent: (e) => event = e,
          isPlaying: false,
        ).build(context, vm(ExperienceState.question, 'question')),
      ),
    );
    expect(find.text('为什么急着削藩？'), findsOneWidget);
    expect(find.text('为什么太看重经典和文字？'), findsOneWidget);
    await tester.tap(find.text('为什么急着削藩？'));
    expect((event as UserAction).action, UserActionType.chooseFeudal);
  });

  testWidgets('observation enforces countdown before continue', (tester) async {
    await pumpRenderer(
      tester,
      Builder(
        builder: (context) =>
            LayeredReconstructionRenderer(onEvent: (_) {}).build(
          context,
          vm(
            ExperienceState.normalPlatformObserve,
            'layered_reconstruction',
            minimumDurationMs: 1000,
            actions: const ['continue'],
          ),
        ),
      ),
    );
    expect(find.text('请观察 1 秒'), findsOneWidget);
    expect(tester.widget<ElevatedButton>(find.byType(ElevatedButton)).onPressed,
        isNull);
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('继续'), findsOneWidget);
  });

  testWidgets('survey submits all five answers', (tester) async {
    ExperienceEvent? submitted;
    await pumpRenderer(
      tester,
      Builder(
        builder: (context) => SurveyRenderer(
          onEvent: (event) => submitted = event,
        ).build(context, vm(ExperienceState.survey, 'survey')),
      ),
    );
    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), '现场叙事');
    await tester.enterText(fields.at(1), '城台复原');
    await tester.enterText(fields.at(2), '路线提示');
    await tester.ensureVisible(find.text('是').first);
    await tester.tap(find.text('是').first);
    await tester.ensureVisible(find.text('提交问卷'));
    await tester.tap(find.text('提交问卷'));
    final answers = (submitted as SubmitSurvey).answers;
    expect(answers.experienceDescription, '现场叙事');
    expect(answers.mostEngagingMoment, '城台复原');
    expect(answers.confusingMoment, '路线提示');
    expect(answers.wantsLongerExperience, isTrue);
    expect(answers.wantsNextTest, isFalse);
  });

  testWidgets('completed and error screens expose recovery actions',
      (tester) async {
    await pumpRenderer(
      tester,
      Builder(
        builder: (context) => CompletedRenderer(onEvent: (_) {}).build(
          context,
          vm(ExperienceState.completed, 'completed'),
        ),
      ),
    );
    expect(find.text('保存并导出'), findsOneWidget);
    expect(find.text('重新开始'), findsOneWidget);

    await pumpRenderer(
      tester,
      const ErrorScreen(message: '配置错误', onRetry: null),
    );
    expect(find.text('加载失败'), findsOneWidget);
    expect(find.text('配置错误'), findsOneWidget);
  });
}
