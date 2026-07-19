import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router.dart';
import '../../../../app/theme.dart';
import '../../../../core/widgets/chasqui_top_bar.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../../profile/domain/user_profile.dart';
import '../../../profile/presentation/widgets/preference_options.dart';
import '../providers/routing_providers.dart';
import '../widgets/route_option_card.dart';
import '../widgets/route_option_display.dart';

class RouteOptionsScreen extends ConsumerWidget {
  const RouteOptionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recommendationState = ref.watch(recommendationsProvider);
    final sortPriority = ref.watch(sortPriorityProvider);
    return Scaffold(
      appBar: ChasquiTopBar(
        title: 'Planificar ruta',
        onBack: () => context.pop(),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                for (final option in TravelPriority.values)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      avatar: Icon(option.icon, size: 16),
                      label: Text(option.label),
                      selected: option == sortPriority,
                      onSelected: (_) => ref
                          .read(sortPriorityProvider.notifier)
                          .select(option),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: recommendationState.when(
              loading: () => const LoadingView(
                message: 'Calculando la mejor combinación de transportes…',
              ),
              error: (error, stackTrace) => ErrorView(
                message: error.toString(),
                onRetry: () => ref.invalidate(recommendationsProvider),
              ),
              data: (recommendation) {
                final sortedOptions = ref.watch(sortedOptionsProvider);
                if (sortedOptions.isEmpty) {
                  return const ErrorView(
                    message:
                        'No encontramos opciones de viaje para ese destino. Prueba con un punto más cercano a una vía o estación.',
                  );
                }
                final tags = classifyRouteOptionTags(recommendation.options);
                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (recommendation.activeIncidentsConsidered > 0)
                      Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: ChasquiColors.warm200,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: ChasquiColors.warm400),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.warning_amber_rounded,
                              size: 14,
                              color: ChasquiColors.orange700,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Bloqueo activo — rutas ajustadas',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: ChasquiColors.orange700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    Text(
                      '${sortedOptions.length} opciones',
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                    const SizedBox(height: 10),
                    for (final option in sortedOptions)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: RouteOptionCard(
                          option: option,
                          tag: tags[option.id] ?? RouteOptionTagKind.combined,
                          onTap: () {
                            ref
                                .read(selectedRouteOptionProvider.notifier)
                                .select(option);
                            context.push(AppRoutes.routeDetail);
                          },
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
