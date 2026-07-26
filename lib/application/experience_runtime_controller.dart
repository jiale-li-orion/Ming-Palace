import 'dart:async';

import '../domain/experience_session_state.dart';
import '../domain/route_config.dart';
import '../infrastructure/device_location_service.dart';
import 'navigation_controller.dart';
import 'orientation_controller.dart';
import 'project_experience_engine.dart';

class ExperienceRuntimeController {
  ExperienceRuntimeController({
    required this.engine,
    required this.locationService,
    required this.orientationService,
    RouteConfig? route,
  }) : navigation =
            NavigationController(route: route ?? RouteConfig.temporaryDemo());

  final ProjectExperienceEngine engine;
  final LocationService locationService;
  final OrientationService orientationService;
  final NavigationController navigation;
  StreamSubscription<LocationSample>? _locations;
  ExperiencePhase? _lastPhase;
  OrientationMode? _lastOrientation;
  Timer? _observationTimer;

  Future<void> start() async {
    engine.onObservationWaitRequested = _scheduleObservationTimer;
    engine.addListener(_onEngineChanged);
    await _onEngineChangedAsync();
  }

  void _scheduleObservationTimer(Duration delay) {
    _observationTimer?.cancel();
    _observationTimer = Timer(delay, engine.onObservationTimer);
  }

  void _onEngineChanged() => unawaited(_onEngineChangedAsync());

  Future<void> _onEngineChangedAsync() async {
    final state = engine.state;
    if (_lastOrientation != state.orientationMode) {
      _lastOrientation = state.orientationMode;
      await orientationService.apply(state.orientationMode);
    }
    if (_lastPhase == state.phase) return;
    _lastPhase = state.phase;
    final needsLocation = state.phase == ExperiencePhase.walkToWumen ||
        state.phase == ExperiencePhase.wumenApproach ||
        state.phase == ExperiencePhase.walkToEnding;
    if (needsLocation && _locations == null) {
      final permission = await locationService.requestPermission();
      if (permission != ProjectLocationPermission.granted) {
        engine.useManualNavigation();
        return;
      }
      _locations = locationService.watch().listen((sample) {
        engine.updateNavigation(navigation.evaluate(sample));
      }, onError: (_) => engine.useManualNavigation());
    } else if (!needsLocation && _locations != null) {
      await _locations?.cancel();
      _locations = null;
    }
  }

  Future<void> dispose() async {
    _observationTimer?.cancel();
    engine.onObservationWaitRequested = null;
    engine.removeListener(_onEngineChanged);
    await _locations?.cancel();
  }
}
