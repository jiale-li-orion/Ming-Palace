class GeoPoint {

  factory GeoPoint.fromJson(Map<String, dynamic> json) => GeoPoint(
        (json['latitude'] as num).toDouble(),
        (json['longitude'] as num).toDouble(),
      );
  const GeoPoint(this.latitude, this.longitude);
  final double latitude;
  final double longitude;
}

class RouteNode {
  const RouteNode({required this.id, required this.point, required this.kind});
  final String id;
  final GeoPoint point;
  final String kind;
}

class RouteThresholds {
  const RouteThresholds({
    this.maxLocationAgeMs = 5000,
    this.maxAccuracyM = 20,
    this.arrivalRadiusM = 25,
    this.offRouteDistanceM = 30,
    this.requiredConsecutiveSamples = 3,
  });

  final int maxLocationAgeMs;
  final double maxAccuracyM;
  final double arrivalRadiusM;
  final double offRouteDistanceM;
  final int requiredConsecutiveSamples;
}

class RouteConfig {

  factory RouteConfig.temporaryDemo() => const RouteConfig(
        polyline: [
          GeoPoint(32.04199, 118.81261),
          GeoPoint(32.04110, 118.81253),
          GeoPoint(32.04018, 118.81245),
        ],
        nodes: [
          RouteNode(
            id: 'wumen_north',
            point: GeoPoint(32.04018, 118.81245),
            kind: 'arrival',
          ),
        ],
        thresholds: RouteThresholds(),
        temporary: true,
        calibrated: false,
        source:
            'OpenStreetMap/Mapcarta public reference; field validation required',
      );
  const RouteConfig({
    required this.polyline,
    required this.nodes,
    required this.thresholds,
    required this.temporary,
    required this.calibrated,
    required this.source,
  });

  final List<GeoPoint> polyline;
  final List<RouteNode> nodes;
  final RouteThresholds thresholds;
  final bool temporary;
  final bool calibrated;
  final String source;
}

class LocationSample {
  const LocationSample({
    required this.latitude,
    required this.longitude,
    required this.accuracyM,
    required this.timestamp,
  });

  final double latitude;
  final double longitude;
  final double accuracyM;
  final DateTime timestamp;
}
