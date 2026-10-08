import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../services/auth_service.dart';
import '../services/hive_service.dart';
import '../theme/app_theme.dart';
import '../widgets/constrained_body.dart';
import '../widgets/saas_widgets.dart';
import 'card_profile_screen.dart';
import 'history_screen.dart';
import 'login_screen.dart';
import 'recharge_screen.dart';

/// ═══════════════════════════════════════════════════════════════
///  ÉCRAN 2 — Dashboard Étudiant (SMART_PAY_UCB)
///  Navigation responsive : Sidebar Desktop / Barre Mobile
///  Sections : Solde & Statut · Historique · Recharge · Mon Profil
/// ═══════════════════════════════════════════════════════════════

class StudentDashboardScreen extends StatefulWidget {
  const StudentDashboardScreen({super.key});

  @override
  State<StudentDashboardScreen> createState() => _StudentDashboardScreenState();
}

class _StudentDashboardScreenState extends State<StudentDashboardScreen> {
  late String _cardUid;
  Timer? _refreshTimer;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _cardUid = AuthService.studentCardUid ?? 'UCB-CARD-001';
    _refreshTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _selectSection(int index) {
    setState(() => _selectedIndex = index);
  }

  void _logout() {
    AuthService.logout();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  void _showReportLostDialog(bool isCurrentlyBlocked) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color:
                    (isCurrentlyBlocked ? AppColors.emerald : AppColors.error)
                        .withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                isCurrentlyBlocked
                    ? Icons.lock_open_rounded
                    : Icons.warning_amber_rounded,
                color: isCurrentlyBlocked ? AppColors.emerald : AppColors.error,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                isCurrentlyBlocked
                    ? 'Débloquer la carte'
                    : 'Signaler carte perdue/volée',
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A)),
              ),
            ),
          ],
        ),
        content: Text(
          isCurrentlyBlocked
              ? 'Voulez-vous réactiver votre carte RFID/NFC ($_cardUid) ?\nVous pourrez à nouveau l\'utiliser pour payer vos déplacements en bus.'
              : 'Êtes-vous sûr de vouloir déclarer votre carte ($_cardUid) comme perdue ou volée ?\n\nElle sera instantanément suspendue dans Hive et refusée dans tous les bus UCB.',
          style: const TextStyle(
              fontSize: 13, height: 1.4, color: Color(0xFF475569)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler',
                style: TextStyle(color: Color(0xFF64748B))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  isCurrentlyBlocked ? AppColors.ucbNavy : AppColors.error,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              final card = HiveService.findByUid(_cardUid);
              if (card != null) {
                card.setBlocked(!isCurrentlyBlocked);
              }
              if (!mounted) return;
              Navigator.pop(ctx);
              setState(() {});
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor:
                      !isCurrentlyBlocked ? AppColors.error : AppColors.emerald,
                  content: Text(
                    !isCurrentlyBlocked
                        ? 'Carte signalée et suspendue avec succès.'
                        : 'Carte réactivée avec succès.',
                  ),
                ),
              );
            },
            child: Text(
              isCurrentlyBlocked ? 'Réactiver' : 'Confirmer le blocage',
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  /// ════ NAVIGATION MENU (Sidebar Desktop / Drawer Mobile) ════
  Widget _buildNavMenu() {
    final card = HiveService.findByUid(_cardUid);
    final String studentName = card?.fullName ?? AuthService.userName;
    final String studentId = card?.studentId ?? '22/0841/UCB';
    final bool isBlocked = card?.isBlocked ?? false;

    final destinations = [
      const NavigationDrawerDestination(
        icon: Icon(Icons.account_balance_wallet_outlined),
        selectedIcon: Icon(Icons.account_balance_wallet_rounded),
        label: Text('Solde & Statut'),
      ),
      const NavigationDrawerDestination(
        icon: Icon(Icons.history_outlined),
        selectedIcon: Icon(Icons.history_rounded),
        label: Text('Historique'),
      ),
      const NavigationDrawerDestination(
        icon: Icon(Icons.bolt_outlined),
        selectedIcon: Icon(Icons.bolt_rounded),
        label: Text('Recharge'),
      ),
      const NavigationDrawerDestination(
        icon: Icon(Icons.person_outline),
        selectedIcon: Icon(Icons.person_rounded),
        label: Text('Mon Profil'),
      ),
    ];

    return NavigationDrawerTheme(
      data: NavigationDrawerThemeData(
        backgroundColor: Colors.white,
        indicatorColor: AppColors.ucbNavy.withValues(alpha: 0.12),
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? AppColors.ucbNavy : AppColors.textMuted,
          );
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            color: selected ? AppColors.ucbNavy : const Color(0xFF64748B),
            fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
            fontSize: 14,
          );
        }),
      ),
      child: NavigationDrawer(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _selectSection,
        children: [
          // ── En-tête : Fond Bleu UCB + Identité Étudiant ──
          Container(
            margin: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: AppColors.ucbCardGradient,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.directions_bus_rounded,
                        color: Colors.white, size: 22),
                    SizedBox(width: 8),
                    Text(
                      'SMART_PAY UCB',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          studentName.isNotEmpty
                              ? studentName[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            studentName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Matricule : $studentId',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: isBlocked
                            ? const Color(0xFFFCA5A5)
                            : const Color(0xFF86EFAC),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isBlocked ? 'CARTE SUSPENDUE' : 'CARTE ACTIVE',
                      style: TextStyle(
                        color: isBlocked
                            ? const Color(0xFFFCA5A5)
                            : const Color(0xFF86EFAC),
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          ...destinations,
        ],
      ),
    );
  }

  /// ════ CONTENU DES SECTIONS ════
  Widget _buildSection(int index) {
    final card = HiveService.findByUid(_cardUid);

    switch (index) {
      case 0:
        return MaxWidthContainer(
          maxWidth: 1100,
          child: _buildBalanceSection(card),
        );
      case 1:
        return HistoryScreen(cardUid: _cardUid);
      case 2:
        return RechargeScreen(card: card);
      case 3:
        if (card != null) {
          return CardProfileScreen(card: card, onLogout: _logout);
        }
        return const EmptyStateWidget(
          icon: Icons.credit_card_off_rounded,
          title: 'Carte introuvable',
          description: 'Aucune carte associée à votre compte.',
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildTabletNavRail() {
    return NavigationRail(
      backgroundColor: Colors.white,
      selectedIndex: _selectedIndex,
      onDestinationSelected: _selectSection,
      labelType: NavigationRailLabelType.all,
      indicatorColor: AppColors.ucbNavy.withValues(alpha: 0.12),
      minWidth: 76,
      leading: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.ucbNavy,
            borderRadius: BorderRadius.circular(12),
          ),
          child:
              const Icon(Icons.school_rounded, color: Colors.white, size: 22),
        ),
      ),
      destinations: const [
        NavigationRailDestination(
          icon: Icon(Icons.account_balance_wallet_outlined),
          selectedIcon: Icon(Icons.account_balance_wallet_rounded,
              color: AppColors.ucbNavy),
          label: Text('Solde', style: TextStyle(fontSize: 11)),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.history_outlined),
          selectedIcon: Icon(Icons.history_rounded, color: AppColors.ucbNavy),
          label: Text('Historique', style: TextStyle(fontSize: 11)),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.bolt_outlined),
          selectedIcon: Icon(Icons.bolt_rounded, color: AppColors.ucbNavy),
          label: Text('Recharge', style: TextStyle(fontSize: 11)),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.person_outline),
          selectedIcon: Icon(Icons.person_rounded, color: AppColors.ucbNavy),
          label: Text('Profil', style: TextStyle(fontSize: 11)),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final card = HiveService.findByUid(_cardUid);
        final width = constraints.maxWidth;
        final bool isDesktop = width >= 1024;
        final bool isTablet = width >= 650 && width < 1024;
        final bool isBlocked = card?.isBlocked ?? false;

        final Widget sections = IndexedStack(
          index: _selectedIndex,
          children: List.generate(4, (i) => _buildSection(i)),
        );

        if (isDesktop) {
          return Scaffold(
            backgroundColor: const Color(0xFFF8FAFC),
            body: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildNavMenu(),
                const VerticalDivider(width: 1, color: Color(0xFFE2E8F0)),
                Expanded(
                  child: ClipRect(child: sections),
                ),
              ],
            ),
          );
        }

        if (isTablet) {
          return Scaffold(
            backgroundColor: const Color(0xFFF8FAFC),
            body: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildTabletNavRail(),
                const VerticalDivider(width: 1, color: Color(0xFFE2E8F0)),
                Expanded(
                  child: ClipRect(child: sections),
                ),
              ],
            ),
          );
        }

        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          appBar: AppBar(
            automaticallyImplyLeading: false,
            backgroundColor: Colors.white,
            elevation: 0,
            title: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8.w),
                  decoration: BoxDecoration(
                    color: AppColors.ucbNavy.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Icon(Icons.school_rounded,
                      color: AppColors.ucbNavy, size: 22.sp),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'SMART_PAY UCB',
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w800,
                          color: AppColors.ucbNavy,
                          letterSpacing: 0.5,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        AuthService.userName,
                        style: TextStyle(
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF64748B),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              if (!isBlocked)
                IconButton(
                  tooltip: 'Recharger',
                  icon:
                      const Icon(Icons.bolt_rounded, color: AppColors.ucbNavy),
                  onPressed: () => setState(() => _selectedIndex = 2),
                ),
            ],
          ),
          body: sections,
          bottomNavigationBar: NavigationBar(
            backgroundColor: Colors.white,
            indicatorColor: AppColors.ucbNavy.withValues(alpha: 0.12),
            selectedIndex: _selectedIndex,
            onDestinationSelected: _selectSection,
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.account_balance_wallet_outlined),
                selectedIcon: Icon(Icons.account_balance_wallet_rounded),
                label: 'Solde',
              ),
              NavigationDestination(
                icon: Icon(Icons.history_outlined),
                selectedIcon: Icon(Icons.history_rounded),
                label: 'Historique',
              ),
              NavigationDestination(
                icon: Icon(Icons.bolt_outlined),
                selectedIcon: Icon(Icons.bolt_rounded),
                label: 'Recharge',
              ),
              NavigationDestination(
                icon: Icon(Icons.person_outline),
                selectedIcon: Icon(Icons.person_rounded),
                label: 'Profil',
              ),
            ],
          ),
        );
      },
    );
  }

  /// ════ SECTION 0 — SOLDE & STATUT ════
  Widget _buildBalanceSection(dynamic card) {
    final double balance = card?.balance ?? 0.0;
    final bool isBlocked = card?.isBlocked ?? false;
    final String studentName = card?.fullName ?? AuthService.userName;
    final String studentId = card?.studentId ?? '22/0841/UCB';
    final bool isWide = MediaQuery.sizeOf(context).width >= 720;

    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      padding: EdgeInsets.all(20.w),
      child: isWide
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Colonne Gauche : Carte Virtuelle
                Expanded(
                  flex: 5,
                  child: _buildVirtualCard(
                    balance: balance,
                    isBlocked: isBlocked,
                    studentName: studentName,
                    studentId: studentId,
                  )
                      .animate()
                      .fadeIn(duration: 350.ms)
                      .slideY(begin: -0.05, end: 0),
                ),
                SizedBox(width: 20.w),
                // Colonne Droite : Bouton Recharge Rapide + Sécurité
                Expanded(
                  flex: 5,
                  child: Column(
                    children: [
                      _buildQuickRechargeButton(card)
                          .animate()
                          .fadeIn(delay: 80.ms, duration: 350.ms),
                      SizedBox(height: 18.h),
                      _buildSecurityCard(isBlocked)
                          .animate()
                          .fadeIn(delay: 200.ms, duration: 350.ms),
                    ],
                  ),
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildVirtualCard(
                  balance: balance,
                  isBlocked: isBlocked,
                  studentName: studentName,
                  studentId: studentId,
                )
                    .animate()
                    .fadeIn(duration: 350.ms)
                    .slideY(begin: -0.05, end: 0),
                SizedBox(height: 18.h),
                _buildQuickRechargeButton(card)
                    .animate()
                    .fadeIn(delay: 80.ms, duration: 350.ms),
                SizedBox(height: 18.h),
                _buildSecurityCard(isBlocked)
                    .animate()
                    .fadeIn(delay: 200.ms, duration: 350.ms),
                SizedBox(height: 24.h),
              ],
            ),
    );
  }

  /// ── Carte Virtuelle Étudiante UCB ──
  Widget _buildVirtualCard({
    required double balance,
    required bool isBlocked,
    required String studentName,
    required String studentId,
  }) {
    final clean = balance.toStringAsFixed(0);
    final reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    final formattedBalance =
        '${clean.replaceAllMapped(reg, (Match m) => '${m[1]} ')} FC';

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        gradient: isBlocked
            ? const LinearGradient(
                colors: [Color(0xFF475569), Color(0xFF1E293B)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : AppColors.ucbCardGradient,
        borderRadius: BorderRadius.circular(22.r),
        boxShadow: [
          BoxShadow(
            color: isBlocked
                ? Colors.black.withValues(alpha: 0.15)
                : AppColors.ucbNavy.withValues(alpha: 0.3),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8.r),
                    border:
                        Border.all(color: Colors.white.withValues(alpha: 0.2)),
                  ),
                  child: Text(
                    'UNIVERSITÉ CATHOLIQUE DE BUKAVU',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.6,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              SizedBox(width: 8.w),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: isBlocked
                      ? AppColors.error.withValues(alpha: 0.3)
                      : AppColors.emerald.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(20.r),
                  border: Border.all(
                    color: isBlocked ? AppColors.error : AppColors.emerald,
                    width: 1.2,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6.w,
                      height: 6.w,
                      decoration: BoxDecoration(
                        color: isBlocked
                            ? const Color(0xFFFCA5A5)
                            : const Color(0xFF86EFAC),
                        shape: BoxShape.circle,
                      ),
                    ),
                    SizedBox(width: 6.w),
                    Text(
                      isBlocked ? 'SUSPENDUE' : 'ACTIVE',
                      style: TextStyle(
                        color: isBlocked
                            ? const Color(0xFFFCA5A5)
                            : const Color(0xFF86EFAC),
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 20.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 36.w,
                      height: 28.h,
                      decoration: BoxDecoration(
                        gradient: AppColors.goldGradient,
                        borderRadius: BorderRadius.circular(6.r),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.ucbGold.withValues(alpha: 0.35),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(Icons.nfc_rounded,
                          color: const Color(0xFF78350F), size: 18.sp),
                    ),
                    SizedBox(height: 12.h),
                    Text(
                      'SOLDE DE TRANSPORT',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.75),
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.0,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        formattedBalance,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 28.sp,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Opacity(
                opacity: 0.2,
                child: Icon(
                  Icons.contactless_rounded,
                  size: 54.sp,
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ),
            ],
          ),
          SizedBox(height: 20.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      studentName,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w800,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      'Matricule : $studentId',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6.r),
                ),
                child: Text(
                  _cardUid,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 11.sp,
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// ── Bouton d'action rapide : Recharger ──
  Widget _buildQuickRechargeButton(dynamic card) {
    return SizedBox(
      width: double.infinity,
      height: 44,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.ucbNavy,
          foregroundColor: Colors.white,
          elevation: 2,
          shadowColor: AppColors.ucbNavy.withValues(alpha: 0.25),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        ),
        onPressed: () => setState(() => _selectedIndex = 2),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bolt_rounded, color: AppColors.ucbGold, size: 20),
            SizedBox(width: 8),
            Flexible(
              child: Text(
                'Recharger mon compte en ligne',
                style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// ── Option de Sécurité : Signaler carte perdue/volée ──
  Widget _buildSecurityCard(bool isBlocked) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color:
            isBlocked ? AppColors.error.withValues(alpha: 0.04) : Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: isBlocked
              ? AppColors.error.withValues(alpha: 0.3)
              : const Color(0xFFE2E8F0),
        ),
        boxShadow: AppColors.saasCardShadow,
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10.w),
            decoration: BoxDecoration(
              color: (isBlocked ? AppColors.error : AppColors.ucbNavy)
                  .withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(
              isBlocked ? Icons.lock_rounded : Icons.shield_outlined,
              color: isBlocked ? AppColors.error : AppColors.ucbNavy,
              size: 22.sp,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isBlocked ? 'Carte Suspendue' : 'Sécurité & Verrouillage',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14.sp,
                    color: const Color(0xFF0F172A),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 2.h),
                Text(
                  isBlocked
                      ? 'Tout débit est actuellement refusé dans les bus.'
                      : 'Perte ou vol ? Bloquez instantanément la carte.',
                  style: TextStyle(
                      fontSize: 12.sp, color: const Color(0xFF64748B)),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
              ],
            ),
          ),
          SizedBox(width: 8.w),
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: isBlocked ? AppColors.emerald : AppColors.error,
              side: BorderSide(
                  color: isBlocked ? AppColors.emerald : AppColors.error),
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.r)),
            ),
            onPressed: () => _showReportLostDialog(isBlocked),
            child: Text(
              isBlocked ? 'Réactiver' : 'Signaler',
              style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}
