import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme.dart';
import '../../../../core/widgets/chasqui_top_bar.dart';
import '../../domain/favorite.dart';
import '../../domain/user_profile.dart';
import '../providers/favorites_providers.dart';
import '../providers/profile_providers.dart';
import '../widgets/preference_options.dart';

class PreferencesScreen extends ConsumerWidget {
  const PreferencesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final profile = ref.watch(profileControllerProvider).value;
    final favoritesState = ref.watch(favoritesProvider);

    return Scaffold(
      appBar: ChasquiTopBar(
        title: 'Preferencias',
        onBack: () => context.pop(),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('MODO DE VIAJE', style: theme.textTheme.labelSmall),
          const SizedBox(height: 10),
          for (final option in TravelPriority.values)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: PreferenceOptionCard(
                icon: option.icon,
                title: option.label,
                subtitle: option.description,
                isSelected: profile?.defaultPriority == option,
                onTap: () => ref
                    .read(profileControllerProvider.notifier)
                    .updatePreferences(defaultPriority: option),
              ),
            ),
          const SizedBox(height: 12),
          Text('ACCESIBILIDAD', style: theme.textTheme.labelSmall),
          const SizedBox(height: 10),
          for (final option in AccessibilityProfile.values)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: PreferenceOptionCard(
                icon: option.icon,
                title: option.label,
                subtitle: option.description,
                isSelected: profile?.accessibilityProfile == option,
                onTap: () => ref
                    .read(profileControllerProvider.notifier)
                    .updatePreferences(accessibilityProfile: option),
              ),
            ),
          const SizedBox(height: 12),
          Text('RUTAS FAVORITAS', style: theme.textTheme.labelSmall),
          const SizedBox(height: 10),
          favoritesState.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, _) => Text(
              'No pudimos cargar tus favoritas.',
              style: theme.textTheme.bodySmall,
            ),
            data: (favorites) {
              if (favorites.isEmpty) {
                return Text(
                  'Guarda un destino como favorita desde el detalle de una ruta.',
                  style: theme.textTheme.bodySmall,
                );
              }
              return Column(
                children: [
                  for (final favorite in favorites) ...[
                    _FavoriteTile(favorite: favorite),
                    const SizedBox(height: 8),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _FavoriteTile extends ConsumerWidget {
  const _FavoriteTile({required this.favorite});

  final Favorite favorite;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ChasquiColors.neutral100),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.star_rounded,
            size: 18,
            color: ChasquiColors.yellow700,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              favorite.name,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: ChasquiColors.neutral950,
              ),
            ),
          ),
          Semantics(
            label: 'Eliminar ${favorite.name} de favoritas',
            button: true,
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => ref.read(favoritesProvider.notifier).remove(favorite.id),
              child: const Padding(
                padding: EdgeInsets.all(4),
                child: Icon(
                  Icons.close_rounded,
                  size: 16,
                  color: ChasquiColors.neutral400,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
