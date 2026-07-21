import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router.dart';
import '../../../../app/theme.dart';
import '../../../../core/widgets/chasqui_card.dart';
import '../../../../core/widgets/chasqui_tag.dart';
import '../../../../core/widgets/chasqui_top_bar.dart';
import '../../domain/complaint_entities.dart';
import '../providers/complaints_providers.dart';
import '../widgets/complaint_type_ui.dart';

const double _tabBarClearance = 112;
const List<String> _shortMonths = [
  'ene', 'feb', 'mar', 'abr', 'may', 'jun',
  'jul', 'ago', 'sep', 'oct', 'nov', 'dic',
];

String _formatComplaintDate(DateTime date) {
  final local = date.toLocal();
  return '${local.day} ${_shortMonths[local.month - 1]}';
}

class ComplaintsScreen extends ConsumerWidget {
  const ComplaintsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final complaintsState = ref.watch(myComplaintsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: ChasquiTopBar(
        title: 'Denuncias',
        subtitle: 'Tu reporte mejora el transporte',
        trailing: Semantics(
          label: 'Nueva denuncia',
          button: true,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => context.push(AppRoutes.newComplaint),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: ChasquiColors.yellow600,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add, size: 14, color: ChasquiColors.neutral950),
                  SizedBox(width: 4),
                  Text(
                    'Nueva',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: ChasquiColors.neutral950,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(myComplaintsProvider.notifier).refresh(),
        child: complaintsState.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text(
                'No pudimos cargar tus denuncias. Desliza para reintentar.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ),
          data: (complaints) => ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, _tabBarClearance),
            children: [
              Text('MIS DENUNCIAS', style: theme.textTheme.labelSmall),
              const SizedBox(height: 12),
              if (complaints.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Text(
                    'Aún no has hecho denuncias. Cuando algo ande mal en tu transporte, repórtalo aquí.',
                    style: theme.textTheme.bodySmall,
                  ),
                )
              else
                for (final complaint in complaints) ...[
                  _ComplaintTile(complaint: complaint),
                  const SizedBox(height: 8),
                ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ComplaintTile extends StatelessWidget {
  const _ComplaintTile({required this.complaint});

  final Complaint complaint;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subtitle = [
      if (complaint.routeLabel != null) complaint.routeLabel!,
      _formatComplaintDate(complaint.createdAt),
    ].join(' · ');

    return ChasquiCard(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(complaint.type.label, style: theme.textTheme.titleSmall),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ChasquiTag(
            label: complaint.status.label,
            background: complaint.status.background,
            foreground: complaint.status.foreground,
          ),
        ],
      ),
    );
  }
}
