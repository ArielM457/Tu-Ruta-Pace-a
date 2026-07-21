import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router.dart';
import '../../../../app/theme.dart';
import '../../../../core/widgets/chasqui_card.dart';
import '../../../../core/widgets/chasqui_tag.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../../../core/supabase/supabase_providers.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../community/domain/community_entities.dart';
import '../../../community/presentation/widgets/community_badge_ui.dart';
import '../../domain/user_profile.dart';
import '../providers/profile_providers.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileState = ref.watch(profileControllerProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi perfil'),
        automaticallyImplyLeading: false,
      ),
      body: profileState.when(
        loading: () => const LoadingView(message: 'Cargando tu perfil…'),
        error: (error, stackTrace) => ErrorView(
          message: error.toString(),
          onRetry: () => ref.invalidate(profileControllerProvider),
        ),
        data: (profile) => _ProfileContent(profile: profile),
      ),
    );
  }
}

const double _tabBarClearance = 112;

class _ProfileContent extends ConsumerWidget {
  const _ProfileContent({required this.profile});

  final UserProfile profile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final email = ref.watch(currentSessionProvider)?.user.email ?? 'Sin correo';
    final displayName = profile.displayName?.trim().isNotEmpty == true
        ? profile.displayName!
        : 'Sin nombre';
    final badge = communityBadgeForPoints(profile.ayniPoints);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, _tabBarClearance),
      children: [
        Row(
          children: [
            Container(
              width: 64,
              height: 64,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: ChasquiColors.yellow600,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                displayName.characters.first.toUpperCase(),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: ChasquiColors.neutral950,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayName,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 2, bottom: 6),
                    child: Text(email, style: theme.textTheme.bodySmall),
                  ),
                  Row(
                    children: [
                      ChasquiTag(
                        label: '${profile.ayniPoints} pts',
                        background: ChasquiColors.yellow200,
                        foreground: ChasquiColors.yellow800,
                      ),
                      const SizedBox(width: 6),
                      ChasquiTag(
                        label: badge.label,
                        background: badge.accentColor.withValues(alpha: 0.15),
                        foreground: badge.accentColor,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        _ProfileSection(
          title: 'Mi cuenta',
          items: [
            _ProfileItem(
              icon: Icons.person_outline_rounded,
              label: 'Información personal',
              subtitle: 'Nombre, teléfono, correo',
              onTap: () => context.push(AppRoutes.personalInfo),
            ),
            _ProfileItem(
              icon: Icons.star_outline_rounded,
              label: 'Preferencias',
              subtitle: 'Rutas favoritas, modo de viaje',
              onTap: () => context.push(AppRoutes.preferences),
            ),
            _ProfileItem(
              icon: Icons.emoji_events_outlined,
              label: 'Puntos y recompensas',
              subtitle: '${profile.ayniPoints} puntos disponibles',
              onTap: () => context.push(AppRoutes.pointsHistory),
            ),
          ],
        ),
        const SizedBox(height: 20),
        _ProfileSection(
          title: 'Familia y comunidad',
          items: [
            _ProfileItem(
              icon: Icons.groups_outlined,
              label: 'Cuenta familiar',
              subtitle: 'Vincula a tu familia',
              onTap: () => context.push(AppRoutes.family),
            ),
            _ProfileItem(
              icon: Icons.description_outlined,
              label: 'Mis denuncias',
              subtitle: 'Revisa tus reportes enviados',
              onTap: () => context.go(AppRoutes.complaints),
            ),
            _HelpHistoryItem(),
          ],
        ),
        const SizedBox(height: 20),
        Text('CONFIGURACIÓN', style: theme.textTheme.labelSmall),
        const SizedBox(height: 10),
        ChasquiCard(
          child: Column(
            children: [
              _SettingsToggle(
                label: 'Alertas de ruta',
                subtitle: 'Bloqueos y desvíos en tiempo real',
                value: profile.routeAlertsEnabled,
                onChanged: (value) => ref
                    .read(profileControllerProvider.notifier)
                    .updatePreferences(routeAlertsEnabled: value),
              ),
              const SizedBox(height: 16),
              _SettingsToggle(
                label: 'Compartir ubicación',
                subtitle: 'Con mi cuenta familiar',
                value: profile.shareLocationWithFamily,
                onChanged: (value) => ref
                    .read(profileControllerProvider.notifier)
                    .updatePreferences(shareLocationWithFamily: value),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        OutlinedButton.icon(
          icon: const Icon(Icons.logout),
          label: const Text('Cerrar sesión'),
          onPressed: () => ref.read(authControllerProvider.notifier).signOut(),
        ),
      ],
    );
  }
}

class _ProfileSection extends StatelessWidget {
  const _ProfileSection({required this.title, required this.items});

  final String title;
  final List<Widget> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title.toUpperCase(), style: Theme.of(context).textTheme.labelSmall),
        const SizedBox(height: 10),
        for (final item in items) ...[item, const SizedBox(height: 8)],
      ],
    );
  }
}

class _ProfileItem extends StatelessWidget {
  const _ProfileItem({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$label. $subtitle',
      button: true,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: ChasquiColors.neutral100),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: ChasquiColors.yellow100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 16, color: ChasquiColors.yellow800),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: ChasquiColors.neutral950,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 11,
                        color: ChasquiColors.neutral500,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                size: 18,
                color: ChasquiColors.neutral300,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HelpHistoryItem extends ConsumerWidget {
  const _HelpHistoryItem();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final countState = ref.watch(peopleHelpedCountProvider);
    final count = countState.value ?? 0;
    return _ProfileItem(
      icon: Icons.favorite_border_rounded,
      label: 'Historial de ayuda',
      subtitle: 'Has ayudado a $count persona${count == 1 ? '' : 's'}',
      onTap: () => showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Historial de ayuda'),
          content: Text(
            'Ayudaste a $count persona${count == 1 ? '' : 's'} respondiendo preguntas de la comunidad y verificando reportes de bloqueos.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cerrar'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsToggle extends StatelessWidget {
  const _SettingsToggle({
    required this.label,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      toggled: value,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: ChasquiColors.neutral950,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 11,
                    color: ChasquiColors.neutral500,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeTrackColor: ChasquiColors.yellow600,
          ),
        ],
      ),
    );
  }
}
