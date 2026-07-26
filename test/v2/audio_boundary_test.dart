import 'package:flutter_test/flutter_test.dart';
import 'package:ming_palace/application/project_audio_coordinator.dart';
import 'package:ming_palace/domain/narration_segment.dart';

void main() {
  test('timeline resolves a playback position to its complete sentence', () {
    const timeline = NarrationTimeline([
      NarrationSegment(
          id: 's1', startMs: 0, endMs: 6200, subtitle: '一', evidenceIds: []),
      NarrationSegment(
          id: 's2',
          startMs: 6200,
          endMs: 12168,
          subtitle: '二',
          evidenceIds: []),
    ]);
    expect(timeline.segmentAt(const Duration(milliseconds: 6199))?.id, 's1');
    expect(timeline.segmentAt(const Duration(milliseconds: 6200))?.id, 's2');
    expect(timeline.boundaryFor(const Duration(milliseconds: 9000)),
        const Duration(milliseconds: 6200));
  });
}
