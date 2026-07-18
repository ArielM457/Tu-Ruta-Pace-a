import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/api_client.dart';
import '../../../../core/types/coordinate.dart';
import '../../../profile/domain/user_profile.dart';
import '../../../profile/presentation/providers/profile_providers.dart';
import '../../data/api_routing_repository.dart';
import '../../domain/route_entities.dart';
import '../../domain/routing_repository.dart';

final routingRepositoryProvider = Provider<RoutingRepository>(
  (ref) => ApiRoutingRepository(ref.watch(apiClientProvider)),
);

class RouteRequestState {
  const RouteRequestState({
    this.origin,
    this.destination,
    required this.priority,
  });

  final Coordinate? origin;
  final Coordinate? destination;
  final TravelPriority priority;

  bool get isComplete => origin != null && destination != null;

  RouteRequestState copyWith({
    Coordinate? origin,
    Coordinate? destination,
    TravelPriority? priority,
  }) {
    return RouteRequestState(
      origin: origin ?? this.origin,
      destination: destination ?? this.destination,
      priority: priority ?? this.priority,
    );
  }
}

final routeRequestProvider =
    NotifierProvider<RouteRequestController, RouteRequestState>(
  RouteRequestController.new,
);

class RouteRequestController extends Notifier<RouteRequestState> {
  @override
  RouteRequestState build() {
    final profile = ref.read(profileControllerProvider).value;
    return RouteRequestState(
      priority: profile?.defaultPriority ?? TravelPriority.time,
    );
  }

  void setOrigin(Coordinate origin) {
    state = state.copyWith(origin: origin);
  }

  void setDestination(Coordinate destination) {
    state = state.copyWith(destination: destination);
  }

  void setPriority(TravelPriority priority) {
    state = state.copyWith(priority: priority);
  }

  void clearDestination() {
    state = RouteRequestState(origin: state.origin, priority: state.priority);
  }
}

final recommendationsProvider =
    FutureProvider.autoDispose<RouteRecommendation>((ref) async {
  final request = ref.watch(routeRequestProvider);
  if (!request.isComplete) {
    return const RouteRecommendation(
      options: [],
      activeIncidentsConsidered: 0,
    );
  }
  final profile = ref.read(profileControllerProvider).value;
  return ref.watch(routingRepositoryProvider).getRecommendations(
        origin: request.origin!,
        destination: request.destination!,
        priority: request.priority,
        accessibility: profile?.accessibilityProfile,
      );
});

final sortPriorityProvider =
    NotifierProvider<SortPriorityController, TravelPriority>(
  SortPriorityController.new,
);

class SortPriorityController extends Notifier<TravelPriority> {
  @override
  TravelPriority build() {
    return ref.watch(routeRequestProvider.select((request) => request.priority));
  }

  void select(TravelPriority priority) {
    state = priority;
  }
}

final sortedOptionsProvider = Provider.autoDispose<List<RouteOption>>((ref) {
  final recommendation = ref.watch(recommendationsProvider).value;
  final priority = ref.watch(sortPriorityProvider);
  final options = [...?recommendation?.options];
  options.sort(switch (priority) {
    TravelPriority.time => (first, second) =>
        first.totalDurationMinutes.compareTo(second.totalDurationMinutes),
    TravelPriority.cost => (first, second) =>
        first.totalCostBs.compareTo(second.totalCostBs),
    TravelPriority.safety => (first, second) =>
        second.safetyScore.compareTo(first.safetyScore),
  });
  return options;
});

final selectedRouteOptionProvider =
    NotifierProvider<SelectedRouteOptionController, RouteOption?>(
  SelectedRouteOptionController.new,
);

class SelectedRouteOptionController extends Notifier<RouteOption?> {
  @override
  RouteOption? build() => null;

  void select(RouteOption option) {
    state = option;
  }
}
