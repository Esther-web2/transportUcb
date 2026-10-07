import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'models/transport_models.dart';
import 'screens/admin_dashboard_screen.dart';
import 'screens/controller_terminal_screen.dart';
import 'screens/login_screen.dart';
import 'screens/student_dashboard_screen.dart';
import 'services/auth_service.dart';
import 'services/hive_service.dart';
import 'services/theme_service.dart';
import 'theme/app_theme.dart';

/// ═══════════════════════════════════════════════════════════════
///  SMART_PAY_UCB — Configuration racine de l'application
///  Université Catholique de Bukavu
/// ═══════════════════════════════════════════════════════════════

class RechargeApp extends StatefulWidget {
  const RechargeApp({super.key});

  @override
  State<RechargeApp> createState() => _RechargeAppState();
}

class _RechargeAppState extends State<RechargeApp> {
  bool _isInitialized = false;
  String? _initError;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      await HiveService.init();
      if (mounted) setState(() => _isInitialized = true);
    } catch (e) {
      if (mounted) setState(() => _initError = e.toString());
    }
  }

  @override
  void dispose() {
    HiveService.close();
    super.dispose();
  }

  Widget _getHomeScreenForRole() {
    if (!AuthService.isLoggedIn) {
      return const LoginScreen();
    }
    switch (AuthService.currentRole) {
      case UserRole.student:
        return const StudentDashboardScreen();
      case UserRole.admin:
        return const AdminDashboardScreen();
      case UserRole.terminal:
        return const ControllerTerminalScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: ThemeService.mode,
      builder: (context, ThemeMode current, _) {
        return ScreenUtilInit(
          designSize: const Size(360, 690),
          minTextAdapt: true,
          splitScreenMode: true,
          builder: (context, child) {
            return MaterialApp(
              title: 'SMART_PAY UCB',
              debugShowCheckedModeBanner: false,
              theme: AppTheme.lightTheme,
              darkTheme: AppTheme.darkTheme,
              themeMode: current,
              home: _isInitialized
                  ? _getHomeScreenForRole()
                  : _buildSplashScreen(),
            );
          },
        );
      },
    );
  }

  Widget _buildSplashScreen() {
    if (_initError != null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  color: AppColors.error,
                  size: 64,
                ),
                const SizedBox(height: 20),
                const Text(
                  'Erreur d\'initialisation',
                  style: TextStyle(
                    color: AppColors.ucbNavy,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _initError!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.ucbNavy,
      body: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: MediaQuery.sizeOf(context).height,
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 84,
                  height: 84,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.directions_bus_rounded,
                    color: AppColors.ucbNavy,
                    size: 44,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'SMART_PAY UCB',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Université Catholique de Bukavu',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 32),
                const SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(AppColors.ucbGold),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
