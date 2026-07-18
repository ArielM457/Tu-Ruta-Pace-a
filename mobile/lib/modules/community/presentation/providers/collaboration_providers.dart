import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/api_client.dart';
import '../../../../core/location/location_providers.dart';
import '../../../profile/presentation/providers/profile_providers.dart';
import '../../data/api_collaboration_repository.dart';
import '../../domain/collaboration_entities.dart';
import '../../domain/collaboration_repository.dart';

const Duration _pingInterval = Duration(seconds: 15);

final collaborationRepositoryProvider = Provider<CollaborationRepository>(
  (ref) => ApiCollaborationRepository(ref.watch(apiClientProvider)),
);

/// Tracks the current active location share (if any) and drives the
/// 15-second ping loop. Only one share can be active at a time.
class ActiveShareNotifier extends Notifier<LocationShare?> {
  Timer? _pingTimer;

  @override
  LocationShare? build() {
    ref.onDispose(() => _pingTimer?.cancel());
    return null;
  }

  Future<void> start({required String tripId, required String lineId}) async {
    final repo = ref.read(collaborationRepositoryProvider);
    final share = await repo.startShare(tripId: tripId, lineId: lineId);
    state = share;
    _startPingLoop(share.id);
  }

  void _startPingLoop(String shareId) {
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(_pingInterval, (_) async {
      final position =
          await ref.read(locationServiceProvider).getCoarseCoordinate();
      if (position == null) return;
      try {
        await ref.read(collaborationRepositoryProvider).recordPing(
              shareId,
              position,
            );
      } catch (_) {
        // Ping failures are silent — the loop retries in 15s.
      }
    });
  }

  /// Stops the active share and returns the points earned this session.
  Future<int?> stop() async {
    final current = state;
    if (current == null) return null;
    _pingTimer?.cancel();
    _pingTimer = null;
    final repo = ref.read(collaborationRepositoryProvider);
    final closed = await repo.stopShare(current.id);
    state = null;
    if (closed.newBalance != null) {
      ref.read(profileControllerProvider.notifier).applyAyniBalance(
            closed.newBalance!,
          );
    }
    return closed.pointsAwarded;
  }
}

final activeShareProvider =
    NotifierProvider<ActiveShareNotifier, LocationShare?>(
  ActiveShareNotifier.new,
);

final ayniHistoryProvider = FutureProvider.autoDispose<AyniHistoryPage>(
  (ref) => ref.read(collaborationRepositoryProvider).getAyniHistory(),
);
