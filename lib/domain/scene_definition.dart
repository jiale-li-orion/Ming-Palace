/// Data model for a scene definition loaded from experience.json.
///
/// Each scene maps to one [ExperienceState] and defines what the renderer,
/// audio, visuals, and allowed actions are for that state.
class SceneDefinition {
  final String id;
  final String renderer;
  final String? background;
  final String? audio;
  final int minimumDurationMs;
  final bool autoAdvance;
  final List<VisualLayer> visualSequence;
  final List<String> allowedActions;
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
    required this.safetyMode,
  });

  factory SceneDefinition.fromJson(Map<String, dynamic> json) {
    return SceneDefinition(
      id: json['id'] as String? ?? '',
      renderer: json['renderer'] as String,
      background: json['background'] as String?,
      audio: json['audio'] as String?,
      minimumDurationMs: json['minimumDurationMs'] as int? ?? 0,
      autoAdvance: json['autoAdvance'] as bool? ?? false,
      visualSequence: (json['visualSequence'] as List<dynamic>?)
              ?.map((e) => VisualLayer.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      allowedActions: (json['allowedActions'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      safetyMode: json['safetyMode'] as String? ?? 'stationary',
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
    return VisualLayer(
      asset: json['asset'] as String,
      startMs: json['startMs'] as int? ?? 0,
      fadeInMs: json['fadeInMs'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'asset': asset,
        'startMs': startMs,
        'fadeInMs': fadeInMs,
      };
}
