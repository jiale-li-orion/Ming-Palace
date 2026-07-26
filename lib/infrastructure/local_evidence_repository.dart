import 'package:flutter/services.dart';

import 'project_content_repository.dart';

abstract interface class EvidenceRepository {
  Future<EvidenceIndex> load();
  Future<EvidenceEntry?> find(String id);
}

class LocalEvidenceRepository implements EvidenceRepository {
  EvidenceIndex? _cache;
  @override
  Future<EvidenceIndex> load() async => _cache ??= parseEvidenceIndex(
        await rootBundle.loadString('assets/content/evidence-index.json'),
      );

  @override
  Future<EvidenceEntry?> find(String id) async {
    final index = await load();
    for (final entry in index.entries) {
      if (entry.id == id) return entry;
    }
    return null;
  }
}
