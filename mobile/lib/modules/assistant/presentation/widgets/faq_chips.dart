import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../app/theme.dart';

const List<String> kFaqQuestions = [
  '¿A qué hora cierra el teleférico?',
  '¿Cuánto cuesta el PumaKatari?',
  '¿Cómo gano Puntos Chass?',
  '¿Qué hago si hay un bloqueo?',
  '¿Cómo reporto un incidente?',
  '¿Qué hago en una emergencia?',
];

class FaqChips extends StatelessWidget {
  const FaqChips({super.key, required this.onSelect});

  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: kFaqQuestions.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final question = kFaqQuestions[index];
          return ActionChip(
            label: Text(question),
            onPressed: () => onSelect(question),
            backgroundColor: ChasquiColors.neutral50,
            side: const BorderSide(color: ChasquiColors.neutral200),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            labelStyle: const TextStyle(
              color: ChasquiColors.neutral700,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          )
              .animate()
              .fadeIn(duration: 300.ms, delay: (index * 50).ms)
              .slideX(begin: 0.3, end: 0, curve: Curves.easeOut);
        },
      ),
    );
  }
}
