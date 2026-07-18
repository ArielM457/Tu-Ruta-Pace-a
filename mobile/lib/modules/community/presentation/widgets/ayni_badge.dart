import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../profile/presentation/providers/profile_providers.dart';

class AyniBadge extends ConsumerWidget {
  const AyniBadge({super.key, this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final points = ref.watch(
      profileControllerProvider.select((state) => state.value?.ayniPoints),
    );
    if (points == null) return const SizedBox.shrink();

    return GestureDetector(
      onTap: onTap,
      child: Chip(
        avatar: const Icon(Icons.hexagon, size: 18, color: Color(0xFFC9A227)),
        label: Text('$points pts'),
        backgroundColor: const Color(0xFFFFF8E1),
      )
          .animate(key: ValueKey(points))
          .scaleXY(begin: 0.7, end: 1.0, curve: Curves.elasticOut, duration: 500.ms)
          .shimmer(duration: 700.ms, color: const Color(0xFFFFD54F)),
    );
  }
}
