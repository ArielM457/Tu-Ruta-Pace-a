import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../domain/emergency_entities.dart';

class EmergencyContactCard extends StatelessWidget {
  const EmergencyContactCard({
    super.key,
    required this.contact,
    required this.index,
  });

  final EmergencyContact contact;
  final int index;

  static const _numberIcons = {
    '911': Icons.security,
    '165': Icons.local_hospital,
    '160': Icons.emergency,
    '114': Icons.account_balance,
  };

  @override
  Widget build(BuildContext context) {
    final icon = _numberIcons[contact.number] ?? Icons.phone;
    return GestureDetector(
      onTap: () => _call(context),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFC62828),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFEF9A9A), width: 1),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                color: Color(0xFFFFEB3B),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.black87, size: 22),
            ),
            const Gap(8),
            Text(
              contact.number,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w800,
                letterSpacing: 1,
              ),
            ),
            const Gap(4),
            Text(
              contact.name,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFFFFCDD2),
                fontSize: 11,
              ),
            ),
            const Gap(8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFFFEB3B),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.phone, size: 12, color: Colors.black87),
                  Gap(4),
                  Text(
                    'Llamar',
                    style: TextStyle(
                      color: Colors.black87,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    )
        .animate(delay: (index * 80).ms)
        .fadeIn(duration: 300.ms)
        .slideX(begin: 0.2, end: 0, curve: Curves.easeOut);
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
