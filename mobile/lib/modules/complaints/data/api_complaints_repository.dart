import 'dart:io';

import 'package:dio/dio.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/api/api_client.dart';
import '../domain/complaint_entities.dart';
import '../domain/complaints_repository.dart';

class ApiComplaintsRepository implements ComplaintsRepository {
  const ApiComplaintsRepository(this._dio, this._supabase);

  final Dio _dio;
  final SupabaseClient _supabase;

  @override
  Future<Complaint> create({
    required ComplaintType type,
    String? vehicleIdentifier,
    String? routeLabel,
    required String description,
    File? photo,
  }) async {
    final photoUrl = photo != null ? await _uploadPhoto(photo) : null;
    try {
      final response = await _dio.post<dynamic>(
        '/complaints',
        data: {
          'type': type.apiValue,
          if (vehicleIdentifier != null) 'vehicleIdentifier': vehicleIdentifier,
          if (routeLabel != null) 'routeLabel': routeLabel,
          'complaint': description,
          if (photoUrl != null) 'photoUrl': photoUrl,
        },
      );
      return Complaint.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw toApiException(e);
    }
  }

  @override
  Future<List<Complaint>> getMine() async {
    try {
      final response = await _dio.get<dynamic>('/complaints/mine');
      return (response.data as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .map(Complaint.fromJson)
          .toList();
    } on DioException catch (e) {
      throw toApiException(e);
    }
  }

  Future<String?> _uploadPhoto(File photo) async {
    try {
      final ext = photo.path.split('.').last;
      final name = 'complaint-${DateTime.now().millisecondsSinceEpoch}.$ext';
      await _supabase.storage.from('incident-photos').upload(name, photo);
      return _supabase.storage.from('incident-photos').getPublicUrl(name);
    } catch (_) {
      return null;
    }
  }
}
