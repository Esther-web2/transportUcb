import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../models/transport_models.dart';
import '../theme/app_theme.dart';
import 'responsive_layout.dart';

/// ═══════════════════════════════════════════════════════════════
///  SMART_PAY_UCB — Reçu Numérique Officiel CinetPay / UCB
///  Affiché après recharge étudiant & consultable par le gestionnaire
/// ═══════════════════════════════════════════════════════════════

class CinetPayReceiptDialog extends StatelessWidget {
  final OnlineRecharge recharge;
  final double? currentBalance;

  const CinetPayReceiptDialog({
    super.key,
    required this.recharge,
    this.currentBalance,
  });

  static void show(BuildContext context, OnlineRecharge recharge, {double? currentBalance}) {
    showAdaptiveModal(
      context: context,
      maxWidth: 480,
      builder: (_) => CinetPayReceiptDialog(recharge: recharge, currentBalance: currentBalance),
    );
  }

  String _formatMoney(double amount) {
    final clean = amount.toStringAsFixed(0);
    final reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    return clean.replaceAllMapped(reg, (m) => '${m[1]} ');
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
    final opColor = _getOperatorColor(recharge.operator);

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 20.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24.r),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 24,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        padding: EdgeInsets.all(20.r),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── En-tête Logos UCB & CinetPay ──
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(8.r),
                      decoration: BoxDecoration(
                        color: AppColors.ucbNavy.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                      child: Icon(
                        Icons.school_rounded,
                        color: AppColors.ucbNavy,
                        size: 20.r,
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'SMART_PAY UCB',
                          style: TextStyle(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w900,
                            color: AppColors.ucbNavy,
                            letterSpacing: 0.5,
                          ),
                        ),
                        Text(
                          'Université Catholique de Bukavu',
                          style: TextStyle(
                            fontSize: 9.sp,
                            color: const Color(0xFF64748B),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                // Badge CinetPay
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
                  decoration: BoxDecoration(
                    color: const Color(0xFF008272).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8.r),
                    border: Border.all(color: const Color(0xFF008272).withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.verified_rounded, size: 13.r, color: const Color(0xFF008272)),
                      SizedBox(width: 4.w),
                      Text(
                        'PAIEMENT EN LIGNE',
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

            SizedBox(height: 18.h),

            // ── Icône de Validation & Montant ──
            Center(
              child: Column(
                children: [
                  Container(
                    width: 56.r,
                    height: 56.r,
                    decoration: BoxDecoration(
                      color: AppColors.emerald.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.check_circle_rounded,
                      color: AppColors.emerald,
                      size: 34.r,
                    ),
                  ),
                  SizedBox(height: 10.h),
                  Text(
                    'REÇU DE PERCEPTION',
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF64748B),
                      letterSpacing: 1.0,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      '+ ${_formatMoney(recharge.amount)} FC',
                      style: TextStyle(
                        fontSize: 26.sp,
                        fontWeight: FontWeight.w900,
                        color: AppColors.ucbNavy,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                  SizedBox(height: 6.h),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(20.r),
                      border: Border.all(color: const Color(0xFF86EFAC)),
                    ),
                    child: Text(
                      'PAIEMENT VALIDÉ & ENCAISSÉ',
                      style: TextStyle(
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF059669),
                        letterSpacing: 0.6,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 18.h),
            const Divider(color: Color(0xFFE2E8F0), height: 1),
            SizedBox(height: 14.h),

            // ── Grille des Détails de la Transaction ──
            _buildDetailRow('Étudiant', recharge.studentName),
            if (recharge.studentId != null)
              _buildDetailRow('Matricule UCB', recharge.studentId!),
            _buildDetailRow('Carte RFID / NFC', recharge.cardUid),
            _buildDetailRow(
              'Opérateur Mobile Money',
              recharge.operator.displayName,
              valueColor: opColor,
            ),
            _buildDetailRow('Téléphone payeur', recharge.phoneNumber),
            _buildDetailRow('Canal', recharge.channel),
            _buildDetailRow('Réf. Transaction', recharge.cinetpayTransactionId),
            if (recharge.operatorTransactionId != null)
              _buildDetailRow('Réf. Opérateur', recharge.operatorTransactionId!),
            _buildDetailRow('N° de Reçu', recharge.receiptNumber),
            _buildDetailRow('Date & Heure', recharge.formattedDateTime),
            _buildDetailRow('Frais de service', '0 FC (Pris en charge)'),
            if (currentBalance != null)
              _buildDetailRow(
                'Solde actuel de la carte',
                '${_formatMoney(currentBalance!)} FC',
                isBold: true,
              ),

            SizedBox(height: 14.h),

            // ── Signature Numérique / Code-barres simulé ──
            Container(
              padding: EdgeInsets.all(12.r),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  Icon(Icons.qr_code_2_rounded, size: 28.r, color: AppColors.ucbNavy),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'CERTIFICAT DE PAIEMENT NUMÉRIQUE',
                          style: TextStyle(
                            fontSize: 9.sp,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF64748B),
                            letterSpacing: 0.5,
                          ),
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          'AUTHENTICATED • REF: ${recharge.cinetpayTransactionId}',
                          style: TextStyle(
                            fontSize: 10.sp,
                            fontFamily: 'monospace',
                            color: const Color(0xFF0F172A),
                            fontWeight: FontWeight.w600,
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

            SizedBox(height: 18.h),

            // ── Boutons d'Action ──
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                      side: const BorderSide(color: Color(0xFFCBD5E1)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                    ),
                    icon: Icon(Icons.copy_rounded, size: 16.r, color: const Color(0xFF475569)),
                    label: Flexible(
                      child: Text(
                        'Copier Réf.',
                        style: TextStyle(color: const Color(0xFF475569), fontWeight: FontWeight.w700, fontSize: 13.sp),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: recharge.cinetpayTransactionId));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          duration: Duration(seconds: 2),
                          content: Text('Référence de paiement copiée dans le presse-papiers !'),
                        ),
                      );
                    },
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.ucbNavy,
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: Flexible(
                      child: Text(
                        'Fermer',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13.sp),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? valueColor, bool isBold = false}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 12.sp, color: const Color(0xFF64748B), fontWeight: FontWeight.w500),
          ),
          SizedBox(width: 12.w),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: isBold ? FontWeight.w800 : FontWeight.w700,
                color: valueColor ?? (isBold ? AppColors.ucbNavy : const Color(0xFF0F172A)),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
