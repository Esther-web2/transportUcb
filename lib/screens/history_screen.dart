import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../models/transport_models.dart';
import '../services/transport_service.dart';
import '../theme/app_theme.dart';
import '../widgets/cinetpay_receipt_dialog.dart';

/// ═══════════════════════════════════════════════════════════════
///  ÉCRAN 3 — Historique & Recharges (SMART_PAY_UCB)
///  SaaS / Fintech Design & Données Locales Hive — Responsive Layout
/// ═══════════════════════════════════════════════════════════════

class HistoryScreen extends StatefulWidget {
  final String cardUid;

  const HistoryScreen({super.key, required this.cardUid});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 1, vsync: this);
    _refreshTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final recharges = TransportService.getRechargesForCard(widget.cardUid);
    final canPop = Navigator.canPop(context);
    final isWide = MediaQuery.sizeOf(context).width >= 720;

    final totalRecharged = recharges
        .where((r) => r.isSuccess)
        .fold<double>(0, (sum, r) => sum + r.amount);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: canPop
            ? IconButton(
                icon: const Icon(
                  Icons.arrow_back_rounded,
                  color: AppColors.ucbNavy,
                ),
                onPressed: () => Navigator.pop(context),
              )
            : null,
        title: Text(
          'Historique & Recharges',
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF0F172A),
          ),
        ),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(56.h),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 960),
              child: Container(
                margin: EdgeInsets.symmetric(horizontal: 20.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  indicator: BoxDecoration(
                    color: AppColors.ucbNavy,
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  labelColor: Colors.white,
                  unselectedLabelColor: const Color(0xFF64748B),
                  dividerColor: Colors.transparent,
                  tabs: [
                    Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.account_balance_wallet_rounded, size: 16.r),
                          SizedBox(width: 8.w),
                          Text('Recharges Mobile Money', style: TextStyle(fontSize: 13.sp)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 960),
          child: Column(
            children: [
              // ── En-tête des totaux ──
              Container(
                margin: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 8.h),
                padding: EdgeInsets.all(16.r),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: AppColors.saasCardShadow,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Total Rechargé en ligne',
                            style: TextStyle(
                              fontSize: 11.sp,
                              color: const Color(0xFF64748B),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: 4.h),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              '+ ${totalRecharged.toStringAsFixed(0)} FC',
                              style: TextStyle(
                                fontSize: 18.sp,
                                fontWeight: FontWeight.w800,
                                color: AppColors.emerald,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 10.w,
                        vertical: 6.h,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.emerald.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                      child: Text(
                        '${recharges.length} transaction(s)',
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w700,
                          color: AppColors.emerald,
                        ),
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 250.ms),

              // ── Liste ou Grille responsive des recharges ──
              Expanded(
                child: recharges.isEmpty
                    ? Center(
                        child: SingleChildScrollView(
                          physics: const ClampingScrollPhysics(),
                          padding: EdgeInsets.all(20.r),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 64.r,
                                height: 64.r,
                                decoration: BoxDecoration(
                                  color: AppColors.ucbNavy.withValues(alpha: 0.08),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.receipt_long_rounded,
                                  size: 30.r,
                                  color: AppColors.ucbNavy,
                                ),
                              ),
                              SizedBox(height: 14.h),
                              Text(
                                'Aucune recharge effectuée',
                                style: TextStyle(
                                  fontSize: 15.sp,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF0F172A),
                                ),
                              ),
                              SizedBox(height: 6.h),
                              Text(
                                'Vos opérations de recharge Mobile Money en ligne\napparaîtront ici en temps réel.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 13.sp,
                                  color: const Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : isWide
                        ? GridView.builder(
                            physics: const ClampingScrollPhysics(),
                            padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 24.h),
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 12.w,
                              mainAxisSpacing: 10.h,
                              mainAxisExtent: 80.h,
                            ),
                            itemCount: recharges.length,
                            itemBuilder: (context, index) {
                              return _buildRechargeCard(recharges[index]);
                            },
                          )
                        : ListView.builder(
                            physics: const ClampingScrollPhysics(),
                            padding: EdgeInsets.all(20.r),
                            itemCount: recharges.length,
                            itemBuilder: (context, index) {
                              return _buildRechargeCard(recharges[index]);
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRechargeCard(OnlineRecharge recharge) {
    final isSuccess = recharge.isSuccess;
    final amount = recharge.amount;
    final date = recharge.timestamp;
    final timeStr =
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    final dateStr =
        '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}';

    return InkWell(
      onTap: () => CinetPayReceiptDialog.show(context, recharge),
      borderRadius: BorderRadius.circular(16.r),
      child: Container(
        margin: EdgeInsets.only(bottom: 10.h),
        padding: EdgeInsets.all(14.r),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: AppColors.saasCardShadow,
        ),
        child: Row(
          children: [
            Container(
              width: 36.r,
              height: 36.r,
              decoration: BoxDecoration(
                color: isSuccess
                    ? const Color(0xFF008272).withValues(alpha: 0.1)
                    : AppColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Icon(
                isSuccess ? Icons.verified_rounded : Icons.cancel_rounded,
                color: isSuccess ? const Color(0xFF008272) : AppColors.error,
                size: 20.r,
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          'En ligne • ${recharge.operator.displayName}',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13.sp,
                            color: const Color(0xFF0F172A),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      SizedBox(width: 6.w),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 1.h),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(4.r),
                        ),
                        child: Text(
                          recharge.cinetpayTransactionId,
                          style: TextStyle(fontSize: 9.sp, fontFamily: 'monospace', color: const Color(0xFF64748B)),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 3.h),
                  Text(
                    '${amount.toStringAsFixed(0)} FC • $dateStr à $timeStr',
                    style: TextStyle(
                      fontSize: 11.sp,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 8.w),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    isSuccess
                        ? '+ ${amount.toStringAsFixed(0)} FC'
                        : '- ${amount.toStringAsFixed(0)} FC',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 13.sp,
                      color: isSuccess ? AppColors.emerald : AppColors.error,
                    ),
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  'Voir reçu',
                  style: TextStyle(fontSize: 10.sp, fontWeight: FontWeight.w600, color: const Color(0xFF008272)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}