import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ming_palace/application/experience_controller.dart';
import 'package:ming_palace/domain/experience_event.dart';
import 'package:ming_palace/domain/experience_state.dart';
import 'package:ming_palace/domain/scene_definition.dart';
import 'package:ming_palace/presentation/renderers/survey_renderer.dart';
import 'package:ming_palace/presentation/screens/experience_screen.dart';

// Widget tests for the ExperienceScreen
// These require Flutter SDK to execute. Implement when Flutter is available.
//
// See Project.md §12.2 for required widget test coverage:
// - Welcome page
// - Walking page
// - Safety page
// - Platform reconstruction page
// - Question page
// - Survey page
// - Configuration error page

void main() {
  group('ExperienceScreen', () {
    testWidgets('renders loading state before initialization', (tester) async {
      // TODO: create ExperienceEngine with fake repos
      // TODO: pump widget
      // TODO: verify loading indicator
    });

    testWidgets('renders error screen on content load failure', (tester) async {
      // TODO: create ExperienceEngine with failing ContentRepository
      // TODO: pump widget
      // TODO: verify error screen with retry and export buttons
    });
  });

  group('InstructionRenderer', () {
    testWidgets('shows welcome message and start button', (tester) async {
      // TODO: pump InstructionRenderer
      // TODO: verify project name, instructions, "开始测试" button
    });
  });

  group('NarrativeRenderer', () {
    testWidgets('shows audio controls and arrived button when walking', (tester) async {
      // TODO: pump NarrativeRenderer with walking state
      // TODO: verify pause/resume/replay/arrived buttons
    });

    testWidgets('shows continue button when stationary', (tester) async {
      // TODO: pump NarrativeRenderer with stationary state
      // TODO: verify "继续" button
    });
  });

  group('SafetyRenderer', () {
    testWidgets('shows safety message and arrived button', (tester) async {
      // TODO: pump SafetyRenderer
      // TODO: verify "请看脚下" text and "我已到达" button
    });
  });

  group('LayeredReconstructionRenderer', () {
    testWidgets('displays background and animation layers', (tester) async {
      // TODO: pump LayeredReconstructionRenderer with mock layers
      // TODO: verify background and visual sequence
    });
  });

  group('QuestionRenderer', () {
    testWidgets('shows two choice buttons', (tester) async {
      // TODO: pump QuestionRenderer
      // TODO: verify both choice buttons present
    });

    testWidgets('tap feudal choice fires correct event', (tester) async {
      // TODO
    });

    testWidgets('tap classics choice fires correct event', (tester) async {
      // TODO
    });
  });

  group('SurveyRenderer', () {
    testWidgets('shows five questions and submit button', (tester) async {
      ExperienceEvent? submitted;
      const scene = SceneDefinition(
        id: 'SURVEY',
        renderer: 'survey',
        minimumDurationMs: 0,
        autoAdvance: false,
        visualSequence: [],
        allowedActions: ['submit_survey'],
        safetyMode: 'stationary',
      );
      const viewModel = SceneViewModel(
        state: ExperienceState.survey,
        scene: scene,
        isWalking: false,
        isSafetyMode: false,
        visualLayers: [],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => SurveyRenderer(
                onEvent: (event) => submitted = event,
              ).build(context, viewModel),
            ),
          ),
        ),
      );

      final fields = find.byType(TextField);
      expect(fields, findsNWidgets(3));
      await tester.enterText(fields.at(0), '现场叙事');
      await tester.enterText(fields.at(1), '城台复原');
      await tester.enterText(fields.at(2), '路线提示');
      await tester.ensureVisible(find.text('是').first);
      await tester.tap(find.text('是').first);
      await tester.ensureVisible(find.text('提交问卷'));
      await tester.tap(find.text('提交问卷'));

      expect(submitted, isA<SubmitSurvey>());
      final answers = (submitted as SubmitSurvey).answers;
      expect(answers.experienceDescription, '现场叙事');
      expect(answers.mostEngagingMoment, '城台复原');
      expect(answers.confusingMoment, '路线提示');
      expect(answers.wantsLongerExperience, isTrue);
      expect(answers.wantsNextTest, isFalse);
    });
  });

  group('CompletedRenderer', () {
    testWidgets('shows completion message and export/restart buttons', (tester) async {
      // TODO: pump CompletedRenderer
      // TODO: verify "体验完成", export and restart buttons
    });
  });

  group('ErrorScreen', () {
    testWidgets('shows error message with retry and export', (tester) async {
      // TODO: pump ErrorScreen
      // TODO: verify error message, retry button, export log button
    });
  });
}
