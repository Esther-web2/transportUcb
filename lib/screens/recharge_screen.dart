import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../models/card_model.dart';
import '../models/transport_models.dart';
import '../services/auth_service.dart';
import '../services/cinetpay_service.dart';
import '../services/hive_service.dart';
import '../services/transport_service.dart';
import '../theme/app_theme.dart';
import '../widgets/cinetpay_receipt_dialog.dart';

/// ═══════════════════════════════════════════════════════════════
///  ÉCRAN 4 — Module de Recharge Mobile Money CinetPay (SMART_PAY_UCB)
///  Université Catholique de Bukavu
/// ═══════════════════════════════════════════════════════════════

class RechargeScreen extends StatefulWidget {
  final RechargeCard? card;

  const RechargeScreen({super.key, this.card});

  @override
  State<RechargeScreen> createState() => _RechargeScreenState();
}

class _RechargeScreenState extends State<RechargeScreen> {
  final _phoneController = TextEditingController(text: '0812345678');
  final _amountController = TextEditingController(text: '5000');

  MobileOperator _selectedOperator = MobileOperator.mpesa;
  double _selectedAmount = 5000.0;
  bool _isCustomAmount = false;
  bool _isProcessing = false;

  final List<double> _quickAmounts = [2000.0, 5000.0, 10000.0, 20000.0];

  @override
  void initState() {
    super.initState();
    if (widget.card != null && widget.card!.phoneNumber.isNotEmpty) {
      final clean = widget.card!.phoneNumber.replaceAll('+243', '').replaceAll(' ', '').trim();
      if (clean.isNotEmpty) {
        _phoneController.text = clean.startsWith('0') ? clean : '0$clean';
      }
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _selectQuickAmount(double amount) {
    setState(() {
      _selectedAmount = amount;
      _isCustomAmount = false;
      _amountController.text = amount.toStringAsFixed(0);
    });
  }

  Future<void> _processPayment() async {
    final phone = _phoneController.text.trim();
    if (phone.length < 9) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.error,
          content: Text('Veuillez saisir un numéro de téléphone valide (ex: 0812345678)'),
        ),
      );
      return;
    }

