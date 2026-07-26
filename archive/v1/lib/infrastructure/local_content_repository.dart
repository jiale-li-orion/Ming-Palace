import 'dart:convert';

import 'package:flutter/services.dart';

import '../domain/experience_state.dart';
import '../domain/scene_definition.dart';
import '../shared/app_error.dart';
import '../shared/result.dart';

/// Repository contract for loading experience content from local assets.
abstract interface class ContentRepository {
  /// Loads all scene definitions from the bundled experience.json asset.
  Future<Result<Map<String, SceneDefinition>, AppError>> loadScenes();
}

/// Parses and validates the complete offline content package.
Result<Map<String, SceneDefinition>, AppError> parseExperienceJson(
  String jsonString,
) {
  try {
    final decoded = json.decode(jsonString) as Map<String, dynamic>;
    if (decoded['schemaVersion'] != 1 ||
        decoded['contentVersion'] is! String ||
        decoded['experienceId'] is! String) {
      return const Err(AppError.contentLoadFailed);
    }

    final rawScenes = decoded['scenes'];
    if (rawScenes is! Map<String, dynamic>) {
      return const Err(AppError.contentLoadFailed);
    }
    final requiredIds = ExperienceState.values.map((state) => state.id).toSet();
    if (rawScenes.keys.toSet().difference(requiredIds).isNotEmpty ||
        requiredIds.difference(rawScenes.keys.toSet()).isNotEmpty) {
      return const Err(AppError.contentLoadFailed);
    }

    const requiredFields = {
      'id',
      'renderer',
      'audio',
      'visualSequence',
      'allowedActions',
      'next',
      'operatorActions',
      'safetyMode',
      'autoAdvance',
      'minimumDurationMs',
    };
    final sceneMap = <String, SceneDefinition>{};
    for (final entry in rawScenes.entries) {
      final sceneJson = Map<String, dynamic>.from(entry.value as Map);
      if (requiredFields.difference(sceneJson.keys.toSet()).isNotEmpty ||
          sceneJson['id'] != entry.key ||
          sceneJson['next'] is! List ||
          sceneJson['operatorActions'] is! List) {
        return const Err(AppError.contentLoadFailed);
      }
      final nextStates = (sceneJson['next'] as List<dynamic>).cast<String>();
      if (nextStates.any((target) => !requiredIds.contains(target))) {
        return const Err(AppError.contentLoadFailed);
      }
      sceneMap[entry.key] = SceneDefinition.fromJson(sceneJson);
    }
    return Ok(sceneMap);
  } catch (_) {
    return const Err(AppError.contentLoadFailed);
  }
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
      return parseExperienceJson(jsonString);
    } catch (_) {
      return const Err(AppError.contentLoadFailed);
    }
  }
}
