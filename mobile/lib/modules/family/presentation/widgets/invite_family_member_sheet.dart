import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme.dart';
import '../providers/family_providers.dart';

class InviteFamilyMemberSheet extends ConsumerStatefulWidget {
  const InviteFamilyMemberSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const InviteFamilyMemberSheet(),
    );
  }

  @override
  ConsumerState<InviteFamilyMemberSheet> createState() =>
      _InviteFamilyMemberSheetState();
}

class _InviteFamilyMemberSheetState
    extends ConsumerState<InviteFamilyMemberSheet> {
  final _relationshipController = TextEditingController();
  final _emailController = TextEditingController();
  String? _generatedCode;

  @override
  void dispose() {
    _relationshipController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final relationship = _relationshipController.text.trim();
    final email = _emailController.text.trim();
    final ok = await ref
        .read(inviteFamilyMemberControllerProvider.notifier)
        .invite(
          relationshipLabel: relationship.isEmpty ? null : relationship,
          email: email.isEmpty ? null : email,
        );
    if (!mounted || !ok) return;
    final invite = ref.read(inviteFamilyMemberControllerProvider).value;
    setState(() => _generatedCode = invite?.code);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final inviteState = ref.watch(inviteFamilyMemberControllerProvider);
    final code = _generatedCode;

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: code == null
            ? [
                Text('Agregar familiar', style: theme.textTheme.titleLarge),
                const SizedBox(height: 4),
                Text(
                  'Genera un código para que tu familiar se una a tu cuenta',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 20),
                Text('PARENTESCO (OPCIONAL)', style: theme.textTheme.labelSmall),
                const SizedBox(height: 8),
                TextField(
                  controller: _relationshipController,
                  decoration: const InputDecoration(hintText: 'Ej: Mamá, Hermano'),
                ),
                const SizedBox(height: 16),
                Text('CORREO (OPCIONAL)', style: theme.textTheme.labelSmall),
                const SizedBox(height: 8),
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(hintText: 'familiar@correo.com'),
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: inviteState.isLoading ? null : _submit,
                  child: inviteState.isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Generar código'),
                ),
              ]
            : [
                Text('Código generado', style: theme.textTheme.titleLarge),
                const SizedBox(height: 4),
                Text(
                  'Comparte este código con tu familiar. Debe ingresarlo en su app.',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: ChasquiColors.yellow100,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: ChasquiColors.yellow400),
                  ),
                  child: Text(
                    code,
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 6,
                      color: ChasquiColors.yellow800,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  icon: const Icon(Icons.copy_rounded, size: 16),
                  label: const Text('Copiar código'),
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: code));
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Código copiado')),
                      );
                    }
                  },
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Listo'),
                ),
              ],
      ),
    );
  }
}
