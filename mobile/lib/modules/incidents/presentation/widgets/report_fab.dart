import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'report_bottom_sheet.dart';

class ReportFab extends StatelessWidget {
  const ReportFab({super.key});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.small(
      heroTag: 'report_fab',
      tooltip: 'Reportar incidente',
      backgroundColor: Colors.indigo[700],
      foregroundColor: Colors.white,
      onPressed: () => showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (_) => const ReportBottomSheet(),
      ),
      child: const Icon(Icons.add),
    )
        .animate()
        .fadeIn(duration: 400.ms, delay: 300.ms)
        .scaleXY(begin: 0.6, curve: Curves.elasticOut);
  }
}
