import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router.dart';
import '../../domain/user_profile.dart';
import '../providers/profile_providers.dart';
import '../widgets/preference_options.dart';

class PreferencesOnboardingScreen extends ConsumerStatefulWidget {
  const PreferencesOnboardingScreen({super.key});

  @override
  ConsumerState<PreferencesOnboardingScreen> createState() =>
      _PreferencesOnboardingScreenState();
}

class _PreferencesOnboardingScreenState
    extends ConsumerState<PreferencesOnboardingScreen> {
  int _currentStep = 0;
  AccessibilityProfile _selectedAccessibility = AccessibilityProfile.none;
  TravelPriority _selectedPriority = TravelPriority.time;
  bool _isSaving = false;
  String? _saveErrorMessage;

  Future<void> _savePreferences() async {
    setState(() {
      _isSaving = true;
      _saveErrorMessage = null;
    });
    final saved =
        await ref.read(profileControllerProvider.notifier).updatePreferences(
              accessibilityProfile: _selectedAccessibility,
              defaultPriority: _selectedPriority,
            );
    if (!mounted) {
      return;
    }
    if (saved) {
      context.go(AppRoutes.home);
      return;
    }
    setState(() {
      _isSaving = false;
      _saveErrorMessage =
          'No se pudieron guardar tus preferencias. Intenta de nuevo.';
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isAccessibilityStep = _currentStep == 0;
    return Scaffold(
      appBar: AppBar(
        title: Text(isAccessibilityStep ? 'Sobre ti (1 de 2)' : 'Tu prioridad (2 de 2)'),
        leading: isAccessibilityStep
            ? null
            : BackButton(onPressed: () => setState(() => _currentStep = 0)),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                isAccessibilityStep
                    ? '¿Tienes alguna necesidad de accesibilidad?'
                    : '¿Qué priorizas al viajar?',
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                isAccessibilityStep
                    ? 'Adaptaremos la app y las rutas a tu respuesta. Puedes cambiarla después en tu perfil.'
                    : 'Ordenaremos las opciones de viaje según tu elección. Puedes cambiarla en cada búsqueda.',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              Expanded(
                child: ListView(
                  children: isAccessibilityStep
                      ? [
                          for (final option in AccessibilityProfile.values)
                            PreferenceOptionCard(
                              icon: option.icon,
                              title: option.label,
                              subtitle: option.description,
                              isSelected: option == _selectedAccessibility,
                              onTap: () => setState(
                                () => _selectedAccessibility = option,
                              ),
                            ),
                        ]
                      : [
                          for (final option in TravelPriority.values)
                            PreferenceOptionCard(
                              icon: option.icon,
                              title: option.label,
                              subtitle: option.description,
                              isSelected: option == _selectedPriority,
                              onTap: () => setState(
                                () => _selectedPriority = option,
                              ),
                            ),
                        ],
                ),
              ),
              if (_saveErrorMessage != null) ...[
                Text(
                  _saveErrorMessage!,
                  style: TextStyle(color: theme.colorScheme.error),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
              ],
              FilledButton(
                onPressed: _isSaving
                    ? null
                    : isAccessibilityStep
                        ? () => setState(() => _currentStep = 1)
                        : _savePreferences,
                child: _isSaving
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(isAccessibilityStep ? 'Continuar' : 'Guardar y empezar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
