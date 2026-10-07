import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// ═══════════════════════════════════════════════════════════════
///  Responsive Layout System — Multiplateforme (Mobile, Tablet, Desktop, Web)
///  Gère les breakpoints :
///  - Mobile  : < 650px (téléphone portrait)
///  - Tablette: 650px - 1024px (tablette / grand smartphone paysage)
///  - Desktop : >= 1024px (ordinateurs de bureau, écrans larges, web)
/// ═══════════════════════════════════════════════════════════════

class ResponsiveBreakpoints {
  static const double mobileMax = 650;
  static const double tabletMax = 1024;

  static bool isMobile(BuildContext context) =>
      MediaQuery.sizeOf(context).width < mobileMax;

  static bool isTablet(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    return w >= mobileMax && w < tabletMax;
  }

  static bool isDesktop(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= tabletMax;

  static bool isWide(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= 900;

  static bool isLandscape(BuildContext context) =>
      MediaQuery.orientationOf(context) == Orientation.landscape;

  static T responsiveValue<T>(
    BuildContext context, {
    required T mobile,
    T? tablet,
    T? desktop,
  }) {
    final w = MediaQuery.sizeOf(context).width;
    if (w >= tabletMax && desktop != null) return desktop;
    if (w >= mobileMax && tablet != null) return tablet;
    return mobile;
  }
}

/// Helper pour afficher une modale adaptative :
/// - Sur Mobile : BottomSheet glissant avec coins arrondis
/// - Sur Tablette / Desktop : Dialogue centré avec contrainte de largeur (ne s'étire pas sur 1920px)
Future<T?> showAdaptiveModal<T>({
  required BuildContext context,
  required Widget Function(BuildContext) builder,
  bool isScrollControlled = true,
  double maxWidth = 540,
  Color? backgroundColor,
}) {
  if (ResponsiveBreakpoints.isMobile(context)) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: isScrollControlled,
      backgroundColor: backgroundColor ?? Colors.transparent,
      builder: builder,
    );
  }

  return showDialog<T>(
    context: context,
    builder: (dialogCtx) => Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Dialog(
          backgroundColor: backgroundColor ?? Colors.transparent,
          elevation: 0,
          insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: builder(dialogCtx),
        ),
      ),
    ),
  );
}

class ResponsiveScaffold extends StatelessWidget {
  final Widget body;
  final String title;
  final int selectedIndex;
  final ValueChanged<int>? onDestinationSelected;
  final VoidCallback? onLogout;

  const ResponsiveScaffold({
    super.key,
    required this.body,
    this.title = '',
    this.selectedIndex = 0,
    this.onDestinationSelected,
    this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isDesktop = constraints.maxWidth >= 900;

        if (!isDesktop) {
          // ── Vue Mobile & Petite Tablette ──
          return Scaffold(
            backgroundColor: AppColors.deepForest,
            body: body,
          );
        }

        // ── Vue Large Écran (Desktop, Web, Tablette en mode paysage) ──
        return Scaffold(
          backgroundColor: AppColors.deepForest,
          body: Row(
            children: [
              // Navigation Rail Latérale
              NavigationRail(
                backgroundColor: AppColors.darkSurface,
                unselectedIconTheme: IconThemeData(
                  color: AppColors.softMist.withValues(alpha: 0.6),
                ),
                selectedIconTheme: const IconThemeData(color: AppColors.mintSage),
                unselectedLabelTextStyle: TextStyle(
                  color: AppColors.softMist.withValues(alpha: 0.6),
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                ),
                selectedLabelTextStyle: const TextStyle(
                  color: AppColors.mintSage,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
                indicatorColor: AppColors.mintSage.withValues(alpha: 0.18),
                selectedIndex: selectedIndex.clamp(0, 2),
                labelType: NavigationRailLabelType.all,
                destinations: const [
                  NavigationRailDestination(
                    icon: Icon(Icons.dashboard_outlined),
                    selectedIcon: Icon(Icons.dashboard_rounded),
                    label: Text('Guichet'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.flash_on_outlined),
                    selectedIcon: Icon(Icons.flash_on_rounded),
                    label: Text('Recharge'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.settings_outlined),
                    selectedIcon: Icon(Icons.settings_rounded),
                    label: Text('Paramètres'),
                  ),
                ],
                onDestinationSelected: onDestinationSelected,
                trailing: onLogout != null
                    ? Expanded(
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 20.0),
                            child: IconButton(
                              tooltip: 'Déconnexion du guichet',
                              icon: const Icon(
                                Icons.logout_rounded,
                                color: AppColors.mintSage,
                              ),
                              onPressed: onLogout,
                            ),
                          ),
                        ),
                      )
                    : null,
              ),

              const VerticalDivider(width: 1, color: Color(0xFF1E3A2E)),

              // Zone de contenu principale plein écran et responsive
              Expanded(
                child: Container(
                  color: AppColors.deepForest,
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1400),
                      child: body,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
