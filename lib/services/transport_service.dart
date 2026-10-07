import '../models/card_model.dart';
import '../models/transport_models.dart';
import 'cinetpay_service.dart';
import 'hive_service.dart';
import 'payment_service.dart';

/// ═══════════════════════════════════════════════════════════════
///  SMART_PAY_UCB — Service Métier de Transport, NFC & Paiement
///  Université Catholique de Bukavu
/// ═══════════════════════════════════════════════════════════════

enum ScanStatus {
  success,
  insufficientBalance,
  blocked,
  notFound,
}

class ScanResult {
  final ScanStatus status;
  final RechargeCard? card;
  final double fare;
  final double remainingBalance;
  final String message;
  final DateTime timestamp;

  ScanResult({
    required this.status,
    this.card,
    this.fare = 0.0,
    this.remainingBalance = 0.0,
    required this.message,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  bool get isSuccess => status == ScanStatus.success;
  bool get isInsufficient => status == ScanStatus.insufficientBalance;
  bool get isBlocked => status == ScanStatus.blocked;
}

class TransportService {
  // ── Lignes de Transport Académiques UCB ──
  static final List<BusLine> lines = [
    BusLine(
      id: 'L01',
      name: 'Ligne Bugabo - Kalambo',
      departure: 'Campus Bugabo',
      destination: 'Campus Kalambo',
      fare: 1000.0,
      availableBuses: ['Bus #01', 'Bus #02', 'Bus #04', 'Bus #07'],
    ),
    BusLine(
      id: 'L02',
      name: 'Ligne Centre-Ville - Karhale',
      departure: 'Place de l\'Indépendance',
      destination: 'Campus Karhale',
      fare: 800.0,
      availableBuses: ['Bus #03', 'Bus #05'],
    ),
    BusLine(
      id: 'L03',
      name: 'Ligne Kadutu - Kalambo',
      departure: 'Marché Kadutu',
      destination: 'Campus Kalambo',
      fare: 1200.0,
      availableBuses: ['Bus #06', 'Bus #08'],
    ),
    BusLine(
      id: 'L04',
      name: 'Ligne Bagira - Kalambo',
      departure: 'Commune de Bagira',
      destination: 'Campus Kalambo',
      fare: 1500.0,
      availableBuses: ['Bus #09', 'Bus #10'],
    ),
  ];

  // ── Historique des trajets (Trajets étudiants & validations NFC) ──
  static final List<BusTrip> _trips = [
    BusTrip(
      id: 'TRIP-101',
      cardUid: 'UCB-CARD-001',
      studentName: 'Pascaline Bahati Cikuru',
      studentId: '22/0841/UCB',
      lineName: 'Ligne Bugabo - Kalambo',
      busNumber: 'Bus #04',
      fare: 1000.0,
      timestamp: DateTime.now().subtract(const Duration(hours: 2, minutes: 15)),
      isSuccessful: true,
    ),
    BusTrip(
      id: 'TRIP-102',
      cardUid: 'UCB-CARD-001',
      studentName: 'Pascaline Bahati Cikuru',
      studentId: '22/0841/UCB',
      lineName: 'Ligne Bugabo - Kalambo',
      busNumber: 'Bus #02',
      fare: 1000.0,
      timestamp: DateTime.now().subtract(const Duration(days: 1, hours: 5)),
      isSuccessful: true,
    ),
    BusTrip(
      id: 'TRIP-103',
      cardUid: 'UCB-CARD-001',
      studentName: 'Pascaline Bahati Cikuru',
      studentId: '22/0841/UCB',
      lineName: 'Ligne Centre-Ville - Karhale',
      busNumber: 'Bus #05',
      fare: 800.0,
      timestamp: DateTime.now().subtract(const Duration(days: 2, hours: 3)),
      isSuccessful: true,
    ),
    BusTrip(
      id: 'TRIP-104',
      cardUid: 'UCB-CARD-002',
      studentName: 'Gloire Munyerere',
      studentId: '21/0452/UCB',
      lineName: 'Ligne Bugabo - Kalambo',
      busNumber: 'Bus #04',
      fare: 1000.0,
      timestamp: DateTime.now().subtract(const Duration(minutes: 40)),
      isSuccessful: true,
    ),
  ];


  /// Récupère les trajets d'une carte spécifique
  static List<BusTrip> getTripsForCard(String cardUid) {
    return _trips.where((t) => t.cardUid == cardUid).toList();
  }

  /// Récupère toutes les recharges d'une carte (via CinetPay & Guichet)
  static List<OnlineRecharge> getRechargesForCard(String cardUid) {
    return PaymentService.getPaymentsForCard(cardUid);
  }

  /// Récupère tous les trajets enregistrés (pour l'admin)
  static List<BusTrip> getAllTrips() => List.unmodifiable(_trips);

  /// Récupère toutes les recharges (pour l'admin & le gestionnaire)
  static List<OnlineRecharge> getAllRecharges() {
    return PaymentService.getAllPayments();
  }

  /// Effectue une recharge Mobile Money en ligne certifiée par la passerelle CinetPay
  static Future<OnlineRecharge> processOnlineRecharge({
    required String cardUid,
    required double amount,
    required MobileOperator operator,
    required String phoneNumber,
  }) async {
    // Récupérer la carte ciblée dans Hive
    var card = HiveService.findByUid(cardUid);
    card ??= await HiveService.addCard(
      uid: cardUid,
      fullName: 'Pascaline Bahati Cikuru',
      phoneNumber: phoneNumber,
      balance: 0.0,
      studentId: '22/0841/UCB',
      promotion: 'Bac 3 Informatique',
      academicYear: '2025-2026',
      faculty: 'Sciences & Technologies',
      program: 'Informatique',
    );

    // Exécution du cycle sécurisé CinetPay (requête USSD + PIN + status check)
    final cinetPayResult = await CinetPayService.processPayment(
      cardUid: card.uid,
      studentName: card.fullName,
      studentId: card.studentId,
      amount: amount,
      operator: operator,
      phoneNumber: phoneNumber,
    );

    final payment = OnlineRecharge(
      id: cinetPayResult.transactionId,
      cardUid: card.uid,
      studentName: card.fullName,
      studentId: card.studentId,
      amount: amount,
      operator: operator,
      phoneNumber: phoneNumber,
      reference: cinetPayResult.transactionId,
      cinetpayTransactionId: cinetPayResult.transactionId,
      operatorTransactionId: cinetPayResult.operatorReference,
      channel: 'CinetPay Mobile Money',
      status: 'ACCEPTED',
      timestamp: cinetPayResult.timestamp,
      isSuccess: true,
      receiptNumber: cinetPayResult.receiptNumber,
    );

    // Enregistrement persistant dans Hive et crédit automatique de la carte
    await PaymentService.recordPayment(payment);

    return payment;
  }

  /// Validation de carte par le Terminal Contrôleur (NFC/RFID) en < 1 seconde
  static Future<ScanResult> validateCardScan({
    required String cardUid,
    required BusLine line,
    required String busNumber,
  }) async {
    // Temps de réaction ultra-rapide (< 1s : 350ms)
    await Future.delayed(const Duration(milliseconds: 350));

    final card = HiveService.findByUid(cardUid);

    // 1. Carte non trouvée
    if (card == null) {
      return ScanResult(
        status: ScanStatus.notFound,
        message: 'Carte non reconnue dans le registre UCB ($cardUid)',
      );
    }

    // 2. Carte bloquée ou signalée perdue/volée
    if (card.isBlocked) {
      // Enregistrer la tentative frauduleuse
      _trips.insert(
        0,
        BusTrip(
          id: 'TRIP-${DateTime.now().millisecondsSinceEpoch}',
          cardUid: card.uid,
          studentName: card.fullName,
          studentId: card.studentId,
          lineName: line.name,
          busNumber: busNumber,
          fare: line.fare,
          timestamp: DateTime.now(),
          isSuccessful: false,
          declineReason: 'Carte déclarée perdue/bloquée',
        ),
      );

      return ScanResult(
        status: ScanStatus.blocked,
        card: card,
        fare: line.fare,
        remainingBalance: card.balance,
        message: 'Carte déclarée perdue / bloquée ! Accès refusé.',
      );
    }

    // 3. Solde insuffisant
    if (card.balance < line.fare) {
      _trips.insert(
        0,
        BusTrip(
          id: 'TRIP-${DateTime.now().millisecondsSinceEpoch}',
          cardUid: card.uid,
          studentName: card.fullName,
          studentId: card.studentId,
          lineName: line.name,
          busNumber: busNumber,
          fare: line.fare,
          timestamp: DateTime.now(),
          isSuccessful: false,
          declineReason: 'Solde insuffisant',
        ),
      );

      return ScanResult(
        status: ScanStatus.insufficientBalance,
        card: card,
        fare: line.fare,
        remainingBalance: card.balance,
        message: 'Solde insuffisant (Reste : ${card.formattedBalance})',
      );
    }

    // 4. Succès : Débit immédiat
    final success = card.deductFare(line.fare);
    if (success) {
      _trips.insert(
        0,
        BusTrip(
          id: 'TRIP-${DateTime.now().millisecondsSinceEpoch}',
          cardUid: card.uid,
          studentName: card.fullName,
          studentId: card.studentId,
          lineName: line.name,
          busNumber: busNumber,
          fare: line.fare,
          timestamp: DateTime.now(),
          isSuccessful: true,
        ),
      );

      return ScanResult(
        status: ScanStatus.success,
        card: card,
        fare: line.fare,
        remainingBalance: card.balance,
        message: 'Paiement validé avec succès ! Bon voyage.',
      );
    } else {
      return ScanResult(
        status: ScanStatus.insufficientBalance,
        card: card,
        fare: line.fare,
        remainingBalance: card.balance,
        message: 'Erreur lors du débit.',
      );
    }
  }

  // ── Indicateurs Financiers et Statistiques ──
  static double get totalRevenueToday {
    final today = DateTime.now();
    return _trips
        .where((t) =>
            t.isSuccessful &&
            t.timestamp.day == today.day &&
            t.timestamp.month == today.month &&
            t.timestamp.year == today.year,)
        .fold<double>(0, (sum, t) => sum + t.fare);
  }

  static int get totalPassengersToday {
    final today = DateTime.now();
    return _trips
        .where((t) =>
            t.isSuccessful &&
            t.timestamp.day == today.day &&
            t.timestamp.month == today.month &&
            t.timestamp.year == today.year,)
        .length;
  }
}
