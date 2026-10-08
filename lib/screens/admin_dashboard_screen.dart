import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/card_model.dart';
import '../models/transport_models.dart';
import '../services/auth_service.dart';
import '../services/hive_service.dart';
import '../services/payment_service.dart';
import '../services/transport_service.dart';
import '../theme/app_theme.dart';
import '../widgets/cinetpay_receipt_dialog.dart';
import '../widgets/responsive_layout.dart';
import 'login_screen.dart';

/// ═══════════════════════════════════════════════════════════════
///  SMART_PAY_UCB — Interface Gestionnaire & Perception CinetPay
///  Assure :
///   1. La perception globale & le suivi financier CinetPay
///   2. Le détail exhaustif de paiement pour chaque étudiant
///   3. Le journal en direct des flux CinetPay & encaissements guichet
/// ═══════════════════════════════════════════════════════════════

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen>
    with TickerProviderStateMixin {
  int _currentTab = 0; // 0: Étudiants & Détails, 1: Journal CinetPay, 2: Guichet Perception
  final _searchController = TextEditingController();
  final _journalSearchController = TextEditingController();
  String _searchQuery = '';
  String _journalSearchQuery = '';
  String _selectedFilter = 'Tous';
  String _selectedOperatorFilter = 'Tous';

  Timer? _refreshTimer;
  late AnimationController _headerAnimController;
  late Animation<double> _headerFadeAnim;

  final List<String> _filters = ['Tous', "Rechargé aujourd'hui"];
  final List<String> _operatorFilters = ['Tous', 'M-Pesa', 'Airtel Money', 'Orange Money'];

  // Formulaire Guichet Perception
  String? _selectedGuichetCardUid;
  final _guichetAmountController = TextEditingController(text: '5000');
  String _guichetMethod = 'Espèces (Cash)';
  bool _isGuichetSubmitting = false;

  @override
  void initState() {
    super.initState();
    _headerAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _headerFadeAnim = CurvedAnimation(
      parent: _headerAnimController,
      curve: Curves.easeOut,
    );
    _headerAnimController.forward();

    // Actualisation périodique pour réactivité en direct
    _refreshTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (mounted) setState(() {});
    });

    PaymentService.updateNotifier.addListener(_onPaymentUpdated);
  }

  void _onPaymentUpdated() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    PaymentService.updateNotifier.removeListener(_onPaymentUpdated);
    _searchController.dispose();
    _journalSearchController.dispose();
    _guichetAmountController.dispose();
    _refreshTimer?.cancel();
    _headerAnimController.dispose();
    super.dispose();
  }

  List<RechargeCard> _getFilteredCards() {
    final all = HiveService.getAllCards();
    final query = _searchQuery.toLowerCase().trim();

    List<RechargeCard> filtered = all.where((c) {
      if (query.isEmpty) return true;
      return c.fullName.toLowerCase().contains(query) ||
          (c.studentId?.toLowerCase().contains(query) ?? false) ||
          c.phoneNumber.contains(query) ||
          c.uid.toLowerCase().contains(query);
    }).toList();

    switch (_selectedFilter) {
      case "Rechargé aujourd'hui":
        final today = DateTime.now();
        filtered = filtered.where((c) {
          final paymentsToday = PaymentService.getPaymentsForCard(c.uid).where((p) =>
              p.timestamp.year == today.year &&
              p.timestamp.month == today.month &&
              p.timestamp.day == today.day,
          );
          return paymentsToday.isNotEmpty;
        }).toList();
        break;
      default:
        filtered.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    }

    return filtered;
  }

  List<OnlineRecharge> _getFilteredJournalPayments() {
    final all = PaymentService.getAllPayments();
    final query = _journalSearchQuery.toLowerCase().trim();

    return all.where((tx) {
      final matchesQuery = query.isEmpty ||
          tx.studentName.toLowerCase().contains(query) ||
          (tx.studentId?.toLowerCase().contains(query) ?? false) ||
          tx.cinetpayTransactionId.toLowerCase().contains(query) ||
          (tx.operatorTransactionId?.toLowerCase().contains(query) ?? false) ||
          tx.phoneNumber.contains(query);

      if (!matchesQuery) return false;

      if (_selectedOperatorFilter == 'Tous') return true;
      if (_selectedOperatorFilter == 'M-Pesa') return tx.operator == MobileOperator.mpesa;
      if (_selectedOperatorFilter == 'Airtel Money') return tx.operator == MobileOperator.airtel;
      if (_selectedOperatorFilter == 'Orange Money') return tx.operator == MobileOperator.orange;
      return true;
    }).toList();
  }

  String _formatMoney(double amount) {
    final clean = amount.toStringAsFixed(0);
    final reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    return clean.replaceAllMapped(reg, (m) => '${m[1]} ');
  }

  String _formatDateTime(DateTime dt) {
    final d = dt.day.toString().padLeft(2, '0');
    final mo = dt.month.toString().padLeft(2, '0');
    final h = dt.hour.toString().padLeft(2, '0');
    final mi = dt.minute.toString().padLeft(2, '0');
    return '$d/$mo/${dt.year} à $h:$mi';
  }

  Color _getOperatorColor(MobileOperator op) {
    switch (op) {
      case MobileOperator.mpesa:
        return const Color(0xFFE60000);
      case MobileOperator.airtel:
        return const Color(0xFFDC2626);
      case MobileOperator.orange:
        return const Color(0xFFFF7900);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cards = HiveService.getAllCards();
    final totalCollected = PaymentService.totalCollected;
    final totalBalance = cards.fold<double>(0, (s, c) => s + c.balance);
    final totalBusTrips = TransportService.getAllTrips().where((t) => t.isSuccessful).length;
    final collectedToday = PaymentService.totalCollectedToday;
    final countToday = PaymentService.countToday;
    final operatorMap = PaymentService.perceptionByOperator;

    final width = MediaQuery.sizeOf(context).width;
    final isWide = width >= 900;

    return Scaffold(
      backgroundColor: const Color(0xFF0B1329),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1400),
          child: Column(
            children: [
              // ── En-tête Gestionnaire & Perception CinetPay ──
              FadeTransition(
                opacity: _headerFadeAnim,
                child: _buildHeader(
                  totalCollected: totalCollected,
                  totalBalance: totalBalance,
                  totalBusTrips: totalBusTrips,
                  collectedToday: collectedToday,
                  countToday: countToday,
                  operatorMap: operatorMap,
                  isWide: isWide,
                ),
              ),

              // ── Corps Principal avec Onglets Métier ──
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(32),
                      topRight: Radius.circular(32),
                    ),
                  ),
                  child: Column(
                    children: [
                      // ── Barre de Navigation des 3 Onglets ──
                      _buildTabBar(isWide),

                      // ── Vue active ──
                      Expanded(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 250),
                          child: _buildCurrentTabView(isWide, cards),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  1. EN-TÊTE FINANCIER & PERCEPTION CINETPAY (EXEMPLE IMAGE)
  // ═══════════════════════════════════════════════════════════════

  Widget _buildHeader({
    required double totalCollected,
    required double totalBalance,
    required int totalBusTrips,
    required double collectedToday,
    required int countToday,
    required Map<MobileOperator, double> operatorMap,
    required bool isWide,
  }) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF091636),
            Color(0xFF0E255B),
            Color(0xFF133682),
          ],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top row : Portefeuille + Titre & Gestionnaire + Déconnexion
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(13),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
                          ),
                          child: const Icon(Icons.account_balance_wallet_rounded, color: Colors.white, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                'SMART_PAY UCB ...',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  letterSpacing: 0.3,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Gestionnaire : ${AuthService.userName}...',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: Colors.white.withValues(alpha: 0.7),
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(13),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
                    ),
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      tooltip: 'Déconnexion',
                      icon: const Icon(Icons.logout_rounded, color: Colors.white, size: 19),
                      onPressed: () {
                        AuthService.logout();
                        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // KPI Principaux
              if (isWide) ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      flex: 4,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'TOTAL RECHARGES (enligne +Guichet)',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF7EA5D9),
                              letterSpacing: 0.8,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                _formatMoney(totalCollected),
                                style: const TextStyle(fontSize: 38, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -1.2, height: 1),
                              ),
                              const SizedBox(width: 8),
                              const Padding(
                                padding: EdgeInsets.only(bottom: 4),
                                child: Text('FC', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF7EA5D9))),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Aujourd'hui : + ${_formatMoney(collectedToday)} FC ($countToday opération(s))",
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF34D399)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 6,
                      child: Row(
                        children: [
                          _buildHeaderKpi(
                            label: 'Solde caisse',
                            value: '${_formatMoney(totalBalance)} FC',
                            icon: Icons.account_balance_wallet_rounded,
                            color: const Color(0xFF2DD4BF),
                          ),
                          const SizedBox(width: 10),
                          _buildHeaderKpi(
                            label: 'Aujourd hui',
                            value: '+ ${_formatMoney(collectedToday)} FC',
                            icon: Icons.calendar_today_rounded,
                            color: const Color(0xFF818CF8),
                          ),
                          const SizedBox(width: 10),
                          _buildHeaderKpi(
                            label: 'Paiements Bus',
                            value: '$totalBusTrips trajets',
                            icon: Icons.directions_bus_rounded,
                            color: const Color(0xFFFBBF24),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ] else ...[
                const Text(
                  'TOTAL RECHARGES (enligne +Guichet)',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF7EA5D9),
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          _formatMoney(totalCollected),
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: -1.0,
                            height: 1,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Padding(
                      padding: EdgeInsets.only(bottom: 4),
                      child: Text(
                        'FC',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF7EA5D9),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    _buildHeaderKpi(
                      label: 'Solde caisse',
                      value: '${_formatMoney(totalBalance)} FC',
                      icon: Icons.account_balance_wallet_rounded,
                      color: const Color(0xFF2DD4BF),
                    ),
                    const SizedBox(width: 8),
                    _buildHeaderKpi(
                      label: 'Aujourd hui',
                      value: '+ ${_formatMoney(collectedToday)} FC',
                      icon: Icons.calendar_today_rounded,
                      color: const Color(0xFF818CF8),
                    ),
                    const SizedBox(width: 8),
                    _buildHeaderKpi(
                      label: 'Paiements Bus',
                      value: '$totalBusTrips trajets',
                      icon: Icons.directions_bus_rounded,
                      color: const Color(0xFFFBBF24),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 12),

              // ── Encart de perception par opérateur Mobile Money (Exact Image) ──
              _buildOperatorMiniBreakdown(totalCollected, operatorMap),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderKpi({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 9),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(height: 7),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  height: 1.1,
                ),
                maxLines: 1,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: Colors.white.withValues(alpha: 0.65),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOperatorMiniBreakdown(double total, Map<MobileOperator, double> map) {
    final mpesa = map[MobileOperator.mpesa] ?? 0.0;
    final orange = map[MobileOperator.orange] ?? 0.0;
    final airtel = map[MobileOperator.airtel] ?? 0.0;

    return Row(
      children: [
        _buildOperatorCard(
          badge: _buildVodacomBadge(),
          operatorTitleWidget: const Text(
            'Vodacom\nM-Pesa',
            style: TextStyle(
              color: Colors.white,
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              height: 1.1,
            ),
            maxLines: 2,
          ),
          amountText: 'M-Pesa ${_formatMoney(mpesa)} FC',
          subText: 'Vodacom',
        ),
        const SizedBox(width: 8),
        _buildOperatorCard(
          badge: _buildOrangeBadge(),
          operatorTitleWidget: const Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: 'Orange\n',
                  style: TextStyle(color: Color(0xFFFF7900), fontWeight: FontWeight.w900, fontSize: 10.5, height: 1.1),
                ),
                TextSpan(
                  text: 'Money',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 10.5, height: 1.1),
                ),
              ],
            ),
            maxLines: 2,
          ),
          amountText: 'Orange ${_formatMoney(orange)} FC',
          subText: 'Orange Money',
        ),
        const SizedBox(width: 8),
        _buildOperatorCard(
          badge: _buildAirtelBadge(),
          operatorTitleWidget: const Text(
            'Airtel\nMoney',
            style: TextStyle(
              color: Colors.white,
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              height: 1.1,
            ),
            maxLines: 2,
          ),
          amountText: 'Airtel ${_formatMoney(airtel)} FC',
          subText: 'Airtel',
        ),
      ],
    );
  }

  Widget _buildVodacomBadge() {
    return Container(
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: const BoxDecoration(
                color: Color(0xFFE60000),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Container(
                  width: 5.5,
                  height: 5.5,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 1),
            const Text(
              'vodacom',
              style: TextStyle(
                color: Color(0xFFE60000),
                fontSize: 4.2,
                fontWeight: FontWeight.w900,
                height: 1.0,
                letterSpacing: -0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrangeBadge() {
    return Container(
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        color: const Color(0xFFFF7900),
        borderRadius: BorderRadius.circular(6),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF7900).withValues(alpha: 0.35),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: const Center(
        child: Icon(
          Icons.sync_alt_rounded,
          color: Colors.white,
          size: 16,
        ),
      ),
    );
  }

  Widget _buildAirtelBadge() {
    return Container(
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        color: const Color(0xFFDC2626),
        borderRadius: BorderRadius.circular(6),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFDC2626).withValues(alpha: 0.35),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'airtel',
              style: TextStyle(
                color: Colors.white,
                fontSize: 5.8,
                fontWeight: FontWeight.w900,
                height: 1.0,
              ),
            ),
            Text(
              'money',
              style: TextStyle(
                color: Colors.white,
                fontSize: 4.8,
                fontWeight: FontWeight.w700,
                height: 1.0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOperatorCard({
    required Widget badge,
    required Widget operatorTitleWidget,
    required String amountText,
    required String subText,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                badge,
                const SizedBox(width: 5),
                Expanded(child: operatorTitleWidget),
              ],
            ),
            const SizedBox(height: 7),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                amountText,
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
                maxLines: 1,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subText,
              style: TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w500,
                color: Colors.white.withValues(alpha: 0.65),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  2. BARRE D'ONGLETS DU GESTIONNAIRE (EXACT IMAGE)
  // ═══════════════════════════════════════════════════════════════

  Widget _buildTabBar(bool isWide) {
    final tabs = [
      {'icon': Icons.people_alt_rounded, 'label': 'Étudiants & Détails'},
      {'icon': Icons.receipt_long_rounded, 'label': 'Journal des Perceptions en ligne'},
      {'icon': Icons.point_of_sale_rounded, 'label': 'Perception au Guichet (Encaisser)'},
    ];

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: List.generate(tabs.length, (index) {
            final isSelected = _currentTab == index;
            final item = tabs[index];
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: InkWell(
                onTap: () => setState(() => _currentTab = index),
                borderRadius: BorderRadius.circular(16),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF162D63) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected ? const Color(0xFF162D63) : const Color(0xFFE2E8F0),
                      width: 1.2,
                    ),
                    boxShadow: isSelected
                        ? [BoxShadow(color: const Color(0xFF162D63).withValues(alpha: 0.25), blurRadius: 8, offset: const Offset(0, 3))]
                        : const [BoxShadow(color: Color(0x06000000), blurRadius: 4, offset: Offset(0, 2))],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        item['icon'] as IconData,
                        size: 16,
                        color: isSelected ? Colors.white : const Color(0xFF64748B),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        item['label'] as String,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                          color: isSelected ? Colors.white : const Color(0xFF475569),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildCurrentTabView(bool isWide, List<RechargeCard> cards) {
    switch (_currentTab) {
      case 0:
        return _buildStudentsTabView(isWide);
      case 1:
        return _buildJournalTabView(isWide);
      case 2:
        return _buildGuichetTabView(isWide, cards);
      default:
        return const SizedBox.shrink();
    }
  }

  // ═══════════════════════════════════════════════════════════════
  //  3. ONGLET 1 : ÉTUDIANTS & DÉTAILS DE PAIEMENT
  // ═══════════════════════════════════════════════════════════════

  Widget _buildStudentsTabView(bool isWide) {
    final filteredCards = _getFilteredCards();

    if (filteredCards.isEmpty) {
      return Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
            child: Column(
              children: [
                _buildSearchField(),
                const SizedBox(height: 10),
                _buildFilterChips(),
              ],
            ),
          ),
          Expanded(
            child: _buildEmptyState(
              title: 'Aucun étudiant trouvé',
              message: 'Modifiez vos critères de recherche ou de filtre.',
            ),
          ),
        ],
      );
    }

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        // ── Recherche & Filtres (collent en haut au scroll) ──
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
            child: Column(
              children: [
                _buildSearchField(),
                const SizedBox(height: 10),
                _buildFilterChips(),
              ],
            ),
          ),
        ),

        // ── Liste des Étudiants ──
        if (isWide)
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
            sliver: SliverGrid(
              delegate: SliverChildBuilderDelegate(
                (context, index) =>
                    _buildStudentCardRow(filteredCards[index], index),
                childCount: filteredCards.length,
              ),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                mainAxisExtent: 86,
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) =>
                    _buildStudentCardRow(filteredCards[index], index),
                childCount: filteredCards.length,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSearchField() {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (v) => setState(() => _searchQuery = v),
        style: const TextStyle(fontSize: 13.5, color: Color(0xFF0F172A), fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          hintText: 'Rechercher par nom, matricule, télé...',
          hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
          prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF94A3B8), size: 20),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear_rounded, size: 18, color: Color(0xFF94A3B8)),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final f = _filters[i];
          final isSelected = _selectedFilter == f;
          return GestureDetector(
            onTap: () => setState(() => _selectedFilter = f),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF162D63) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? const Color(0xFF162D63) : const Color(0xFFE2E8F0),
                  width: 1.2,
                ),
                boxShadow: isSelected
                    ? [BoxShadow(color: const Color(0xFF162D63).withValues(alpha: 0.2), blurRadius: 6, offset: const Offset(0, 2))]
                    : [],
              ),
              child: Text(
                f,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                  color: isSelected ? Colors.white : const Color(0xFF1E293B),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStudentCardRow(RechargeCard card, int index) {
    final studentPayments = PaymentService.getPaymentsForCard(card.uid);

    // Palettes correspondantes aux étudiants de la capture d'écran
    // 0: AL (Bleu ciel / Bleu roi)
    // 1: JK (Lavande / Violet)
    // 2: GM (Menthe / Vert foncé)
    final palettes = [
      {'bg': const Color(0xFFE0EDFD), 'text': const Color(0xFF1D4ED8)},
      {'bg': const Color(0xFFF3E8FF), 'text': const Color(0xFF7E22CE)},
      {'bg': const Color(0xFFDCFCE7), 'text': const Color(0xFF15803D)},
      {'bg': const Color(0xFFFEF3C7), 'text': const Color(0xFFB45309)},
      {'bg': const Color(0xFFFFE4E6), 'text': const Color(0xFFBE123C)},
      {'bg': const Color(0xFFE0F2FE), 'text': const Color(0xFF0369A1)},
    ];
    final palette = palettes[index % palettes.length];
    final initials = card.fullName
        .split(' ')
        .where((w) => w.isNotEmpty)
        .take(2)
        .map((w) => w[0])
        .join()
        .toUpperCase();



    return GestureDetector(
      onTap: () => _showStudentPaymentDetails(card),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE5E7EB), width: 1.2),
          boxShadow: const [
            BoxShadow(
              color: Color(0x06000000),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Avatar
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: palette['bg'],
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Text(
                  initials.isNotEmpty ? initials : 'ET',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: palette['text'],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Colonne informations centrale
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          card.fullName,
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDCFCE7),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${studentPayments.length} paiements',
                          style: const TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF15803D),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${card.studentId ?? card.uid} • ${card.promotion ?? card.faculty ?? "UCB"}',
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: Color(0xFF64748B),
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                ],
              ),
            ),
            const SizedBox(width: 8),

            // Colonne droite : Solde
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${_formatMoney(card.balance)} FC',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF0F172A),
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 1),
                const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'solde',
                      style: TextStyle(
                        fontSize: 10,
                        color: Color(0xFF94A3B8),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(width: 2),
                    Icon(Icons.chevron_right_rounded, size: 13, color: Color(0xFFCBD5E1)),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  4. FICHE DÉTAILLÉE DE PERCEPTION & PAIEMENTS D'UN ÉTUDIANT
  // ═══════════════════════════════════════════════════════════════

  void _showStudentPaymentDetails(RechargeCard card) {
    showAdaptiveModal(
      context: context,
      maxWidth: 680,
      builder: (_) => _StudentPaymentDetailModal(
        card: card,
        formatMoney: _formatMoney,
        formatDateTime: _formatDateTime,
        getOperatorColor: _getOperatorColor,
        onDirectPerception: () {
          Navigator.pop(context);
          setState(() {
            _currentTab = 2;
            _selectedGuichetCardUid = card.uid;
          });
        },
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  5. ONGLET 2 : JOURNAL CENTRAL DES PERCEPTIONS CINETPAY
  // ═══════════════════════════════════════════════════════════════

  Widget _buildJournalTabView(bool isWide) {
    final payments = _getFilteredJournalPayments();

    return Column(
      children: [
        // Recherche & Filtres Opérateur
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
          child: Column(
            children: [
              TextField(
                controller: _journalSearchController,
                onChanged: (v) => setState(() => _journalSearchQuery = v),
                style: const TextStyle(fontSize: 14, color: Color(0xFF0F172A)),
                decoration: InputDecoration(
                  hintText: 'Rechercher par référence, nom d\'étudiant ou matricule...',
                  hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                  prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF94A3B8), size: 20),
                  suffixIcon: _journalSearchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 18, color: Color(0xFF94A3B8)),
                          onPressed: () {
                            _journalSearchController.clear();
                            setState(() => _journalSearchQuery = '');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.ucbNavy, width: 1.5)),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 34,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _operatorFilters.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, i) {
                    final opName = _operatorFilters[i];
                    final isSelected = _selectedOperatorFilter == opName;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedOperatorFilter = opName),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFF008272) : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: isSelected ? const Color(0xFF008272) : const Color(0xFFE2E8F0)),
                        ),
                        child: Text(
                          opName,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: isSelected ? Colors.white : const Color(0xFF64748B),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),

        // Liste du Journal
        Expanded(
          child: payments.isEmpty
              ? _buildEmptyState(
                  title: 'Aucune perception trouvée',
                  message: 'Aucune transaction ne correspond à vos filtres de recherche.',
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
                  itemCount: payments.length,
                  itemBuilder: (context, index) {
                    final tx = payments[index];
                    final opColor = _getOperatorColor(tx.operator);

                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        boxShadow: const [BoxShadow(color: Color(0x05000000), blurRadius: 6, offset: Offset(0, 2))],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: opColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(Icons.verified_user_rounded, color: opColor, size: 22),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        tx.studentName,
                                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF1F5F9),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        tx.operator.displayName,
                                        style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: opColor),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  'Réf: ${tx.cinetpayTransactionId} • ${_formatDateTime(tx.timestamp)}',
                                  style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Carte: ${tx.cardUid} • Téléphone: ${tx.phoneNumber}',
                                  style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '+ ${_formatMoney(tx.amount)} FC',
                                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFF059669)),
                              ),
                              const SizedBox(height: 4),
                              InkWell(
                                onTap: () => CinetPayReceiptDialog.show(context, tx),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF008272).withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.receipt_rounded, size: 11, color: Color(0xFF008272)),
                                      SizedBox(width: 3),
                                      Text(
                                        'Reçu de paiement',
                                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF008272)),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  6. ONGLET 3 : PERCEPTION AU GUICHET (ENCAISSEMENT DIRECT)
  // ═══════════════════════════════════════════════════════════════

  Widget _buildGuichetTabView(bool isWide, List<RechargeCard> cards) {
    final quickAmounts = [1000.0, 2000.0, 5000.0, 10000.0, 20000.0, 50000.0];

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 540),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: const [BoxShadow(color: Color(0x06000000), blurRadius: 10, offset: Offset(0, 4))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.ucbNavy.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.point_of_sale_rounded, color: AppColors.ucbNavy, size: 24),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Encaissement Direct au Guichet UCB',
                            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                          ),
                          Text(
                            'Perception physique en caisse avec crédit immédiat de la carte étudiante',
                            style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const Divider(color: Color(0xFFE2E8F0), height: 1),
                const SizedBox(height: 20),

                // 1. Choix de l'étudiant
                const Text(
                  '1. Sélectionner l\'étudiant payeur',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  isExpanded: true,
                  initialValue: _selectedGuichetCardUid ?? (cards.isNotEmpty ? cards.first.uid : null),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.person_rounded, color: AppColors.ucbNavy),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                  ),
                  items: cards.map((c) {
                    return DropdownMenuItem<String>(
                      value: c.uid,
                      child: Text(
                        '${c.fullName} (${c.studentId ?? c.uid}) — Solde: ${_formatMoney(c.balance)} FC',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    setState(() => _selectedGuichetCardUid = val);
                  },
                ),

                const SizedBox(height: 20),

                // 2. Montant perçu
                const Text(
                  '2. Montant perçu en Francs Congolais (FC)',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: quickAmounts.map((amt) {
                    final isSel = _guichetAmountController.text == amt.toStringAsFixed(0);
                    return InkWell(
                      onTap: () => setState(() => _guichetAmountController.text = amt.toStringAsFixed(0)),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSel ? AppColors.ucbNavy : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: isSel ? AppColors.ucbNavy : const Color(0xFFCBD5E1)),
                        ),
                        child: Text(
                          '${_formatMoney(amt)} FC',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: isSel ? Colors.white : const Color(0xFF334155),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _guichetAmountController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    labelText: 'Montant libre à percevoir',
                    suffixText: 'FC',
                    suffixStyle: TextStyle(fontWeight: FontWeight.w800, color: AppColors.ucbNavy),
                    prefixIcon: Icon(Icons.attach_money_rounded, color: AppColors.ucbNavy),
                  ),
                ),

                const SizedBox(height: 20),

                // 3. Mode d'encaissement
                const Text(
                  '3. Mode de perception en caisse',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 10,
                  children: ['Espèces (Cash)', 'Mobile Money Direct Guichet', 'Chèque / Virement'].map((mode) {
                    final isSel = _guichetMethod == mode;
                    return ChoiceChip(
                      label: Text(mode),
                      selected: isSel,
                      selectedColor: AppColors.ucbNavy,
                      labelStyle: TextStyle(color: isSel ? Colors.white : const Color(0xFF334155), fontWeight: FontWeight.w700),
                      onSelected: (_) => setState(() => _guichetMethod = mode),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 28),

                // Bouton d'action
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.ucbNavy,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _isGuichetSubmitting ? null : _submitGuichetPerception,
                    child: _isGuichetSubmitting
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                          )
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.check_circle_rounded, color: AppColors.ucbGold, size: 20),
                              SizedBox(width: 10),
                              Text(
                                'Valider l\'Encaissement & Émettre le Reçu',
                                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white),
                              ),
                            ],
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submitGuichetPerception() async {
    final uid = _selectedGuichetCardUid ?? (HiveService.getAllCards().isNotEmpty ? HiveService.getAllCards().first.uid : null);
    if (uid == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Veuillez sélectionner un étudiant.')));
      return;
    }

    final card = HiveService.findByUid(uid);
    if (card == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Carte introuvable.')));
      return;
    }

    final amount = double.tryParse(_guichetAmountController.text) ?? 0.0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Veuillez saisir un montant valide supérieur à 0.')));
      return;
    }

    setState(() => _isGuichetSubmitting = true);

    final payment = await PaymentService.recordDirectPerception(
      cardUid: card.uid,
      amount: amount,
      studentName: card.fullName,
      studentId: card.studentId,
      phoneNumber: card.phoneNumber,
      method: _guichetMethod,
    );

    setState(() => _isGuichetSubmitting = false);

    // Afficher le Reçu Officiel d'Encaissement
    if (mounted) {
      CinetPayReceiptDialog.show(context, payment, currentBalance: card.balance);
    }
  }



  Widget _buildEmptyState({required String title, required String message}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(color: AppColors.ucbNavy.withValues(alpha: 0.06), shape: BoxShape.circle),
            child: const Icon(Icons.receipt_long_rounded, size: 30, color: Color(0xFF94A3B8)),
          ),
          const SizedBox(height: 14),
          Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
          const SizedBox(height: 6),
          Text(message, textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, color: Color(0xFF64748B), height: 1.4)),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  MODAL FICHE DÉTAILLÉE DE PAIEMENT POUR UN ÉTUDIANT SPÉCIFIQUE
