import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// ═══════════════════════════════════════════════════════════════
///  Wireframe Layout Components
///  Reproduit fidèlement l'architecture visuelle du wireframe :
///  - AmbientNodesVisualizer : Nœuds lumineux/interactifs en zone sombre
///  - CurvedNotchHeader : Découpe organique avec encoche incurvée
///  - WireframePillToggle : Sélecteur à bascule logé dans l'encoche
/// ═══════════════════════════════════════════════════════════════

/// Visualiseur de nœuds et points de communication flottants
class AmbientNodesVisualizer extends StatefulWidget {
  final double height;
  final int activeNodeIndex;
  final Function(int)? onNodeSelected;
  final Widget? centerWidget;

  const AmbientNodesVisualizer({
    super.key,
    this.height = 200,
    this.activeNodeIndex = 0,
    this.onNodeSelected,
    this.centerWidget,
  });

  @override
  State<AmbientNodesVisualizer> createState() => _AmbientNodesVisualizerState();
}

class _AmbientNodesVisualizerState extends State<AmbientNodesVisualizer>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Coordonnées relatives des nœuds inspirées du wireframe
    final nodes = [
      const Offset(0.22, 0.45), // Nœud 1 (gauche bas)
      const Offset(0.48, 0.25), // Nœud 2 (centre haut)
      const Offset(0.82, 0.38), // Nœud 3 (droite milieu)
      const Offset(0.18, 0.80), // Nœud 4 (gauche bas - secondaire)
      const Offset(0.75, 0.72), // Nœud 5 (droite bas - secondaire)
    ];

    return SizedBox(
      height: widget.height,
      width: double.infinity,
      child: Stack(
        children: [
          // Lignes de connexion et halos d'ambiance
          CustomPaint(
            size: Size(double.infinity, widget.height),
            painter: _NodesConnectionPainter(
              progress: _pulseController.value,
              nodes: nodes,
              accentColor: AppColors.mintSage,
              darkColor: AppColors.deepForest,
            ),
          ),

          // Widget central optionnel (ex: Solde en temps réel ou icône terminal)
          if (widget.centerWidget != null)
            Center(
              child: widget.centerWidget!,
            ),

          // Rendu des nœuds interactifs
          ...List.generate(nodes.length, (index) {
            final node = nodes[index];
            final isActive = index == widget.activeNodeIndex;
            final isPrimary = index < 3;

            return Positioned.fill(
              child: Align(
                alignment: Alignment(
                  (node.dx * 2) - 1,
                  (node.dy * 2) - 1,
                ),
                child: GestureDetector(
                  onTap: () => widget.onNodeSelected?.call(index),
                  child: AnimatedBuilder(
                    animation: _pulseController,
                    builder: (context, child) {
                      final scale = 1.0 +
                          (isActive
                              ? 0.15 * math.sin(_pulseController.value * math.pi)
                              : 0.05 * math.sin((_pulseController.value + index * 0.2) * math.pi));

                      return Transform.scale(
                        scale: scale,
                        child: Container(
                          width: isPrimary ? 22 : 14,
                          height: isPrimary ? 22 : 14,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isActive
                                ? AppColors.mintSage
                                : (isPrimary
                                    ? AppColors.softMist.withValues(alpha: 0.85)
                                    : AppColors.softMist.withValues(alpha: 0.4)),
                            boxShadow: [
                              BoxShadow(
                                color: (isActive ? AppColors.mintSage : AppColors.softMist)
                                    .withValues(alpha: isActive ? 0.6 : 0.25),
                                blurRadius: isActive ? 16 : 8,
                                spreadRadius: isActive ? 4 : 1,
                              ),
                            ],
                            border: Border.all(
                              color: AppColors.deepForest,
                              width: 2.5,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _NodesConnectionPainter extends CustomPainter {
  final double progress;
  final List<Offset> nodes;
  final Color accentColor;
  final Color darkColor;

  _NodesConnectionPainter({
    required this.progress,
    required this.nodes,
    required this.accentColor,
    required this.darkColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = accentColor.withValues(alpha: 0.18 + 0.1 * progress)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    // Relier les 3 nœuds principaux
    if (nodes.length >= 3) {
      final p1 = Offset(nodes[0].dx * size.width, nodes[0].dy * size.height);
      final p2 = Offset(nodes[1].dx * size.width, nodes[1].dy * size.height);
      final p3 = Offset(nodes[2].dx * size.width, nodes[2].dy * size.height);

      final path = Path()
        ..moveTo(p1.dx, p1.dy)
        ..lineTo(p2.dx, p2.dy)
        ..lineTo(p3.dx, p3.dy);

      canvas.drawPath(path, linePaint);

      // Cercles concentriques autour du nœud central
      final wavePaint = Paint()
        ..color = accentColor.withValues(alpha: (1 - progress) * 0.12)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;

      canvas.drawCircle(p2, 28 + (progress * 20), wavePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _NodesConnectionPainter oldDelegate) => true;
}

/// Sélecteur de mode en pilule sculptée (intégré dans l'encoche du wireframe)
class WireframePillToggle extends StatelessWidget {
  final int selectedIndex; // 0: Dashboard/Activité, 1: Station Recharge
  final ValueChanged<int> onToggle;
  final String leftLabel;
  final String rightLabel;

  const WireframePillToggle({
    super.key,
    required this.selectedIndex,
    required this.onToggle,
    this.leftLabel = 'Activité',
    this.rightLabel = 'Recharge',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 146,
      height: 48,
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: AppColors.deepForest,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: AppColors.softMist.withValues(alpha: 0.25),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.deepForest.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Curseur animé de la bascule
          AnimatedAlign(
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOutCubic,
            alignment: selectedIndex == 0 ? Alignment.centerLeft : Alignment.centerRight,
            child: Container(
              width: 66,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.mintSage,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.mintSage.withValues(alpha: 0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Center(
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: const BoxDecoration(
                    color: AppColors.deepForest,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          ),

          // Zones tactiles
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onToggle(0),
                  child: const Center(
                    child: SizedBox(),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onToggle(1),
                  child: const Center(
                    child: SizedBox(),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// En-tête avec découpe organique et encoche incurvée (Signature Wireframe)
class CurvedNotchJunction extends StatelessWidget {
  final Widget titleContent;
  final Widget toggleWidget;

  const CurvedNotchJunction({
    super.key,
    required this.titleContent,
    required this.toggleWidget,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AppColors.softMist,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: const EdgeInsets.fromLTRB(22, 20, 20, 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Titre et indicateurs à gauche
          Expanded(child: titleContent),
          const SizedBox(width: 14),
          // Toggle sculpté à droite
          toggleWidget,
        ],
      ),
    );
  }
}

/// Barre supérieure moderne (Top Bar) avec badge en pilule et menu
class WireframeTopBar extends StatelessWidget {
  final String statusText;
  final VoidCallback? onMenuPressed;
  final VoidCallback? onStatusTap;

  const WireframeTopBar({
    super.key,
    this.statusText = 'Guichet Actif',
    this.onMenuPressed,
    this.onStatusTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Bouton retour si ouvert depuis Admin + Badge en pilule (gauche)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (Navigator.canPop(context))
                Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.softMist.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.arrow_back_rounded,
                        color: AppColors.softMist,
                        size: 18,
                      ),
                    ),
                  ),
                ),
              GestureDetector(
                onTap: onStatusTap,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.softMist,
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 9,
                        height: 9,
                        decoration: const BoxDecoration(
                          color: AppColors.mintSage,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        statusText,
                        style: const TextStyle(
                          color: AppColors.deepForest,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Menu icon / Actions (droite)
          GestureDetector(
            onTap: onMenuPressed,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.softMist.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.softMist.withValues(alpha: 0.25),
                  width: 1,
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      width: 20,
                      height: 2.5,
                      decoration: BoxDecoration(
                        color: AppColors.softMist,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Container(
                      width: 13,
                      height: 2.5,
                      decoration: BoxDecoration(
                        color: AppColors.mintSage,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
