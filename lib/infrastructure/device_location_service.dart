import 'package:geolocator/geolocator.dart';

import '../domain/route_config.dart';

enum ProjectLocationPermission {
  granted,
  denied,
  deniedForever,
  serviceDisabled
}

abstract interface class LocationService {
  Future<ProjectLocationPermission> requestPermission();
  Stream<LocationSample> watch();
  Future<bool> openSettings();
}

class DeviceLocationService implements LocationService {
  @override
  Future<ProjectLocationPermission> requestPermission() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      return ProjectLocationPermission.serviceDisabled;
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    return switch (permission) {
      LocationPermission.denied => ProjectLocationPermission.denied,
      LocationPermission.deniedForever =>
        ProjectLocationPermission.deniedForever,
      _ => ProjectLocationPermission.granted,
    };
  }

  @override
  Stream<LocationSample> watch() => Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 3,
        ),
      ).map(
        (position) => LocationSample(
          latitude: position.latitude,
          longitude: position.longitude,
          accuracyM: position.accuracy,
          timestamp: position.timestamp,
        ),
      );

  @override
  Future<bool> openSettings() => Geolocator.openAppSettings();
}

class SimulatedLocationService implements LocationService {
  SimulatedLocationService(this.samples);
  final Stream<LocationSample> samples;
  @override
  Future<ProjectLocationPermission> requestPermission() async =>
      ProjectLocationPermission.granted;
  @override
  Stream<LocationSample> watch() => samples;
  @override
  Future<bool> openSettings() async => true;
}