// ═══════════════════════════════════════════════════════════════

class _StudentPaymentDetailModal extends StatelessWidget {
  final RechargeCard card;
  final String Function(double) formatMoney;
  final String Function(DateTime) formatDateTime;
  final Color Function(MobileOperator) getOperatorColor;
  final VoidCallback onDirectPerception;

  const _StudentPaymentDetailModal({
    required this.card,
    required this.formatMoney,
    required this.formatDateTime,
    required this.getOperatorColor,
    required this.onDirectPerception,
  });

  @override
  Widget build(BuildContext context) {
    final payments = PaymentService.getPaymentsForCard(card.uid);
    final totalPerceived = payments.where((p) => p.isSuccess).fold<double>(0, (s, p) => s + p.amount);

    return Container(
      margin: const EdgeInsets.all(12),
      constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.85),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(28)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Padding(
            padding: const EdgeInsets.only(top: 14),
            child: Container(width: 40, height: 4, decoration: BoxDecoration(color: const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(2))),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // En-tête Étudiant
                  Row(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Center(
                          child: Text(
                            card.fullName.split(' ').take(2).map((w) => w.isNotEmpty ? w[0] : '').join().toUpperCase(),
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              card.fullName,
                              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Matricule : ${card.studentId ?? "-"} • Carte UID : ${card.uid}',
                              style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                            ),
                            if (card.faculty != null)
                              Text(card.faculty!, style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: card.isBlocked ? const Color(0xFFFEF2F2) : const Color(0xFFF0FDF4),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: card.isBlocked ? const Color(0xFFFCA5A5) : const Color(0xFF86EFAC)),
                        ),
                        child: Text(
                          card.isBlocked ? 'SUSPENDU' : 'ACTIF',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: card.isBlocked ? AppColors.error : AppColors.emerald),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),
                  const Divider(color: Color(0xFFF1F5F9), height: 1),
                  const SizedBox(height: 16),

                  // Cartes Statistiques financières de l'étudiant
                  Row(
                    children: [
                      Expanded(
                        child: _buildStudentStat(
                          label: 'Total Perçu',
                          value: '${formatMoney(totalPerceived)} FC',
                          icon: Icons.arrow_downward_rounded,
                          color: AppColors.ucbNavy,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildStudentStat(
                          label: 'Solde actuel',
                          value: '${formatMoney(card.balance)} FC',
                          icon: Icons.account_balance_wallet_rounded,
                          color: AppColors.emerald,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildStudentStat(
                          label: 'Nb Paiements',
                          value: '${payments.length} reçus',
                          icon: Icons.repeat_rounded,
                          color: const Color(0xFFF59E0B),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Titre Section Historique Détaillé
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.history_edu_rounded, size: 20, color: Color(0xFF008272)),
                          SizedBox(width: 8),
                          Text(
                            'Détails des Paiements & Recharges',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF008272).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${payments.length} transaction(s)',
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF008272)),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Liste de chaque paiement
                  if (payments.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: const Column(
                        children: [
                          Icon(Icons.receipt_long_rounded, color: Color(0xFF94A3B8), size: 28),
                          SizedBox(height: 8),
                          Text(
                            'Aucun paiement enregistré pour cet étudiant',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF475569)),
                          ),
                          Text(
                            'Cet étudiant n\'a pas encore effectué de recharge en ligne.',
                            style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                          ),
                        ],
                      ),
                    )
                  else
                    ...payments.map((tx) {
                      final opColor = getOperatorColor(tx.operator);

                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: opColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(Icons.verified_rounded, color: opColor, size: 18),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        '+ ${formatMoney(tx.amount)} FC',
                                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF059669)),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                        decoration: BoxDecoration(
                                          color: opColor.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          tx.operator.displayName,
                                          style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: opColor),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    'Réf: ${tx.cinetpayTransactionId}',
                                    style: const TextStyle(fontSize: 10, fontFamily: 'monospace', color: Color(0xFF475569)),
                                  ),
                                  Text(
                                    '${formatDateTime(tx.timestamp)} • Tél: ${tx.phoneNumber}',
                                    style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
                                  ),
                                ],
                              ),
                            ),
                            TextButton.icon(
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                backgroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              icon: const Icon(Icons.receipt_rounded, size: 14, color: Color(0xFF008272)),
                              label: const Text('Reçu', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF008272))),
                              onPressed: () => CinetPayReceiptDialog.show(context, tx),
                            ),
                          ],
                        ),
                      );
                    }),

                  const SizedBox(height: 20),

                  // Actions pour le gestionnaire
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            side: const BorderSide(color: AppColors.ucbNavy),
                          ),
                          icon: const Icon(Icons.point_of_sale_rounded, color: AppColors.ucbNavy, size: 16),
                          label: const Text(
                            'Perception Guichet',
                            style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.ucbNavy, fontSize: 13),
                          ),
                          onPressed: onDirectPerception,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.ucbNavy,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Fermer', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentStat({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: color, height: 1.2),
              maxLines: 1,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
