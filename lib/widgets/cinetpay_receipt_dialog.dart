import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  static void show(
    BuildContext context,
    OnlineRecharge recharge, {
    double? currentBalance,
  }) {
    showAdaptiveModal(
      context: context,
      maxWidth: 640,
      builder: (_) => CinetPayReceiptDialog(
        recharge: recharge,
        currentBalance: currentBalance,
      ),
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
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
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
        padding: const EdgeInsets.all(20),
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
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.ucbNavy.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.school_rounded,
                        color: AppColors.ucbNavy,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'SMART_PAY UCB',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            color: AppColors.ucbNavy,
                            letterSpacing: 0.5,
                          ),
                        ),
                        Text(
                          'Université Catholique de Bukavu',
                          style: TextStyle(
                            fontSize: 9,
                            color: Color(0xFF64748B),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                // Badge CinetPay
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFF008272).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: const Color(0xFF008272).withValues(alpha: 0.2),
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.verified_rounded,
                        size: 13,
                        color: Color(0xFF008272),
                      ),
                      SizedBox(width: 4),
                      Text(
                        'PAIEMENT EN LIGNE',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF008272),
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 18),

            // ── Icône de Validation & Montant ──
            Center(
              child: Column(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: AppColors.emerald.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_circle_rounded,
                      color: AppColors.emerald,
                      size: 34,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'REÇU DE PERCEPTION',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF64748B),
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 4),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      '+ ${_formatMoney(recharge.amount)} FC',
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        color: AppColors.ucbNavy,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFF86EFAC)),
                    ),
                    child: const Text(
                      'PAIEMENT VALIDÉ & ENCAISSÉ',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF059669),
                        letterSpacing: 0.6,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),
            const Divider(color: Color(0xFFE2E8F0), height: 1),
            const SizedBox(height: 14),

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
              _buildDetailRow(
                'Réf. Opérateur',
                recharge.operatorTransactionId!,
              ),
            _buildDetailRow('N° de Reçu', recharge.receiptNumber),
            _buildDetailRow('Date & Heure', recharge.formattedDateTime),
            _buildDetailRow('Frais de service', '0 FC (Pris en charge)'),
            if (currentBalance != null)
              _buildDetailRow(
                'Solde actuel de la carte',
                '${_formatMoney(currentBalance!)} FC',
                isBold: true,
              ),

            const SizedBox(height: 14),

            // ── Signature Numérique / Code-barres simulé ──
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.qr_code_2_rounded,
                    size: 28,
                    color: AppColors.ucbNavy,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'CERTIFICAT DE PAIEMENT NUMÉRIQUE',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF64748B),
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'AUTHENTICATED • REF: ${recharge.cinetpayTransactionId}',
                          style: const TextStyle(
                            fontSize: 10,
                            fontFamily: 'monospace',
                            color: Color(0xFF0F172A),
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

            const SizedBox(height: 18),

            // ── Boutons d'Action ──
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: const BorderSide(color: Color(0xFFCBD5E1)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(
                      Icons.copy_rounded,
                      size: 16,
                      color: Color(0xFF475569),
                    ),
                    label: const Flexible(
                      child: Text(
                        'Copier Réf.',
                        style: TextStyle(
                          color: Color(0xFF475569),
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    onPressed: () {
                      Clipboard.setData(
                        ClipboardData(text: recharge.cinetpayTransactionId),
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          duration: Duration(seconds: 2),
                          content: Text(
                            'Référence de paiement copiée dans le presse-papiers !',
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.ucbNavy,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Flexible(
                      child: Text(
                        'Fermer',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
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

  Widget _buildDetailRow(
    String label,
    String value, {
    Color? valueColor,
    bool isBold = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w500),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isBold ? FontWeight.w800 : FontWeight.w700,
                color: valueColor ??
                    (isBold ? AppColors.ucbNavy : const Color(0xFF0F172A)),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
