import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';

/// ═══════════════════════════════════════════════════════════════
///  SMART_PAY_UCB — Charte Graphique Académique Université Catholique de Bukavu
///  1. Bleu Institutionnel UCB : #1E3A8A (Royal Navy officiel)
///  2. Bleu Cobalt             : #2563EB (Accent moderne)
///  3. Or Académique UCB       : #F59E0B / #D97706 (Puces NFC, distinctions)
///  4. Vert Émeraude           : #10B981 (Validation NFC, crédits)
///  5. Rouge Alerte            : #EF4444 (Solde insuffisant, débits)
///  6. Blanc Pur / Ardoise     : #FFFFFF / #F8FAFC (Fond épuré)
/// ═══════════════════════════════════════════════════════════════

class AppColors {
  // ── Palette Institutionnelle UCB ──
  static const Color ucbNavy = Color(0xFF1E3A8A);
  static const Color ucbBlue = Color(0xFF2563EB);
  static const Color ucbLightBlue = Color(0xFF3B82F6);
  static const Color ucbGold = Color(0xFFF59E0B);
  static const Color ucbGoldDark = Color(0xFFD97706);
  static const Color ucbGreen = Color(0xFF10B981);
  static const Color ucbRed = Color(0xFFEF4444);
  static const Color ucbSlate = Color(0xFFF8FAFC);
  static const Color ucbSlateDark = Color(0xFF0F172A);

  // ── Alias de Rétrocompatibilité (Deep Forest -> UCB Navy) ──
  static const Color deepForest = ucbNavy;
  static const Color softMist = ucbSlate;
  static const Color mintSage = ucbGreen;

  // ── Alias sémantiques ──
  static const Color primary = ucbNavy;
  static const Color secondary = ucbBlue;
  static const Color accent = ucbGold;
  static const Color gold = ucbGold;
  static const Color background = Color(0xFFF8FAFC);

  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceElevated = Color(0xFFFFFFFF);
  static const Color border = Color(0xFFE2E8F0);
  static const Color borderSubtle = Color(0xFFCBD5E1);

  // ── Mode sombre académique ──
  static const Color darkBackground = Color(0xFF0B1329);
  static const Color darkSurface = Color(0xFF111C3A);
  static const Color textOnDark = Color(0xFFF8FAFC);

  // ── Typographie et Textes ──
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF475569);
  static const Color textMuted = Color(0xFF64748B);

  // ── Statuts & SaaS Fintech Tokens ──
  static const Color emerald = Color(0xFF059669);
  static const Color darkSlate = Color(0xFF0F172A);
  static const Color success = emerald;
  static const Color warning = ucbGold;
  static const Color error = ucbRed;

  // ── Ombres SaaS Douces ──
  static const List<BoxShadow> saasCardShadow = [
    BoxShadow(
      color: Color(0x0A000000), // Colors.black.withOpacity(0.04)
      blurRadius: 10,
      offset: Offset(0, 4),
    ),
  ];

  // ── Dégradés Premium UCB ──
  static const LinearGradient ucbCardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF1E3A8A), // Bleu Institutionnel UCB
      Color(0xFF1E40AF),
      Color(0xFF0F2360),
    ],
    stops: [0.0, 0.6, 1.0],
  );

  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [ucbNavy, Color(0xFF2563EB)],
  );

  static const LinearGradient goldGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFBBF24), Color(0xFFD97706)],
  );

  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [ucbGreen, Color(0xFF059669)],
  );
}

class AppTheme {
  static ThemeData get lightTheme {
    final baseTextTheme = GoogleFonts.interTextTheme();

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      visualDensity: VisualDensity.adaptivePlatformDensity,
      scaffoldBackgroundColor: AppColors.background,
      textTheme: baseTextTheme.apply(
        bodyColor: AppColors.textPrimary,
        displayColor: AppColors.textPrimary,
      ),
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        tertiary: AppColors.accent,
        surface: AppColors.surface,
        error: AppColors.error,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: AppColors.textPrimary,
        onError: Colors.white,
      ),

      // ── AppBar ──
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.inter(
          color: AppColors.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.2,
        ),
        iconTheme: const IconThemeData(color: AppColors.ucbNavy),
      ),

      // ── Navigation Rail ──
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: AppColors.surfaceElevated,
        elevation: 0,
        indicatorColor: AppColors.ucbBlue.withValues(alpha: 0.12),
        labelType: NavigationRailLabelType.all,
      ),

      // ── Cards ──
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.border, width: 1.0),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),

      // ── Input Decoration ──
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceElevated,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.ucbNavy, width: 2.0),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error, width: 1.2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        hintStyle: GoogleFonts.inter(
          color: AppColors.textMuted,
          fontSize: 14,
        ),
        labelStyle: GoogleFonts.inter(
          color: AppColors.textSecondary,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),

      // ── Elevated Button ──
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.ucbNavy,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size(0, 52),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
          ),
        ),
      ),

      // ── Outlined Button ──
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.ucbNavy,
          side: const BorderSide(color: AppColors.ucbNavy, width: 1.5),
          minimumSize: const Size(0, 52),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // ── Text Button ──
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.ucbNavy,
          textStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // ── TabBar ──
      tabBarTheme: TabBarThemeData(
        indicatorColor: AppColors.ucbNavy,
        labelColor: AppColors.ucbNavy,
        unselectedLabelColor: AppColors.textMuted,
        labelStyle: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14),
        unselectedLabelStyle: GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: 14),
      ),

      // ── Dialog ──
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surfaceElevated,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        titleTextStyle: GoogleFonts.inter(
          color: AppColors.textPrimary,
          fontSize: 19,
          fontWeight: FontWeight.w700,
        ),
        contentTextStyle: GoogleFonts.inter(
          color: AppColors.textSecondary,
          fontSize: 14,
        ),
      ),

      // ── Snackbar ──
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.ucbNavy,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        contentTextStyle: GoogleFonts.inter(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),

      // ── Bottom Sheet ──
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surfaceElevated,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        modalBarrierColor: Color(0x660F172A),
      ),

      // ── Divider ──
      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        thickness: 1,
        space: 1,
      ),

      // ── Page Transitions ──
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.windows: CupertinoPageTransitionsBuilder(),
          TargetPlatform.linux: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData.dark().copyWith(
      scaffoldBackgroundColor: AppColors.darkBackground,
      colorScheme: const ColorScheme.dark(
        surface: AppColors.darkSurface,
        primary: AppColors.ucbBlue,
        secondary: AppColors.ucbGold,
        onSurface: AppColors.textOnDark,
        onPrimary: Colors.white,
        onSecondary: Colors.black,
        error: AppColors.error,
      ),
      textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme).apply(
        bodyColor: AppColors.textOnDark,
        displayColor: AppColors.textOnDark,
      ),
      iconTheme: const IconThemeData(color: AppColors.textOnDark),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.inter(
          color: AppColors.textOnDark,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.2,
        ),
        iconTheme: const IconThemeData(color: AppColors.textOnDark),
      ),
      cardTheme: CardThemeData(
        color: AppColors.darkSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: AppColors.ucbNavy.withValues(alpha: 0.4), width: 1.0),
        ),
      ),
    );
  }
}
