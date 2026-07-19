import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/api/api_client.dart';
import '../../data/api_complaints_repository.dart';
import '../../domain/complaint_entities.dart';
import '../../domain/complaints_repository.dart';

final complaintsRepositoryProvider = Provider<ComplaintsRepository>(
  (ref) => ApiComplaintsRepository(
    ref.watch(apiClientProvider),
    Supabase.instance.client,
  ),
);

final myComplaintsProvider =
    AsyncNotifierProvider<MyComplaintsNotifier, List<Complaint>>(
  MyComplaintsNotifier.new,
);

class MyComplaintsNotifier extends AsyncNotifier<List<Complaint>> {
  @override
  Future<List<Complaint>> build() {
    return ref.read(complaintsRepositoryProvider).getMine();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(complaintsRepositoryProvider).getMine(),
    );
  }

  void addOptimistic(Complaint complaint) {
    final current = state.value ?? [];
    state = AsyncData([complaint, ...current]);
  }
}

final createComplaintControllerProvider =
    AsyncNotifierProvider<CreateComplaintController, Complaint?>(
  CreateComplaintController.new,
);

class CreateComplaintController extends AsyncNotifier<Complaint?> {
  @override
  Future<Complaint?> build() async => null;

  Future<bool> submit({
    required ComplaintType type,
    String? vehicleIdentifier,
    String? routeLabel,
    required String description,
    File? photo,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(complaintsRepositoryProvider).create(
            type: type,
            vehicleIdentifier: vehicleIdentifier,
            routeLabel: routeLabel,
            description: description,
            photo: photo,
          ),
    );
    final complaint = state.value;
    if (!state.hasError && complaint != null) {
      ref.read(myComplaintsProvider.notifier).addOptimistic(complaint);
    }
    return !state.hasError;
  }
}
