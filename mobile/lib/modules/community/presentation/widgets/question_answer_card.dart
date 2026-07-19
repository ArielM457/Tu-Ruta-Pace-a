import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

import '../../domain/community_entities.dart';
import '../providers/community_providers.dart';

class QuestionAnswerCard extends ConsumerStatefulWidget {
  const QuestionAnswerCard({
    super.key,
    required this.question,
    required this.index,
  });

  final CommunityQuestion question;
  final int index;

  @override
  ConsumerState<QuestionAnswerCard> createState() => _QuestionAnswerCardState();
}

class _QuestionAnswerCardState extends ConsumerState<QuestionAnswerCard> {
  final _answerController = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _answerController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final content = _answerController.text.trim();
    if (content.length < 5) return;

    setState(() => _submitting = true);
    final ok = await ref
        .read(answerQuestionControllerProvider.notifier)
        .answer(widget.question.id, content);

    if (!mounted) return;
    setState(() => _submitting = false);

    if (ok) {
      final result = ref.read(answerQuestionControllerProvider).value;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('¡+${result?.pointsAwarded ?? widget.question.pointsCost} Puntos Chass!'),
          backgroundColor: const Color(0xFF2E7D32),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo enviar la respuesta. Intenta de nuevo.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  String _waitingLabel() {
    final createdAt = DateTime.tryParse(widget.question.createdAt);
    if (createdAt == null) return '';
    final diff = DateTime.now().difference(createdAt);
    if (diff.inMinutes < 1) return 'hace instantes';
    if (diff.inMinutes < 60) return 'hace ${diff.inMinutes} min';
    return 'hace ${diff.inHours} h';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final q = widget.question;
    final canSubmit = _answerController.text.trim().length >= 5 && !_submitting;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(q.kind.emoji, style: const TextStyle(fontSize: 20)),
                const Gap(8),
                Expanded(
                  child: Text(
                    q.lineName ?? 'Línea de transporte',
                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                Text(
                  _waitingLabel(),
                  style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[500]),
                ),
              ],
            ),
            const Gap(6),
            Text(q.kind.label, style: theme.textTheme.bodyMedium),
            if (q.content != null && q.content!.isNotEmpty) ...[
              const Gap(4),
              Text(
                '"${q.content}"',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontStyle: FontStyle.italic,
                  color: Colors.grey[700],
                ),
              ),
            ],
            const Gap(12),
            TextField(
              controller: _answerController,
              onChanged: (_) => setState(() {}),
              maxLines: 2,
              decoration: InputDecoration(
                hintText: 'Tu respuesta...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
            const Gap(10),
            FilledButton(
              onPressed: canSubmit ? _submit : null,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D32),
                minimumSize: const Size(double.infinity, 44),
              ),
              child: _submitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Text('Responder — Ganar ${q.pointsCost} pts'),
            ),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 300.ms, delay: (widget.index * 80).ms)
        .slideY(begin: 0.1, end: 0, curve: Curves.easeOut);
  }
}
