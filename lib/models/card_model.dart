import 'package:hive/hive.dart';

part 'card_model.g.dart';

/// ═══════════════════════════════════════════════════════════════
///  SMART_PAY_UCB — Modèle de données pour une carte étudiante RFID/NFC
///  Stocké localement via Hive (base de données NoSQL embarquée)
/// ═══════════════════════════════════════════════════════════════

@HiveType(typeId: 0)
class RechargeCard extends HiveObject {
  /// Identifiant unique de la carte (UID RFID/NFC)
  @HiveField(0)
  String uid;

  /// Nom complet de l'étudiant
  @HiveField(1)
  String fullName;

  /// Numéro de téléphone (Mobile Money)
  @HiveField(2)
  String phoneNumber;

  /// Solde actuel en FC (Francs Congolais)
  @HiveField(3)
  double balance;

  /// Date de création de la carte
  @HiveField(4)
  DateTime createdAt;

  /// Date de dernière modification
  @HiveField(5)
  DateTime updatedAt;

  /// Nombre total de recharges effectuées
  @HiveField(6)
  int rechargeCount;

  /// Montant total cumulé des recharges
  @HiveField(7)
  double totalRecharged;

  /// Identifiant étudiant (Matricule UCB ex: 21/0452/UCB)
  @HiveField(8)
  String? studentId;

  /// Promotion (ex: Bac 3 Informatique, Master 1 Médecine)
  @HiveField(9)
  String? promotion;

  /// Année académique (ex: 2025-2026)
  @HiveField(10)
  String? academicYear;

  /// Faculté / Département (ex: Sciences et Technologies)
  @HiveField(11)
  String? faculty;

  /// Filière / Programme (ex: Informatique de Gestion)
  @HiveField(12)
  String? program;

  /// Statut de sécurité (bloquée / perdue / active)
  @HiveField(13, defaultValue: false)
  bool isBlocked;

  RechargeCard({
    required this.uid,
    required this.fullName,
    required this.phoneNumber,
    this.balance = 0.0,
    this.studentId,
    this.promotion,
    this.academicYear,
    this.faculty,
    this.program,
    this.isBlocked = false,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.rechargeCount = 0,
    this.totalRecharged = 0.0,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  /// Met à jour le solde après une recharge
  void addRecharge(double amount) {
    balance += amount;
    rechargeCount++;
    totalRecharged += amount;
    updatedAt = DateTime.now();
    if (isInBox) save();
  }

  /// Déduit le tarif d'un trajet (Validation NFC)
  bool deductFare(double amount) {
    if (isBlocked || balance < amount) return false;
    balance -= amount;
    updatedAt = DateTime.now();
    if (isInBox) save();
    return true;
  }

  /// Bloque ou débloque la carte (signalement perte/vol)
  void setBlocked(bool blocked) {
    isBlocked = blocked;
    updatedAt = DateTime.now();
    if (isInBox) save();
  }

  /// Met à jour les informations du profil
  void updateProfile({
    String? fullName,
    String? phoneNumber,
    String? studentId,
    String? promotion,
    String? academicYear,
    String? faculty,
    String? program,
  }) {
    if (fullName != null) this.fullName = fullName;
    if (phoneNumber != null) this.phoneNumber = phoneNumber;
    if (studentId != null) this.studentId = studentId;
    if (promotion != null) this.promotion = promotion;
    if (academicYear != null) this.academicYear = academicYear;
    if (faculty != null) this.faculty = faculty;
    if (program != null) this.program = program;
    updatedAt = DateTime.now();
    if (isInBox) save();
  }

  /// Formate le solde en chaîne lisible (ex: 12 500 FC)
  String get formattedBalance {
    final clean = balance.toStringAsFixed(0);
    // Insère les séparateurs de milliers
    final reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    final formatted = clean.replaceAllMapped(reg, (Match m) => '${m[1]} ');
    return '$formatted FC';
  }

  /// Formate la date de création
  String get formattedDate {
    return '${createdAt.day.toString().padLeft(2, '0')}/'
        '${createdAt.month.toString().padLeft(2, '0')}/'
        '${createdAt.year}';
  }
}
