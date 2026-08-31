import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:strawberry/features/auth/auth_service.dart';
import 'package:strawberry/features/payments/payment_service.dart';

import 'package:strawberry/core/theme/app_colors.dart';
import 'package:strawberry/core/widgets/playschool_animations.dart';

/// Admin-facing screen that tracks every UPI fee payment attempt logged
/// by students — across the whole school, newest first. Lets the admin
/// confirm or reject a payment that isn't already marked "success"
/// (e.g. after checking the bank statement), which mirrors the existing
/// manual "mark fees paid" flow on the student detail page.
class FeePaymentsAdminPage extends StatefulWidget {
  final AuthService authService;

  const FeePaymentsAdminPage({super.key, required this.authService});

  @override
  State<FeePaymentsAdminPage> createState() => _FeePaymentsAdminPageState();
}

class _FeePaymentsAdminPageState extends State<FeePaymentsAdminPage> {
  final _paymentService = PaymentService();
  bool _loading = true;
  List<Map<String, dynamic>> _payments = [];
  String _filter = 'all'; // all | success | pending | failed
  String _search = '';

  static const Color _bg = AppColors.background;
  static const Color _surface = AppColors.surface;
  static const Color _primary = AppColors.primary;
  static const Color _primarySoft = AppColors.primarySoft;
  static const Color _textDark = AppColors.textDark;
  static const Color _textMuted = AppColors.textMuted;
  static const Color _border = AppColors.borderSubtle;
  static const Color _success = AppColors.emerald;
  static const Color _danger = AppColors.danger;
  static const Color _pending = Color(0xFFF5A623);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await _paymentService.getAllPayments();
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

  List<Map<String, dynamic>> get _filtered {
    return _payments.where((p) {
      final status = p['status'] as String? ?? 'initiated';
      final matchesFilter = switch (_filter) {
        'success' => status == 'success',
        'pending' => status == 'initiated' || status == 'submitted',
        'failed' => status == 'failed' || status == 'cancelled',
        _ => true,
      };
      final name = (p['student_name'] ?? '').toString().toLowerCase();
      final matchesSearch = _search.isEmpty || name.contains(_search.toLowerCase());
      return matchesFilter && matchesSearch;
    }).toList();
  }

  double get _totalCollected => _payments
      .where((p) => p['status'] == 'success')
      .fold(0.0, (sum, p) => sum + ((p['amount'] as num?)?.toDouble() ?? 0));

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

  (Color, IconData, String) _statusMeta(String status) {
    switch (status) {
      case 'success':
        return (_success, Icons.check_circle_rounded, 'Success');
      case 'failed':
        return (_danger, Icons.cancel_rounded, 'Failed');
      case 'cancelled':
        return (_danger, Icons.close_rounded, 'Cancelled');
      case 'submitted':
        return (_pending, Icons.hourglass_top_rounded, 'Processing');
      default:
        return (_pending, Icons.schedule_rounded, 'Initiated');
    }
  }

