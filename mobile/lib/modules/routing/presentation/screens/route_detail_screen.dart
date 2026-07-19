import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router.dart';
import '../../../../app/theme.dart';
import '../../../../core/types/coordinate.dart';
import '../../../../core/widgets/chasqui_card.dart';
import '../../../../core/widgets/chasqui_tag.dart';
import '../../../../core/widgets/chasqui_top_bar.dart';
import '../../../community/presentation/providers/collaboration_providers.dart';
import '../../../community/presentation/widgets/ask_question_sheet.dart';
import '../../../community/presentation/widgets/share_optin_sheet.dart';
import '../../../profile/presentation/providers/favorites_providers.dart';
import '../../../trips/presentation/providers/trips_providers.dart';
import '../../data/route_recommendation_mapper.dart';
import '../../domain/route_entities.dart';
import '../providers/routing_providers.dart';
import '../widgets/route_option_display.dart';
import '../widgets/transport_mode_ui.dart';

class RouteDetailScreen extends ConsumerWidget {
  const RouteDetailScreen({super.key});

  Future<void> _startTrip(
    BuildContext context,
    WidgetRef ref,
    RouteOption option,
  ) async {
    final started = await ref
        .read(startTripControllerProvider.notifier)
        .startTrip(routeOptionToJson(option));
    if (!context.mounted) {
      return;
    }
    final messenger = ScaffoldMessenger.of(context);
    if (!started) {
      final error = ref.read(startTripControllerProvider).error;
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            error?.toString() ?? 'No se pudo iniciar el viaje. Intenta de nuevo.',
          ),
        ),
      );
      return;
    }

    final trip = ref.read(startTripControllerProvider).value;
    if (trip == null) return;
    ref.read(activeTripProvider.notifier).start(trip, option);

    final firstTransitLeg = option.legs.firstWhere(
      (leg) => leg.mode != TransportMode.walk && leg.lineId != null,
      orElse: () => const RouteLeg(
        mode: TransportMode.walk,
        durationMinutes: 0,
        distanceMeters: 0,
        costBs: 0,
        polyline: '',
        instruction: '',
      ),
    );

    if (firstTransitLeg.lineId != null && context.mounted) {
      final wantsToShare = await ShareOptInSheet.show(
        context,
        lineLabel: firstTransitLeg.lineName ?? 'tu línea de transporte',
      );
      if (wantsToShare == true) {
        try {
          await ref.read(activeShareProvider.notifier).start(
                tripId: trip.id,
                lineId: firstTransitLeg.lineId!,
              );
        } catch (_) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('No se pudo iniciar el compartido de ubicación.'),
              ),
            );
          }
        }
      }
    }

    if (context.mounted) {
      context.go(AppRoutes.map);
    }
  }

  void _askCommunity(BuildContext context, RouteLeg leg) {
    AskQuestionSheet.show(
      context,
      lineId: leg.lineId!,
      lineLabel: leg.lineName ?? 'esta línea',
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final option = ref.watch(selectedRouteOptionProvider);
    final startTripState = ref.watch(startTripControllerProvider);
    if (option == null) {
      return Scaffold(
        appBar: const ChasquiTopBar(title: 'Detalle de ruta'),
        body: Center(
          child: FilledButton(
            onPressed: () => context.go(AppRoutes.routeOptions),
            child: const Text('Volver a las opciones'),
          ),
        ),
      );
    }
    final theme = Theme.of(context);
    final tag = classifyRouteOptionTags([option])[option.id] ??
        RouteOptionTagKind.combined;
    final transfers = countRouteTransfers(option);
    final name = compositeRouteName(option);

    final destination = ref.watch(routeRequestProvider).destination;

    return Scaffold(
      appBar: ChasquiTopBar(
        title: 'Detalle de ruta',
        onBack: () => context.pop(),
        trailing: destination == null
            ? null
            : IconButton(
                tooltip: 'Guardar como favorita',
                icon: const Icon(Icons.star_outline_rounded),
                onPressed: () => _SaveFavoriteDialog.show(context, ref, destination),
              ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                ChasquiCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          ChasquiTag(
                            label: tag.label,
                            background: tag.background,
                            foreground: tag.foreground,
                          ),
                          Text(
                            transfers == 0
                                ? 'Sin transbordos'
                                : '$transfers transbordo${transfers > 1 ? 's' : ''}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: ChasquiColors.neutral500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(name, style: theme.textTheme.titleSmall),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Tiempo total',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: ChasquiColors.neutral500,
                                  ),
                                ),
                                Text.rich(
                                  TextSpan(
                                    text: '${option.totalDurationMinutes}',
                                    style: const TextStyle(
                                      fontSize: 26,
                                      fontWeight: FontWeight.w900,
                                      color: ChasquiColors.neutral950,
                                    ),
                                    children: const [
                                      TextSpan(
                                        text: ' min',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.normal,
                                          color: ChasquiColors.neutral950,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Costo total',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: ChasquiColors.neutral500,
                                  ),
                                ),
                                Text(
                                  formatCostBs(option.totalCostBs),
                                  style: const TextStyle(
                                    fontSize: 26,
                                    fontWeight: FontWeight.w900,
                                    color: ChasquiColors.yellow700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (option.avoidsAnyIncident) ...[
                        const SizedBox(height: 10),
                        Text(
                          'Esta ruta evita bloqueos activos en la ciudad',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: ChasquiColors.yellow800,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Text('PASO A PASO', style: theme.textTheme.labelSmall),
                const SizedBox(height: 12),
                for (int index = 0; index < option.legs.length; index++)
                  _LegTile(
                    leg: option.legs[index],
                    isLast: index == option.legs.length - 1,
                    onAskCommunity: option.legs[index].mode != TransportMode.walk &&
                            option.legs[index].lineId != null
                        ? () => _askCommunity(context, option.legs[index])
                        : null,
                  ),
              ],
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: FilledButton(
                onPressed: startTripState.isLoading
                    ? null
                    : () => _startTrip(context, ref, option),
                child: startTripState.isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Iniciar navegación'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SaveFavoriteDialog extends StatefulWidget {
  const _SaveFavoriteDialog();

  static Future<void> show(
    BuildContext context,
    WidgetRef ref,
    Coordinate destination,
  ) async {
    final name = await showDialog<String>(
      context: context,
      builder: (_) => const _SaveFavoriteDialog(),
    );
    if (name == null || name.trim().isEmpty || !context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    final ok = await ref
        .read(favoritesProvider.notifier)
        .add(name.trim(), destination);
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          ok ? 'Guardado en tus favoritas' : 'No se pudo guardar la favorita',
        ),
      ),
    );
  }

  @override
  State<_SaveFavoriteDialog> createState() => _SaveFavoriteDialogState();
}

class _SaveFavoriteDialogState extends State<_SaveFavoriteDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Guardar como favorita'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        decoration: const InputDecoration(hintText: 'Ej: Casa, Trabajo'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_controller.text),
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}

class _LegTile extends StatelessWidget {
  const _LegTile({required this.leg, required this.isLast, this.onAskCommunity});

  final RouteLeg leg;
  final bool isLast;
  final VoidCallback? onAskCommunity;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lineDetail = [
      if (leg.lineName != null) leg.lineName!,
      if (leg.boardStop != null) 'Sube en ${leg.boardStop!.name}',
      if (leg.alightStop != null) 'Baja en ${leg.alightStop!.name}',
    ].join(' · ');

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: ChasquiColors.yellow100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  leg.mode.icon,
                  size: 14,
                  color: ChasquiColors.yellow800,
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 1,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    color: ChasquiColors.neutral200,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    leg.instruction,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (lineDetail.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(lineDetail, style: theme.textTheme.bodySmall),
                    ),
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.access_time_rounded,
                          size: 11,
                          color: ChasquiColors.neutral400,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          '${leg.durationMinutes} min',
                          style: const TextStyle(
                            fontSize: 11,
                            color: ChasquiColors.neutral500,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          leg.costBs > 0 ? formatCostBs(leg.costBs) : 'Gratis',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: leg.costBs > 0
                                ? ChasquiColors.yellow700
                                : ChasquiColors.successText,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (onAskCommunity != null)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: onAskCommunity,
                        icon: const Icon(Icons.forum_outlined, size: 16),
                        label: const Text('Preguntar a la comunidad'),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(0, 32),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