    final amount = double.tryParse(_amountController.text.replaceAll(' ', '')) ?? 0.0;
    if (amount < 500) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.error,
          content: Text('Le montant minimum de recharge est de 500 FC'),
        ),
      );
      return;
    }

    final cardUid = widget.card?.uid ?? AuthService.studentCardUid ?? 'UCB-CARD-001';
    final tempTxId = CinetPayService.generateTransactionId();

    setState(() => _isProcessing = true);

    // ── Guichet de Paiement CinetPay Interactif ──
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => PopScope(
        canPop: false,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24.r)),
          contentPadding: EdgeInsets.fromLTRB(24.w, 20.h, 24.w, 24.h),
          content: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Badge CinetPay
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                      decoration: BoxDecoration(
                        color: const Color(0xFF008272).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8.r),
                        border: Border.all(color: const Color(0xFF008272).withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.lock_rounded, size: 12.r, color: const Color(0xFF008272)),
                          SizedBox(width: 4.w),
                          Text(
                            'PAIEMENT SÉCURISÉ • RDC',
                            style: TextStyle(
                              fontSize: 10.sp,
                              fontWeight: FontWeight.w900,
                              color: const Color(0xFF008272),
                              letterSpacing: 0.8,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16.h),
                Container(
                  width: 68.r,
                  height: 68.r,
                  decoration: BoxDecoration(
                    color: _getOperatorColor(_selectedOperator).withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.phonelink_ring_rounded,
                    color: _getOperatorColor(_selectedOperator),
                    size: 34.r,
                  ),
                ).animate(onPlay: (controller) => controller.repeat(reverse: true))
                    .scale(begin: const Offset(1, 1), end: const Offset(1.12, 1.12), duration: 800.ms),
                SizedBox(height: 18.h),
                Text(
                  'Requête de paiement ${_selectedOperator.displayName}',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A)),
                ),
                SizedBox(height: 6.h),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(6.r),
                  ),
                  child: Text(
                    'Réf: $tempTxId',
                    style: TextStyle(fontSize: 10.sp, fontFamily: 'monospace', color: const Color(0xFF64748B)),
                  ),
                ),
                SizedBox(height: 12.h),
                Text(
                  'Veuillez confirmer le débit de ${amount.toStringAsFixed(0)} FC en saisissant votre code PIN secret sur votre téléphone ($phone)...',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13.sp, color: AppColors.textSecondary, height: 1.4),
                ),
                SizedBox(height: 20.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 20.r,
                      height: 20.r,
                      child: const CircularProgressIndicator(strokeWidth: 2.5, color: Color(0xFF008272)),
                    ),
                    SizedBox(width: 10.w),
                    Flexible(
                      child: Text(
                        'Validation passerelle en cours...',
                        style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600, color: const Color(0xFF64748B)),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );

    // Exécution du paiement CinetPay via TransportService
    final payment = await TransportService.processOnlineRecharge(
      cardUid: cardUid,
      amount: amount,
      operator: _selectedOperator,
      phoneNumber: '+243 $phone',
    );

    if (!mounted) return;
    Navigator.pop(context); // Fermer le dialogue d'attente
    setState(() => _isProcessing = false);

    // Afficher le Reçu Numérique Officiel CinetPay
    final updatedCard = HiveService.findByUid(cardUid);
    CinetPayReceiptDialog.show(
      context,
      payment,
      currentBalance: updatedCard?.balance,
    );
  }

  Color _getOperatorColor(MobileOperator op) {
    switch (op) {
      case MobileOperator.mpesa:
        return const Color(0xFFE60000); // Rouge Vodacom
      case MobileOperator.airtel:
        return const Color(0xFFDC2626); // Rouge Airtel
      case MobileOperator.orange:
        return const Color(0xFFFF7900); // Orange
    }
  }

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.canPop(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: canPop
            ? IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: AppColors.ucbNavy),
                onPressed: () => Navigator.pop(context),
              )
            : null,
        title: Text(
          'Recharge Mobile Money',
          style: TextStyle(
            fontSize: 17.sp,
            fontWeight: FontWeight.w800,
            color: AppColors.ucbNavy,
          ),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 820),
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Carte Cible ──
                    Container(
                      padding: EdgeInsets.all(16.r),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18.r),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(12.r),
                            decoration: BoxDecoration(
                              color: AppColors.ucbNavy.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(14.r),
                            ),
                            child: Icon(Icons.credit_card_rounded, color: AppColors.ucbNavy, size: 22.r),
                          ),
                          SizedBox(width: 14.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.card?.fullName ?? AuthService.userName,
                                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14.sp),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  'Carte : ${widget.card?.uid ?? AuthService.studentCardUid ?? "UCB-CARD-001"}',
                                  style: TextStyle(fontSize: 12.sp, color: AppColors.textMuted),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          SizedBox(width: 8.w),
                          Text(
                            widget.card?.formattedBalance ?? '0 FC',
                            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14.sp, color: AppColors.ucbNavy),
                          ),
                        ],
                      ),
                    ).animate().fadeIn(duration: 350.ms),

                    SizedBox(height: 16.h),

                    // ── Badge CinetPay Passerelle Agréée ──
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
                      decoration: BoxDecoration(
                        color: const Color(0xFF008272).withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(14.r),
                        border: Border.all(color: const Color(0xFF008272).withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.security_rounded, color: const Color(0xFF008272), size: 20.r),
                          SizedBox(width: 10.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Passerelle Agréée en Ligne RDC',
                                  style: TextStyle(
                                    fontSize: 12.sp,
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFF008272),
                                    letterSpacing: 0.3,
                                  ),
                                ),
                                SizedBox(height: 2.h),
                                Text(
                                  'Paiement instantané en Francs Congolais (CDF) par USSD Mobile Money.',
                                  style: TextStyle(
                                    fontSize: 11.sp,
                                    color: const Color(0xFF475569),
                                    height: 1.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ).animate().fadeIn(delay: 50.ms, duration: 350.ms),

                    SizedBox(height: 20.h),

                    // ── 1. Choix de l'Opérateur RDC ──
                    Text(
                      '1. Choisissez votre opérateur Mobile Money',
                      style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                    ),
                    SizedBox(height: 12.h),
                    Row(
                      children: [
                        _buildOperatorCard(MobileOperator.mpesa, 'M-Pesa', Icons.signal_cellular_alt_rounded),
                        SizedBox(width: 10.w),
                        _buildOperatorCard(MobileOperator.airtel, 'Airtel', Icons.phone_android_rounded),
                        SizedBox(width: 10.w),
                        _buildOperatorCard(MobileOperator.orange, 'Orange', Icons.network_cell_rounded),
                      ],
                    ).animate().fadeIn(delay: 100.ms, duration: 350.ms),

                    SizedBox(height: 24.h),

                    // ── 2. Grille de Montants Rapides ──
                    Text(
                      '2. Choisissez ou saisissez le montant',
                      style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                    ),
                    SizedBox(height: 12.h),
                    GridView.count(
                      crossAxisCount: MediaQuery.sizeOf(context).width >= 650 ? 4 : 2,
                      crossAxisSpacing: 12.w,
                      mainAxisSpacing: 12.h,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      childAspectRatio: MediaQuery.sizeOf(context).width >= 650 ? 2.4 : 2.3,
                      children: _quickAmounts.map((amount) {
                        final isSelected = !_isCustomAmount && _selectedAmount == amount;
                        return InkWell(
                          onTap: () => _selectQuickAmount(amount),
                          borderRadius: BorderRadius.circular(16.r),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: isSelected ? AppColors.ucbNavy : Colors.white,
                              borderRadius: BorderRadius.circular(16.r),
                              border: Border.all(
                                color: isSelected ? AppColors.ucbNavy : AppColors.border,
                                width: isSelected ? 2 : 1,
                              ),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: AppColors.ucbNavy.withValues(alpha: 0.25),
                                        blurRadius: 10.r,
                                        offset: Offset(0, 4.h),
                                      ),
                                    ]
                                  : [],
                            ),
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Padding(
                                padding: EdgeInsets.symmetric(horizontal: 8.w),
                                child: Text(
                                  '${amount.toStringAsFixed(0)} FC',
                                  style: TextStyle(
                                    fontSize: 16.sp,
                                    fontWeight: FontWeight.w800,
                                    color: isSelected ? Colors.white : AppColors.textPrimary,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ).animate().fadeIn(delay: 200.ms, duration: 350.ms),

                    SizedBox(height: 14.h),

                    // Champ de saisie libre du montant
                    TextField(
                      controller: _amountController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      style: TextStyle(fontSize: 14.sp),
                      onChanged: (val) {
                        setState(() {
                          _isCustomAmount = true;
                          _selectedAmount = double.tryParse(val) ?? 0.0;
                        });
                      },
                      decoration: InputDecoration(
                        labelText: 'Montant libre en Francs Congolais (FC)',
                        labelStyle: TextStyle(fontSize: 13.sp),
                        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
                        prefixIcon: Icon(Icons.payments_rounded, color: AppColors.ucbNavy, size: 20.r),
                        suffixText: 'FC',
                        suffixStyle: TextStyle(fontWeight: FontWeight.w800, fontSize: 13.sp, color: AppColors.ucbNavy),
                      ),
                    ),

                    SizedBox(height: 24.h),

                    // ── 3. Champ Numéro de Téléphone ──
                    Text(
                      '3. Numéro de téléphone payeur',
                      style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                    ),
                    SizedBox(height: 12.h),
                    TextField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      style: TextStyle(fontSize: 14.sp),
                      decoration: InputDecoration(
                        labelText: 'Numéro Mobile Money (ex: 0812345678)',
                        labelStyle: TextStyle(fontSize: 13.sp),
                        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
                        prefixText: '+243 ',
                        prefixStyle: TextStyle(fontWeight: FontWeight.w700, fontSize: 14.sp, color: AppColors.textPrimary),
                        prefixIcon: Icon(Icons.phone_rounded, color: AppColors.ucbNavy, size: 20.r),
                        helperText: 'Vous recevrez une notification USSD pour valider par PIN.',
                        helperStyle: TextStyle(fontSize: 11.sp),
                      ),
                    ).animate().fadeIn(delay: 300.ms, duration: 350.ms),

                    SizedBox(height: 32.h),

                    // ── Bouton de Confirmation ──
                    SizedBox(
                      width: double.infinity,
                      height: 52.h,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.ucbNavy,
                          elevation: 4,
                          shadowColor: AppColors.ucbNavy.withValues(alpha: 0.3),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18.r)),
                        ),
                        onPressed: _isProcessing ? null : _processPayment,
                        child: _isProcessing
                            ? SizedBox(
                                width: 22.r,
                                height: 22.r,
                                child: const CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.lock_rounded, size: 18.r, color: AppColors.ucbGold),
                                  SizedBox(width: 10.w),
                                  Flexible(
                                    child: Text(
                                      'Payer ${_amountController.text} FC en ligne',
                                      style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w700),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ).animate().fadeIn(delay: 400.ms, duration: 350.ms),

                    SizedBox(height: 30.h),
                  ],
                ),
              ),
            ),
          ),
        );
      }

  Widget _buildOperatorCard(MobileOperator op, String name, IconData icon) {
    final isSelected = _selectedOperator == op;
    final opColor = _getOperatorColor(op);

    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedOperator = op),
        borderRadius: BorderRadius.circular(16.r),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(vertical: 14.h),
          decoration: BoxDecoration(
            color: isSelected ? opColor.withValues(alpha: 0.08) : Colors.white,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: isSelected ? opColor : AppColors.border,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(8.r),
                decoration: BoxDecoration(
                  color: opColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: opColor, size: 20.r),
              ),
              SizedBox(height: 8.h),
              Text(
                name,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 13.sp,
                  color: isSelected ? opColor : AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
