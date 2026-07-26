import 'package:flutter/services.dart';

import '../domain/experience_session_state.dart';

abstract interface class OrientationService {
  Future<void> apply(OrientationMode mode);
}

class OrientationController implements OrientationService {
  @override
  Future<void> apply(OrientationMode mode) async {
    final orientations = switch (mode) {
      OrientationMode.requestLandscape || OrientationMode.landscapeRequired => [
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight
        ],
      OrientationMode.requestPortrait || OrientationMode.portraitRequired => [
          DeviceOrientation.portraitUp
        ],
      OrientationMode.portraitFallback => [DeviceOrientation.portraitUp],
    };
    await SystemChrome.setPreferredOrientations(orientations);
  }
}
