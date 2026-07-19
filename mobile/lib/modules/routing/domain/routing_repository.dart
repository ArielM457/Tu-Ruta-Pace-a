import '../../../core/types/coordinate.dart';
import '../../profile/domain/user_profile.dart';
import 'place_suggestion.dart';
import 'route_entities.dart';

abstract class RoutingRepository {
  Future<RouteRecommendation> getRecommendations({
    required Coordinate origin,
    required Coordinate destination,
    TravelPriority? priority,
    AccessibilityProfile? accessibility,
  });

  Future<List<PlaceSuggestion>> autocompletePlaces(String query);
}
