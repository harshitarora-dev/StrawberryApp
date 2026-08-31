import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:strawberry/core/theme/app_colors.dart';
import 'package:strawberry/core/theme/app_typography.dart';
import 'package:strawberry/core/theme/app_decorations.dart';
import 'package:strawberry/core/widgets/app_badge.dart';
import 'package:strawberry/features/payments/payment_service.dart';

class PaymentHistoryPage extends StatefulWidget {
  final String studentId;

  const PaymentHistoryPage({super.key, required this.studentId});

  @override
  State<PaymentHistoryPage> createState() => _PaymentHistoryPageState();
}

class _PaymentHistoryPageState extends State<PaymentHistoryPage> {
  final _paymentService = PaymentService();
  bool _loading = true;
  List<Map<String, dynamic>> _payments = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await _paymentService.getPaymentsForStudent(widget.studentId);
      if (!mounted) return;
      setState(() {
        _payments = data;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  String _formatMonthKey(String key) {
    final parts = key.split('-');
    if (parts.length != 2) return key;
    const months = [
      '', 'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    final m = int.tryParse(parts[1]) ?? 0;
    return '${months[m]} ${parts[0]}';
  }

  (Color, IconData, String, AppBadgeType) _statusMeta(String status) {
    switch (status) {
      case 'success':
        return (AppColors.emerald, Icons.check_circle_rounded, 'Paid', AppBadgeType.success);
      case 'failed':
        return (AppColors.danger, Icons.cancel_rounded, 'Failed', AppBadgeType.danger);
      case 'cancelled':
        return (AppColors.danger, Icons.close_rounded, 'Cancelled', AppBadgeType.danger);
      case 'submitted':
        return (AppColors.amberDark, Icons.hourglass_top_rounded, 'Verifying', AppBadgeType.warning);
      default:
        return (AppColors.violet, Icons.schedule_rounded, 'Initiated', AppBadgeType.info);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Payment Receipts', style: AppTypography.h2),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = constraints.maxWidth >= 960;
          final isTablet = constraints.maxWidth >= 600 && constraints.maxWidth < 960;
          final horizontalPadding = isDesktop ? 32.0 : (isTablet ? 24.0 : 16.0);

          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: _load,
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : _payments.isEmpty
                    ? ListView(
                        children: [
                          const SizedBox(height: 120),
                          Container(
                            width: 64,
                            height: 64,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: AppColors.surfaceAlt,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.receipt_long_rounded, size: 32, color: AppColors.textMuted),
                          ),
                          const SizedBox(height: 16),
                          Center(
                            child: Text(
                              'No payments recorded yet',
                              style: AppTypography.bodyMedium.copyWith(color: AppColors.textMuted),
                            ),
                          ),
                        ],
                      )
                    : ListView.separated(
                        padding: EdgeInsets.fromLTRB(horizontalPadding, 16, horizontalPadding, 32),
                        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                        itemCount: _payments.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 12),
                        itemBuilder: (context, i) {
                          final p = _payments[i];
                          final (color, icon, label, badgeType) =
                              _statusMeta(p['status'] as String? ?? 'initiated');
                          final createdAt = DateTime.tryParse(p['created_at'] ?? '')?.toLocal();
                          return Container(
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: AppDecorations.radiusLg,
                              border: Border.all(color: AppColors.borderSubtle),
                              boxShadow: AppDecorations.shadowSm,
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: color.withValues(alpha: 0.12),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(icon, color: color, size: 24),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _formatMonthKey(p['month_key'] ?? ''),
                                        style: AppTypography.h3.copyWith(fontSize: 15),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        '${p['upi_app'] ?? 'UPI'} · ${createdAt != null ? DateFormat('d MMM y, h:mm a').format(createdAt) : ''}',
                                        style: AppTypography.caption,
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      '₹${(p['amount'] as num?)?.toStringAsFixed(0) ?? '0'}',
                                      style: AppTypography.h3.copyWith(fontSize: 16),
                                    ),
                                    const SizedBox(height: 4),
                                    AppBadge(
                                      label: label,
                                      type: badgeType,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
          );
        },
      ),
    );
  }
}