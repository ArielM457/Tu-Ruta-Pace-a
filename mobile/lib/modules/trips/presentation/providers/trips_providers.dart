import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/api_client.dart';
import '../../data/api_trips_repository.dart';
import '../../domain/trip.dart';
import '../../domain/trips_repository.dart';

final tripsRepositoryProvider = Provider<TripsRepository>(
  (ref) => ApiTripsRepository(ref.watch(apiClientProvider)),
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
