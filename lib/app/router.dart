/// Route configuration.
///
/// This app uses **state-driven rendering** rather than Navigator-based
/// routing.  All screen transitions are controlled by [ExperienceEngine]'s
/// state machine (see `lib/application/experience_controller.dart`).
///
/// No named routes are registered — the single [MaterialApp] home screen
/// observes the [ExperienceEngine] and swaps content per [SceneViewModel].
///
/// If a future feature requires push-style navigation (e.g. a settings or
/// about screen), register routes here and keep the main experience flow
/// state-driven.
