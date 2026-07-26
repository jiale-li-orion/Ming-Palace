import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:ming_palace/domain/experience_state.dart';
import 'package:ming_palace/domain/route_definition.dart';

ExperienceState follow(
  RouteDefinition route,
  ExperienceState state,
  ExperienceEventType event,
) {
  final next = route.nextState(state, event);
  expect(next, isNotNull,
      reason: '${state.id} has no ${event.name} transition');
  return next!;
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('normal route reaches completion through the feudal branch',
      (_) async {
    final route = RouteDefinition(
      id: 'normal',
      initialState: ExperienceState.ready,
      transitions: buildNormalTransitions(),
    );
    var state = route.initialState;
    const events = [
      ExperienceEventType.userStartTest,
      ExperienceEventType.userContinue,
      ExperienceEventType.userArrived,
      ExperienceEventType.userContinue,
      ExperienceEventType.userContinue,
      ExperienceEventType.operatorSelectNormal,
      ExperienceEventType.userArrived,
      ExperienceEventType.userContinue,
      ExperienceEventType.audioCompleted,
      ExperienceEventType.userChooseFeudal,
      ExperienceEventType.audioCompleted,
      ExperienceEventType.audioCompleted,
      ExperienceEventType.userArrived,
      ExperienceEventType.userArrived,
      ExperienceEventType.audioCompleted,
      ExperienceEventType.timerElapsed,
      ExperienceEventType.userSubmitSurvey,
    ];
    for (final event in events) {
      state = follow(route, state, event);
    }
    expect(state, ExperienceState.completed);
  });

  testWidgets('fallback route reaches completion through the classics branch',
      (_) async {
    final route = RouteDefinition(
      id: 'fallback',
      initialState: ExperienceState.ready,
      transitions: buildFallbackTransitions(),
    );
    var state = route.initialState;
    const events = [
      ExperienceEventType.userStartTest,
      ExperienceEventType.userContinue,
      ExperienceEventType.userArrived,
      ExperienceEventType.userContinue,
      ExperienceEventType.userContinue,
      ExperienceEventType.operatorSelectFallback,
      ExperienceEventType.userContinue,
      ExperienceEventType.audioCompleted,
      ExperienceEventType.userChooseClassics,
      ExperienceEventType.audioCompleted,
      ExperienceEventType.audioCompleted,
      ExperienceEventType.audioCompleted,
      ExperienceEventType.timerElapsed,
      ExperienceEventType.userSubmitSurvey,
    ];
    for (final event in events) {
      state = follow(route, state, event);
    }
    expect(state, ExperienceState.completed);
  });
}
