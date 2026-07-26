// Integration test skeleton — Ming Palace Experience
//
// These tests verify the complete user flow. They require a real device or
// Android emulator to run.  Use `flutter test integration_test/` to execute.
//
// Project.md §12.3 requires two integration tests:
//
// 1. Normal route → choose "why reduce feudal princes" → complete survey
// 2. Fallback route → choose "why value classics" → complete survey

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Normal route', () {
    testWidgets('full flow with feudal choice', (tester) async {
      // TODO: implement when Flutter SDK is available
      // 1. Launch app
      // 2. Verify welcome screen
      // 3. Tap "开始测试"
      // 4. Walk through normal route by tapping "继续" and "我已到达"
      // 5. At question, choose "为什么急着削藩？"
      // 6. Complete remaining states
      // 7. Submit survey
      // 8. Verify COMPLETED state
      // 9. Verify telemetry file exists and is parseable
    });
  });

  group('Fallback route', () {
    testWidgets('full flow with classics choice', (tester) async {
      // TODO: implement when Flutter SDK is available
      // 1. Launch app
      // 2. Tap "开始测试"
      // 3. Walk to fallback route decision point
      // 4. Use operator panel to switch to fallback
      // 5. At question, choose "为什么太看重经典和文字？"
      // 6. Complete survey
      // 7. Verify COMPLETED
    });
  });

  group('Operator panel', () {
    testWidgets('7-tap reveals operator panel', (tester) async {
      // TODO: implement when Flutter SDK is available
    });

    testWidgets('operator can reset session', (tester) async {
      // TODO: implement when Flutter SDK is available
    });
  });
}
