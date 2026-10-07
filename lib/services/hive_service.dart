import 'package:hive_flutter/hive_flutter.dart';
import 'payment_service.dart';
import '../models/card_model.dart';

/// ═══════════════════════════════════════════════════════════════
///  Service Hive — Gestion de la base de données locale
///  Initialise, lit, écrit et recherche les cartes de recharge
/// ═══════════════════════════════════════════════════════════════

class HiveService {
  static const String _boxName = 'recharge_cards';
  static Box<RechargeCard>? _box;

  /// Initialise Hive et ouvre la boîte de données
  /// Utilise Hive.initFlutter() — compatible mobile, desktop ET web
  static Future<void> init() async {
    await Hive.initFlutter();

    // Enregistrement de l'adaptateur
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(RechargeCardAdapter());
    }

    _box = await Hive.openBox<RechargeCard>(_boxName);

    // Initialisation automatique : cartes exemples UCB
    final card1 = findByUid('UCB-CARD-001');
    if (card1 == null) {
      await box.add(RechargeCard(
        uid: 'UCB-CARD-001',
        fullName: 'Akoko Munyerenkana',
        phoneNumber: '+243 812 345 678',
        studentId: '22/0841/UCB',
        promotion: 'Bac 3 Informatique',
        academicYear: '2025-2026',
        faculty: 'Sciences & Technologies',
        program: 'Informatique',
        balance: 12500.0,
        rechargeCount: 3,
        totalRecharged: 25000.0,
        isBlocked: false,
      ),);
    } else if (card1.fullName != 'Akoko Munyerenkana') {
      card1.fullName = 'Akoko Munyerenkana';
      await card1.save();
    }

    if (findByUid('UCB-CARD-002') == null) {
      await box.add(RechargeCard(
        uid: 'UCB-CARD-002',
        fullName: 'Gloire Munyerere',
        phoneNumber: '+243 971 234 567',
        studentId: '21/0452/UCB',
        promotion: 'Bac 2 Économie',
        academicYear: '2025-2026',
        faculty: 'Sciences Économiques & Gestion',
        program: 'Économie Financière',
        balance: 500.0, // Solde insuffisant pour test
        rechargeCount: 1,
        totalRecharged: 5000.0,
        isBlocked: false,
      ),);
    }

    if (findByUid('UCB-CARD-003') == null) {
      await box.add(RechargeCard(
        uid: 'UCB-CARD-003',
        fullName: 'Joseph Kalumuna',
        phoneNumber: '+243 850 123 456',
        studentId: '20/0112/UCB',
        promotion: 'Doctorat Médecine',
        academicYear: '2025-2026',
        faculty: 'Médecine',
        program: 'Santé Publique',
        balance: 8000.0,
        rechargeCount: 2,
        totalRecharged: 16000.0,
        isBlocked: true, // Carte suspendue / perdue pour test
      ),);
    }

    if (findByUid('ABC123456789') == null) {
      await addSampleCard();
    }

