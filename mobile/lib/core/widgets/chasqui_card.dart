import 'package:flutter/material.dart';

import '../../app/theme.dart';

class ChasquiCard extends StatelessWidget {
  const ChasquiCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  static final BorderRadius _borderRadius = BorderRadius.circular(16);

  @override
  Widget build(BuildContext context) {
    final content = Padding(padding: padding, child: child);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: _borderRadius,
        border: Border.all(color: ChasquiColors.neutral100),
        boxShadow: const [
          BoxShadow(
            color: ChasquiColors.cardShadow,
            offset: Offset(0, 1),
            blurRadius: 6,
          ),
        ],
      ),
      child: onTap == null
          ? content
          : Material(
              color: Colors.transparent,
              borderRadius: _borderRadius,
              child: InkWell(
                borderRadius: _borderRadius,
                onTap: onTap,
                child: content,
              ),
            ),
    );
  }
}
