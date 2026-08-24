import 'package:flutter/material.dart';
import 'package:strawberry/core/theme/app_colors.dart';
import 'package:strawberry/core/theme/app_typography.dart';
import 'package:strawberry/core/theme/app_decorations.dart';
import 'package:strawberry/core/utils/responsive.dart';
import 'package:strawberry/core/widgets/app_button.dart';
import 'package:strawberry/features/auth/auth_service.dart';
import 'package:strawberry/features/payments/payment_service.dart';
import 'package:strawberry/features/dashboard/student/payment_history_page.dart';

class PayFeesPage extends StatefulWidget {
  final AuthService authService;
  final Map<String, dynamic> profile;

  const PayFeesPage({
    super.key,
    required this.authService,
    required this.profile,
  });

  @override
  State<PayFeesPage> createState() => _PayFeesPageState();
}

class _PayFeesPageState extends State<PayFeesPage> {
  final _paymentService = PaymentService();
  final _amountController = TextEditingController();

  String? _selectedMonth;
  bool _paying = false;

  static const _monthNames = [
    '',
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  String _formatMonthKey(String key) {
    final parts = key.split('-');
    if (parts.length != 2) return key;
    final m = int.tryParse(parts[1]) ?? 0;
    return '${_monthNames[m]} ${parts[0]}';
  }

  List<String> get _paidMonths =>
      List<String>.from((widget.profile['fees_paid_months'] as List?) ?? []);

  List<String> get _unpaidMonths {
    final now = DateTime.now();
    final months = List.generate(12, (i) {
      final d = DateTime(now.year, now.month - (11 - i), 1);
      return '${d.year}-${d.month.toString().padLeft(2, '0')}';
    });
    return months.where((m) => !_paidMonths.contains(m)).toList();
  }

  double get _monthlyFee => (widget.profile['fees'] as num?)?.toDouble() ?? 0;

  @override
  void initState() {
    super.initState();
    final unpaid = _unpaidMonths;
    _selectedMonth = unpaid.isNotEmpty ? unpaid.first : null;
    _amountController.text =
        _monthlyFee > 0 ? _monthlyFee.toStringAsFixed(0) : '';
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  double? get _amount => double.tryParse(_amountController.text.trim());

  Future<void> _startPayment() async {
    final amount = _amount;
    if (amount == null || amount <= 0) {
      _snack('Please enter a valid amount', danger: true);
      return;
    }
    if (_selectedMonth == null) {
      _snack('Please select a month', danger: true);
      return;
    }

    setState(() => _paying = true);
    final result = await _paymentService.payViaUpi(
      amount: amount,
      monthKey: _selectedMonth!,
      studentId: widget.profile['id'],
      studentName: widget.profile['name'] ?? '',
      authService: widget.authService,
    );
    if (!mounted) return;
    setState(() => _paying = false);

    if (!result.launched) {
      _snack(
        'Could not open a UPI app. Please install Google Pay, PhonePe or Paytm.',
        danger: true,
      );
      return;
    }

    switch (result.autoStatus) {
      case 'success':
        _snack('Payment successful! Fees marked as paid. 🎉', danger: false);
        setState(() {}); // refresh unpaid-months list
        return;
      case 'failed':
        final reason = result.failureReason;
        _snack(
          reason == null
              ? 'Payment failed. Please try again.'
              : 'Payment failed ($reason)',
          danger: true,
        );
        return;
      case 'cancelled':
        _snack('Payment was cancelled.', danger: true);
        return;
      default:
        _showFollowUpDialog(result.rowId);
    }
  }

  void _showFollowUpDialog(String rowId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: AppDecorations.radiusLg),
        title: Row(
          children: [
            const Icon(Icons.hourglass_top_rounded, color: AppColors.amberDark),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Complete Payment in UPI',
                style: AppTypography.h3,
              ),
            ),
          ],
        ),
        content: Text(
          'We initiated your transaction with the school\'s UPI ID and amount pre-filled. '
          'Once completed in your UPI app, tap below to confirm.',
          style: AppTypography.bodySmall,
        ),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _paymentService.markSelfReportedFailed(rowId);
              _snack('Marked as not completed', danger: true);
            },
            child: Text('Cancel', style: AppTypography.button.copyWith(color: AppColors.danger)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _paymentService.markSelfReportedPaid(rowId);
              if (!mounted) return;
              _snack('Thanks! We\'ll confirm it shortly.', danger: false);
              setState(() {});
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.emerald,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: AppDecorations.radiusSm),
            ),
            child: const Text('I\'ve Paid'),
          ),
        ],
      ),
    );
  }

  void _snack(String msg, {bool danger = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: AppTypography.bodySmall.copyWith(color: Colors.white)),
        backgroundColor: danger ? AppColors.danger : AppColors.emerald,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final unpaid = _unpaidMonths;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Pay Academic Fees', style: AppTypography.h2),
        actions: [
          IconButton(
            tooltip: 'Payment History',
            icon: const Icon(Icons.receipt_long_rounded, color: AppColors.primary),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) =>
                    PaymentHistoryPage(studentId: widget.profile['id']),
              ),
            ),
          ),
        ],
      ),
      body: Center(
        child: ResponsiveContentWrapper(
          maxWidth: 600,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: ListView(
            physics: const BouncingScrollPhysics(),
            children: [
              // Monthly Fee Header Card
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: AppDecorations.radiusXl,
                  boxShadow: AppDecorations.primaryGlow,
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.account_balance_wallet_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Monthly Tuition Fee',
                            style: AppTypography.caption.copyWith(color: Colors.white.withValues(alpha: 0.85)),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '₹${_monthlyFee.toStringAsFixed(0)} / month',
                            style: AppTypography.h1.copyWith(color: Colors.white, fontSize: 24),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              if (unpaid.isEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: AppDecorations.radiusLg,
                    border: Border.all(color: AppColors.borderSubtle),
                    boxShadow: AppDecorations.shadowSm,
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.celebration_rounded, color: AppColors.emerald, size: 28),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          'All monthly fees are cleared! No pending dues.',
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.emeraldDark,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                Text('Select Fee Month', style: AppTypography.h3),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _selectedMonth,
                  dropdownColor: Colors.white,
                  style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.calendar_month_rounded, color: AppColors.primary),
                  ),
                  items: unpaid
                      .map(
                        (m) => DropdownMenuItem(
                          value: m,
                          child: Text(_formatMonthKey(m)),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => setState(() => _selectedMonth = v),
                ),

                const SizedBox(height: 20),

                Text('Payment Amount (₹)', style: AppTypography.h3),
                const SizedBox(height: 8),
                TextField(
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: AppTypography.h2,
                  decoration: InputDecoration(
                    prefixText: '₹ ',
                    prefixStyle: AppTypography.h2.copyWith(color: AppColors.primary),
                  ),
                ),

                const SizedBox(height: 28),

                AppButton(
                  label: _paying ? 'Opening UPI App...' : 'Pay Instant via UPI',
                  icon: Icons.bolt_rounded,
                  loading: _paying,
                  onPressed: _paying ? null : _startPayment,
                  variant: AppButtonVariant.primary,
                  height: 52,
                ),

                const SizedBox(height: 12),

                Center(
                  child: Text(
                    'Compatible with Google Pay, PhonePe, Paytm & BHIM UPI',
                    textAlign: TextAlign.center,
                    style: AppTypography.caption,
                  ),
                ),
              ],

              const SizedBox(height: 28),

              AppButton(
                label: 'View Payment Receipts',
                icon: Icons.receipt_long_rounded,
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => PaymentHistoryPage(studentId: widget.profile['id']),
                  ),
                ),
                variant: AppButtonVariant.outline,
                height: 48,
              ),
            ],
          ),
        ),
      ),
    );
  }
}