import '../../../core/types/coordinate.dart';
import 'collaboration_entities.dart';

abstract class CollaborationRepository {
  Future<LocationShare> startShare({
    required String tripId,
    required String lineId,
  });

  Future<void> recordPing(String shareId, Coordinate position);

  Future<LocationShare> stopShare(String shareId);

  Future<AyniHistoryPage> getAyniHistory({int page = 1, int pageSize = 20});
}
