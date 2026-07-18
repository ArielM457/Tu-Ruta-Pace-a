import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';

import '../../domain/community_entities.dart';

class HelpPopup extends StatelessWidget {
  const HelpPopup({super.key, required this.questions});

  final List<CommunityQuestion> questions;

  static Future<bool?> show(
    BuildContext context, {
    required List<CommunityQuestion> questions,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => HelpPopup(questions: questions),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lineLabel = questions.first.lineName ?? 'una línea cercana';
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.amber[50],
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.volunteer_activism, color: Color(0xFFC9A227)),
                ),
                const Gap(12),
                Expanded(
                  child: Text(
                    'Alguien necesita ayuda',
                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            const Gap(16),
            Text(
              questions.length == 1
                  ? 'Hay una pregunta pendiente en $lineLabel'
                  : 'Hay ${questions.length} preguntas pendientes en líneas donde estás activo',
              style: theme.textTheme.bodyMedium,
            ),
            const Gap(24),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.indigo[700],
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text('Ayudar'),
            ),
            const Gap(8),
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Ahora no'),
            ),
          ],
        ),
      ),
    ).animate().slideY(begin: 0.15, end: 0, duration: 350.ms, curve: Curves.easeOut);
  }
}
