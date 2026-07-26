/// Data model for a scene definition loaded from experience.json.
///
/// Each scene maps to one [ExperienceState] and defines what the renderer,
/// audio, visuals, and allowed actions are for that state.
class SceneDefinition {
  static const supportedRenderers = {
    'instruction',
    'narrative',
    'layered_reconstruction',
    'question',
    'survey',
    'safety',
    'completed',
  };
  static const supportedActions = {
    'start_test',
    'continue',
    'pause',
    'resume',
    'replay',
    'arrived',
    'choose_feudal',
    'choose_classics',
    'submit_survey',
    'export',
    'restart',
  };
  static const supportedSafetyModes = {
    'stationary',
    'walking',
    'ascending',
    'descending',
  };

  final String id;
  final String renderer;
  final String? background;
  final String? audio;
  final int minimumDurationMs;
  final bool autoAdvance;
  final List<VisualLayer> visualSequence;
  final List<String> allowedActions;
  final List<String> next;
  final List<String> operatorActions;
  final String safetyMode;

  const SceneDefinition({
    required this.id,
    required this.renderer,
    this.background,
    this.audio,
    required this.minimumDurationMs,
    required this.autoAdvance,
    required this.visualSequence,
    required this.allowedActions,
    this.next = const [],
    this.operatorActions = const [],
    required this.safetyMode,
  });

  factory SceneDefinition.fromJson(Map<String, dynamic> json) {
    final id = json['id'] as String? ?? '';
    final renderer = json['renderer'] as String?;
    if (renderer == null || !supportedRenderers.contains(renderer)) {
      throw FormatException('$id.renderer 不受支持: $renderer');
    }
    final minimumDurationMs = json['minimumDurationMs'] as int? ?? 0;
    if (minimumDurationMs < 0) {
      throw FormatException('$id.minimumDurationMs 不能为负数');
    }
    final allowedActions = (json['allowedActions'] as List<dynamic>?)
            ?.map((e) => e as String)
            .toList() ??
        [];
    String? invalidAction;
    for (final action in allowedActions) {
      if (!supportedActions.contains(action)) {
        invalidAction = action;
        break;
      }
    }
    if (invalidAction != null) {
      throw FormatException('$id.allowedActions 不受支持: $invalidAction');
    }
    final safetyMode = json['safetyMode'] as String? ?? 'stationary';
    if (!supportedSafetyModes.contains(safetyMode)) {
      throw FormatException('$id.safetyMode 不受支持: $safetyMode');
    }
    return SceneDefinition(
      id: id,
      renderer: renderer,
      background: json['background'] as String?,
      audio: json['audio'] as String?,
      minimumDurationMs: minimumDurationMs,
      autoAdvance: json['autoAdvance'] as bool? ?? false,
      visualSequence: (json['visualSequence'] as List<dynamic>?)
              ?.map((e) => VisualLayer.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      allowedActions: allowedActions,
      next: (json['next'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      operatorActions: (json['operatorActions'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      safetyMode: safetyMode,
    );
  }

  Map<String, dynamic> toJson() => {
        'renderer': renderer,
        if (background != null) 'background': background,
        if (audio != null) 'audio': audio,
        'minimumDurationMs': minimumDurationMs,
        'autoAdvance': autoAdvance,
        'visualSequence': visualSequence.map((v) => v.toJson()).toList(),
        'allowedActions': allowedActions,
        'next': next,
        'operatorActions': operatorActions,
        'safetyMode': safetyMode,
      };

  /// Whether this scene has layered reconstruction visuals.
  bool get hasLayers => visualSequence.isNotEmpty && visualSequence.length > 1;

  /// Whether the allowed actions include the given action name.
  bool allowsAction(String action) => allowedActions.contains(action);
}

/// A single visual layer in a layered reconstruction scene.
class VisualLayer {
  final String asset;
  final int startMs;
  final int fadeInMs;

  const VisualLayer({
    required this.asset,
    required this.startMs,
    required this.fadeInMs,
  });

  factory VisualLayer.fromJson(Map<String, dynamic> json) {
    final asset = json['asset'] as String?;
    final startMs = json['startMs'] as int? ?? 0;
    final fadeInMs = json['fadeInMs'] as int? ?? 0;
    if (asset == null || asset.isEmpty) {
      throw const FormatException('visualSequence.asset 不能为空');
    }
    if (startMs < 0 || fadeInMs < 0) {
      throw FormatException('$asset 的动画时间不能为负数');
    }
    return VisualLayer(
      asset: asset,
      startMs: startMs,
      fadeInMs: fadeInMs,
    );
  }

  Map<String, dynamic> toJson() => {
        'asset': asset,
        'startMs': startMs,
        'fadeInMs': fadeInMs,
      };
}
