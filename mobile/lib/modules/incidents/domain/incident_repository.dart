import 'dart:io';

import '../../../core/types/coordinate.dart';
import 'incident_entities.dart';

abstract class IncidentRepository {
  Future<List<Incident>> getActive({String? bbox});
  Future<List<Incident>> getPendingNear(Coordinate pos, {int radius = 800});
  Future<Incident> report({
    required IncidentKind kind,
    required Coordinate position,
    required String description,
    File? photo,
  });
  Future<Incident> vote(String incidentId, {required bool confirm});
}
