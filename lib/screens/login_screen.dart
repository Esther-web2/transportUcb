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
///  Université Catholique de Bukavu — Layout Responsive Adaptatif
///  (Mobile Portrait/Landscape, Tablette, Desktop/Web)
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
      maxWidth: 480.w,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24.r),
        ),
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          padding: EdgeInsets.only(
            left: 24.w,
            right: 24.w,
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
                    padding: EdgeInsets.all(10.w),
                    decoration: BoxDecoration(
                      color: AppColors.ucbNavy.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Icon(
                      Icons.lock_reset_rounded,
                      color: AppColors.ucbNavy,
                      size: 22.sp,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Text(
                      'Récupération de compte',
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ucbNavy,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12.h),
              Text(
                'Saisissez votre e-mail institutionnel (@ucbukavu.ac.cd) pour recevoir un lien de réinitialisation sécurisé.',
                style: TextStyle(
                  fontSize: 13.sp,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
              SizedBox(height: 16.h),
              TextField(
                controller: resetEmailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'E-mail institutionnel',
                  contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
                  prefixIcon: const Icon(
                    Icons.mail_outline_rounded,
                    color: AppColors.ucbNavy,
                  ),
                ),
              ),
              SizedBox(height: 20.h),
              SizedBox(
                width: double.infinity,
                height: 48.h,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.ucbNavy,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16.r),
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
                  child: Text(
                    'Envoyer le lien',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14.sp,
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
        final isDesktop = constraints.maxWidth >= 800;

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
        padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 32.h),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 1040.w),
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
                      padding: EdgeInsets.all(36.w),
                      decoration: const BoxDecoration(
                        gradient: AppColors.ucbCardGradient,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildBrandLogo(),
                          SizedBox(height: 24.h),
                          Text(
                            'SMART_PAY UCB',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 26.sp,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.0,
                            ),
                          ),
                          SizedBox(height: 6.h),
                          Text(
                            'Université Catholique de Bukavu',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.8),
                              fontSize: 14.sp,
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
                  ),

                  // Colonne Droite : Formulaire de connexion
                  Expanded(
                    flex: 6,
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(36.w, 32.h, 36.w, 32.h),
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
        padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 40.h),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 520.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Logo ──
              _buildBrandLogo()
                  .animate()
                  .scale(duration: 400.ms, curve: Curves.easeOutBack),
              SizedBox(height: 16.h),
              Text(
                'SMART_PAY UCB',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22.sp,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.6,
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                'Université Catholique de Bukavu',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.75),
                  fontSize: 12.sp,
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
                padding: EdgeInsets.fromLTRB(24.w, 28.h, 24.w, 24.h),
                child: _buildFormContent(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBrandLogo() {
    return Container(
      width: 72.r,
      height: 72.r,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.22),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(
              Icons.directions_bus_rounded,
              color: const Color(0xFF2B3FA0),
              size: 36.sp,
            ),
            Positioned(
              right: 4.w,
              bottom: 4.h,
              child: Container(
                padding: EdgeInsets.all(2.r),
                decoration: const BoxDecoration(
                  color: AppColors.ucbGold,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.nfc_rounded,
                  size: 13.sp,
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
          padding: EdgeInsets.all(8.w),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10.r),
          ),
          child: Icon(icon, color: AppColors.ucbGold, size: 20.sp),
        ),
        SizedBox(width: 14.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 13.sp,
                ),
              ),
              SizedBox(height: 2.h),
              Text(
                subtitle,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 11.sp,
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
      contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14.r),
        borderSide: const BorderSide(color: Color(0xFFD5DAE8), width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14.r),
        borderSide: const BorderSide(color: Color(0xFFD5DAE8), width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14.r),
        borderSide: const BorderSide(color: Color(0xFF2B3FA0), width: 1.8),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14.r),
        borderSide: const BorderSide(color: AppColors.error, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14.r),
        borderSide: const BorderSide(color: AppColors.error, width: 1.8),
      ),
      labelStyle: TextStyle(fontSize: 12.sp, color: const Color(0xFF6B7590)),
      hintStyle: TextStyle(fontSize: 14.sp, color: const Color(0xFFADB5C8)),
      floatingLabelStyle: TextStyle(fontSize: 11.sp, color: const Color(0xFF6B7590)),
    );

    return Theme(
      data: Theme.of(context).copyWith(inputDecorationTheme: inputDecoration),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Titre ──
            Center(
              child: Text(
                'Connexion',
                style: TextStyle(
                  fontSize: 26.sp,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF1A2340),
                  letterSpacing: -0.3,
                ),
              ),
            ),
            SizedBox(height: 24.h),

            // ── Champ E-mail ──
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              style: TextStyle(fontSize: 14.sp, color: const Color(0xFF1A2340)),
              decoration: InputDecoration(
                labelText: 'Identifiant / E-mail UCB',
                hintText: 'Identifiant / E-mail UCB',
                prefixIcon: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 14.w),
                  child: Icon(Icons.mail_outline_rounded,
                      color: const Color(0xFF6B7590), size: 20.r),
                ),
                prefixIconConstraints:
                    BoxConstraints(minWidth: 46.w, minHeight: 24),
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
            SizedBox(height: 14.h),

            // ── Champ Mot de passe ──
            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              style: TextStyle(fontSize: 14.sp, color: const Color(0xFF1A2340)),
              decoration: InputDecoration(
                labelText: 'Mot de passe',
                hintText: 'Mot de passe',
                prefixIcon: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 14.w),
                  child: Icon(Icons.lock_outline_rounded,
                      color: const Color(0xFF6B7590), size: 20.r),
                ),
                prefixIconConstraints:
                    BoxConstraints(minWidth: 46.w, minHeight: 24),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    color: const Color(0xFF6B7590),
                    size: 20.r,
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
            SizedBox(height: 4.h),

            // ── Mot de passe oublié ──
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _showForgotPasswordModal,
                style: TextButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 6.h),
                ),
                child: Text(
                  'Mot de passe oublié ?',
                  style: TextStyle(
                    color: const Color(0xFF2B3FA0),
                    fontWeight: FontWeight.w600,
                    fontSize: 13.sp,
                  ),
                ),
              ),
            ),
            SizedBox(height: 8.h),

            // ── Bouton Se connecter ──
            SizedBox(
              width: double.infinity,
              height: 52.h,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E2F7A),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28.r),
                  ),
                ),
                onPressed: _isLoading ? null : _submit,
                child: _isLoading
                    ? SizedBox(
                        width: 22.r,
                        height: 22.r,
                        child: const CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        'Se connecter',
                        style: TextStyle(
                          fontSize: 15.sp,
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
            Text(
              'Accès rapide (cliquez pour pré-remplir) :',
              style: TextStyle(
                fontSize: 11.sp,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF6B7590),
              ),
            ),
            SizedBox(height: 10.h),
            Wrap(
              spacing: 8.w,
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
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(color: color.withValues(alpha: 0.28)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14.sp, color: color),
            SizedBox(width: 6.w),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12.sp,
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
