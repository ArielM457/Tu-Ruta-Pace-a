import 'dart:io';

import 'complaint_entities.dart';

abstract class ComplaintsRepository {
  Future<Complaint> create({
    required ComplaintType type,
    String? vehicleIdentifier,
    String? routeLabel,
    required String description,
    File? photo,
  });

  Future<List<Complaint>> getMine();
}
