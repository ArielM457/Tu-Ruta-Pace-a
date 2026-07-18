import 'package:flutter/material.dart';

import '../../domain/user_profile.dart';

extension AccessibilityProfileUi on AccessibilityProfile {
  String get label => switch (this) {
        AccessibilityProfile.none => 'Sin necesidades específicas',
        AccessibilityProfile.visual => 'Discapacidad visual',
        AccessibilityProfile.reducedMobility => 'Movilidad reducida',
      };

  String get description => switch (this) {
        AccessibilityProfile.none => 'Usaré la app de forma estándar',
        AccessibilityProfile.visual =>
          'Quiero pedir rutas por voz y recibir guía hablada',
        AccessibilityProfile.reducedMobility =>
          'Prefiero rutas con estaciones accesibles y poca caminata',
      };

  IconData get icon => switch (this) {
        AccessibilityProfile.none => Icons.person,
        AccessibilityProfile.visual => Icons.record_voice_over,
        AccessibilityProfile.reducedMobility => Icons.accessible,
      };
}

extension TravelPriorityUi on TravelPriority {
  String get label => switch (this) {
        TravelPriority.time => 'Más rápido',
        TravelPriority.cost => 'Más barato',
        TravelPriority.safety => 'Más seguro',
      };

  String get description => switch (this) {
        TravelPriority.time => 'Llegar en el menor tiempo posible',
        TravelPriority.cost => 'Gastar la menor cantidad de Bs',
        TravelPriority.safety => 'Evitar zonas de riesgo aunque tarde más',
      };

  IconData get icon => switch (this) {
        TravelPriority.time => Icons.bolt,
        TravelPriority.cost => Icons.savings,
        TravelPriority.safety => Icons.shield,
      };
}

class PreferenceOptionCard extends StatelessWidget {
  const PreferenceOptionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      selected: isSelected,
      label: '$title. $subtitle',
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: isSelected ? colorScheme.primary : colorScheme.outlineVariant,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: ListTile(
              leading: Icon(
                icon,
                color: isSelected ? colorScheme.primary : null,
              ),
              title: Text(title),
              subtitle: Text(subtitle),
              trailing: isSelected
                  ? Icon(Icons.check_circle, color: colorScheme.primary)
                  : null,
            ),
          ),
        ),
      ),
    );
  }
}
