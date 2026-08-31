import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:strawberry/core/theme/app_colors.dart';
import 'package:strawberry/core/theme/app_typography.dart';
import 'package:strawberry/core/theme/app_decorations.dart';
import 'package:strawberry/core/upi_config.dart';
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

  @override
  void initState() {
    super.initState();
    final unpaid = _unpaidMonths;
    if (unpaid.isNotEmpty) {
      _selectedMonth = unpaid.first;
    }
    _amountController.text = _monthlyFee > 0 ? _monthlyFee.toStringAsFixed(0) : '';
  }

  double get _monthlyFee =>
      ((widget.profile['monthly_fee'] ?? widget.profile['fees']) as num?)
          ?.toDouble() ??
      0.0;

  DateTime get _startMonth {
    final raw = widget.profile['approved_at'] ?? widget.profile['created_at'];
    if (raw != null) {
      final parsed = DateTime.tryParse(raw.toString());
      if (parsed != null) return DateTime(parsed.year, parsed.month, 1);
    }
    final now = DateTime.now();
    return DateTime(now.year, now.month, 1);
  }

  List<String> get _unpaidMonths {
    final paid = List<String>.from(widget.profile['fees_paid_months'] ?? []);
    final start = _startMonth;
    final now = DateTime.now();
    final current = DateTime(now.year, now.month, 1);

    final months = <String>[];
    var cursor = start;
    // Iterate from account approval month up to current month
    while (!cursor.isAfter(current)) {
      final key = '${cursor.year}-${cursor.month.toString().padLeft(2, '0')}';
      if (!paid.contains(key)) {
        months.add(key);
      }
      cursor = DateTime(cursor.year, cursor.month + 1, 1);
    }
    return months;
  }

  String _formatMonthKey(String key) {
    final parts = key.split('-');
    if (parts.length != 2) return key;
    final m = int.tryParse(parts[1]) ?? 0;
    final y = parts[0];
    if (m >= 1 && m <= 12) {
      return '${_monthNames[m]} $y';
    }
    return key;
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  double? get _amount => double.tryParse(_amountController.text.trim());

  void _copyUpiId() {
    Clipboard.setData(const ClipboardData(text: UpiConfig.vpa));
    HapticFeedback.lightImpact();
    _snack('UPI ID copied to clipboard: ${UpiConfig.vpa}');
  }

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
      _showNoUpiAppDialog(
        amount: amount,
        monthKey: _selectedMonth!,
        rowId: result.rowId,
      );
      return;
    }

    switch (result.autoStatus) {
      case 'success':
        final paid = List<String>.from(widget.profile['fees_paid_months'] ?? []);
        if (_selectedMonth != null && !paid.contains(_selectedMonth)) {
          paid.add(_selectedMonth!);
          widget.profile['fees_paid_months'] = paid;
        }
        _snack('Payment successful! Fees marked as paid. 🎉', danger: false);
        final nextUnpaid = _unpaidMonths;
        setState(() {
          _selectedMonth = nextUnpaid.isNotEmpty ? nextUnpaid.first : null;
        });
        return;
      case 'failed':
        _showPaymentFailedDialog(
          amount: amount,
          monthKey: _selectedMonth!,
          rowId: result.rowId,
          reason: result.failureReason,
        );
        return;
      case 'cancelled':
        _snack('Payment was cancelled.', danger: true);
        return;
      default:
        _showFollowUpDialog(result.rowId);
    }
  }

  Widget _buildUpiCopyCard({required double amount}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primarySoft.withValues(alpha: 0.4),
        borderRadius: AppDecorations.radiusMd,
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'School Payee Details',
                style: AppTypography.caption.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryDark,
                ),
              ),
              Text(
                '₹${amount.toStringAsFixed(0)}',
                style: AppTypography.bodyMedium.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Name: ${UpiConfig.payeeName}',
            style: AppTypography.bodySmall.copyWith(color: AppColors.textDark),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: AppDecorations.radiusSm,
              border: Border.all(color: AppColors.borderSubtle),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    UpiConfig.vpa,
                    style: AppTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                InkWell(
                  onTap: _copyUpiId,
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.copy_rounded, size: 14, color: Colors.white),
                        const SizedBox(width: 4),
                        Text(
                          'Copy',
                          style: AppTypography.caption.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showNoUpiAppDialog({
    required double amount,
    required String monthKey,
    required String rowId,
  }) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: AppDecorations.radiusLg),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.amberSoft,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.phonelink_erase_rounded, color: AppColors.amberDark, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text('No UPI App Detected', style: AppTypography.h3),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'We couldn\'t find a UPI app (Google Pay, PhonePe, Paytm) installed on this device.',
              style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
            ),
            const SizedBox(height: 14),
            Text(
              'You can copy the School\'s UPI ID below and pay from another phone or device:',
              style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),
            _buildUpiCopyCard(amount: amount),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: AppTypography.button.copyWith(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _paymentService.markSelfReportedPaid(rowId);
              if (!mounted) return;
              _snack('Payment submitted! School admin will confirm shortly.', danger: false);
              setState(() {});
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.emerald,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: AppDecorations.radiusSm),
            ),
            child: const Text('I\'ve Paid (Submit)'),
          ),
        ],
      ),
    );
  }

  void _showPaymentFailedDialog({
    required double amount,
    required String monthKey,
    required String rowId,
    String? reason,
  }) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: AppDecorations.radiusLg),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.danger.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.error_outline_rounded, color: AppColors.danger, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text('Payment Failed', style: AppTypography.h3),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (reason != null && reason.isNotEmpty) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.danger.withValues(alpha: 0.08),
                  borderRadius: AppDecorations.radiusSm,
                  border: Border.all(color: AppColors.danger.withValues(alpha: 0.2)),
                ),
                child: Text(
                  'Reason: $reason',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.danger,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
            Text(
              'If the transaction didn\'t go through, you can try again or transfer manually to the school\'s UPI ID:',
              style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
            ),
            const SizedBox(height: 10),
            _buildUpiCopyCard(amount: amount),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Close', style: AppTypography.button.copyWith(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _paymentService.markSelfReportedPaid(rowId);
              if (!mounted) return;
              _snack('Payment submitted! School admin will verify and confirm.', danger: false);
              setState(() {});
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.emerald,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: AppDecorations.radiusSm),
            ),
            child: const Text('I\'ve Paid Manually'),
          ),
        ],
      ),
    );
  }

  void _showReportManualPaymentModal() {
    final unpaid = _unpaidMonths;
    if (unpaid.isEmpty) {
      _snack('All fees are already cleared!');
      return;
    }

    String month = _selectedMonth ?? unpaid.first;
    final manualAmountController = TextEditingController(text: _amountController.text);
    final utrController = TextEditingController();
    bool submitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (bCtx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.borderSubtle,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Icon(Icons.mark_email_read_rounded, color: AppColors.primary),
                  const SizedBox(width: 10),
                  Text('Submit External Payment', style: AppTypography.h3),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Paid via UPI ID directly, scanned QR, or from another device? Submit details for School Admin verification.',
                style: AppTypography.caption.copyWith(color: AppColors.textMuted),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: month,
                decoration: const InputDecoration(
                  labelText: 'Fee Month',
                  prefixIcon: Icon(Icons.calendar_month_rounded, color: AppColors.primary),
                ),
                items: unpaid
                    .map(
                      (m) => DropdownMenuItem(
                        value: m,
                        child: Text(_formatMonthKey(m)),
                      ),
                    )
                    .toList(),
                onChanged: (v) {
                  if (v != null) setSheetState(() => month = v);
                },
              ),
              const SizedBox(height: 14),
              TextField(
                controller: manualAmountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Amount Paid (₹)',
                  prefixText: '₹ ',
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: utrController,
                decoration: const InputDecoration(
                  labelText: 'UTR / Transaction Ref / Note (Optional)',
                  hintText: 'e.g. 12-digit UTR or GPay Txn ID',
                  prefixIcon: Icon(Icons.tag_rounded, color: AppColors.primary),
                ),
              ),
              const SizedBox(height: 20),
              AppButton(
                label: submitting ? 'Submitting...' : 'Submit for Admin Verification',
                icon: Icons.check_circle_rounded,
                loading: submitting,
                onPressed: submitting
                    ? null
                    : () async {
                        final amt = double.tryParse(manualAmountController.text.trim());
                        if (amt == null || amt <= 0) {
                          _snack('Please enter a valid amount', danger: true);
                          return;
                        }
                        setSheetState(() => submitting = true);
                        try {
                          await _paymentService.submitManualPayment(
                            studentId: widget.profile['id'],
                            studentName: widget.profile['name'] ?? '',
                            monthKey: month,
                            amount: amt,
                            utrOrTxnNote: utrController.text,
                          );
                          if (!ctx.mounted) return;
                          Navigator.pop(ctx);
                          if (!mounted) return;
                          _snack('Payment reported successfully! Admin will confirm soon.', danger: false);
                          setState(() {});
                        } catch (e) {
                          setSheetState(() => submitting = false);
                          _snack('Failed to submit: $e', danger: true);
                        }
                      },
                variant: AppButtonVariant.primary,
                height: 50,
              ),
            ],
          ),
        ),
      ),
    ),
    );
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
    if (_selectedMonth == null || !unpaid.contains(_selectedMonth)) {
      _selectedMonth = unpaid.isNotEmpty ? unpaid.first : null;
    }

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

                const SizedBox(height: 24),

                Row(
                  children: [
                    const Expanded(child: Divider(color: AppColors.borderSubtle)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        'OR PAY VIA UPI ID / QR',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textMuted,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const Expanded(child: Divider(color: AppColors.borderSubtle)),
                  ],
                ),

                const SizedBox(height: 16),

                _buildUpiCopyCard(amount: _amount ?? _monthlyFee),

                const SizedBox(height: 12),

                AppButton(
                  label: 'Already Paid? Submit Confirmation',
                  icon: Icons.check_circle_outline_rounded,
                  onPressed: _showReportManualPaymentModal,
                  variant: AppButtonVariant.outline,
                  height: 48,
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