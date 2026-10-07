import 'dart:math';
import '../models/transport_models.dart';

/// ═══════════════════════════════════════════════════════════════
///  SMART_PAY_UCB — Service Passerelle de Paiement CinetPay
///  Université Catholique de Bukavu (RDC)
///  Agrégateur Mobile Money : Vodacom M-Pesa, Airtel Money, Orange Money
/// ═══════════════════════════════════════════════════════════════

class CinetPayPaymentResult {
  final bool isSuccess;
  final String transactionId;
  final String operatorReference;
  final String receiptNumber;
  final String statusMessage;
  final String code;
  final DateTime timestamp;
  final double amount;
  final MobileOperator operator;
  final String phoneNumber;
  final String studentName;
  final String? studentId;
  final String cardUid;

  const CinetPayPaymentResult({
    required this.isSuccess,
    required this.transactionId,
    required this.operatorReference,
    required this.receiptNumber,
    required this.statusMessage,
    required this.code,
    required this.timestamp,
    required this.amount,
    required this.operator,
    required this.phoneNumber,
    required this.studentName,
    this.studentId,
    required this.cardUid,
  });
}

class CinetPayService {
  // ── Paramètres CinetPay UCB ──
  static String siteId = '5869632'; // Site ID CinetPay attribué à l'UCB
  static String apiKey = '193740924065609d948b809.12345678'; // Clé API CinetPay
  static const String currency = 'CDF'; // Franc Congolais (FC / CDF)
  static const String country = 'CD'; // République Démocratique du Congo
  static const String gatewayName = 'CinetPay Gateway RDC';
  static String environment = 'SANDBOX / UCB TEST'; // SANDBOX ou PRODUCTION

  /// Génère un identifiant unique de transaction CinetPay conforme
  /// Format : CP-UCB-AAAAMMJJ-XXXXX
  static String generateTransactionId() {
    final now = DateTime.now();
    final y = now.year.toString();
    final m = now.month.toString().padLeft(2, '0');
    final d = now.day.toString().padLeft(2, '0');
    final rand = (10000 + Random().nextInt(89999)).toString();
    return 'CP-UCB-$y$m$d-$rand';
  }

  /// Génère une référence de confirmation opérateur Mobile Money réaliste
  static String generateOperatorReference(MobileOperator op) {
    final rand = (100000 + Random().nextInt(899999)).toString();
    final suffix = (100 + Random().nextInt(899)).toString();
    switch (op) {
      case MobileOperator.mpesa:
        return 'MP${DateTime.now().year.toString().substring(2)}$rand.$suffix';
      case MobileOperator.airtel:
        return 'AIR${DateTime.now().year.toString().substring(2)}$rand.$suffix';
      case MobileOperator.orange:
        return 'OM${DateTime.now().year.toString().substring(2)}$rand.$suffix';
    }
  }

  /// Génère un numéro de reçu fiscal / perception certifié CinetPay
  static String generateReceiptNumber() {
    final rand = (100000 + Random().nextInt(899999)).toString();
    return 'REC-CP-$rand';
  }

  /// Traitement d'un rechargement étudiant via CinetPay
  static Future<CinetPayPaymentResult> processPayment({
    required String cardUid,
    required String studentName,
    String? studentId,
    required double amount,
    required MobileOperator operator,
    required String phoneNumber,
  }) async {
    final transactionId = generateTransactionId();
    final operatorRef = generateOperatorReference(operator);
    final receiptNumber = generateReceiptNumber();

    // Simulation du cycle de paiement CinetPay complet :
    // 1. Initialisation de la transaction avec CinetPay API
    // 2. Déclenchement de la notification Push USSD vers le mobile de l'étudiant
    // 3. Saisie du code secret PIN par l'étudiant
    // 4. Vérification du statut de la transaction (Code 00 : ACCEPTED)
    await Future.delayed(const Duration(milliseconds: 1500));

    return CinetPayPaymentResult(
      isSuccess: true,
      transactionId: transactionId,
      operatorReference: operatorRef,
      receiptNumber: receiptNumber,
      statusMessage: 'Paiement CinetPay validé avec succès (Code 00 : ACCEPTED)',
      code: '00',
      timestamp: DateTime.now(),
      amount: amount,
      operator: operator,
      phoneNumber: phoneNumber,
      studentName: studentName,
      studentId: studentId,
      cardUid: cardUid,
    );
  }
}
