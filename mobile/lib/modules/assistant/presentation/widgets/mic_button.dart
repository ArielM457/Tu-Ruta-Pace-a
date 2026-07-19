import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../providers/assistant_providers.dart';

class MicButton extends StatelessWidget {
  const MicButton({
    super.key,
    required this.status,
    required this.onStartListening,
    required this.onStopListening,
  });

  final VoiceInputStatus status;
  final VoidCallback onStartListening;
  final VoidCallback onStopListening;

  @override
  Widget build(BuildContext context) {
    final isListening = status == VoiceInputStatus.listening;
    final isProcessing = status == VoiceInputStatus.processing;

    final button = Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isListening ? const Color(0xFFE74C3C) : Colors.grey[200],
      ),
      child: isProcessing
          ? const Padding(
              padding: EdgeInsets.all(12),
              child: CircularProgressIndicator(strokeWidth: 2.4),
            )
          : Icon(
              isListening ? Icons.mic : Icons.mic_none,
              color: isListening ? Colors.white : Colors.grey[700],
            ),
    );

    return GestureDetector(
      onLongPressStart: (_) => onStartListening(),
      onLongPressEnd: (_) => onStopListening(),
      child: isListening
          ? button
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .scaleXY(begin: 1.0, end: 1.15, duration: 450.ms, curve: Curves.easeInOut)
          : button,
    );
  }
}