    await PaymentService.init();
  }

  /// Récupère la boîte de données (avec vérification)
  static Box<RechargeCard> get box {
    if (_box == null || !_box!.isOpen) {
      throw StateError(
        'HiveService non initialisé. Appeler HiveService.init() d\'abord.',
      );
    }
    return _box!;
  }

  /// Recherche une carte par son UID (recherche exacte)
  static RechargeCard? findByUid(String uid) {
    final normalizedUid = uid.trim().toUpperCase();
    try {
      final card = box.values.firstWhere(
        (card) => card.uid.trim().toUpperCase() == normalizedUid,
      );
      if (card.totalRecharged > card.balance) {
        card.totalRecharged = card.balance;
        card.save();
      }
      return card;
    } catch (_) {
      return null;
    }
  }

  /// Recherche floue par UID (pour l'autocomplétion)
  static List<RechargeCard> searchByUid(String query) {
    final normalizedQuery = query.trim().toUpperCase();
    if (normalizedQuery.isEmpty) return [];

    return box.values
        .where((card) => card.uid.toUpperCase().contains(normalizedQuery))
        .toList();
  }

  /// Recherche par nom
  static List<RechargeCard> searchByName(String query) {
    final normalizedQuery = query.trim().toLowerCase();
    if (normalizedQuery.isEmpty) return [];

    return box.values
        .where((card) => card.fullName.toLowerCase().contains(normalizedQuery))
        .toList();
  }

  /// Ajoute une carte de recharge exemple avec toutes ses informations
  static Future<RechargeCard> addSampleCard() async {
    final existingCard = findByUid('ABC123456789');
    if (existingCard != null) {
      return existingCard;
    }

    final card = RechargeCard(
      uid: 'ABC123456789',
      fullName: 'Aganze Landry',
      phoneNumber: '+243 981401138',
      studentId: '2025-001',
      promotion: 'Licence 3',
      academicYear: '2025-2026',
      faculty: 'Sciences',
      program: 'Informatique et Télécommunications',
      balance: 15000.0,
      rechargeCount: 1,
      totalRecharged: 15000.0,
      createdAt: DateTime.now().subtract(const Duration(days: 15)),
      updatedAt: DateTime.now(),
    );
    await box.add(card);
    return card;
  }

  /// Ajoute une nouvelle carte
  static Future<RechargeCard> addCard({
    required String uid,
    required String fullName,
    required String phoneNumber,
    String? studentId,
    String? promotion,
    String? academicYear,
    String? faculty,
    String? program,
    double balance = 0.0,
    int rechargeCount = 0,
    double totalRecharged = 0.0,
  }) async {
    final card = RechargeCard(
      uid: uid.trim().toUpperCase(),
      fullName: fullName.trim(),
      phoneNumber: phoneNumber.trim(),
      studentId: studentId?.trim(),
      promotion: promotion?.trim(),
      academicYear: academicYear?.trim(),
      faculty: faculty?.trim(),
      program: program?.trim(),
      balance: balance,
      rechargeCount: rechargeCount,
      totalRecharged: totalRecharged,
    );
    await box.add(card);
    return card;
  }

  /// Met à jour le solde d'une carte
  static Future<void> rechargeCard(RechargeCard card, double amount) async {
    card.addRecharge(amount);
    await card.save();
  }

  /// Met à jour le profil d'une carte
  static Future<void> updateCardProfile(
    RechargeCard card, {
    String? fullName,
    String? phoneNumber,
    String? studentId,
    String? promotion,
    String? academicYear,
    String? faculty,
    String? program,
  }) async {
    card.updateProfile(
      fullName: fullName,
      phoneNumber: phoneNumber,
      studentId: studentId,
      promotion: promotion,
      academicYear: academicYear,
      faculty: faculty,
      program: program,
    );
    await card.save();
  }

  /// Supprime une carte
  static Future<void> deleteCard(RechargeCard card) async {
    await card.delete();
  }

  /// Récupère toutes les cartes, triées par date de modification (récentes d'abord)
  static List<RechargeCard> getAllCards() {
    final cards = box.values.toList();
    for (final card in cards) {
      if (card.totalRecharged > card.balance) {
        card.totalRecharged = card.balance;
        card.save();
      }
    }
    cards.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return cards;
  }

  /// Récupère les N dernières cartes rechargées
  static List<RechargeCard> getRecentCards({int limit = 10}) {
    return getAllCards().take(limit).toList();
  }

  /// Statistiques globales
  static Map<String, dynamic> getStatistics() {
    final cards = getAllCards();
    if (cards.isEmpty) {
      return {
        'totalCards': 0,
        'totalBalance': 0.0,
        'totalRecharged': 0.0,
        'totalRecharges': 0,
      };
    }

    return {
      'totalCards': cards.length,
      'totalBalance': cards.fold<double>(0, (sum, c) => sum + c.balance),
      'totalRecharged':
          cards.fold<double>(0, (sum, c) => sum + c.totalRecharged),
      'totalRecharges': cards.fold<int>(0, (sum, c) => sum + c.rechargeCount),
    };
  }

  /// Ferme proprement Hive
  static Future<void> close() async {
    await box.close();
  }
}
