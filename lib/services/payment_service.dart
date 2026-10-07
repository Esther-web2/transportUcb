import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/transport_models.dart';
import 'hive_service.dart';

/// ═══════════════════════════════════════════════════════════════
///  SMART_PAY_UCB — Service de Perception & Historique CinetPay
///  Gère la persistance locale de TOUTES les transactions de recharges
///  et offre au Gestionnaire le suivi financier et les détails par étudiant
/// ═══════════════════════════════════════════════════════════════

class PaymentService {
  static const String _boxName = 'cinetpay_transactions';
  static Box<Map>? _box;
  static final ValueNotifier<int> updateNotifier = ValueNotifier<int>(0);

  /// Initialise la boîte de persistance Hive des transactions
  static Future<void> init() async {
    _box = await Hive.openBox<Map>(_boxName);

    // Initialisation des données exemples si la boîte est vide
    if (_box!.isEmpty) {
      await _seedInitialTransactions();
    }
  }

  static Box<Map> get box {
    if (_box == null || !_box!.isOpen) {
      throw StateError('PaymentService non initialisé. Appeler PaymentService.init() d\'abord.');
    }
    return _box!;
  }

  /// Récupère toutes les transactions enregistrées (les plus récentes en premier)
  static List<OnlineRecharge> getAllPayments() {
    try {
      final list = box.values.map((map) => OnlineRecharge.fromMap(map)).toList();
      list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return list;
    } catch (_) {
      return [];
    }
  }

  /// Récupère l'historique complet et détaillé des paiements d'une carte étudiante
  static List<OnlineRecharge> getPaymentsForCard(String cardUid) {
    final cleanUid = cardUid.trim().toUpperCase();
    return getAllPayments().where((tx) => tx.cardUid.trim().toUpperCase() == cleanUid).toList();
  }

  /// Récupère les paiements associés à un étudiant (par matricule ou nom)
  static List<OnlineRecharge> getPaymentsForStudent({String? studentId, String? fullName}) {
    final all = getAllPayments();
    return all.where((tx) {
      if (studentId != null && tx.studentId != null && tx.studentId!.toLowerCase().trim() == studentId.toLowerCase().trim()) {
        return true;
      }
      if (fullName != null && tx.studentName.toLowerCase().trim() == fullName.toLowerCase().trim()) {
        return true;
      }
      return false;
    }).toList();
  }

  /// Enregistre une nouvelle transaction CinetPay et met à jour la carte dans Hive
  static Future<void> recordPayment(OnlineRecharge payment) async {
    // 1. Sauvegarder la transaction dans Hive
    await box.put(payment.id, payment.toMap());

    // 2. Mettre à jour le solde de la carte étudiante
    final card = HiveService.findByUid(payment.cardUid);
    if (card != null) {
      await HiveService.rechargeCard(card, payment.amount);
    }

    updateNotifier.value++;
  }

  /// Enregistrement direct d'une perception guichet (paiement physique au gestionnaire)
  static Future<OnlineRecharge> recordDirectPerception({
    required String cardUid,
    required double amount,
    required String studentName,
    String? studentId,
    required String phoneNumber,
    String method = 'Espèces / Guichet UCB',
    String? note,
  }) async {
    final now = DateTime.now();
    final y = now.year.toString();
    final m = now.month.toString().padLeft(2, '0');
    final d = now.day.toString().padLeft(2, '0');
    final ref = 'PERC-UCB-$y$m$d-${now.millisecondsSinceEpoch.toString().substring(7)}';

    final recharge = OnlineRecharge(
      id: 'REC-${now.millisecondsSinceEpoch}',
      cardUid: cardUid,
      studentName: studentName,
      studentId: studentId,
      amount: amount,
      operator: MobileOperator.mpesa, // par défaut
      phoneNumber: phoneNumber,
      reference: ref,
      cinetpayTransactionId: ref,
      operatorTransactionId: 'GUICHET-${now.millisecondsSinceEpoch.toString().substring(8)}',
      channel: 'Perception Guichet ($method)',
      status: 'ACCEPTED',
      timestamp: now,
      isSuccess: true,
      receiptNumber: 'REC-PERC-${now.millisecondsSinceEpoch.toString().substring(7)}',
    );

    await recordPayment(recharge);
    return recharge;
  }

  // ── Indicateurs Financiers pour le Gestionnaire ──

  /// Montant total cumulé perçu (toutes transactions confondues)
  static double get totalCollected {
    final all = getAllPayments();
    return all.where((t) => t.isSuccess).fold<double>(0, (sum, t) => sum + t.amount);
  }

  /// Montant total perçu aujourd'hui
  static double get totalCollectedToday {
    final today = DateTime.now();
    final all = getAllPayments();
    return all.where((t) =>
        t.isSuccess &&
        t.timestamp.year == today.year &&
        t.timestamp.month == today.month &&
        t.timestamp.day == today.day,
    ).fold<double>(0, (sum, t) => sum + t.amount);
  }

  /// Nombre d'opérations de perception aujourd'hui
  static int get countToday {
    final today = DateTime.now();
    final all = getAllPayments();
    return all.where((t) =>
        t.timestamp.year == today.year &&
        t.timestamp.month == today.month &&
        t.timestamp.day == today.day,
    ).length;
  }

  /// Répartition des montants perçus par opérateur Mobile Money (CinetPay)
  static Map<MobileOperator, double> get perceptionByOperator {
    final all = getAllPayments().where((t) => t.isSuccess);
    final map = <MobileOperator, double>{
      MobileOperator.mpesa: 0.0,
      MobileOperator.airtel: 0.0,
      MobileOperator.orange: 0.0,
    };

    for (final tx in all) {
      map[tx.operator] = (map[tx.operator] ?? 0.0) + tx.amount;
    }
    return map;
  }

