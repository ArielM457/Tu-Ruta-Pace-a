import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

import '../../../../core/api/api_exception.dart';
import '../../domain/community_entities.dart';
import '../providers/community_providers.dart';

class AskQuestionSheet extends ConsumerStatefulWidget {
  const AskQuestionSheet({
    super.key,
    required this.lineId,
    required this.lineLabel,
  });

  final String lineId;
  final String lineLabel;

  static Future<void> show(
    BuildContext context, {
    required String lineId,
    required String lineLabel,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => AskQuestionSheet(lineId: lineId, lineLabel: lineLabel),
    );
  }

  @override
  ConsumerState<AskQuestionSheet> createState() => _AskQuestionSheetState();
}

class _AskQuestionSheetState extends ConsumerState<AskQuestionSheet> {
  CommunityQuestionKind _kind = CommunityQuestionKind.availability;
  final _contentController = TextEditingController();
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _submitting = true;
      _error = null;
    });
    final controller = ref.read(askQuestionControllerProvider.notifier);
    final ok = await controller.ask(
      lineId: widget.lineId,
      kind: _kind,
      content: _contentController.text.trim().isEmpty
          ? null
          : _contentController.text.trim(),
    );
    if (!mounted) return;

    if (ok) {
      final question = ref.read(askQuestionControllerProvider).value;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            question != null
                ? 'Pregunta enviada — costó ${question.pointsCost} Puntos Chass'
                : 'Pregunta enviada',
          ),
          backgroundColor: Colors.indigo[700],
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      final err = ref.read(askQuestionControllerProvider).error;
      setState(() {
        _submitting = false;
        _error = _messageFor(err);
      });
    }
  }

  String _messageFor(Object? error) {
    if (error is ApiException) {
      switch (error.code) {
        case 'NO_ACTIVE_COLLABORATORS':
          return 'No hay viajeros activos en esta línea ahora';
        case 'INSUFFICIENT_AYNI_POINTS':
          return 'Necesitas más Puntos Chass. Comparte tu ubicación para ganarlos.';
        default:
          return error.message;
      }
    }
    return 'No se pudo enviar la pregunta. Intenta de nuevo.';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final activityAsync = ref.watch(lineActivityProvider(widget.lineId));

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (_, scrollController) => Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: ListView(
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          children: [
            Text(
              'Preguntar a la comunidad',
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const Gap(4),
            Text(widget.lineLabel, style: theme.textTheme.bodyMedium),
            const Gap(16),
            activityAsync.when(
              data: (activity) => _buildActivityBanner(activity.activePeople),
              loading: () => const LinearProgressIndicator(),
              error: (_, __) => const SizedBox.shrink(),
            ),
            const Gap(20),
            Text('¿Qué quieres saber?', style: theme.textTheme.labelLarge),
            const Gap(10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: CommunityQuestionKind.values.map((kind) {
                final selected = kind == _kind;
                return ChoiceChip(
                  selected: selected,
                  label: Text('${kind.emoji} ${kind.label}'),
                  onSelected: (_) => setState(() => _kind = kind),
                );
              }).toList(),
            ),
            const Gap(16),
            TextField(
              controller: _contentController,
              maxLength: 280,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: 'Detalles adicionales (opcional)',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            if (_error != null) ...[
              const Gap(4),
              Text(_error!, style: TextStyle(color: theme.colorScheme.error, fontSize: 13)),
            ],
            const Gap(12),
            Text(
              'Preguntar tiene un costo en Puntos Chass. Si nadie responde a tiempo, se te reembolsan automáticamente.',
              style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
            ),
            const Gap(20),
            FilledButton.icon(
              onPressed: _submitting ? null : _submit,
              icon: _submitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.send),
              label: const Text('Preguntar'),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.indigo[700],
                minimumSize: const Size(double.infinity, 50),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityBanner(int activePeople) {
    final hasPeople = activePeople > 0;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: hasPeople ? const Color(0xFFE8F5E9) : const Color(0xFFFFF3E0),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            hasPeople ? Icons.people : Icons.people_outline,
            color: hasPeople ? const Color(0xFF2E7D32) : const Color(0xFFE65100),
          ),
          const Gap(10),
          Expanded(
            child: Text(
              hasPeople
                  ? '$activePeople persona(s) compartiendo ubicación en esta línea ahora'
                  : 'Nadie está compartiendo ubicación en esta línea ahora mismo',
              style: TextStyle(
                color: hasPeople ? const Color(0xFF2E7D32) : const Color(0xFFE65100),
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 250.ms);
  }
}
