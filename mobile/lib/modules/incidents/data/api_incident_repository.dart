import 'dart:io';

import 'package:dio/dio.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/api/api_client.dart';
import '../../../core/types/coordinate.dart';
import '../domain/incident_entities.dart';
import '../domain/incident_repository.dart';

class ApiIncidentRepository implements IncidentRepository {
  const ApiIncidentRepository(this._dio, this._supabase);

  final Dio _dio;
  final SupabaseClient _supabase;

  @override
  Future<List<Incident>> getActive({String? bbox}) async {
    try {
      final response = await _dio.get<dynamic>(
        '/incidents/active',
        queryParameters: {if (bbox != null) 'bbox': bbox},
      );
      return (response.data as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .map(Incident.fromJson)
          .toList();
    } on DioException catch (e) {
      throw toApiException(e);
    }
  }

  @override
  Future<List<Incident>> getPendingNear(Coordinate pos, {int radius = 800}) async {
    try {
      final response = await _dio.get<dynamic>(
        '/incidents/pending/near',
        queryParameters: {
          'lat': pos.lat,
          'lng': pos.lng,
          'radius': radius,
        },
      );
      return (response.data as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .map(Incident.fromJson)
          .toList();
    } on DioException catch (e) {
      throw toApiException(e);
    }
  }

  @override
  Future<Incident> report({
    required IncidentKind kind,
    required Coordinate position,
    required String description,
    File? photo,
  }) async {
    final photoUrl = photo != null ? await _uploadPhoto(photo) : null;
    try {
      final response = await _dio.post<dynamic>(
        '/incidents',
        data: {
          'kind': kind.apiValue,
          'position': {'lat': position.lat, 'lng': position.lng},
          'description': description,
          if (photoUrl != null) 'photoUrl': photoUrl,
        },
      );
      return Incident.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw toApiException(e);
    }
  }

  @override
  Future<Incident> vote(String incidentId, {required bool confirm}) async {
    try {
      final response = await _dio.post<dynamic>(
        '/incidents/$incidentId/votes',
        data: {'vote': confirm ? 'confirm' : 'deny'},
      );
      return Incident.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw toApiException(e);
    }
  }

  Future<String?> _uploadPhoto(File photo) async {
    try {
      final ext = photo.path.split('.').last;
      final name = '${DateTime.now().millisecondsSinceEpoch}.$ext';
      await _supabase.storage.from('incident-photos').upload(name, photo);
      return _supabase.storage.from('incident-photos').getPublicUrl(name);
    } catch (_) {
      return null;
    }
  }
}
