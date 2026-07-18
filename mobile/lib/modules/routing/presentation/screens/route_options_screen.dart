import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../../profile/domain/user_profile.dart';
import '../../../profile/presentation/widgets/preference_options.dart';
import '../providers/routing_providers.dart';
import '../widgets/route_option_card.dart';

class RouteOptionsScreen extends ConsumerWidget {
  const RouteOptionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recommendationState = ref.watch(recommendationsProvider);
    final sortPriority = ref.watch(sortPriorityProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Opciones de viaje'),
        leading: BackButton(onPressed: () => context.go(AppRoutes.home)),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                for (final option in TravelPriority.values)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      avatar: Icon(option.icon, size: 18),
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
                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (recommendation.activeIncidentsConsidered > 0)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          'Se consideraron ${recommendation.activeIncidentsConsidered} incidentes activos en la ciudad',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    for (final option in sortedOptions)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: RouteOptionCard(
                          option: option,
                          onTap: () {
                            ref
                                .read(selectedRouteOptionProvider.notifier)
                                .select(option);
                            context.go(AppRoutes.routeDetail);
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
