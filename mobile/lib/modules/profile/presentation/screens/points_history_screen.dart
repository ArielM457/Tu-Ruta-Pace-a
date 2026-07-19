import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme.dart';
import '../../../../core/widgets/chasqui_top_bar.dart';
import '../../../community/presentation/providers/collaboration_providers.dart';
import '../widgets/ayni_movement_tile.dart';

class PointsHistoryScreen extends ConsumerWidget {
  const PointsHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyState = ref.watch(ayniHistoryProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: ChasquiTopBar(
        title: 'Puntos y recompensas',
        onBack: () => context.pop(),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(ayniHistoryProvider.future),
        child: historyState.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text(
                'No pudimos cargar tu historial. Desliza para reintentar.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ),
          data: (page) {
            if (page.movements.isEmpty) {
              return ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  Text(
                    'Todavía no tienes movimientos de Puntos Chass.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              );
            }
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: ChasquiColors.yellow200,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: ChasquiColors.yellow400),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '${page.balance}',
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          color: ChasquiColors.neutral950,
                        ),
                      ),
                      const Text(
                        'Puntos Chass disponibles',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: ChasquiColors.yellow800,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Text('HISTORIAL', style: theme.textTheme.labelSmall),
                const SizedBox(height: 10),
                for (final (i, movement) in page.movements.indexed) ...[
                  AyniMovementTile(movement: movement, index: i),
                  const SizedBox(height: 8),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}
