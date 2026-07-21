import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../types/coordinate.dart';

class LocationService {
  Future<bool> isLocationAvailable() async {
    final isServiceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!isServiceEnabled) {
      return false;
    }
    final permission = await Geolocator.checkPermission();
    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  Future<Coordinate?> getCurrentCoordinate() async {
    final isServiceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!isServiceEnabled) {
      return null;
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return null;
    }
    final position = await Geolocator.getCurrentPosition();
    return Coordinate(lat: position.latitude, lng: position.longitude);
  }

  /// Low-accuracy fix for background-ish periodic pings (battery friendly).
  Future<Coordinate?> getCoarseCoordinate() async {
    final isServiceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!isServiceEnabled) {
      return null;
    }
    final permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return null;
    }
    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.low),
    );
    return Coordinate(lat: position.latitude, lng: position.longitude);
  }
}

final locationServiceProvider = Provider<LocationService>(
  (ref) => LocationService(),
);

final currentPositionProvider = FutureProvider<Coordinate?>(
  (ref) => ref.watch(locationServiceProvider).getCurrentCoordinate(),
);
