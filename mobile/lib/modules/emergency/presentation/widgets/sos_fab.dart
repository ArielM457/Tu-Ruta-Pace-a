import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router.dart';

class SosFab extends StatelessWidget {
  const SosFab({super.key});

  static const _fabColor = Color(0xFFE74C3C);

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      heroTag: 'sos_fab',
      backgroundColor: _fabColor,
      foregroundColor: Colors.white,
      onPressed: () => _confirmActivation(context),
      tooltip: 'Modo urgencia',
      child: const Icon(Icons.emergency, size: 28),
    )
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .scaleXY(begin: 1.0, end: 1.08, duration: 1200.ms, curve: Curves.easeInOut);
  }

  Future<void> _confirmActivation(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _SosConfirmDialog(),
    );
    if (confirmed == true && context.mounted) {
      context.push(AppRoutes.emergency);
    }
  }
}

class _SosConfirmDialog extends StatelessWidget {
  const _SosConfirmDialog();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFFB71C1C),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Row(
        children: [
          Icon(Icons.emergency, color: Colors.white, size: 28),
          SizedBox(width: 12),
          Text(
            '¿Activar modo urgencia?',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
      content: const Text(
        'La app te mostrará los hospitales más cercanos y los números de emergencia de La Paz.',
        style: TextStyle(color: Color(0xFFFFCDD2), fontSize: 14),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text(
            'Cancelar',
            style: TextStyle(color: Color(0xFFFFCDD2)),
          ),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFFEB3B),
            foregroundColor: Colors.black,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text(
            'Sí, es una emergencia',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}
