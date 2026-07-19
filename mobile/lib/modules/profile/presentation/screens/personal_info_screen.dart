import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme.dart';
import '../../../../core/supabase/supabase_providers.dart';
import '../../../../core/widgets/chasqui_top_bar.dart';
import '../providers/profile_providers.dart';

const int _minimumNameLength = 2;

class PersonalInfoScreen extends ConsumerStatefulWidget {
  const PersonalInfoScreen({super.key});

  @override
  ConsumerState<PersonalInfoScreen> createState() =>
      _PersonalInfoScreenState();
}

class _PersonalInfoScreenState extends ConsumerState<PersonalInfoScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  String? _error;

  @override
  void initState() {
    super.initState();
    final profile = ref.read(profileControllerProvider).value;
    _nameController = TextEditingController(text: profile?.displayName ?? '');
    _phoneController = TextEditingController(text: profile?.phone ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.length < _minimumNameLength) {
      setState(() => _error = 'El nombre debe tener al menos 2 caracteres');
      return;
    }
    setState(() => _error = null);
    final phone = _phoneController.text.trim();
    final saved = await ref.read(profileControllerProvider.notifier).updatePreferences(
          displayName: name,
          phone: phone.isEmpty ? null : phone,
        );
    if (!mounted) return;
    if (saved) {
      context.pop();
    } else {
      setState(() => _error = 'No se pudo guardar. Intenta de nuevo.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final email = ref.watch(currentSessionProvider)?.user.email ?? 'Sin correo';
    final saveState = ref.watch(profileControllerProvider);

    return Scaffold(
      appBar: ChasquiTopBar(
        title: 'Información personal',
        onBack: () => context.pop(),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('NOMBRE', style: theme.textTheme.labelSmall),
          const SizedBox(height: 8),
          TextField(
            controller: _nameController,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(hintText: 'Tu nombre completo'),
          ),
          const SizedBox(height: 16),
          Text('TELÉFONO (OPCIONAL)', style: theme.textTheme.labelSmall),
          const SizedBox(height: 8),
          TextField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(hintText: 'Ej: 7XXXXXXX'),
          ),
          const SizedBox(height: 16),
          Text('CORREO', style: theme.textTheme.labelSmall),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: ChasquiColors.neutral50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: ChasquiColors.neutral200),
            ),
            child: Text(
              email,
              style: const TextStyle(color: ChasquiColors.neutral500),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(
              _error!,
              style: TextStyle(color: theme.colorScheme.error, fontSize: 13),
            ),
          ],
          const SizedBox(height: 20),
          FilledButton(
            onPressed: saveState.isLoading ? null : _save,
            child: saveState.isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Guardar'),
          ),
        ],
      ),
    );
  }
}
