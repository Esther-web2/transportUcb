import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../models/transport_models.dart';
import '../services/auth_service.dart';
import '../services/transport_service.dart';
import '../theme/app_theme.dart';
import 'login_screen.dart';

/// ═══════════════════════════════════════════════════════════════
///  ÉCRAN 5 — Terminal Contrôleur / Validation NFC (SMART_PAY_UCB)
///  SaaS / Fintech Design & Transactions Atomiques Locales
/// ═══════════════════════════════════════════════════════════════

class ControllerTerminalScreen extends StatefulWidget {
  const ControllerTerminalScreen({super.key});

  @override
  State<ControllerTerminalScreen> createState() =>
      _ControllerTerminalScreenState();
}

class _ControllerTerminalScreenState extends State<ControllerTerminalScreen> {
  late BusLine _selectedLine;
  late String _selectedBus;

  final _uidInputController = TextEditingController();
  ScanResult? _lastResult;
  bool _isScanning = false;

  @override
  void initState() {
    super.initState();
    _selectedLine = TransportService.lines.first;
    _selectedBus = _selectedLine.availableBuses.first;
  }

  @override
  void dispose() {
    _uidInputController.dispose();
    super.dispose();
  }

  Future<void> _handleScan(String uid) async {
    if (_isScanning) return;
    setState(() {
      _isScanning = true;
    });

    final result = await TransportService.validateCardScan(
      cardUid: uid,
      line: _selectedLine,
      busNumber: _selectedBus,
    );

    if (result.isSuccess) {
      HapticFeedback.mediumImpact();
    } else if (result.isBlocked) {
      HapticFeedback.heavyImpact();
    } else {
      HapticFeedback.lightImpact();
    }

    if (!mounted) return;
    setState(() {
      _lastResult = result;
      _isScanning = false;
      _uidInputController.clear();
    });

    Future.delayed(const Duration(milliseconds: 4500), () {
      if (mounted && _lastResult == result) {
        setState(() => _lastResult = null);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _lastResult != null
          ? _getBackgroundColorForStatus(_lastResult!.status)
          : const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: AppColors.ucbNavy.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Icon(Icons.directions_bus_filled_rounded,
                  color: AppColors.ucbNavy, size: 22.sp),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'TERMINAL CONTRÔLEUR',
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w800,
                      color: AppColors.ucbNavy,
                      letterSpacing: 0.5,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'Session : ${AuthService.userName} (${AuthService.currentUser?.busNumber ?? _selectedBus})',
                    style: TextStyle(
                        fontSize: 11.sp, color: const Color(0xFF64748B)),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Déconnexion',
            icon: Icon(Icons.logout_rounded,
                color: const Color(0xFF64748B), size: 20.sp),
            onPressed: () {
              AuthService.logout();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          child: Column(
            children: [
              // ── 1. En-tête de Service : Ligne & Bus ──
              _buildServiceHeader(),

              // ── 2. Feedback Immédiat Grand Écran lors d'un scan ──
              if (_lastResult != null)
                _buildGrandResultBanner(_lastResult!)
                    .animate()
                    .fadeIn(duration: 150.ms)
                    .slideY(begin: -0.1, end: 0),

              // ── 3. Zone Centrale Radar & Écoute NFC ──
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 500),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    child: Column(
                      children: [
                        _buildRadarSection(),
                        const SizedBox(height: 14),
                        // ── 4. Raccourcis de simulation 1-clic (< 1s) ──
                        if (_lastResult != null) _buildSimulationShortcuts(),
                        const SizedBox(height: 14),
                        // ── 5. Saisie manuelle UID / Lecteur Bluetooth / Arduino ──
                        _buildManualUidInput(),
                      ],
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

  Color _getBackgroundColorForStatus(ScanStatus status) {
    switch (status) {
      case ScanStatus.success:
        return const Color(0xFFF0FDF4); // Émeraude très doux
      case ScanStatus.insufficientBalance:
        return const Color(0xFFFEF2F2); // Rouge très doux
      case ScanStatus.blocked:
      case ScanStatus.notFound:
        return const Color(0xFFFFFBEB); // Ambre très doux
    }
  }

  /// ── 1. En-tête de Service connectée aux Lignes Transport ──
  Widget _buildServiceHeader() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: DropdownButtonFormField<BusLine>(
              initialValue: _selectedLine,
              decoration: InputDecoration(
                labelText: 'Ligne active',
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
                isDense: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
              ),
              items: TransportService.lines.map((l) {
                return DropdownMenuItem<BusLine>(
                  value: l,
                  child: Text(
                    l.name,
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13.sp,
                        color: const Color(0xFF0F172A)),
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
              onChanged: (line) {
                if (line != null) {
                  setState(() {
                    _selectedLine = line;
                    if (!line.availableBuses.contains(_selectedBus)) {
                      _selectedBus = line.availableBuses.first;
                    }
                  });
                }
              },
            ),
          ),
          SizedBox(width: 10.w),
          Expanded(
            flex: 2,
            child: DropdownButtonFormField<String>(
              initialValue: _selectedBus,
              decoration: InputDecoration(
                labelText: 'N° Bus',
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
                isDense: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
              ),
              items: _selectedLine.availableBuses.map((b) {
                return DropdownMenuItem<String>(
                  value: b,
                  child: Text(
                    b,
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13.sp,
                        color: const Color(0xFF0F172A)),
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
              onChanged: (bus) {
                if (bus != null) setState(() => _selectedBus = bus);
              },
            ),
          ),
        ],
      ),
    );
  }

  /// ── 2. Grand Écran / Feedback Immédiat (< 1s) ──
  Widget _buildGrandResultBanner(ScanResult res) {
    Color bannerColor;
    IconData icon;
    String title;

    switch (res.status) {
      case ScanStatus.success:
        bannerColor = AppColors.emerald;
        icon = Icons.check_circle_rounded;
        title = 'VALIDATION RÉUSSIE';
        break;
      case ScanStatus.insufficientBalance:
        bannerColor = AppColors.error;
        icon = Icons.cancel_rounded;
        title = 'SOLDE INSUFFISANT';
        break;
      case ScanStatus.blocked:
        bannerColor = AppColors.ucbGoldDark;
        icon = Icons.warning_rounded;
        title = 'CARTE SUSPENDUE / BLOQUÉE';
        break;
      case ScanStatus.notFound:
        bannerColor = AppColors.ucbNavy;
        icon = Icons.help_outline_rounded;
        title = 'CARTE NON RECONNUE';
        break;
    }

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
      decoration: BoxDecoration(
        color: bannerColor,
        boxShadow: [
          BoxShadow(
            color: bannerColor.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.25),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 28.sp),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.8,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 2.h),
                Text(
                  res.card?.fullName ?? res.message,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w700,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                if (res.card?.studentId != null)
                  Text(
                    'Matricule : ${res.card!.studentId} • ${res.card!.faculty ?? ""}',
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 11.sp),
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          if (res.status == ScanStatus.success)
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '- ${res.fare.toStringAsFixed(0)} FC',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  'Reste : ${res.remainingBalance.toStringAsFixed(0)} FC',
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 11.sp),
                ),
              ],
            ),
        ],
      ),
    );
  }

  /// ── 3. Zone Radar Animée (Écoute NFC / Arduino) ──
  Widget _buildRadarSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: AppColors.saasCardShadow,
      ),
      child: Column(
        children: [
          SizedBox(
            width: 156.w,
            height: 156.w,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 120.w,
                  height: 120.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.ucbNavy.withValues(alpha: 0.05),
                  ),
                )
                    .animate(onPlay: (controller) => controller.repeat())
                    .scale(
                        begin: const Offset(1, 1),
                        end: const Offset(1.3, 1.3),
                        duration: 1500.ms)
                    .fadeOut(duration: 1500.ms),
                Container(
                  width: 90.w,
                  height: 90.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.ucbNavy.withValues(alpha: 0.1),
                  ),
                ),
                Container(
                  width: 68.w,
                  height: 68.w,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: AppColors.primaryGradient,
                  ),
                  child: _isScanning
                      ? Padding(
                          padding: EdgeInsets.all(16.w),
                          child: const CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 3),
                        )
                      : Icon(Icons.nfc_rounded,
                          color: Colors.white, size: 32.sp),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'PRÊT À VALIDER',
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w900,
              color: AppColors.ucbNavy,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Approchez la carte de l\'antenne NFC / Bluetooth ou utilisez les tests 1-clic.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Tarif de la ligne : ${_selectedLine.formattedFare}',
              style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13.sp,
                  color: AppColors.ucbNavy),
            ),
          ),
        ],
      ),
    );
  }

  /// ── 4. Raccourcis de simulation 1-clic (< 1s) ──
  Widget _buildSimulationShortcuts() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Simulations de Validation Immédiate (< 1s) :',
          style: TextStyle(
              fontSize: 13.sp,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF0F172A)),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.emerald,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding:
                      EdgeInsets.symmetric(vertical: 10.h, horizontal: 4.w),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r)),
                ),
                onPressed:
                    _isScanning ? null : () => _handleScan('UCB-CARD-001'),
                child: Column(
                  children: [
                    Icon(Icons.check_circle_outline, size: 16),
                    SizedBox(height: 2),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        'Solde OK\n(12 500 FC)',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 11.sp, fontWeight: FontWeight.w800),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding:
                      EdgeInsets.symmetric(vertical: 10.h, horizontal: 4.w),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r)),
                ),
                onPressed:
                    _isScanning ? null : () => _handleScan('UCB-CARD-002'),
                child: Column(
                  children: [
                    Icon(Icons.highlight_off, size: 16),
                    SizedBox(height: 2),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        'Solde Faible\n(500 FC)',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 11.sp, fontWeight: FontWeight.w800),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.ucbGoldDark,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding:
                      EdgeInsets.symmetric(vertical: 10.h, horizontal: 4.w),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r)),
                ),
                onPressed:
                    _isScanning ? null : () => _handleScan('UCB-CARD-003'),
                child: Column(
                  children: [
                    Icon(Icons.lock_clock, size: 16),
                    SizedBox(height: 2),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        'Carte Bloquée\n(Perte/Vol)',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 11.sp, fontWeight: FontWeight.w800),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// ── 5. Saisie Manuelle ou Scan USB/Bluetooth ──
  Widget _buildManualUidInput() {
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: AppColors.saasCardShadow,
      ),
      child: Row(
        children: [
          SizedBox(width: 8.w),
          Icon(Icons.qr_code_scanner_rounded,
              color: const Color(0xFF64748B), size: 20.sp),
          SizedBox(width: 10.w),
          Expanded(
            child: TextField(
              controller: _uidInputController,
              decoration: InputDecoration(
                hintText: 'Saisir UID RFID scanné via Bluetooth...',
                hintStyle:
                    TextStyle(color: const Color(0xFF94A3B8), fontSize: 13.sp),
                isDense: true,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 8),
              ),
              onSubmitted: (uid) {
                if (uid.trim().isNotEmpty) _handleScan(uid.trim());
              },
            ),
          ),
          SizedBox(
            height: 38,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.ucbNavy,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.r)),
                padding: EdgeInsets.symmetric(horizontal: 14.w),
              ),
              onPressed: () {
                final uid = _uidInputController.text.trim();
                if (uid.isNotEmpty) _handleScan(uid);
              },
              child: Text('Valider',
                  style:
                      TextStyle(fontWeight: FontWeight.w700, fontSize: 13.sp)),
            ),
          ),
        ],
      ),
    );
  }
}
