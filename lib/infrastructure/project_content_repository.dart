import 'dart:convert';

import '../domain/narration_segment.dart';

class ProjectScene {

  factory ProjectScene.fromJson(String id, Map<String, dynamic> json) =>
      ProjectScene(
        id: id,
        renderer: json['renderer'] as String,
        orientation: json['orientation'] as String,
        background: json['background'] as String?,
        audio: json['audio'] as String?,
        segments: (json['segments'] as List)
            .map((value) =>
                NarrationSegment.fromJson(value as Map<String, dynamic>))
            .toList(),
        next: (json['next'] as List).cast<String>(),
        safetyPolicy: json['safetyPolicy'] as String,
      );
  const ProjectScene({
    required this.id,
    required this.renderer,
    required this.orientation,
    required this.background,
    required this.audio,
    required this.segments,
    required this.next,
    required this.safetyPolicy,
  });

  final String id;
  final String renderer;
  final String orientation;
  final String? background;
  final String? audio;
  final List<NarrationSegment> segments;
  final List<String> next;
  final String safetyPolicy;
}

class ProjectExperienceContent {
  const ProjectExperienceContent({required this.scenes, required this.routes});

  final Map<String, ProjectScene> scenes;
  final Map<String, List<String>> routes;

  List<String> validate() {
    final errors = <String>[];
    const renderers = {
      'welcome',
      'route_choice',
      'navigation',
      'walking_narration',
      'arrival',
      'safety',
      'observation',
      'question',
      'ending',
      'survey',
      'completed',
    };
    for (final scene in scenes.values) {
      if (!renderers.contains(scene.renderer)) {
        errors.add('${scene.id}: renderer 不受支持');
      }
      if (scene.next.any((target) => !scenes.containsKey(target))) {
        errors.add('${scene.id}: next 引用不存在');
      }
      if (scene.orientation == 'landscape' &&
          !{'observation', 'question'}.contains(scene.renderer)) {
        errors.add('${scene.id}: 横屏 renderer 不匹配');
      }
      var previousEnd = 0;
      for (final segment in scene.segments) {
        if (segment.startMs < previousEnd || segment.endMs <= segment.startMs) {
          errors.add('${scene.id}: ${segment.id} 时间边界无效');
        }
        previousEnd = segment.endMs;
      }
      if (scene.renderer == 'safety' && scene.audio != null) {
        errors.add('${scene.id}: 安全状态不得播放叙事');
      }
    }
    for (final route in routes.entries) {
      if (route.value.isEmpty || route.value.last != 'COMPLETED') {
        errors.add('${route.key}: 路线不可达 COMPLETED');
      }
      if (route.value.any((phase) => !scenes.containsKey(phase))) {
        errors.add('${route.key}: 路线引用不存在');
      }
    }
    if ((routes['ground'] ?? const []).any(
      (phase) => phase == 'TOWER_ASCEND' || phase == 'TOWER_DESCEND',
    )) {
      errors.add('ground: 地面路线包含台阶阶段');
    }
    return errors;
  }

  bool routeReachesCompleted(String route) =>
      routes[route]?.lastOrNull == 'COMPLETED';
  List<String> routePhases(String route) => routes[route] ?? const [];
}

ProjectExperienceContent parseProjectExperience(String source) {
  final json = jsonDecode(source) as Map<String, dynamic>;
  if (json['schemaVersion'] != 2) {
    throw const FormatException('experience.json schemaVersion 必须为 2');
  }
  final rawScenes = json['scenes'] as Map<String, dynamic>;
  final scenes = rawScenes.map(
    (id, value) => MapEntry(
      id,
      ProjectScene.fromJson(id, value as Map<String, dynamic>),
    ),
  );
  final rawRoutes = json['routes'] as Map<String, dynamic>;
  final routes = rawRoutes.map(
    (id, value) => MapEntry(id, (value as List).cast<String>()),
  );
  return ProjectExperienceContent(scenes: scenes, routes: routes);
}

class EvidenceEntry {
  const EvidenceEntry({
    required this.id,
    required this.category,
    required this.summary,
    required this.source,
    required this.index,
  });
  final String id;
  final String category;
  final String summary;
  final String source;
  final String index;
}

class EvidenceIndex {
  const EvidenceIndex({required this.categoryKeys, required this.entries});
  final List<String> categoryKeys;
  final List<EvidenceEntry> entries;
}

EvidenceIndex parseEvidenceIndex(String source) {
  final json = jsonDecode(source) as Map<String, dynamic>;
  final categories = (json['categories'] as Map<String, dynamic>).keys.toList();
  final entries = (json['entries'] as List).map((raw) {
    final value = raw as Map<String, dynamic>;
    return EvidenceEntry(
      id: value['id'] as String,
      category: value['category'] as String,
      summary: value['summary'] as String,
      source: value['source'] as String,
      index: value['index'] as String,
    );
  }).toList();
  if (entries.any((entry) => !categories.contains(entry.category))) {
    throw const FormatException('证据分类不存在');
  }
  return EvidenceIndex(categoryKeys: categories, entries: entries);
}

extension<T> on List<T> {
  T? get lastOrNull => isEmpty ? null : last;
}
