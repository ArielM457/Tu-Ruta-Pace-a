import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/collaboration_providers.dart';

class SharingChip extends ConsumerWidget {
  const SharingChip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final share = ref.watch(activeShareProvider);
    if (share == null) return const SizedBox.shrink();

    return GestureDetector(
      onTap: () => _confirmStop(context, ref),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFE8F5E9),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF66BB6A)),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.circle, size: 10, color: Color(0xFFE53935)),
            SizedBox(width: 6),
            Text(
              'Compartiendo ubicación',
              style: TextStyle(
                color: Color(0xFF2E7D32),
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ],
        ),
      )
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .scaleXY(begin: 1.0, end: 1.05, duration: 900.ms, curve: Curves.easeInOut),
    );
  }

  Future<void> _confirmStop(BuildContext context, WidgetRef ref) async {
    final stop = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('¿Dejar de compartir?'),
        content: const Text(
          'Recibirás los puntos Ayni acumulados por el tiempo que compartiste tu ubicación.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Seguir compartiendo'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Detener'),
          ),
        ],
      ),
    );
    if (stop != true) return;

    final pointsEarned = await ref.read(activeShareProvider.notifier).stop();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            pointsEarned != null && pointsEarned > 0
                ? '¡+$pointsEarned puntos Ayni ganados!'
                : 'Dejaste de compartir tu ubicación',
          ),
          backgroundColor: const Color(0xFF2E7D32),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}
