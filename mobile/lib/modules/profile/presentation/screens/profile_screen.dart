import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router.dart';
import '../../../../core/supabase/supabase_providers.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/user_profile.dart';
import '../providers/profile_providers.dart';
import '../widgets/preference_options.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileState = ref.watch(profileControllerProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi perfil'),
        leading: BackButton(onPressed: () => context.go(AppRoutes.home)),
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

class _ProfileContent extends ConsumerWidget {
  const _ProfileContent({required this.profile});

  final UserProfile profile;

  Future<void> _editAccessibility(BuildContext context, WidgetRef ref) async {
    final selected = await _pickOption<AccessibilityProfile>(
      context,
      title: 'Necesidad de accesibilidad',
      options: [
        for (final option in AccessibilityProfile.values)
          (value: option, icon: option.icon, label: option.label),
      ],
      current: profile.accessibilityProfile,
    );
    if (selected != null) {
      await ref
          .read(profileControllerProvider.notifier)
          .updatePreferences(accessibilityProfile: selected);
    }
  }

  Future<void> _editPriority(BuildContext context, WidgetRef ref) async {
    final selected = await _pickOption<TravelPriority>(
      context,
      title: 'Prioridad al viajar',
      options: [
        for (final option in TravelPriority.values)
          (value: option, icon: option.icon, label: option.label),
      ],
      current: profile.defaultPriority,
    );
    if (selected != null) {
      await ref
          .read(profileControllerProvider.notifier)
          .updatePreferences(defaultPriority: selected);
    }
  }

  Future<void> _editDisplayName(BuildContext context, WidgetRef ref) async {
    final nameController =
        TextEditingController(text: profile.displayName ?? '');
    final newName = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Editar nombre'),
        content: TextField(
          controller: nameController,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(labelText: 'Nombre'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.of(dialogContext).pop(nameController.text.trim()),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
    if (newName != null && newName.length >= 2) {
      await ref
          .read(profileControllerProvider.notifier)
          .updatePreferences(displayName: newName);
    }
  }

  Future<T?> _pickOption<T>(
    BuildContext context, {
    required String title,
    required List<({T value, IconData icon, String label})> options,
    required T current,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title, style: Theme.of(sheetContext).textTheme.titleMedium),
            const SizedBox(height: 8),
            for (final option in options)
              ListTile(
                leading: Icon(option.icon),
                title: Text(option.label),
                trailing: option.value == current
                    ? Icon(
                        Icons.check,
                        color: Theme.of(sheetContext).colorScheme.primary,
                      )
                    : null,
                onTap: () => Navigator.of(sheetContext).pop(option.value),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final email =
        ref.watch(currentSessionProvider)?.user.email ?? 'Sin correo';
    final displayName = profile.displayName ?? 'Sin nombre';
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 32,
              child: Text(
                displayName.characters.first.toUpperCase(),
                style: theme.textTheme.headlineSmall,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(displayName, style: theme.textTheme.titleLarge),
                  Text(email, style: theme.textTheme.bodyMedium),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Editar nombre',
              icon: const Icon(Icons.edit),
              onPressed: () => _editDisplayName(context, ref),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Card(
          color: theme.colorScheme.primaryContainer,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => context.push(AppRoutes.community),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    Icons.handshake,
                    size: 40,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${profile.ayniPoints} puntos Ayni',
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: theme.colorScheme.onPrimaryContainer,
                          ),
                        ),
                        Text(
                          'Gana puntos ayudando a otros viajeros — toca para ver tu historial',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right, color: theme.colorScheme.onPrimaryContainer),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text('Mis preferencias', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        ListTile(
          leading: Icon(profile.accessibilityProfile.icon),
          title: const Text('Accesibilidad'),
          subtitle: Text(profile.accessibilityProfile.label),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _editAccessibility(context, ref),
        ),
        ListTile(
          leading: Icon(profile.defaultPriority.icon),
          title: const Text('Prioridad al viajar'),
          subtitle: Text(profile.defaultPriority.label),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _editPriority(context, ref),
        ),
        const SizedBox(height: 24),
        OutlinedButton.icon(
          icon: const Icon(Icons.logout),
          label: const Text('Cerrar sesión'),
          onPressed: () =>
              ref.read(authControllerProvider.notifier).signOut(),
        ),
      ],
    );
  }
}
