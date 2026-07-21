import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/api_client.dart';
import '../../../routing/domain/route_entities.dart';
import '../../data/api_trips_repository.dart';
import '../../domain/trip.dart';
import '../../domain/trips_repository.dart';

final tripsRepositoryProvider = Provider<TripsRepository>(
  (ref) => ApiTripsRepository(ref.watch(apiClientProvider)),
);

final recentTripsProvider = FutureProvider.autoDispose<List<Trip>>(
  (ref) => ref.read(tripsRepositoryProvider).listTrips(),
);

final startTripControllerProvider =
    AsyncNotifierProvider<StartTripController, Trip?>(StartTripController.new);

class StartTripController extends AsyncNotifier<Trip?> {
  @override
  Future<Trip?> build() async => null;

  Future<bool> startTrip(Map<String, dynamic> routeSnapshot) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(tripsRepositoryProvider).startTrip(routeSnapshot),
    );
    return !state.hasError;
  }
}

final finishTripControllerProvider =
    AsyncNotifierProvider<FinishTripController, void>(
  FinishTripController.new,
);

class FinishTripController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<bool> finishTrip(String tripId) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(tripsRepositoryProvider).finishTrip(tripId),
    );
    return !state.hasError;
  }
}

class ActiveTrip {
  const ActiveTrip({required this.trip, required this.option});

  final Trip trip;
  final RouteOption option;
}

final activeTripProvider =
    NotifierProvider<ActiveTripNotifier, ActiveTrip?>(ActiveTripNotifier.new);

class ActiveTripNotifier extends Notifier<ActiveTrip?> {
  @override
  ActiveTrip? build() => null;

  void start(Trip trip, RouteOption option) {
    state = ActiveTrip(trip: trip, option: option);
  }

  void clear() {
    state = null;
  }
}
