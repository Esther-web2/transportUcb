library transport_models;

/// ═══════════════════════════════════════════════════════════════
///  SMART_PAY_UCB — Modèles Métiers de Transport & Paiement
///  Université Catholique de Bukavu
/// ═══════════════════════════════════════════════════════════════

enum UserRole {
  student,
  admin,
  terminal,
}

enum MobileOperator {
  mpesa,
  airtel,
  orange;

  String get displayName {
    switch (this) {
      case MobileOperator.mpesa:
        return 'Vodacom M-Pesa';
      case MobileOperator.airtel:
        return 'Airtel Money';
      case MobileOperator.orange:
        return 'Orange Money';
    }
  }

  String get shortName {
    switch (this) {
      case MobileOperator.mpesa:
        return 'M-Pesa';
      case MobileOperator.airtel:
        return 'Airtel';
      case MobileOperator.orange:
        return 'Orange';
    }
  }
}

/// Modèle d'utilisateur connecté dans l'application
class AppUser {
  final String email;
  final String fullName;
  final UserRole role;
  final String? studentId; // Matricule ex: 21/0452/UCB
  final String? cardUid;    // UID RFID/NFC associé
  final String? busNumber;  // Si chauffeur ex: Bus #04
  final String? faculty;

  const AppUser({
    required this.email,
    required this.fullName,
    required this.role,
    this.studentId,
    this.cardUid,
    this.busNumber,
    this.faculty,
  });
}

/// Modèle d'un trajet effectué en bus
class BusTrip {
  final String id;
  final String cardUid;
  final String studentName;
  final String? studentId;
  final String lineName;
  final String busNumber;
  final double fare;
  final DateTime timestamp;
  final bool isSuccessful;
  final String? declineReason;

  BusTrip({
    required this.id,
    required this.cardUid,
    required this.studentName,
    this.studentId,
    required this.lineName,
    required this.busNumber,
    required this.fare,
    required this.timestamp,
    this.isSuccessful = true,
    this.declineReason,
  });

  String get formattedFare => '- ${fare.toStringAsFixed(0)} FC';

  String get formattedTime {
    final hour = timestamp.hour.toString().padLeft(2, '0');
    final minute = timestamp.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String get formattedDate {
    final day = timestamp.day.toString().padLeft(2, '0');
    final month = timestamp.month.toString().padLeft(2, '0');
    return '$day/$month/${timestamp.year}';
  }
}

/// Modèle d'une recharge de solde Mobile Money via CinetPay
class OnlineRecharge {
  final String id;
  final String cardUid;
  final String studentName;
  final String? studentId;
  final double amount;
  final MobileOperator operator;
  final String phoneNumber;
  final String reference;
  final String cinetpayTransactionId;
  final String? operatorTransactionId;
  final String channel;
  final String status;
  final DateTime timestamp;
  final bool isSuccess;
  final double fee;
  final String receiptNumber;

  OnlineRecharge({
    required this.id,
    required this.cardUid,
    required this.studentName,
    this.studentId,
    required this.amount,
    required this.operator,
    required this.phoneNumber,
    required this.reference,
    String? cinetpayTransactionId,
    this.operatorTransactionId,
    this.channel = 'CinetPay Mobile Money',
    this.status = 'ACCEPTED',
    required this.timestamp,
    this.isSuccess = true,
    this.fee = 0.0,
    String? receiptNumber,
  })  : cinetpayTransactionId = cinetpayTransactionId ?? reference,
        receiptNumber = receiptNumber ?? 'REC-CP-${reference.replaceAll(RegExp(r'[^0-9]'), '').padRight(6, '0').substring(0, 6)}';

  String get formattedAmount => '+ ${amount.toStringAsFixed(0)} FC';

  String get formattedTime {
    final hour = timestamp.hour.toString().padLeft(2, '0');
    final minute = timestamp.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String get formattedDate {
    final day = timestamp.day.toString().padLeft(2, '0');
    final month = timestamp.month.toString().padLeft(2, '0');
    return '$day/$month/${timestamp.year}';
  }

  String get formattedDateTime => '$formattedDate à $formattedTime';

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'cardUid': cardUid,
      'studentName': studentName,
      'studentId': studentId,
      'amount': amount,
      'operator': operator.name,
      'phoneNumber': phoneNumber,
      'reference': reference,
      'cinetpayTransactionId': cinetpayTransactionId,
      'operatorTransactionId': operatorTransactionId,
      'channel': channel,
      'status': status,
      'timestamp': timestamp.toIso8601String(),
      'isSuccess': isSuccess,
      'fee': fee,
      'receiptNumber': receiptNumber,
    };
  }

  factory OnlineRecharge.fromMap(Map map) {
    return OnlineRecharge(
      id: map['id']?.toString() ?? '',
      cardUid: map['cardUid']?.toString() ?? '',
      studentName: map['studentName']?.toString() ?? '',
      studentId: map['studentId']?.toString(),
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      operator: MobileOperator.values.firstWhere(
        (o) => o.name == map['operator'],
        orElse: () => MobileOperator.mpesa,
      ),
      phoneNumber: map['phoneNumber']?.toString() ?? '',
      reference: map['reference']?.toString() ?? '',
      cinetpayTransactionId: map['cinetpayTransactionId']?.toString() ?? map['reference']?.toString(),
      operatorTransactionId: map['operatorTransactionId']?.toString(),
      channel: map['channel']?.toString() ?? 'CinetPay Mobile Money',
      status: map['status']?.toString() ?? (map['isSuccess'] == true ? 'ACCEPTED' : 'FAILED'),
      timestamp: map['timestamp'] != null
          ? DateTime.tryParse(map['timestamp'].toString()) ?? DateTime.now()
          : DateTime.now(),
      isSuccess: map['isSuccess'] ?? true,
      fee: (map['fee'] as num?)?.toDouble() ?? 0.0,
      receiptNumber: map['receiptNumber']?.toString(),
    );
  }
}

/// Modèle d'une ligne de transport académique UCB
class BusLine {
  final String id;
  final String name;
  final String departure;
  final String destination;
  double fare;
  final List<String> availableBuses;

  BusLine({
    required this.id,
    required this.name,
    required this.departure,
    required this.destination,
    required this.fare,
    required this.availableBuses,
  });

  String get formattedFare => '${fare.toStringAsFixed(0)} FC';
}
