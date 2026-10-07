import 'package:flutter_test/flutter_test.dart';
import 'package:recharge_app/models/card_model.dart';
import 'package:recharge_app/models/transport_models.dart';
import 'package:recharge_app/services/auth_service.dart';
import 'package:recharge_app/services/cinetpay_service.dart';
import 'package:recharge_app/services/transport_service.dart';

void main() {
  group('SMART_PAY_UCB Tests Unitaires', () {
    test('AuthService gère les 2 parties UCB (Étudiant & Gestionnaire Admin)', () {
      // 1. Connexion Étudiant
      expect(AuthService.login('etudiant@ucbukavu.ac.cd', '12345'), isTrue);
      expect(AuthService.currentRole, equals(UserRole.student));
      expect(AuthService.userName, contains('Pascaline'));

      // 2. Connexion Gestionnaire (Admin) avec mot de passe 'admin123'
      expect(AuthService.login('gestionnaire@ucbukavu.ac.cd', 'admin123'), isTrue);
      expect(AuthService.currentRole, equals(UserRole.admin));
      expect(AuthService.userName, equals('Gestionnaire'));

      // Échec si mauvais mot de passe pour le gestionnaire
      expect(AuthService.login('gestionnaire@ucbukavu.ac.cd', 'wrongpassword'), isFalse);

      // Alias admin accepté
      expect(AuthService.login('admin@ucbukavu.ac.cd', 'admin123'), isTrue);
      expect(AuthService.currentRole, equals(UserRole.admin));
      expect(AuthService.userName, equals('Gestionnaire'));
    });

    test('RechargeCard déduction et blocage', () {
      final card = RechargeCard(
        uid: 'TEST-001',
        fullName: 'Test Etudiant',
        phoneNumber: '+243 812 345 678',
        balance: 2000.0,
      );

      expect(card.formattedBalance, contains('2 000 FC'));

      // Débit valide
      final deducted = card.deductFare(1000.0);
      expect(deducted, isTrue);
      expect(card.balance, equals(1000.0));

      // Blocage de carte
      card.setBlocked(true);
      expect(card.isBlocked, isTrue);

      // Débit refusé si bloquée
      final blockedDeduct = card.deductFare(500.0);
      expect(blockedDeduct, isFalse);
    });

    test('TransportService dispose des lignes académiques UCB', () {
      expect(TransportService.lines.isNotEmpty, isTrue);
      final firstLine = TransportService.lines.first;
      expect(firstLine.name, contains('Bugabo'));
      expect(firstLine.fare, equals(1000.0));
    });

    test('CinetPayService génère des identifiants et références valides', () {
      expect(CinetPayService.siteId, equals('5869632'));
      expect(CinetPayService.currency, equals('CDF'));

      final txId = CinetPayService.generateTransactionId();
      expect(txId.startsWith('CP-UCB-'), isTrue);

      final mpesaRef = CinetPayService.generateOperatorReference(MobileOperator.mpesa);
      expect(mpesaRef.startsWith('MP'), isTrue);

      final airtelRef = CinetPayService.generateOperatorReference(MobileOperator.airtel);
      expect(airtelRef.startsWith('AIR'), isTrue);

      final orangeRef = CinetPayService.generateOperatorReference(MobileOperator.orange);
      expect(orangeRef.startsWith('OM'), isTrue);
    });

    test('OnlineRecharge supporte la sérialisation CinetPay', () {
      final now = DateTime.now();
      final recharge = OnlineRecharge(
        id: 'REC-TEST-1',
        cardUid: 'UCB-CARD-001',
        studentName: 'Pascaline Bahati Cikuru',
        studentId: '22/0841/UCB',
        amount: 5000.0,
        operator: MobileOperator.mpesa,
        phoneNumber: '+243 812 345 678',
        reference: 'CP-UCB-20261005-1234',
        cinetpayTransactionId: 'CP-UCB-20261005-1234',
        operatorTransactionId: 'MP261005.101',
        channel: 'CinetPay Mobile Money',
        status: 'ACCEPTED',
        timestamp: now,
        isSuccess: true,
      );

      final map = recharge.toMap();
      expect(map['cinetpayTransactionId'], equals('CP-UCB-20261005-1234'));
      expect(map['operator'], equals('mpesa'));
      expect(map['amount'], equals(5000.0));

      final restored = OnlineRecharge.fromMap(map);
      expect(restored.cinetpayTransactionId, equals(recharge.cinetpayTransactionId));
      expect(restored.studentId, equals('22/0841/UCB'));
      expect(restored.operator, equals(MobileOperator.mpesa));
    });
  });
}
