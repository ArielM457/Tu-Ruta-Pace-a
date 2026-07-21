import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../app/theme.dart';
import '../../../../core/widgets/chasqui_card.dart';
import '../../domain/emergency_entities.dart';

class EmergencyContactCard extends StatelessWidget {
  const EmergencyContactCard({
    super.key,
    required this.contact,
    required this.index,
  });

  final EmergencyContact contact;
  final int index;

  @override
  Widget build(BuildContext context) {
    return ChasquiCard(
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: ChasquiColors.yellow100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.local_phone_rounded,
              size: 17,
              color: ChasquiColors.yellow800,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  contact.name,
                  style: const TextStyle(
                    fontSize: 12,
                    color: ChasquiColors.neutral500,
                  ),
                ),
                Text(
                  contact.number,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: ChasquiColors.neutral950,
                  ),
                ),
              ],
            ),
          ),
          Semantics(
            label: 'Llamar a ${contact.name}',
            button: true,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => _call(context),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: ChasquiColors.yellow600,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Llamar',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: ChasquiColors.neutral950,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    ).animate(delay: (index * 60).ms).fadeIn(duration: 250.ms);
  }

  Future<void> _call(BuildContext context) async {
    final uri = Uri(scheme: 'tel', path: contact.number);
    if (!await launchUrl(uri)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Llama al ${contact.number}')),
        );
      }
    }
  }
}
