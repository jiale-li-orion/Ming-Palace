class NarrationSegment {

  factory NarrationSegment.fromJson(Map<String, dynamic> json) =>
      NarrationSegment(
        id: json['id'] as String,
        startMs: json['startMs'] as int,
        endMs: json['endMs'] as int,
        subtitle: json['subtitle'] as String,
        evidenceIds: (json['evidenceIds'] as List).cast<String>(),
      );
  const NarrationSegment({
    required this.id,
    required this.startMs,
    required this.endMs,
    required this.subtitle,
    required this.evidenceIds,
  });

  final String id;
  final int startMs;
  final int endMs;
  final String subtitle;
  final List<String> evidenceIds;
}