  /// Initialisation de données de démonstration riches et cohérentes
  static Future<void> _seedInitialTransactions() async {
    final now = DateTime.now();

    final samples = [
      OnlineRecharge(
        id: 'REC-1001',
        cardUid: 'UCB-CARD-001',
        studentName: 'Pascaline Bahati Cikuru',
        studentId: '22/0841/UCB',
        amount: 10000.0,
        operator: MobileOperator.mpesa,
        phoneNumber: '+243 812 345 678',
        reference: 'CP-UCB-20261004-9841',
        cinetpayTransactionId: 'CP-UCB-20261004-9841',
        operatorTransactionId: 'MP261004.1420.A821',
        channel: 'CinetPay Mobile Money',
        status: 'ACCEPTED',
        timestamp: now.subtract(const Duration(hours: 4, minutes: 20)),
        isSuccess: true,
        receiptNumber: 'REC-CP-892401',
      ),
      OnlineRecharge(
        id: 'REC-1002',
        cardUid: 'UCB-CARD-001',
        studentName: 'Pascaline Bahati Cikuru',
        studentId: '22/0841/UCB',
        amount: 10000.0,
        operator: MobileOperator.airtel,
        phoneNumber: '+243 971 234 567',
        reference: 'CP-UCB-20261002-3104',
        cinetpayTransactionId: 'CP-UCB-20261002-3104',
        operatorTransactionId: 'AIR261002.0914.F102',
        channel: 'CinetPay Mobile Money',
        status: 'ACCEPTED',
        timestamp: now.subtract(const Duration(days: 3, hours: 2)),
        isSuccess: true,
        receiptNumber: 'REC-CP-774912',
      ),
      OnlineRecharge(
        id: 'REC-1003',
        cardUid: 'UCB-CARD-001',
        studentName: 'Pascaline Bahati Cikuru',
        studentId: '22/0841/UCB',
        amount: 5000.0,
        operator: MobileOperator.orange,
        phoneNumber: '+243 850 123 456',
        reference: 'CP-UCB-20260928-8472',
        cinetpayTransactionId: 'CP-UCB-20260928-8472',
        operatorTransactionId: 'OM260928.1645.K904',
        channel: 'CinetPay Mobile Money',
        status: 'ACCEPTED',
        timestamp: now.subtract(const Duration(days: 7, hours: 5)),
        isSuccess: true,
        receiptNumber: 'REC-CP-661298',
      ),
      OnlineRecharge(
        id: 'REC-1004',
        cardUid: 'UCB-CARD-002',
        studentName: 'Gloire Munyerere',
        studentId: '21/0452/UCB',
        amount: 5000.0,
        operator: MobileOperator.airtel,
        phoneNumber: '+243 971 234 567',
        reference: 'CP-UCB-20261003-5519',
        cinetpayTransactionId: 'CP-UCB-20261003-5519',
        operatorTransactionId: 'AIR261003.1118.B442',
        channel: 'CinetPay Mobile Money',
        status: 'ACCEPTED',
        timestamp: now.subtract(const Duration(days: 2, hours: 6)),
        isSuccess: true,
        receiptNumber: 'REC-CP-518290',
      ),
      OnlineRecharge(
        id: 'REC-1005',
        cardUid: 'UCB-CARD-003',
        studentName: 'Joseph Kalumuna',
        studentId: '20/0112/UCB',
        amount: 10000.0,
        operator: MobileOperator.mpesa,
        phoneNumber: '+243 850 123 456',
        reference: 'CP-UCB-20260930-1092',
        cinetpayTransactionId: 'CP-UCB-20260930-1092',
        operatorTransactionId: 'MP260930.0820.T302',
        channel: 'CinetPay Mobile Money',
        status: 'ACCEPTED',
        timestamp: now.subtract(const Duration(days: 5, hours: 1)),
        isSuccess: true,
        receiptNumber: 'REC-CP-430911',
      ),
      OnlineRecharge(
        id: 'REC-1006',
        cardUid: 'UCB-CARD-003',
        studentName: 'Joseph Kalumuna',
        studentId: '20/0112/UCB',
        amount: 6000.0,
        operator: MobileOperator.orange,
        phoneNumber: '+243 850 123 456',
        reference: 'CP-UCB-20260925-4401',
        cinetpayTransactionId: 'CP-UCB-20260925-4401',
        operatorTransactionId: 'OM260925.1730.Z771',
        channel: 'CinetPay Mobile Money',
        status: 'ACCEPTED',
        timestamp: now.subtract(const Duration(days: 10, hours: 3)),
        isSuccess: true,
        receiptNumber: 'REC-CP-390481',
      ),
      OnlineRecharge(
        id: 'REC-1007',
        cardUid: 'ABC123456789',
        studentName: 'Aganze Landry',
        studentId: '2025-001',
        amount: 15000.0,
        operator: MobileOperator.mpesa,
        phoneNumber: '+243 981401138',
        reference: 'CP-UCB-20260920-7712',
        cinetpayTransactionId: 'CP-UCB-20260920-7712',
        operatorTransactionId: 'MP260920.1004.X819',
        channel: 'CinetPay Mobile Money',
        status: 'ACCEPTED',
        timestamp: now.subtract(const Duration(days: 15, hours: 4)),
        isSuccess: true,
        receiptNumber: 'REC-CP-219800',
      ),
    ];

    for (final sample in samples) {
      await _box!.put(sample.id, sample.toMap());
    }
  }
}
