import 'trip.dart';

abstract class TripsRepository {
  Future<Trip> startTrip(Map<String, dynamic> routeSnapshot);

  Future<Trip> finishTrip(String tripId);

  Future<List<Trip>> listTrips({int page = 1, int pageSize = 5});
}
