import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';

import '../../../../app/theme.dart';
import '../../domain/chat_entities.dart';

class ChatBubble extends StatelessWidget {
  const ChatBubble({super.key, required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == MessageRole.user;
    final theme = Theme.of(context);

    final bubbleColor = message.isError
        ? Colors.red[50]
        : isUser
            ? ChasquiColors.yellow600
            : ChasquiColors.neutral50;
    final textColor = message.isError
        ? Colors.red[900]
        : isUser
            ? ChasquiColors.neutral950
            : ChasquiColors.neutral900;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment:
            isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment:
                isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            children: [
              Flexible(
                child: Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.78,
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: bubbleColor,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(18),
                      topRight: const Radius.circular(18),
                      bottomLeft: Radius.circular(isUser ? 18 : 4),
                      bottomRight: Radius.circular(isUser ? 4 : 18),
                    ),
                    border: isUser
                        ? null
                        : Border.all(color: ChasquiColors.neutral100),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (message.isError)
                        const Padding(
                          padding: EdgeInsets.only(right: 6, top: 1),
                          child: Icon(Icons.error_outline,
                              size: 16, color: Colors.red),
                        ),
                      Flexible(
                        child: Text(
                          message.content,
                          style: theme.textTheme.bodyMedium
                              ?.copyWith(color: textColor),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (message.isCommunityEstimate) ...[
            const Gap(4),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.amber[100],
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.amber[300]!),
              ),
              child: Text(
                'Estimación comunitaria 🏘️',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.amber[900],
                ),
              ),
            ).animate().fadeIn(duration: 300.ms, delay: 200.ms),
          ],
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 250.ms)
        .slideX(begin: isUser ? 0.15 : -0.15, end: 0, curve: Curves.easeOut);
  }
}
