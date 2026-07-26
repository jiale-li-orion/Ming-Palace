import 'experience_state.dart';
import 'session_summary.dart';

/// Events that can trigger state transitions in the experience engine.
sealed class ExperienceEvent {
  const ExperienceEvent();
}

/// User tapped a UI action button.
class UserAction extends ExperienceEvent {
  const UserAction(this.action);
  final UserActionType action;
}

/// Operator triggered an action from the hidden panel.
class OperatorAction extends ExperienceEvent {
  const OperatorAction(this.action);
  final OperatorActionType action;
}

/// Audio playback completed.
class AudioCompleted extends ExperienceEvent {
  const AudioCompleted();
}

/// A timed auto-advance fired.
class TimerElapsed extends ExperienceEvent {
  const TimerElapsed();
}

/// User submitted the five-question post-experience survey.
class SubmitSurvey extends ExperienceEvent {

  const SubmitSurvey(this.answers);
  final SurveyAnswers answers;
}

/// App returned from background; contains saved state for recovery.
class AppResumed extends ExperienceEvent {
  const AppResumed(this.savedState, this.savedAudioPositionMs);
  final ExperienceState savedState;
  final int savedAudioPositionMs;
}

// --- Action type enums ---

enum UserActionType {
  startTest,
  continue_,
  pause,
  resume,
  replay,
  arrived,
  chooseFeudal,
  chooseClassics,
  submitSurvey,
  export_,
  restart;

  String get apiName {
    switch (this) {
      case UserActionType.startTest:
        return 'start_test';
      case UserActionType.continue_:
        return 'continue';
      case UserActionType.pause:
        return 'pause';
      case UserActionType.resume:
        return 'resume';
      case UserActionType.replay:
        return 'replay';
      case UserActionType.arrived:
        return 'arrived';
      case UserActionType.chooseFeudal:
        return 'choose_feudal';
      case UserActionType.chooseClassics:
        return 'choose_classics';
      case UserActionType.submitSurvey:
        return 'submit_survey';
      case UserActionType.export_:
        return 'export';
      case UserActionType.restart:
        return 'restart';
    }
  }

  static UserActionType fromApiName(String name) {
    return UserActionType.values.firstWhere(
      (e) => e.apiName == name,
      orElse: () => throw ArgumentError('Unknown action: $name'),
    );
  }
}

enum OperatorActionType {
  createSession,
  previousStep,
  nextStep,
  replayAudio,
  markNeedsHelp,
  switchToNormal,
  switchToFallback,
  endSession,
  viewLog,
  exportLog,
  clearData;

  String get apiName {
    switch (this) {
      case OperatorActionType.createSession:
        return 'create_session';
      case OperatorActionType.previousStep:
        return 'previous_step';
      case OperatorActionType.nextStep:
        return 'next_step';
      case OperatorActionType.replayAudio:
        return 'replay_audio';
      case OperatorActionType.markNeedsHelp:
        return 'mark_help';
      case OperatorActionType.switchToNormal:
        return 'switch_normal';
      case OperatorActionType.switchToFallback:
        return 'switch_fallback';
      case OperatorActionType.endSession:
        return 'end_session';
      case OperatorActionType.viewLog:
        return 'view_log';
      case OperatorActionType.exportLog:
        return 'export_log';
      case OperatorActionType.clearData:
        return 'clear_data';
    }
  }
}
