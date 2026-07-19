import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

import '../../../../core/api/api_exception.dart';
import '../../domain/incident_entities.dart';
import '../providers/incident_providers.dart';

class IncidentDetailSheet extends ConsumerStatefulWidget {
  const IncidentDetailSheet({super.key, required this.incident});

  final Incident incident;

  @override
  ConsumerState<IncidentDetailSheet> createState() => _IncidentDetailSheetState();
}

class _IncidentDetailSheetState extends ConsumerState<IncidentDetailSheet> {
  bool _voting = false;
  Incident? _updated;

  Incident get _incident => _updated ?? widget.incident;

  Future<void> _vote(bool confirm) async {
    if (_voting) return;
    setState(() => _voting = true);
    try {
      final repo = ref.read(incidentRepositoryProvider);
      final result = await repo.vote(_incident.id, confirm: confirm);
      setState(() => _updated = result);
      ref.read(activeIncidentsProvider.notifier).applyVote(result);
      ref.read(pendingIncidentsProvider.notifier).applyVote(result);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              confirm
                  ? '✓ Confirmado — gracias por verificar'
                  : '✗ Denegado — gracias por informar',
            ),
            backgroundColor: confirm ? Colors.green[700] : Colors.red[700],
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } on ApiException catch (e) {
      if (mounted) {
        final msg = e.code == 'CONFLICT'
            ? 'Ya registraste tu opinión sobre este incidente'
            : e.message;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudo registrar el voto. Intenta de nuevo.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _voting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final kind = _incident.kind;
    final isPending = _incident.status == IncidentStatus.pending;
    final confirmThreshold = 3;
    final progress = (_incident.confirmations / confirmThreshold).clamp(0.0, 1.0);

    return DraggableScrollableSheet(
      initialChildSize: 0.55,
      minChildSize: 0.3,
      maxChildSize: 0.85,
      expand: false,
      builder: (_, scrollController) => Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            _buildDragHandle(),
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
                children: [
                  _buildBadges(kind, theme),
                  const Gap(14),
                  Text(
                    _incident.description,
                    style: theme.textTheme.bodyMedium,
                  ),
                  if (_incident.photoUrl != null) ...[
                    const Gap(16),
                    _buildPhoto(_incident.photoUrl!),
                  ],
                  const Gap(20),
                  _buildConfirmationBar(context, progress, confirmThreshold),
                  const Gap(8),
                  _buildTimingRow(theme),
                  if (isPending) ...[
                    const Gap(20),
                    _buildVoteButtons(),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    )
        .animate()
        .slideY(begin: 0.1, end: 0, duration: 350.ms, curve: Curves.easeOut)
        .fadeIn(duration: 300.ms);
  }

  Widget _buildDragHandle() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Center(
        child: Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }

  Widget _buildBadges(IncidentKind kind, ThemeData theme) {
    return Wrap(
      spacing: 8,
      children: [
        _KindBadge(kind: kind),
        _SourceBadge(source: _incident.source),
      ],
    );
  }

  Widget _buildPhoto(String url) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.network(
        url,
        height: 200,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
      ),
    );
  }

  Widget _buildConfirmationBar(
      BuildContext context, double progress, int threshold) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${_incident.confirmations} de $threshold confirmaciones',
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.secondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (_incident.denials > 0)
              Text(
                '${_incident.denials} desmintieron',
                style: theme.textTheme.labelSmall
                    ?.copyWith(color: Colors.grey[600]),
              ),
          ],
        ),
        const Gap(6),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 8,
            backgroundColor: Colors.grey[200],
            valueColor:
                const AlwaysStoppedAnimation<Color>(Color(0xFF2E7D32)),
          ),
        )
            .animate(target: progress)
            .custom(
              duration: 600.ms,
              curve: Curves.easeOut,
              builder: (_, v, child) => child,
            ),
      ],
    );
  }

  Widget _buildTimingRow(ThemeData theme) {
    DateTime? expiresAt;
    try {
      expiresAt = DateTime.parse(_incident.expiresAt);
    } catch (_) {}

    final timeLabel = expiresAt != null
        ? 'Expira ${_formatRelative(expiresAt)}'
        : '';

    return Text(
      timeLabel,
      style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
    );
  }

  Widget _buildVoteButtons() {
    return Row(
      children: [
        Expanded(
          child: FilledButton.icon(
            onPressed: _voting ? null : () => _vote(true),
            icon: _voting
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.check_circle_outline),
            label: const Text('Confirmar — sigue ahí'),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF2E7D32),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ).animate().scale(begin: const Offset(0.95, 0.95), duration: 200.ms),
        ),
        const Gap(10),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _voting ? null : () => _vote(false),
            icon: const Icon(Icons.cancel_outlined),
            label: const Text('Ya no está'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFB71C1C),
              side: const BorderSide(color: Color(0xFFB71C1C)),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ).animate().scale(begin: const Offset(0.95, 0.95), duration: 200.ms),
        ),
      ],
    );
  }

  String _formatRelative(DateTime dt) {
    final diff = dt.difference(DateTime.now());
    if (diff.isNegative) return '(ya expiró)';
    if (diff.inHours < 1) return 'en ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'en ${diff.inHours} h';
    return 'en ${diff.inDays} días';
  }
}

class _KindBadge extends StatelessWidget {
  const _KindBadge({required this.kind});

  final IncidentKind kind;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: kind.chipColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '${kind.emoji} ${kind.label}',
        style: TextStyle(
          color: kind.chipTextColor,
          fontWeight: FontWeight.w700,
          fontSize: 13,
        ),
      ),
    );
  }
}

class _SourceBadge extends StatelessWidget {
  const _SourceBadge({required this.source});

  final IncidentSource source;

  @override
  Widget build(BuildContext context) {
    final isOfficial = source == IncidentSource.official;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isOfficial
            ? const Color(0xFFE3F2FD)
            : const Color(0xFFF3E5F5),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isOfficial ? Icons.verified : Icons.people,
            size: 13,
            color: isOfficial
                ? const Color(0xFF0D47A1)
                : const Color(0xFF6A1B9A),
          ),
          const Gap(4),
          Text(
            source.label.toUpperCase(),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: isOfficial
                  ? const Color(0xFF0D47A1)
                  : const Color(0xFF6A1B9A),
            ),
          ),
        ],
      ),
    );
  }
}
