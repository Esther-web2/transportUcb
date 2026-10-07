import 'package:flutter/material.dart';

/// ═══════════════════════════════════════════════════════════════
///  Responsive Max-Width Container — Centrage sur grands écrans
///  Évite que boutons & formulaires s'étirent infiniment sur Desktop/Web
///  Ex: maxWidth 500 (formulaires/connexion), 1100 (dashboards)
/// ═══════════════════════════════════════════════════════════════

class MaxWidthContainer extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  final EdgeInsets padding;

  const MaxWidthContainer({
    super.key,
    required this.child,
    this.maxWidth = 1100,
    this.padding = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}
