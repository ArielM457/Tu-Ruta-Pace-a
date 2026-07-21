import 'package:flutter/material.dart';

import '../../../../app/theme.dart';
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Semantics(
        button: true,
        selected: isSelected,
        label: '$title. $subtitle',
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isSelected
                    ? ChasquiColors.yellow600
                    : ChasquiColors.neutral100,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? ChasquiColors.yellow200
                        : ChasquiColors.neutral50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    size: 20,
                    color: isSelected
                        ? ChasquiColors.yellow800
                        : ChasquiColors.neutral500,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
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
                if (isSelected)
                  const Icon(
                    Icons.check_circle,
                    size: 20,
                    color: ChasquiColors.yellow600,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
