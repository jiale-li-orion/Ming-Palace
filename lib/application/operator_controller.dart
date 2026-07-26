import 'dart:async';

import 'package:flutter/foundation.dart';

import '../domain/experience_event.dart';
import 'experience_controller.dart';

/// Operator panel controller (Project.md §5.6).
///
/// Manages panel visibility (hidden by default, revealed by 7 taps on the
/// title) and exposes operator actions that delegate to the
/// [ExperienceEngine].
///
/// Keeps its own counters for help-request tallying and session tracking
/// so the operator panel can display live stats without querying the
/// telemetry repository on every change.
class OperatorController extends ChangeNotifier {
  final ExperienceEngine _engine;

  OperatorController(this._engine) : _panelVisible = false;

  // ---- internal state ------------------------------------------------------

  bool _panelVisible;
  int _helpRequestCount = 0;
  int _sessionCount = 0;

  // ---- public getters ------------------------------------------------------

  /// Whether the operator panel should be displayed.
  bool get isPanelVisible => _panelVisible;

  /// The engine's current tap count (read-only proxy).
  int get tapCount => _engine.isOperatorUnlocked ? 7 : 0; // threshold reached

  /// Total help requests recorded during the current session.
  int get helpRequestCount => _helpRequestCount;

  /// Number of sessions created since the app started.
  int get sessionCount => _sessionCount;

  /// Whether the 7-tap threshold has been reached (delegates to engine).
  bool get isUnlocked => _engine.isOperatorUnlocked;

  // ---- tap detection -------------------------------------------------------

  /// Increments the title-tap counter.  Delegates to [ExperienceEngine] for
  /// the 7-tap unlock threshold; [panelVisible] is derived from the engine.
  void incrementTapCount() {
    _engine.incrementOperatorTap();
    _panelVisible = _engine.isOperatorUnlocked;
    notifyListeners();
  }

  /// Resets the tap counter and hides the panel.
  void resetTapCount() {
    _engine.resetOperatorTap();
    _panelVisible = false;
    notifyListeners();
  }

  // ---- operator actions ----------------------------------------------------

  /// Advances the experience by one step (operator override).
  void nextStep() => _engine.handleEvent(
        const OperatorAction(OperatorActionType.nextStep),
      );

  /// Switches to the normal (ascend-to-platform) route.
  void switchToNormalRoute() {
    _engine.setRoute('normal');
    _engine.handleEvent(
      const OperatorAction(OperatorActionType.switchToNormal),
    );
  }

  /// Switches to the fallback (ground-level) route.
  void switchToFallbackRoute() {
    _engine.setRoute('fallback');
    _engine.handleEvent(
      const OperatorAction(OperatorActionType.switchToFallback),
    );
  }

  /// Replays the current audio narration.
  void replayAudio() => _engine.handleEvent(
        const OperatorAction(OperatorActionType.replayAudio),
      );

  /// Records a help request (user asked for assistance during testing).
  void markNeedsHelp() {
    _helpRequestCount++;
    _engine.handleEvent(
      const OperatorAction(OperatorActionType.markNeedsHelp),
    );
    notifyListeners();
  }

  /// Creates a brand new session (discarding any in-progress state).
  ///
  /// The async [ExperienceEngine.startSession] result is handled with
  /// [unawaited] and a silent catch — errors are surfaced through the
  /// engine's [ExperienceEngine.reportError] mechanism.
  void createNewSession() {
    _sessionCount++;
    unawaited(
      _engine.startSession().then((result) {
        if (result.isErr) {
          _engine.reportError(result.errValue!.message);
        }
      }),
    );
    notifyListeners();
  }

  /// Steps backward through the experience (operator override).
  void previousStep() => _engine.handleEvent(
        const OperatorAction(OperatorActionType.previousStep),
      );

  /// Ends the current session (marks it as interrupted).
  void endSession() => _engine.handleEvent(
        const OperatorAction(OperatorActionType.endSession),
      );

}
