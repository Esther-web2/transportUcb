import '../models/transport_models.dart';

/// ═══════════════════════════════════════════════════════════════
///  SMART_PAY_UCB — Service d'authentification et gestion des rôles
///  Université Catholique de Bukavu
/// ═══════════════════════════════════════════════════════════════

class AuthService {
  static bool _loggedIn = false;
  static AppUser? _currentUser;

  // ── 1. Compte Étudiant ──
  static const String studentEmail = 'akoko.munyerenkana@ucbukavu.ac.cd';
  static const String studentPassword = '12345';

  // ── 2. Compte Admin / Gestionnaire ──
  static const String adminEmail = 'aganze.nfundiko@ucbukavu.ac.cd';
  static const String adminPassword = '56789';

  // ── 3. Compte Terminal Bus / Contrôleur ──
  static const String terminalEmail = 'terminal.bus@ucbukavu.ac.cd';
  static const String terminalPassword = '12345';

  static const AppUser demoStudent = AppUser(
    email: studentEmail,
    fullName: 'Akoko Munyerenkana',
    role: UserRole.student,
    studentId: '22/0841/UCB',
    cardUid: 'UCB-CARD-001',
    faculty: 'Sciences & Technologies (Informatique)',
  );

  static const AppUser demoAdmin = AppUser(
    email: adminEmail,
    fullName: 'Aganze Nfundiko',
    role: UserRole.admin,
    faculty: 'Direction du Charroi & Finance',
  );

  static const AppUser demoTerminal = AppUser(
    email: terminalEmail,
    fullName: 'Terminal Bus (Contrôleur)',
    role: UserRole.terminal,
    busNumber: 'Bus #01',
    faculty: 'Service de Transport Universitaire',
  );

  /// Authentification avec e-mail et mot de passe saisis par l'utilisateur
  static bool login(String email, String password) {
    _loggedIn = false;
    _currentUser = null;

    final cleanEmail = email.trim().toLowerCase();
    final cleanPassword = password.trim();

    // 1. Compte Étudiant
    if (cleanEmail == studentEmail.toLowerCase()) {
      if (cleanPassword == studentPassword) {
        _loggedIn = true;
        _currentUser = demoStudent;
        return true;
      }
      return false;
    }

    // 2. Compte Admin / Gestionnaire
    if (cleanEmail == adminEmail.toLowerCase()) {
      if (cleanPassword == adminPassword) {
        _loggedIn = true;
        _currentUser = demoAdmin;
        return true;
      }
      return false;
    }

    // 3. Compte Terminal Bus
    if (cleanEmail == terminalEmail.toLowerCase()) {
      if (cleanPassword == terminalPassword) {
        _loggedIn = true;
        _currentUser = demoTerminal;
        return true;
      }
      return false;
    }

    return false;
  }

  /// Connexions programmées (si besoin)
  static void loginAsStudent() {
    _loggedIn = true;
    _currentUser = demoStudent;
  }

  static void loginAsAdmin() {
    _loggedIn = true;
    _currentUser = demoAdmin;
  }

  static void loginAsTerminal() {
    _loggedIn = true;
    _currentUser = demoTerminal;
  }

  /// Déconnexion
  static void logout() {
    _loggedIn = false;
    _currentUser = null;
  }

  // ── Getters d'état ──
  static bool get isLoggedIn => _loggedIn;
  static AppUser? get currentUser => _currentUser;
  static UserRole get currentRole => _currentUser?.role ?? UserRole.student;
  static String? get userEmail => _currentUser?.email;
  static String get userName => _currentUser?.fullName ?? 'Utilisateur UCB';
  static String? get studentCardUid => _currentUser?.cardUid;
}
