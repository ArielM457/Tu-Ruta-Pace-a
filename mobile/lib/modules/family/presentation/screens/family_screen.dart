import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme.dart';
import '../../../../core/widgets/chasqui_card.dart';
import '../../../../core/widgets/chasqui_tag.dart';
import '../../../../core/widgets/chasqui_top_bar.dart';
import '../../domain/family_entities.dart';
import '../providers/family_providers.dart';
import '../widgets/family_status_ui.dart';
import '../widgets/invite_family_member_sheet.dart';

const int _simulatedSupportPoints = 20;

class FamilyScreen extends ConsumerWidget {
  const FamilyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupState = ref.watch(familyGroupProvider);

    return Scaffold(
      appBar: ChasquiTopBar(
        title: 'Cuenta familiar',
        subtitle: 'Ubica y apoya a tu familia',
        onBack: () => context.pop(),
      ),
      body: groupState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'No pudimos cargar tu cuenta familiar. Intenta de nuevo.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ),
        data: (group) =>
            group == null ? const _EmptyFamilyState() : _FamilyGroupView(group: group),
      ),
    );
  }
}

class _EmptyFamilyState extends ConsumerWidget {
  const _EmptyFamilyState();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: ChasquiColors.yellow200,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.groups_rounded,
                size: 32,
                color: ChasquiColors.yellow800,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Aún no tienes una cuenta familiar',
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              'Crea una para ubicar y apoyar a tu familia, o únete con un código.',
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => _CreateGroupDialog.show(context, ref),
              child: const Text('Crear cuenta familiar'),
            ),
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: () => _JoinWithCodeDialog.show(context, ref),
              child: const Text('Unirme con un código'),
            ),
          ],
        ),
      ),
    );
  }
}

class _FamilyGroupView extends ConsumerWidget {
  const _FamilyGroupView({required this.group});

  final FamilyGroup group;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final activeCount =
        group.members.where((m) => m.status == FamilyMemberStatus.onTrip).length;
    final supportableMembers = group.members
        .where((m) => m.status != FamilyMemberStatus.pending && m.userId != null)
        .toList();

    return RefreshIndicator(
      onRefresh: () => ref.read(familyGroupProvider.notifier).refresh(),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [ChasquiColors.neutral700, ChasquiColors.neutral950],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  group.name,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${group.members.length} miembro${group.members.length == 1 ? '' : 's'} · $activeCount activo${activeCount == 1 ? '' : 's'} ahora',
                  style: const TextStyle(fontSize: 12, color: Colors.white70),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          for (final member in group.members) ...[
            _FamilyMemberTile(member: member),
            const SizedBox(height: 8),
          ],
          Semantics(
            label: 'Agregar familiar',
            button: true,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => InviteFamilyMemberSheet.show(context),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: ChasquiColors.neutral300,
                    style: BorderStyle.solid,
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.person_add_alt_rounded,
                      size: 16,
                      color: ChasquiColors.neutral600,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Agregar familiar',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: ChasquiColors.neutral600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (supportableMembers.isNotEmpty) ...[
            const SizedBox(height: 20),
            ChasquiCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Apoyo familiar', style: theme.textTheme.titleSmall),
                  const SizedBox(height: 4),
                  Text(
                    'Envía tus Puntos Chass a un familiar para que pueda pedir ayuda a la comunidad.',
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final member in supportableMembers)
                        OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            backgroundColor: ChasquiColors.yellow100,
                            foregroundColor: ChasquiColors.yellow800,
                            side: const BorderSide(color: ChasquiColors.yellow300),
                          ),
                          onPressed: () => _confirmSupport(context, member),
                          child: Text(
                            'Apoyar a ${member.displayName ?? member.relationshipLabel ?? 'familiar'}',
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _confirmSupport(BuildContext context, FamilyMember member) async {
    final name = member.displayName ?? member.relationshipLabel ?? 'tu familiar';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Apoyo familiar'),
        content: Text(
          '¿Enviar $_simulatedSupportPoints Puntos Chass a $name?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Enviar'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Enviaste $_simulatedSupportPoints Puntos Chass a $name')),
      );
    }
  }
}

class _FamilyMemberTile extends StatelessWidget {
  const _FamilyMemberTile({required this.member});

  final FamilyMember member;

  @override
  Widget build(BuildContext context) {
    final display = familyMemberDisplayStatus(member);
    final name = member.displayName ??
        member.relationshipLabel ??
        (member.status == FamilyMemberStatus.pending ? 'Invitación pendiente' : 'Familiar');
    final initial = name.characters.isNotEmpty ? name.characters.first.toUpperCase() : '?';

    return ChasquiCard(
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: display.color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              initial,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w900,
                color: display.color,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: ChasquiColors.neutral950,
                  ),
                ),
                Text(
                  member.status == FamilyMemberStatus.pending && member.inviteCode != null
                      ? 'Código: ${member.inviteCode}'
                      : display.subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    color: ChasquiColors.neutral500,
                  ),
                ),
              ],
            ),
          ),
          ChasquiTag(
            label: display.label,
            background: display.color.withValues(alpha: 0.15),
            foreground: display.color,
          ),
        ],
      ),
    );
  }
}

class _CreateGroupDialog extends StatefulWidget {
  const _CreateGroupDialog();

  static Future<void> show(BuildContext context, WidgetRef ref) async {
    final name = await showDialog<String>(
      context: context,
      builder: (_) => const _CreateGroupDialog(),
    );
    if (name == null || name.trim().isEmpty) return;
    await ref.read(familyGroupProvider.notifier).createGroup(name.trim());
  }

  @override
  State<_CreateGroupDialog> createState() => _CreateGroupDialogState();
}

class _CreateGroupDialogState extends State<_CreateGroupDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Crear cuenta familiar'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        decoration: const InputDecoration(hintText: 'Ej: Familia González'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_controller.text),
          child: const Text('Crear'),
        ),
      ],
    );
  }
}

class _JoinWithCodeDialog extends StatefulWidget {
  const _JoinWithCodeDialog();

  static Future<void> show(BuildContext context, WidgetRef ref) async {
    final code = await showDialog<String>(
      context: context,
      builder: (_) => const _JoinWithCodeDialog(),
    );
    if (code == null || code.trim().isEmpty || !context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    final ok = await ref
        .read(familyGroupProvider.notifier)
        .acceptInvitation(code.trim());
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          ok ? 'Te uniste a la cuenta familiar' : 'Código inválido o ya usado',
        ),
      ),
    );
  }

  @override
  State<_JoinWithCodeDialog> createState() => _JoinWithCodeDialogState();
}

class _JoinWithCodeDialogState extends State<_JoinWithCodeDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Unirme con un código'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        textCapitalization: TextCapitalization.characters,
        decoration: const InputDecoration(hintText: 'Ej: 3VVB3U'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_controller.text),
          child: const Text('Unirme'),
        ),
      ],
    );
  }
}
