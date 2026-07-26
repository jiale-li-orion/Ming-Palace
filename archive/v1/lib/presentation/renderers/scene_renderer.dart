import 'package:flutter/widgets.dart';

import '../../application/experience_controller.dart';

/// Contract for a renderer that knows how to draw a scene.
///
/// Each concrete renderer maps one or more [ExperienceState] values to a
/// widget subtree.  The [build] method receives the current [SceneViewModel]
/// so the renderer can query the state, allowed actions, audio asset, etc.
abstract interface class SceneRenderer {
  Widget build(BuildContext context, SceneViewModel viewModel);
}
