import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/card_model.dart';
import '../services/hive_service.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_widgets.dart';
import '../widgets/wireframe_layout.dart';
import 'card_profile_screen.dart';
import '../widgets/responsive_layout.dart';
import '../services/theme_service.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';

/// ═══════════════════════════════════════════════════════════════
///  ecran Principal — Architecture Wireframe & Responsive Multiplateforme
///  - Mobile (< 900px) : Commutation fluide par Pill Toggle (Vue 0 / Vue 1)
///  - Desktop & Tablette (>= 900px) : Affichage Dual-Panel côte à côte
///  - Consultation et recharge de cartes existantes uniquement
/// ═══════════════════════════════════════════════════════════════

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _activeViewIndex = 0; // 0: Activité, 1: Recharge
  final _searchController = TextEditingController();
  final _rechargeSearchController = TextEditingController();
  final _amountController = TextEditingController();
  final _searchFocusNode = FocusNode();

  List<RechargeCard> _recentCards = [];
  RechargeCard? _selectedCardForRecharge;
  int? _selectedQuickAmount;
  bool _isRecharging = false;

  Map<String, dynamic> _stats = {
    'totalCards': 0,
    'totalBalance': 0.0,
    'totalRecharged': 0.0,
    'totalRecharges': 0,
  };

  final List<int> _quickAmounts = [500, 1000, 2000, 5000, 10000, 20000];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _rechargeSearchController.dispose();
    _amountController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _loadData() {
    setState(() {
      _recentCards = HiveService.getRecentCards(limit: 12);
      _stats = HiveService.getStatistics();
      if (_recentCards.isNotEmpty && _selectedCardForRecharge == null) {
        _selectedCardForRecharge = _recentCards.first;
      } else if (_selectedCardForRecharge != null) {
        _selectedCardForRecharge = HiveService.findByUid(_selectedCardForRecharge!.uid);
      }
    });
  }

  void _onSearchSubmitted(String query) {
    if (query.trim().isEmpty) return;

    final card = HiveService.findByUid(query.trim());
    if (card != null) {
      setState(() {
        _selectedCardForRecharge = card;
      });
      if (_activeViewIndex == 0 && !ResponsiveBreakpoints.isWide(context)) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => CardProfileScreen(card: card)),
        ).then((_) => _loadData());
      } else {
        AppSnackBar.success(context, 'Carte de ${card.fullName} sélectionnée');
      }
    } else {
      _showCardNotFoundDialog(query.trim());
    }
  }

  void _showCardNotFoundDialog(String uid) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textMuted.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.deepForest.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Icon(
                Icons.credit_card_off_rounded,
                color: AppColors.deepForest,
                size: 32,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Carte Introuvable',
              style: TextStyle(
                color: AppColors.deepForest,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Aucune carte avec l\'UID "$uid" n\'est enregistrée dans le système.\nVeuillez vérifier la saisie ou scanner une carte valide.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            ActionButton(
              label: 'Fermer',
              icon: Icons.check_rounded,
              onPressed: () => Navigator.pop(ctx),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _executeRecharge() async {
    if (_selectedCardForRecharge == null) {
      AppSnackBar.error(context, 'Veuillez sélectionner ou rechercher une carte');
      return;
    }

    final textVal = _amountController.text.trim().replaceAll(',', '.');
    final amount = double.tryParse(textVal);

    if (amount == null || amount <= 0) {
      AppSnackBar.error(context, 'Veuillez saisir un montant valide');
      return;
    }

    final confirmed = await showConfirmDialog(
      context: context,
      title: 'Confirmer la recharge',
      message:
          'Recharger ${amount.toStringAsFixed(0)} FC sur la carte de ${_selectedCardForRecharge!.fullName} ?\n\nNouveau solde : ${(_selectedCardForRecharge!.balance + amount).toStringAsFixed(0)} FC',
      confirmLabel: 'Recharger',
      cancelLabel: 'Annuler',
    );

    if (confirmed != true) return;

    setState(() => _isRecharging = true);
    HapticFeedback.mediumImpact();

    try {
      await HiveService.rechargeCard(_selectedCardForRecharge!, amount);
      _loadData();
      _amountController.clear();
      setState(() {
        _selectedQuickAmount = null;
      });
      if (mounted) {
        AppSnackBar.success(
          context,
          'Recharge de ${amount.toStringAsFixed(0)} FC effectuée avec succès !',
        );
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.error(context, 'Erreur lors de la recharge : $e');
      }
    } finally {
      if (mounted) setState(() => _isRecharging = false);
    }
  }

  void _showSettingsModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.textMuted.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Paramètres du Guichet',
                  style: TextStyle(
                    color: AppColors.deepForest,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                ListTile(
                  leading: const Icon(Icons.light_mode_rounded, color: AppColors.deepForest),
                  title: const Text('Mode clair', style: TextStyle(fontWeight: FontWeight.w600)),
                  trailing: ThemeService.mode.value == ThemeMode.light
                      ? const Icon(Icons.check_circle_rounded, color: AppColors.mintSage)
                      : null,
                  onTap: () {
                    ThemeService.setMode(ThemeMode.light);
                    Navigator.pop(ctx);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.dark_mode_rounded, color: AppColors.deepForest),
                  title: const Text('Mode sombre', style: TextStyle(fontWeight: FontWeight.w600)),
                  trailing: ThemeService.mode.value == ThemeMode.dark
                      ? const Icon(Icons.check_circle_rounded, color: AppColors.mintSage)
                      : null,
                  onTap: () {
                    ThemeService.setMode(ThemeMode.dark);
                    Navigator.pop(ctx);
                  },
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.logout_rounded, color: AppColors.error),
                  title: const Text(
                    'Déconnexion du guichet',
                    style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w700),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    _logout();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _logout() {
    AuthService.logout();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  String _formatNumber(double n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return n.toStringAsFixed(0);
  }

  @override
  Widget build(BuildContext context) {
    final bool isWide = MediaQuery.of(context).size.width >= 900;

    final Widget bodyContent = Container(
      color: AppColors.deepForest,
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // ── Top Bar ──
            WireframeTopBar(
              statusText: isWide
                  ? 'GUICHET /CAMPUS BUGABO'
                  : (_activeViewIndex == 0 ? 'GUICHET /CAMPUS BUGABO' : 'Station NFC · Prête'),
              onMenuPressed: _showSettingsModal,
              onStatusTap: () {
                if (!isWide) {
                  setState(() {
                    _activeViewIndex = _activeViewIndex == 0 ? 1 : 0;
                  });
                }
              },
            ),

            // ── Visualiseur Nœuds & Titre ──
            AmbientNodesVisualizer(
              height: isWide ? 130 : 150,
              activeNodeIndex: _activeViewIndex == 0 ? 1 : 0,
              onNodeSelected: (index) {
                if (index < _recentCards.length) {
                  setState(() {
                    _selectedCardForRecharge = _recentCards[index];
                  });
                }
              },
              centerWidget: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    isWide
                        ? 'TERMINAL CENTRAL DE RECHARGE'
                        : (_activeViewIndex == 0
                            ? 'SOLDE GLOBAL DU GUICHET'
                            : 'STATION RECHARGE RAPIDE'),
                    style: TextStyle(
                      color: AppColors.softMist.withValues(alpha: 0.65),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    isWide
                        ? '${_formatNumber(_stats['totalBalance'])} FC  ·  ${_stats['totalCards']} Cartes'
                        : (_activeViewIndex == 0
                            ? '${_formatNumber(_stats['totalBalance'])} FC'
                            : (_selectedCardForRecharge != null
                                ? _selectedCardForRecharge!.formattedBalance
                                : '0 FC')),
                    style: const TextStyle(
                      color: AppColors.mintSage,
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
            ),

            // ── Jonction Incurvée (Affichage adaptatif Mobile / Desktop) ──
            CurvedNotchJunction(
              titleContent: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    isWide
                        ? 'Console Guichetier & Station de Recharge'
                        : (_activeViewIndex == 0
                            ? 'Guichet Terminal'
                            : 'Station de Recharge'),
                    style: const TextStyle(
                      color: AppColors.deepForest,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isWide
                        ? 'Gestion des opérations et alimentation directe de compte'
                        : (_activeViewIndex == 0
                            ? 'Recherche & Activités récentes'
                            : 'Alimentation directe de compte'),
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              toggleWidget: isWide
                  ? const SizedBox.shrink()
                  : WireframePillToggle(
                      selectedIndex: _activeViewIndex,
                      onToggle: (index) {
                        HapticFeedback.selectionClick();
                        setState(() {
                          _activeViewIndex = index;
                        });
                      },
                    ),
            ),

            // ── Zone de contenu Inférieure (Soft Mist) ──
            Expanded(
              child: Container(
                color: AppColors.softMist,
                child: isWide
                    // ── Mode Dual-Panel (Desktop & Tablette large) ──
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Panneau gauche : Dashboard & Cartes récentes
                          Expanded(
                            flex: 6,
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(20, 10, 10, 20),
                              child: _buildDashboardView(),
                            ),
                          ),
                          // Séparateur vertical
                          Container(
                            width: 1,
                            margin: const EdgeInsets.symmetric(vertical: 20),
                            color: AppColors.border,
                          ),
                          // Panneau droit : Station de Recharge
                          Expanded(
                            flex: 5,
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(10, 10, 20, 20),
                              child: _buildRechargeStationView(),
                            ),
                          ),
                        ],
                      )
                    // ── Mode Simple (Mobile) ──
                    : RefreshIndicator(
                        color: AppColors.deepForest,
                        onRefresh: () async {
                          HapticFeedback.lightImpact();
                          _loadData();
                        },
                        child: _activeViewIndex == 0
                            ? _buildDashboardView()
                            : _buildRechargeStationView(),
                      ),
              ),
            ),
          ],
        ),
      ),
    );

    return ResponsiveScaffold(
      title: 'Guichet de Recharge',
      body: bodyContent,
      selectedIndex: _activeViewIndex,
      onDestinationSelected: (idx) {
        if (idx == 0) {
          setState(() => _activeViewIndex = 0);
        } else if (idx == 1) {
          setState(() => _activeViewIndex = 1);
        } else if (idx == 2) {
          _showSettingsModal();
        }
      },
      onLogout: _logout,
    );
  }

  /// Vue 0 : Dashboard & Activité Guichet
  Widget _buildDashboardView() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
      children: [
        // Champ de recherche en pilule
        SearchField(
          controller: _searchController,
          hintText: 'Rechercher un UID ou Nom (ex: ABC123456)...',
          onChanged: (q) {},
          onSubmitted: _onSearchSubmitted,
          focusNode: _searchFocusNode,
        ),

        const SizedBox(height: 18),

        // Résumé Statistique 2x2
        Row(
          children: [
            Expanded(
              child: StatCard(
                label: 'Cartes Actives',
                value: '${_stats['totalCards']}',
                icon: Icons.credit_card_rounded,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: StatCard(
                label: 'Volume Total',
                value: '${_formatNumber(_stats['totalRecharged'])} FC',
                icon: Icons.trending_up_rounded,
              ),
            ),
          ],
        ),

        const SizedBox(height: 24),

        // En-tête de section cartes récentes (sans bouton créer)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Cartes Répertoriées',
              style: TextStyle(
                color: AppColors.deepForest,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              '${_recentCards.length} carte(s)',
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // Liste des cartes
        if (_recentCards.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 40),
            child: Column(
              children: [
                Icon(
                  Icons.credit_card_rounded,
                  size: 48,
                  color: AppColors.textMuted.withValues(alpha: 0.4),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Aucune carte dans le système',
                  style: TextStyle(
                    color: AppColors.deepForest,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          )
        else
          ..._recentCards.map(
            (card) => RecentCardItem(
              uid: card.uid,
              name: card.fullName,
              balance: card.formattedBalance,
              promotion: card.promotion,
              academicYear: card.academicYear,
              faculty: card.faculty,
              studentId: card.studentId,
              onTap: () {
                setState(() {
                  _selectedCardForRecharge = card;
                });
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CardProfileScreen(card: card),
                  ),
                ).then((_) => _loadData());
              },
            ),
          ),
      ],
    );
  }

  /// Vue 1 : Station de Recharge Interactive
  Widget _buildRechargeStationView() {
    final activeCard = _selectedCardForRecharge ??
        (_recentCards.isNotEmpty ? _recentCards.first : null);

    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
      children: [
        // Recherche rapide de carte à recharger
        SearchField(
          controller: _rechargeSearchController,
          hintText: 'Saisir ou scanner l\'UID...',
          onChanged: (q) {},
          onSubmitted: _onSearchSubmitted,
        ),

        const SizedBox(height: 18),

        // Carte terminale sombre (Wireframe Inset Card)
        if (activeCard != null)
          TerminalCardPreview(
            title: activeCard.fullName,
            subtitle: 'UID: ${activeCard.uid}  ·  ${activeCard.promotion ?? "Étudiant"}',
            balanceText: activeCard.formattedBalance,
            statusText: 'Carte active connectée',
            onAction: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CardProfileScreen(card: activeCard),
                ),
              ).then((_) => _loadData());
            },
          )
        else
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.deepForest,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              children: [
                const Icon(Icons.contactless_rounded, color: AppColors.mintSage, size: 40),
                const SizedBox(height: 12),
                const Text(
                  'Aucune carte sélectionnée',
                  style: TextStyle(
                    color: AppColors.softMist,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Recherchez un UID ci-dessus ou scannez une carte',
                  style: TextStyle(
                    color: AppColors.softMist.withValues(alpha: 0.7),
                    fontSize: 13,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

        const SizedBox(height: 22),

        // Sélecteur de montants rapides (Quick Amount Pills)
        const Text(
          'Montant Rapide',
          style: TextStyle(
            color: AppColors.deepForest,
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),

        const SizedBox(height: 12),

        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: _quickAmounts.map((amount) {
            final isSelected = _selectedQuickAmount == amount;
            return QuickAmountPill(
              amount: amount,
              isSelected: isSelected,
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() {
                  _selectedQuickAmount = amount;
                  _amountController.text = amount.toString();
                });
              },
            );
          }).toList(),
        ),

        const SizedBox(height: 20),

        // Champ montant personnalisé
        Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceElevated,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border, width: 1),
          ),
          child: TextField(
            controller: _amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(
              color: AppColors.deepForest,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
            onChanged: (val) {
              final parsed = int.tryParse(val);
              if (parsed != null && _quickAmounts.contains(parsed)) {
                setState(() => _selectedQuickAmount = parsed);
              } else {
                setState(() => _selectedQuickAmount = null);
              }
            },
            decoration: const InputDecoration(
              hintText: 'Autre montant (FC)',
              hintStyle: TextStyle(
                color: AppColors.textMuted,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              prefixIcon: Padding(
                padding: EdgeInsets.symmetric(horizontal: 14),
                child: Icon(Icons.payments_rounded, color: AppColors.deepForest),
              ),
              suffixText: 'FC',
              suffixStyle: TextStyle(
                color: AppColors.deepForest,
                fontWeight: FontWeight.w800,
                fontSize: 15,
              ),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
          ),
        ),

        const SizedBox(height: 24),

        // Bouton de confirmation de recharge
        ActionButton(
          label: 'Effectuer la Recharge',
          icon: Icons.flash_on_rounded,
          isLoading: _isRecharging,
          onPressed: _executeRecharge,
        ),
      ],
    );
  }
}
