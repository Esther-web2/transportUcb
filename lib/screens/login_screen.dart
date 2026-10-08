import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../models/transport_models.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/responsive_layout.dart';
import 'admin_dashboard_screen.dart';
import 'controller_terminal_screen.dart';
import 'student_dashboard_screen.dart';

/// ═══════════════════════════════════════════════════════════════
///  ÉCRAN 1 — Connexion Institutionnelle (SMART_PAY_UCB)
///  Université Catholique de Bukavu — Design centré & responsive
/// ═══════════════════════════════════════════════════════════════

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  // Couleurs du design
  static const Color _bgColor = Color(0xFF2B3FA0);
  static const Color _btnColor = Color(0xFF1E2F7A);
  static const Color _cardColor = Color(0xFFEDF0F7);
  static const Color _fieldFill = Colors.white;
  static const Color _labelColor = Color(0xFF6B7590);
  static const Color _textColor = Color(0xFF1A2340);
  static const Color _borderColor = Color(0xFFD5DAE8);

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _navigateToRoleScreen(UserRole role) {
    Widget destination;
    switch (role) {
      case UserRole.student:
        destination = const StudentDashboardScreen();
        break;
      case UserRole.admin:
        destination = const AdminDashboardScreen();
        break;
      case UserRole.terminal:
        destination = const ControllerTerminalScreen();
        break;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => destination),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      HapticFeedback.heavyImpact();
      return;
    }

    setState(() => _isLoading = true);

    final ok = AuthService.login(
      _emailController.text.trim(),
      _passwordController.text,
    );

    await Future.delayed(const Duration(milliseconds: 350));
    if (!mounted) return;
    setState(() => _isLoading = false);

    if (ok) {
      _navigateToRoleScreen(AuthService.currentRole);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.error,
          content: Text(
            'Identifiants invalides. Veuillez vérifier votre e-mail et votre mot de passe.',
          ),
        ),
      );
    }
  }

  void _showForgotPasswordModal() {
    final resetEmailController =
        TextEditingController(text: _emailController.text);

    showAdaptiveModal(
      context: context,
      maxWidth: 480,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24.h,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24.h,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.ucbNavy.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.lock_reset_rounded,
                      color: AppColors.ucbNavy,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Récupération de compte',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ucbNavy,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12.h),
              const Text(
                'Saisissez votre e-mail institutionnel (@ucbukavu.ac.cd) pour recevoir un lien de réinitialisation sécurisé.',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: resetEmailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'E-mail institutionnel',
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  prefixIcon: Icon(
                    Icons.mail_outline_rounded,
                    color: AppColors.ucbNavy,
                    size: 20,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.ucbNavy,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        backgroundColor: AppColors.success,
                        content: Text(
                          'Un lien de réinitialisation a été envoyé à votre adresse UCB.',
                        ),
                      ),
                    );
                  },
                  child: const Text(
                    'Envoyer le lien',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 960;

        return Scaffold(
          backgroundColor: const Color(0xFF2B3FA0),
          body: SafeArea(
            child: isDesktop ? _buildDesktopLayout() : _buildMobileLayout(),
          ),
        );
      },
    );
  }

  /// ── Disposition Desktop / Grand Écran (2 colonnes élégantes) ──
  Widget _buildDesktopLayout() {
    return Center(
      child: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 32.h),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1120),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28.r),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.28),
                  blurRadius: 32,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Colonne Gauche : Identité Institutionnelle
                  Expanded(
                    flex: 5,
                    child: Container(
                      padding: const EdgeInsets.all(36),
                      decoration: const BoxDecoration(
                        gradient: AppColors.ucbCardGradient,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildBrandLogo(),
                          SizedBox(height: 24.h),
                          const Text(
                            'SMART_PAY UCB',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.0,
                            ),
                          ),
                          SizedBox(height: 6.h),
                          Text(
                            'Université Catholique de Bukavu',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.8),
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: 28.h),
                          _buildBrandFeature(
                            icon: Icons.contactless_rounded,
                            title: 'Paiement Instantané',
                            subtitle:
                                'Validation en bus par simple scan de carte',
                          ),
                          SizedBox(height: 16.h),
                          _buildBrandFeature(
                            icon: Icons.bolt_rounded,
                            title: 'Recharge Mobile Money',
                            subtitle: 'M-Pesa, Airtel Money et Orange Money',
                          ),
                          SizedBox(height: 16.h),
                          _buildBrandFeature(
                            icon: Icons.security_rounded,
                            title: 'Sécurité & Contrôle',
                            subtitle:
                                'Suspension immédiate en cas de perte de carte',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                  // Colonne Droite : Formulaire de connexion
                  Expanded(
                    flex: 6,
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(36, 32.h, 36, 32.h),
                      child: _buildFormContent(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// ── Disposition Mobile & Tablette Portrait ──
  Widget _buildMobileLayout() {
    return Center(
      child: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 40.h),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Logo ──
              _buildBrandLogo()
                  .animate()
                  .scale(duration: 400.ms, curve: Curves.easeOutBack),
              SizedBox(height: 16.h),
              const Text(
                'SMART_PAY UCB',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.6,
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                'Université Catholique de Bukavu',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.75),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 32.h),

              // ── Carte formulaire ──
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFEDF0F7),
                  borderRadius: BorderRadius.circular(26.r),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.18),
                      blurRadius: 28,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                padding: EdgeInsets.fromLTRB(24, 28.h, 24, 24.h),
                child: _buildFormContent(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Logo officiel ──
  Widget _buildLogo() {
    return Container(
      width: 58,
      height: 58,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            const Icon(
              Icons.directions_bus_rounded,
              color: Color(0xFF2B3FA0),
              size: 36,
            ),
            Positioned(
              right: 4,
              bottom: 4.h,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                  color: AppColors.ucbGold,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.nfc_rounded,
                  size: 13,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBrandFeature({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10.r),
          ),
          child: Icon(icon, color: AppColors.ucbGold, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
              SizedBox(height: 2.h),
              Text(
                subtitle,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// ── Corps du Formulaire & Boutons Démo ──
  Widget _buildFormContent() {
    // Style pour les champs (fond blanc, bords subtils)
    final inputDecoration = InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16.h),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _borderColor, width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _borderColor, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _bgColor, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.error, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.error, width: 1.5),
      ),
      labelStyle: const TextStyle(fontSize: 12, color: Color(0xFF6B7590)),
      hintStyle: const TextStyle(fontSize: 14, color: Color(0xFFADB5C8)),
      floatingLabelStyle:
          const TextStyle(fontSize: 11, color: Color(0xFF6B7590)),
    );

    return Theme(
      data: Theme.of(context).copyWith(inputDecorationTheme: fieldTheme),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Titre ──
            const Center(
              child: Text(
                'Connexion',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF1A2340),
                  letterSpacing: -0.3,
                ),
              ),
            ),
            const SizedBox(height: 18),

            // Champ Identifiant / E-mail UCB
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              style: const TextStyle(fontSize: 14, color: Color(0xFF1A2340)),
              decoration: InputDecoration(
                labelText: 'Identifiant / E-mail UCB',
                hintText: 'Identifiant / E-mail UCB',
                prefixIcon: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Icon(
                    Icons.mail_outline_rounded,
                    color: const Color(0xFF6B7590),
                    size: 20.r,
                  ),
                ),
                prefixIconConstraints:
                    const BoxConstraints(minWidth: 46, minHeight: 24),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Veuillez renseigner votre e-mail';
                }
                if (!value.trim().contains('@')) {
                  return 'Format d\'e-mail invalide';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),

            // Champ Mot de passe
            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              style: const TextStyle(fontSize: 14, color: Color(0xFF1A2340)),
              decoration: InputDecoration(
                labelText: 'Mot de passe',
                hintText: 'Mot de passe',
                prefixIcon: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Icon(
                    Icons.lock_outline_rounded,
                    color: const Color(0xFF6B7590),
                    size: 20.r,
                  ),
                ),
                prefixIconConstraints:
                    const BoxConstraints(minWidth: 46, minHeight: 24),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    color: _labelColor,
                    size: 19,
                  ),
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Veuillez saisir votre mot de passe';
                }
                return null;
              },
            ),
            const SizedBox(height: 2),

            // Lien "Mot de passe oublié ?"
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _showForgotPasswordModal,
                style: TextButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 4, vertical: 6.h),
                ),
                child: const Text(
                  'Mot de passe oublié ?',
                  style: TextStyle(
                    color: Color(0xFF2B3FA0),
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Bouton "Se connecter"
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _btnColor,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _isLoading ? null : _submit,
                child: _isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Se connecter',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 0.3,
                        ),
                      ),
              ),
            ),

            SizedBox(height: 20.h),
            const Divider(color: Color(0xFFD0D5E5), height: 1),
            SizedBox(height: 14.h),
            const Text(
              'Accès rapide (cliquez pour pré-remplir) :',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Color(0xFF6B7590),
              ),
            ),
            SizedBox(height: 10.h),
            Wrap(
              spacing: 8,
              runSpacing: 8.h,
              children: [
                _buildQuickLoginChip(
                  label: 'Étudiant',
                  email: AuthService.studentEmail,
                  password: AuthService.studentPassword,
                  icon: Icons.school_rounded,
                  color: const Color(0xFF2B3FA0),
                ),
                _buildQuickLoginChip(
                  label: 'Admin',
                  email: AuthService.adminEmail,
                  password: AuthService.adminPassword,
                  icon: Icons.admin_panel_settings_rounded,
                  color: AppColors.ucbGold,
                ),
                _buildQuickLoginChip(
                  label: 'Terminal Bus',
                  email: AuthService.terminalEmail,
                  password: AuthService.terminalPassword,
                  icon: Icons.directions_bus_rounded,
                  color: const Color(0xFF0D9488),
                ),
              ],
            ),
            SizedBox(height: 6.h),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickLoginChip({
    required String label,
    required String email,
    required String password,
    required IconData icon,
    required Color color,
  }) {
    return InkWell(
      onTap: () {
        setState(() {
          _emailController.text = email;
          _passwordController.text = password;
        });
      },
      borderRadius: BorderRadius.circular(10.r),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6.h),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(color: color.withValues(alpha: 0.28)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
