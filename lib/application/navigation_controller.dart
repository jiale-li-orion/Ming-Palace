import 'dart:math' as math;

import '../domain/experience_session_state.dart';
import '../domain/route_config.dart';

class NavigationController {
  NavigationController({required this.route, DateTime Function()? now})
      : _now = now ?? DateTime.now;

  final RouteConfig route;
  final DateTime Function() _now;
  int _arrivalSamples = 0;

  NavigationMode evaluate(LocationSample sample) {
    final age = _now().difference(sample.timestamp).inMilliseconds.abs();
    if (age > route.thresholds.maxLocationAgeMs ||
        sample.accuracyM > route.thresholds.maxAccuracyM) {
      _arrivalSamples = 0;
      return NavigationMode.manualMode;
    }
    final location = GeoPoint(sample.latitude, sample.longitude);
    final target = route.nodes.last.point;
    if (_distanceM(location, target) <= route.thresholds.arrivalRadiusM) {
      _arrivalSamples++;
      if (_arrivalSamples >= route.thresholds.requiredConsecutiveSamples) {
        return NavigationMode.arrivalSuggested;
      }
      return NavigationMode.approaching;
    }
    _arrivalSamples = 0;
    final routeDistance = route.polyline
        .map((point) => _distanceM(location, point))
        .reduce(math.min);
    if (routeDistance > route.thresholds.offRouteDistanceM) {
      return NavigationMode.offRoute;
    }
    if (_distanceM(location, target) < route.thresholds.arrivalRadiusM * 3) {
      return NavigationMode.approaching;
    }
    return NavigationMode.stableWalk;
  }

  static double _distanceM(GeoPoint a, GeoPoint b) {
    const radius = 6371000.0;
    final lat1 = a.latitude * math.pi / 180;
    final lat2 = b.latitude * math.pi / 180;
    final dLat = (b.latitude - a.latitude) * math.pi / 180;
    final dLon = (b.longitude - a.longitude) * math.pi / 180;
    final h = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1) *
            math.cos(lat2) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    return radius * 2 * math.atan2(math.sqrt(h), math.sqrt(1 - h));
  }
}
