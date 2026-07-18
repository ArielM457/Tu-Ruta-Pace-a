import 'trip.dart';

abstract class TripsRepository {
  Future<Trip> startTrip(Map<String, dynamic> routeSnapshot);

  Future<Trip> finishTrip(String tripId);
}
