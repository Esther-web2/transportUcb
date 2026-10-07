import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

import '../models/card_model.dart';
import '../services/hive_service.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_widgets.dart';

/// ═══════════════════════════════════════════════════════════════
///  Écran Profil Carte — Responsive Multiplateforme & 3 Couleurs
///  Adapté pour Mobile, Tablette, Desktop et Web
/// ═══════════════════════════════════════════════════════════════

class CardProfileScreen extends StatefulWidget {
  final RechargeCard card;

  const CardProfileScreen({super.key, required this.card});

  @override
  State<CardProfileScreen> createState() => _CardProfileScreenState();
}

class _CardProfileScreenState extends State<CardProfileScreen>
    with SingleTickerProviderStateMixin {
  late RechargeCard _card;
  late TextEditingController _amountController;
  final _rechargeFormKey = GlobalKey<FormState>();
  bool _isRecharging = false;
  int? _selectedQuickAmount;

  final List<int> _quickAmounts = [500, 1000, 2000, 5000, 10000, 20000];

  late AnimationController _animController;
  late Animation<double> _balanceScale;

  @override
  void initState() {
    super.initState();
    _card = widget.card;
    _amountController = TextEditingController();

    _animController = AnimationController(
      duration: const Duration(milliseconds: 700),
      vsync: this,
    );
    _balanceScale = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutBack),
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _animController.dispose();
    super.dispose();
  }

  void _refreshCard() {
    final updated = HiveService.findByUid(_card.uid);
    if (updated != null) {
      setState(() => _card = updated);
    }
  }

  String? _validateAmount(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Entrez le montant de la recharge';
    }
    final amount = double.tryParse(value.replaceAll(',', '.'));
    if (amount == null || amount <= 0) return 'Montant invalide';
    if (amount > 10000000) return 'Montant trop élevé (max 10 000 000 FC)';
    return null;
  }

  Future<void> _performRecharge() async {
    if (!_rechargeFormKey.currentState!.validate()) {
      HapticFeedback.heavyImpact();
      return;
    }
    final amount = double.parse(_amountController.text.replaceAll(',', '.'));
    final confirmed = await showConfirmDialog(
      context: context,
      title: 'Confirmer la recharge',
      message:
          'Recharger ${amount.toStringAsFixed(0)} FC sur la carte de ${_card.fullName} ?\n\nSolde actuel : ${_card.formattedBalance}\nNouveau solde : ${(_card.balance + amount).toStringAsFixed(0)} FC',
      confirmLabel: 'Confirmer',
      cancelLabel: 'Annuler',
    );
    if (confirmed != true) return;
    setState(() => _isRecharging = true);
    HapticFeedback.mediumImpact();
    try {
      await HiveService.rechargeCard(_card, amount);
      _refreshCard();
      _amountController.clear();
      setState(() => _selectedQuickAmount = null);
      if (mounted) {
        AppSnackBar.success(
          context,
          'Recharge de ${amount.toStringAsFixed(0)} FC effectuée avec succès !',
        );
        _animController.reset();
        _animController.forward();
      }
    } catch (e) {
      if (mounted) AppSnackBar.error(context, 'Erreur : ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isRecharging = false);
    }
  }

  String _formatFullNumber(double n) {
    final formatter = NumberFormat('#,##0', 'fr_FR');
    return '${formatter.format(n)} FC';
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 800;

        return Scaffold(
          backgroundColor: AppColors.deepForest,
          body: SafeArea(
            bottom: false,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1100),
                child: Column(
                  children: [
                    // Top Bar
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
                      child: Row(
                        children: [
                          if (Navigator.canPop(context)) ...[
                            GestureDetector(
                              onTap: () => Navigator.pop(context, true),
                              child: Container(
                                padding: EdgeInsets.all(10.r),
                                decoration: BoxDecoration(
                                  color: AppColors.softMist.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(16.r),
                                ),
                                child: Icon(
                                  Icons.arrow_back_rounded,
                                  color: AppColors.softMist,
                                  size: 20.r,
                                ),
                              ),
                            ),
                            SizedBox(width: 14.w),
                          ],
                          Flexible(
                            child: Text(
                              'Détails & Recharge de la Carte',
                              style: TextStyle(
                                color: AppColors.softMist,
                                fontSize: 18.sp,
                                fontWeight: FontWeight.w800,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          SizedBox(width: 8.w),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 6.h),
                            decoration: BoxDecoration(
                              color: AppColors.mintSage.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(16.r),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.contactless_rounded, color: AppColors.mintSage, size: 16.r),
                                SizedBox(width: 6.w),
                                Text(
                                  'NFC Connecté',
                                  style: TextStyle(
                                    color: AppColors.mintSage,
                                    fontSize: 12.sp,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Contenu Adaptatif (Dual Column sur Desktop/Tablette, Single sur Mobile)
                    Expanded(
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: AppColors.softMist,
                          borderRadius: BorderRadius.vertical(top: Radius.circular(32.r)),
                        ),
                        child: isWide
                            ? Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Colonne gauche : Carte visuelle + Infos
                                  Expanded(
                                    flex: 5,
                                    child: ListView(
                                      physics: const ClampingScrollPhysics(),
                                      padding: EdgeInsets.all(24.r),
                                      children: [
                                        _buildVisualCard(),
                                        SizedBox(height: 20.h),
                                        _buildStudentInfoCard(),
                                      ],
                                    ),
                                  ),
                                  // Séparateur
                                  Container(
                                    width: 1,
                                    margin: EdgeInsets.symmetric(vertical: 24.h),
                                    color: AppColors.border,
                                  ),
                                  // Colonne droite : Formulaire de recharge
                                  Expanded(
                                    flex: 5,
                                    child: ListView(
                                      physics: const ClampingScrollPhysics(),
                                      padding: EdgeInsets.all(24.r),
                                      children: [
                                        _buildRechargeForm(),
                                      ],
                                    ),
                                  ),
                                ],
                              )
                            : ListView(
                                physics: const ClampingScrollPhysics(),
                                padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 36.h),
                                children: [
                                  _buildVisualCard(),
                                  SizedBox(height: 20.h),
                                  _buildStudentInfoCard(),
                                  SizedBox(height: 24.h),
                                  _buildRechargeForm(),
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
      },
    );
  }

  Widget _buildVisualCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.deepForest,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: AppColors.deepForest.withValues(alpha: 0.35),
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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.mintSage.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle_rounded, color: AppColors.mintSage, size: 14),
                    SizedBox(width: 6),
                    Text(
                      'CARTE RÉPERTORIÉE',
                      style: TextStyle(
                        color: AppColors.mintSage,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.contactless_rounded, color: AppColors.softMist, size: 26),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            _card.fullName,
            style: const TextStyle(
              color: AppColors.softMist,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'UID: ${_card.uid}',
            style: TextStyle(
              color: AppColors.softMist.withValues(alpha: 0.7),
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'SOLDE DISPONIBLE',
            style: TextStyle(
              color: AppColors.softMist.withValues(alpha: 0.6),
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 4),
          ScaleTransition(
            scale: _balanceScale,
            child: Text(
              _formatFullNumber(_card.balance),
              style: const TextStyle(
                color: AppColors.mintSage,
                fontSize: 32,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentInfoCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border, width: 0.8),
      ),
      child: Column(
        children: [
          _buildInfoRow(Icons.phone_rounded, 'Téléphone', _card.phoneNumber),
          if (_card.promotion != null && _card.promotion!.isNotEmpty) ...[
            const Divider(height: 20),
            _buildInfoRow(Icons.school_rounded, 'Promotion', _card.promotion!),
          ],
          if (_card.studentId != null && _card.studentId!.isNotEmpty) ...[
            const Divider(height: 20),
            _buildInfoRow(Icons.badge_rounded, 'Matricule', _card.studentId!),
          ],
          const Divider(height: 20),
          _buildInfoRow(
            Icons.receipt_long_rounded,
            'Historique Recharges',
            '${_card.rechargeCount} opération(s) · Total: ${_formatFullNumber(_card.totalRecharged)}',
          ),
        ],
      ),
    );
  }

  Widget _buildRechargeForm() {
    return Form(
      key: _rechargeFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Alimentation du Solde',
            style: TextStyle(
              color: AppColors.deepForest,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Sélectionnez un montant rapide ou saisissez une valeur',
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 16),

          // Montants rapides
          Wrap(
            spacing: 8,
            runSpacing: 8,
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

          const SizedBox(height: 16),

          // Champ de saisie
          Container(
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border, width: 1),
            ),
            child: TextFormField(
              controller: _amountController,
              validator: _validateAmount,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(
                color: AppColors.deepForest,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
              onChanged: (val) {
                final parsed = int.tryParse(val);
                setState(() {
                  _selectedQuickAmount =
                      (parsed != null && _quickAmounts.contains(parsed)) ? parsed : null;
                });
              },
              decoration: const InputDecoration(
                hintText: 'Montant personnalisé (FC)',
                hintStyle: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 14,
                ),
                prefixIcon: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 14),
                  child: Icon(Icons.flash_on_rounded, color: AppColors.deepForest),
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

          ActionButton(
            label: 'Recharger la Carte',
            icon: Icons.check_circle_rounded,
            isLoading: _isRecharging,
            onPressed: _performRecharge,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.deepForest.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.deepForest, size: 18),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  color: AppColors.deepForest,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
