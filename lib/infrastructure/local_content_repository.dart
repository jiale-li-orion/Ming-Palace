import 'dart:convert';

import 'package:flutter/services.dart';

import '../domain/scene_definition.dart';
import '../shared/app_error.dart';
import '../shared/result.dart';

/// Repository contract for loading experience content from local assets.
abstract interface class ContentRepository {
  /// Loads all scene definitions from the bundled experience.json asset.
  Future<Result<Map<String, SceneDefinition>, AppError>> loadScenes();
}

/// Loads scene content from `assets/content/experience.json` via the
/// Flutter asset bundle.  Single-source of truth for all scene definitions
/// used by the experience engine.
class LocalContentRepository implements ContentRepository {
  static const String _assetPath = 'assets/content/experience.json';

  @override
  Future<Result<Map<String, SceneDefinition>, AppError>> loadScenes() async {
    try {
      final jsonString = await rootBundle.loadString(_assetPath);
      final decoded = json.decode(jsonString) as Map<String, dynamic>;

      final scenes = decoded['scenes'];
      if (scenes == null || scenes is! Map) {
        return Err(AppError.contentLoadFailed);
      }

      final sceneMap = <String, SceneDefinition>{};
      for (final entry in (scenes as Map<String, dynamic>).entries) {
        final sceneJson = Map<String, dynamic>.from(entry.value as Map);
        // Inject the map key so SceneDefinition carries its own id.
        sceneJson['id'] = entry.key;
        sceneMap[entry.key] = SceneDefinition.fromJson(sceneJson);
      }

      return Ok(sceneMap);
    } catch (_) {
      return Err(AppError.contentLoadFailed);
    }
  }
}