  Future<void> _openActions(Map<String, dynamic> p) async {
    final status = p['status'] as String? ?? 'initiated';
    if (status == 'success') return; // already confirmed, nothing to do

    await showModalBottomSheet(
      context: context,
      backgroundColor: _surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${p['student_name'] ?? 'Student'} · ${_formatMonthKey(p['month_key'] ?? '')}',
                style: const TextStyle(fontWeight: FontWeight.w800, color: _textDark, fontSize: 16),
              ),
              const SizedBox(height: 4),
              Text(
                '₹${(p['amount'] as num?)?.toStringAsFixed(0) ?? '0'} via ${p['upi_app'] ?? 'UPI'}',
                style: const TextStyle(color: _textMuted, fontSize: 13),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () async {
                  Navigator.pop(ctx);
                  await _confirm(p);
                },
                icon: const Icon(Icons.check_circle_rounded),
                label: const Text('Confirm as Paid'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _success,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: () async {
                  Navigator.pop(ctx);
                  await _reject(p);
                },
                icon: const Icon(Icons.cancel_rounded, color: _danger),
                label: const Text('Mark as Failed', style: TextStyle(color: _danger)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: _danger),
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirm(Map<String, dynamic> p) async {
    try {
      await _paymentService.adminConfirmPayment(
        rowId: p['id'],
        studentId: p['student_id'],
        monthKey: p['month_key'],
        authService: widget.authService,
      );
      _snack('Marked as paid for ${p['student_name']}', danger: false);
      _load();
    } catch (e) {
      _snack('Failed to update. Try again.', danger: true);
    }
  }

  Future<void> _reject(Map<String, dynamic> p) async {
    try {
      await _paymentService.adminRejectPayment(p['id']);
      _snack('Marked as failed', danger: false);
      _load();
    } catch (e) {
      _snack('Failed to update. Try again.', danger: true);
    }
  }

  void _snack(String msg, {required bool danger}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: danger ? _danger : _success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _filterChip(String key, String label) {
    final selected = _filter == key;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        showCheckmark: false,
        label: Text(label),
        selected: selected,
        onSelected: (_) => setState(() => _filter = key),
        selectedColor: _primary,
        backgroundColor: _surface,
        labelStyle: TextStyle(
          color: selected ? Colors.white : _textDark,
          fontWeight: FontWeight.w700,
          fontSize: 12.5,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: selected ? _primary : _border),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        foregroundColor: _textDark,
        title: const Text(
          'Fee Payments',
          style: TextStyle(fontWeight: FontWeight.w800, color: _textDark),
        ),
      ),
      body: RefreshIndicator(
        color: _primary,
        onRefresh: _load,
        child: _loading
            ? const StrawberryLoader(message: 'Loading payment records... 💳')
            : LayoutBuilder(
                builder: (context, constraints) {
                  final isDesktop = constraints.maxWidth >= 960;
                  final isTablet = constraints.maxWidth >= 600 && constraints.maxWidth < 960;
                  final horizontalPadding = isDesktop ? 32.0 : (isTablet ? 24.0 : 16.0);

                  return Align(
                    alignment: Alignment.topCenter,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1100),
                      child: ListView(
                        padding: EdgeInsets.fromLTRB(horizontalPadding, 12, horizontalPadding, 32),
                        children: [
                          Container(
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: _primarySoft,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: _border),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: const Icon(Icons.account_balance_wallet_rounded, color: _primary, size: 24),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Total Collected via UPI',
                                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _textMuted),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '₹${_totalCollected.toStringAsFixed(0)}',
                                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: _textDark),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            onChanged: (v) => setState(() => _search = v),
                            style: const TextStyle(color: _textDark),
                            decoration: InputDecoration(
                              hintText: 'Search by student name...',
                              prefixIcon: const Icon(Icons.search_rounded, color: _textMuted),
                              filled: true,
                              fillColor: _surface,
                              contentPadding: const EdgeInsets.symmetric(vertical: 14),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(color: _border),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(color: _primary, width: 1.6),
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                _filterChip('all', 'All'),
                                _filterChip('success', 'Success'),
                                _filterChip('pending', 'Pending'),
                                _filterChip('failed', 'Failed'),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          if (_filtered.isEmpty)
                            const Padding(
                              padding: EdgeInsets.only(top: 60),
                              child: Center(
                                child: Text(
                                  'No payments found',
                                  style: TextStyle(color: _textMuted, fontWeight: FontWeight.w600),
                                ),
                              ),
                            )
                          else if (isDesktop)
                            GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 14,
                                mainAxisSpacing: 14,
                                mainAxisExtent: 110,
                              ),
                              itemCount: _filtered.length,
                              itemBuilder: (context, index) {
                                final p = _filtered[index];
                                final status = p['status'] as String? ?? 'initiated';
                                final (color, icon, label) = _statusMeta(status);
                                final createdAt = DateTime.tryParse(p['created_at'] ?? '')?.toLocal();

                                return InkWell(
                                  borderRadius: BorderRadius.circular(18),
                                  onTap: () => _openActions(p),
                                  child: Container(
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      color: _surface,
                                      borderRadius: BorderRadius.circular(18),
                                      border: Border.all(color: _border),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.02),
                                          blurRadius: 8,
                                          offset: const Offset(0, 3),
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(9),
                                          decoration: BoxDecoration(
                                            color: color.withValues(alpha: 0.12),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Icon(icon, color: color, size: 20),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                p['student_name'] ?? 'Unknown',
                                                style: const TextStyle(fontWeight: FontWeight.w800, color: _textDark, fontSize: 13.5),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                '${_formatMonthKey(p['month_key'] ?? '')} · ${p['upi_app'] ?? 'UPI'}',
                                                style: const TextStyle(fontSize: 11.5, color: _textMuted),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              if (createdAt != null) ...[
                                                const SizedBox(height: 1),
                                                Text(
                                                  DateFormat('d MMM y, h:mm a').format(createdAt),
                                                  style: const TextStyle(fontSize: 10.5, color: _textMuted),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.end,
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              '₹${(p['amount'] as num?)?.toStringAsFixed(0) ?? '0'}',
                                              style: const TextStyle(fontWeight: FontWeight.w900, color: _textDark, fontSize: 14),
                                            ),
                                            const SizedBox(height: 4),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: color.withValues(alpha: 0.12),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Text(
                                                label,
                                                style: TextStyle(
                                                  color: color,
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w800,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            )
                          else
                            ..._filtered.map((p) {
                              final status = p['status'] as String? ?? 'initiated';
                              final (color, icon, label) = _statusMeta(status);
                              final createdAt = DateTime.tryParse(p['created_at'] ?? '')?.toLocal();
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(18),
                                  onTap: () => _openActions(p),
                                  child: Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: _surface,
                                      borderRadius: BorderRadius.circular(18),
                                      border: Border.all(color: _border),
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            color: color.withValues(alpha: 0.12),
                                            borderRadius: BorderRadius.circular(14),
                                          ),
                                          child: Icon(icon, color: color, size: 22),
                                        ),
                                        const SizedBox(width: 14),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                p['student_name'] ?? 'Unknown',
                                                style: const TextStyle(fontWeight: FontWeight.w800, color: _textDark, fontSize: 14.5),
                                              ),
                                              const SizedBox(height: 3),
                                              Text(
                                                '${_formatMonthKey(p['month_key'] ?? '')} · ${p['upi_app'] ?? 'UPI'}',
                                                style: const TextStyle(fontSize: 12, color: _textMuted),
                                              ),
                                              if (createdAt != null) ...[
                                                const SizedBox(height: 2),
                                                Text(
                                                  DateFormat('d MMM y, h:mm a').format(createdAt),
                                                  style: const TextStyle(fontSize: 11, color: _textMuted),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.end,
                                          children: [
                                            Text(
                                              '₹${(p['amount'] as num?)?.toStringAsFixed(0) ?? '0'}',
                                              style: const TextStyle(fontWeight: FontWeight.w800, color: _textDark),
                                            ),
                                            const SizedBox(height: 4),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                              decoration: BoxDecoration(
                                                color: color.withValues(alpha: 0.12),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Text(
                                                label,
                                                style: TextStyle(
                                                  color: color,
                                                  fontSize: 10.5,
                                                  fontWeight: FontWeight.w800,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}