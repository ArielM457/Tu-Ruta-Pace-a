import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';

class ShareOptInSheet extends StatelessWidget {
  const ShareOptInSheet({super.key, required this.lineLabel});

  final String lineLabel;

  static Future<bool?> show(BuildContext context, {required String lineLabel}) {
    return showModalBottomSheet<bool>(
      context: context,
      isDismissible: false,
      enableDrag: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => ShareOptInSheet(lineLabel: lineLabel),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
                    color: Colors.indigo[50],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.share_location, color: Colors.indigo[700]),
                ),
                const Gap(12),
                Expanded(
                  child: Text(
                    'Comparte tu ubicación',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ).animate().fadeIn(duration: 250.ms),
            const Gap(16),
            Text('Estás en: $lineLabel', style: theme.textTheme.titleSmall),
            const Gap(10),
            Text(
              'Mientras compartes, otros viajeros pueden saber que tu transporte está en camino.',
              style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey[700]),
            ),
            const Gap(6),
            Text(
              'Ganarás Puntos Chass proporcionales al tiempo que compartas.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.indigo[700],
                fontWeight: FontWeight.w600,
              ),
            ),
            const Gap(24),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.indigo[700],
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text('Sí, compartir'),
            ).animate().fadeIn(duration: 300.ms, delay: 100.ms),
            const Gap(8),
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('No por ahora'),
            ),
          ],
        ),
      ),
    ).animate().slideY(begin: 0.15, end: 0, duration: 350.ms, curve: Curves.easeOut);
  }
}
