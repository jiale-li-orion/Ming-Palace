import 'package:flutter_test/flutter_test.dart';
import 'package:ming_palace/infrastructure/project_session_repository.dart';
import 'package:ming_palace/domain/experience_session_state.dart';

void main() {
  test(
      'legacy stair snapshot restores into safety confirmation, never autoplay',
      () {
    final snapshot = ProjectSessionSnapshot.decode({
      'sessionId': 'legacy-1',
      'state': 'NORMAL_ASCEND',
      'route': 'normal',
      'audioPositionMs': 4312,
    });
    expect(snapshot.state.phase, ExperiencePhase.towerAscend);
    expect(snapshot.state.safetyInterruption, isNotNull);
    expect(snapshot.state.narrationMode, NarrationMode.systemPaused);
  });

  test('v2 snapshot retains complete segment boundary and composite state', () {
    final snapshot = ProjectSessionSnapshot.decode({
      'schemaVersion': 2,
      'sessionId': 'v2-1',
      'state': {
        'phase': 'PLATFORM_RESTORED',
        'routeMode': 'tower',
        'navigationMode': 'inactive',
        'narrationMode': 'playing',
        'orientationMode': 'landscapeRequired',
        'chromeMode': 'hidden',
        'currentSegmentId': 'platform-s02'
      }
    });
    expect(snapshot.state.currentSegmentId, 'platform-s02');
    expect(snapshot.state.narrationMode, NarrationMode.userPaused);
    expect(snapshot.state.chromeMode, ChromeMode.hidden);
  });
}
