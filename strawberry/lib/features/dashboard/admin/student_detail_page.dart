import 'package:flutter/material.dart';
import 'package:strawberry/features/auth/auth_service.dart';
import 'package:strawberry/features/payments/fee_service.dart';
import 'package:strawberry/features/payments/fee_head_field.dart';
import 'package:strawberry/core/widgets/student_avatar.dart';
import 'package:strawberry/features/dashboard/admin/student_attendance_history_page.dart';

import 'package:strawberry/core/theme/app_colors.dart';
import 'package:strawberry/core/widgets/playschool_animations.dart';

/// Full-screen admin detail page for a student
class StudentDetailPage extends StatefulWidget {
  final Map<String, dynamic> student;
  final AuthService authService;

  const StudentDetailPage({
    super.key,
    required this.student,
    required this.authService,
  });

  @override
  State<StudentDetailPage> createState() => _StudentDetailPageState();
}

class _StudentDetailPageState extends State<StudentDetailPage> {
  late Map<String, dynamic> _student;
  bool _saving = false;

  // ── Palette (mirrors AppTheme tokens) ──────────────────────────
  static const _primary = AppColors.primary;
  static const _primarySoft = AppColors.primarySoft;
  static const _primaryDark = AppColors.primaryDark;
  static const _accentPeach = AppColors.primaryLight;
  static const _bg = AppColors.background;
  static const _surface = AppColors.surface;
  static const _border = AppColors.borderSubtle;
  static const _textDark = AppColors.textDark;
  static const _textMuted = AppColors.textMuted;
  static const _success = AppColors.emerald;
  static const _danger = AppColors.danger;

  List<String> _categories = [];
  final FeeService _feeService = FeeService();
  List<FeeItem> _feeItems = [];
  bool _loadingFeeItems = false;

  @override
  void initState() {
    super.initState();
    _student = Map<String, dynamic>.from(widget.student);
    _loadCategories();
    _loadFeeItems();
  }

  Future<void> _loadCategories() async {
    try {
      final cats = await widget.authService.getCategories();
      if (!mounted) return;
      setState(() {
        _categories = cats;
      });
    } catch (e) {
      // Ignore
    }
  }

  Future<void> _loadFeeItems() async {
    setState(() => _loadingFeeItems = true);
    try {
      final items = await _feeService.getStudentFeeItems(_student['id']?.toString() ?? '');
      if (mounted) {
        setState(() {
          _feeItems = items;
          _loadingFeeItems = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingFeeItems = false);
    }
  }

  List<String> get _paidMonths =>
      List<String>.from((_student['fees_paid_months'] as List?) ?? []);

  // ── Mark fee as paid (Tuition and/or Custom Fee items) ───────────────
  Future<void> _showMarkFeeDialog() async {
    final now = DateTime.now();
    DateTime startMonth;
    final createdAtStr = _student['created_at'] as String?;
    if (createdAtStr != null && createdAtStr.isNotEmpty) {
      final parsed = DateTime.tryParse(createdAtStr);
      if (parsed != null) {
        startMonth = DateTime(parsed.year, parsed.month, 1);
      } else {
        startMonth = DateTime(now.year, now.month, 1);
      }
    } else {
      startMonth = DateTime(now.year, now.month, 1);
    }

    final endMonth = DateTime(now.year, now.month + 1, 1);
    final List<String> allEligibleMonths = [];
    DateTime cur = endMonth;
    while (!cur.isBefore(startMonth)) {
      final key = '${cur.year}-${cur.month.toString().padLeft(2, '0')}';
      allEligibleMonths.add(key);
      cur = DateTime(cur.year, cur.month - 1, 1);
    }

    final availableMonths = allEligibleMonths
        .where((m) => !_paidMonths.contains(m))
        .toList();
    final pendingFeeItems = _feeItems.where((item) => item.isPending).toList();

    if (availableMonths.isEmpty && pendingFeeItems.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          _snack('All fees and dues are already marked as paid!', success: true),
        );
      }
      return;
    }

    final Set<String> selectedMonths = {};
    if (availableMonths.isNotEmpty) {
      selectedMonths.add(availableMonths.first);
    }
    final Set<String> selectedItemIds = {};
    String selectedMode = 'Cash';
    final refController = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDlg) {
            final isPrimary = AuthService.isPrimaryAdmin(widget.authService.currentUserEmail);
            return AlertDialog(
              backgroundColor: _surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              title: const Text(
                'Mark Payment Received',
                style: TextStyle(
                  color: _textDark,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Select the dues for which payment has been received:',
                        style: TextStyle(color: _textMuted, fontSize: 12.5),
                      ),
                      const SizedBox(height: 14),

                      // Section 1: Monthly Tuition
                      if (availableMonths.isNotEmpty) ...[
                        const Text(
                          'Monthly Tuition',
                          style: TextStyle(
                            color: _primaryDark,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 6),
                        ...availableMonths.take(4).map((m) {
                          final isChecked = selectedMonths.contains(m);
                          final feeAmt = _student['fees'];
                          final feeSuffix = (isPrimary && feeAmt != null) ? ' (₹${(feeAmt as num).toInt()})' : '';
                          return CheckboxListTile(
                            contentPadding: EdgeInsets.zero,
                            dense: true,
                            activeColor: _primary,
                            value: isChecked,
                            title: Text(
                              '${_formatMonthKey(m)}$feeSuffix',
                              style: const TextStyle(fontSize: 13.5, color: _textDark, fontWeight: FontWeight.w600),
                            ),
                            onChanged: (val) {
                              setDlg(() {
                                if (val == true) {
                                  selectedMonths.add(m);
                                } else {
                                  selectedMonths.remove(m);
                                }
                              });
                            },
                          );
                        }),
                        const SizedBox(height: 10),
                      ],

                      // Section 2: Custom Fee Items (Picnic, Admission, Uniform, etc.)
                      if (pendingFeeItems.isNotEmpty) ...[
                        const Text(
                          'Configured Fee Heads',
                          style: TextStyle(
                            color: _primaryDark,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 6),
                        ...pendingFeeItems.map((item) {
                          final isChecked = selectedItemIds.contains(item.id);
                          final typeLabel = item.feeType == 'one_time'
                              ? 'One-Time'
                              : (item.feeType == 'annual' ? 'Annual' : 'Monthly');
                          return CheckboxListTile(
                            contentPadding: EdgeInsets.zero,
                            dense: true,
                            activeColor: _primary,
                            value: isChecked,
                            title: Text(
                              item.title,
                              style: const TextStyle(fontSize: 13.5, color: _textDark, fontWeight: FontWeight.w600),
                            ),
                            subtitle: Text(
                              isPrimary
                                  ? '$typeLabel • ₹${item.amount.toStringAsFixed(0)}'
                                  : typeLabel,
                              style: const TextStyle(fontSize: 11.5, color: _textMuted),
                            ),
                            onChanged: (val) {
                              setDlg(() {
                                if (val == true) {
                                  selectedItemIds.add(item.id);
                                } else {
                                  selectedItemIds.remove(item.id);
                                }
                              });
                            },
                          );
                        }),
                        const SizedBox(height: 10),
                      ],

                      // Payment Mode
                      const Divider(color: _border),
                      const SizedBox(height: 6),
                      const Text(
                        'Payment Mode',
                        style: TextStyle(color: _textMuted, fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String>(
                        initialValue: selectedMode,
                        dropdownColor: _surface,
                        style: const TextStyle(color: _textDark, fontSize: 13.5),
                        decoration: _inputDecor(
                          label: 'Received Via',
                          icon: Icons.payments_rounded,
                        ),
                        items: const [
                          DropdownMenuItem(value: 'Cash', child: Text('Cash')),
                          DropdownMenuItem(value: 'UPI', child: Text('UPI / QR')),
                          DropdownMenuItem(value: 'Bank Transfer', child: Text('Bank Transfer')),
                        ],
                        onChanged: (v) => setDlg(() => selectedMode = v ?? 'Cash'),
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: refController,
                        style: const TextStyle(color: _textDark, fontSize: 13),
                        decoration: _inputDecor(
                          label: 'Receipt / Reference (Optional)',
                          icon: Icons.tag_rounded,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: TextButton.styleFrom(foregroundColor: _textMuted),
                  child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.w600)),
                ),
                ElevatedButton(
                  onPressed: (selectedMonths.isEmpty && selectedItemIds.isEmpty)
                      ? null
                      : () async {
                          Navigator.pop(ctx);
                          await _processMarkPaid(
                            months: selectedMonths.toList(),
                            itemIds: selectedItemIds.toList(),
                            paymentMode: selectedMode,
                            refNote: refController.text.trim(),
                          );
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _success,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Confirm Received', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _processMarkPaid({
    required List<String> months,
    required List<String> itemIds,
    required String paymentMode,
    String? refNote,
  }) async {
    setState(() => _saving = true);
    try {
      for (final m in months) {
        await widget.authService.markFeesPaid(_student['id'], m);
      }
      for (final id in itemIds) {
        await _feeService.markFeeItemPaid(
          id,
          paidVia: paymentMode,
          txnRef: refNote?.isNotEmpty == true ? refNote : null,
        );
      }

      final updated = List<String>.from(_paidMonths);
      for (final m in months) {
        if (!updated.contains(m)) updated.add(m);
      }
      updated.sort((a, b) => b.compareTo(a));

      setState(() {
        _student['fees_paid_months'] = updated;
        _saving = false;
      });
      await _loadFeeItems();

      if (mounted) {
        final totalCount = months.length + itemIds.length;
        ScaffoldMessenger.of(context).showSnackBar(
          _snack('Marked $totalCount item(s) as paid via $paymentMode', success: true),
        );
      }
    } catch (e) {
      setState(() => _saving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          _snack('Failed to mark payment: $e', success: false),
        );
      }
    }
  }

  Future<void> _unmarkPaid(String monthKey) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Remove Payment?',
          style: TextStyle(color: _textDark, fontWeight: FontWeight.w800),
        ),
        content: Text(
          'Remove payment record for ${_formatMonthKey(monthKey)}?',
          style: const TextStyle(color: _textMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: _textMuted)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: _danger,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirm != true) return;
    setState(() => _saving = true);
    try {
      await widget.authService.unmarkFeesPaid(_student['id'], monthKey);
      final updated = List<String>.from(_paidMonths)..remove(monthKey);
      setState(() {
        _student['fees_paid_months'] = updated;
        _saving = false;
      });
    } catch (e) {
      setState(() => _saving = false);
    }
  }

  Future<void> _unmarkFeeItemPaid(FeeItem item) async {
    final isPrimary = AuthService.isPrimaryAdmin(widget.authService.currentUserEmail);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Remove Payment?',
          style: TextStyle(color: _textDark, fontWeight: FontWeight.w800),
        ),
        content: Text(
          isPrimary
              ? 'Remove paid record for ${item.title} (₹${item.amount.toInt()}) and set back to pending?'
              : 'Remove paid record for ${item.title} and set back to pending?',
          style: const TextStyle(color: _textMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: _textMuted)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: _danger,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirm != true) return;
    setState(() => _saving = true);
    try {
      await _feeService.unmarkFeeItemPaid(item.id);
      await _loadFeeItems();
      setState(() => _saving = false);
    } catch (e) {
      setState(() => _saving = false);
    }
  }

  void _openAttendanceHistory() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => StudentAttendanceHistoryPage(
          student: _student,
          authService: widget.authService,
        ),
      ),
    );
  }

  // ── Upgrade student sheet ────────────────────────────────────────────
  void _openUpgradeSheet() {
    if (!AuthService.isPrimaryAdmin(widget.authService.currentUserEmail)) {
      return;
    }
    String? selectedType = _student['student_type'] as String?;

    // Ensure the current category is represented in the dropdown selection, even if it was deleted.
    List<String> dropdownItems = List.from(_categories);
    if (selectedType != null &&
        selectedType.isNotEmpty &&
        !dropdownItems.contains(selectedType)) {
      dropdownItems.add(selectedType);
    }

    final feesController = TextEditingController(
      text: (_student['fees'] ?? 0).toString(),
    );
    bool chargeAdmissionFee = false;
    final admissionTitleController = TextEditingController(text: 'Admission Fee (Upgrade)');
    final admissionAmountController = TextEditingController(text: '1000');
    String admissionFeeType = 'one_time';
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheet) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
                top: 12,
                left: 24,
                right: 24,
              ),
              child: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          margin: const EdgeInsets.only(bottom: 18),
                          decoration: BoxDecoration(
                            color: _border,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                      const Text(
                        'Upgrade Student',
                        style: TextStyle(
                          color: _textDark,
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 20),
                      DropdownButtonFormField<String>(
                        initialValue: selectedType,
                        dropdownColor: _surface,
                        style: const TextStyle(color: _textDark, fontSize: 15),
                        decoration: _inputDecor(
                          label: 'Student Type',
                          icon: Icons.school_rounded,
                        ),
                        items: dropdownItems.map((cat) {
                          return DropdownMenuItem<String>(
                            value: cat,
                            child: Text(cat),
                          );
                        }).toList(),
                        onChanged: (v) => setSheet(() => selectedType = v),
                        validator: (v) =>
                            (v == null || v.isEmpty) ? 'Select type' : null,
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: feesController,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(color: _textDark),
                        decoration: _inputDecor(
                          label: 'Monthly Fees (₹)',
                          icon: Icons.currency_rupee_rounded,
                        ),
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Enter fees' : null,
                      ),
                      const SizedBox(height: 16),

                      // Optional Admission/Upgrade fee toggle
                      Container(
                        decoration: BoxDecoration(
                          color: _bg,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: _border),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Charge Admission / Upgrade Fee',
                                        style: TextStyle(
                                          color: _textDark,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 13.5,
                                        ),
                                      ),
                                      Text(
                                        'Charge for category upgrade (exceptions: leave off)',
                                        style: TextStyle(
                                          color: _textMuted.withValues(alpha: 0.8),
                                          fontSize: 11.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Switch(
                                  value: chargeAdmissionFee,
                                  activeThumbColor: _primary,
                                  onChanged: (val) => setSheet(() => chargeAdmissionFee = val),
                                ),
                              ],
                            ),
                            if (chargeAdmissionFee) ...[
                              const SizedBox(height: 10),
                              FeeHeadField(
                                controller: admissionTitleController,
                                labelText: 'Fee Title',
                                fontSize: 13.5,
                                borderRadius: 14,
                                borderColor: _border,
                                textColor: _textDark,
                                primaryColor: _primary,
                                fillColor: _surface,
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      controller: admissionAmountController,
                                      keyboardType: TextInputType.number,
                                      style: const TextStyle(color: _textDark, fontSize: 13.5),
                                      decoration: _inputDecor(
                                        label: 'Amount (₹)',
                                        icon: Icons.currency_rupee_rounded,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: DropdownButtonFormField<String>(
                                      initialValue: admissionFeeType,
                                      dropdownColor: _surface,
                                      style: const TextStyle(color: _textDark, fontSize: 13),
                                      decoration: _inputDecor(
                                        label: 'Frequency',
                                        icon: Icons.repeat_rounded,
                                      ),
                                      items: const [
                                        DropdownMenuItem(value: 'one_time', child: Text('One-Time')),
                                        DropdownMenuItem(value: 'annual', child: Text('Annual')),
                                      ],
                                      onChanged: (v) => setSheet(() => admissionFeeType = v ?? 'one_time'),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 22),
                      SizedBox(
                        height: 52,
                        child: ElevatedButton(
                          onPressed: () async {
                            if (!formKey.currentState!.validate()) return;
                            final type = selectedType!;
                            final fees =
                                double.tryParse(feesController.text.trim()) ??
                                0.0;
                            Map<String, dynamic>? extra;
                            if (chargeAdmissionFee) {
                              final admAmt = double.tryParse(admissionAmountController.text.trim()) ?? 0.0;
                              if (admAmt > 0) {
                                final now = DateTime.now();
                                extra = {
                                  'title': admissionTitleController.text.trim().isNotEmpty
                                      ? admissionTitleController.text.trim()
                                      : 'Admission Fee',
                                  'fee_type': admissionFeeType,
                                  'amount': admAmt,
                                  'period_key': admissionFeeType == 'annual'
                                      ? '${now.year}-${(now.year + 1).toString().substring(2)}'
                                      : 'ONE_TIME',
                                };
                              }
                            }
                            Navigator.pop(ctx);
                            await _doUpgrade(type, fees, extraFeeItem: extra);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _primary,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                          child: const Text(
                            'Save Changes',
                            style: TextStyle(
                              fontSize: 15.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ── Add Ad-Hoc / Custom Fee Item (Picnic, Uniform, Books, etc.) ───────
  void _openAddFeeItemSheet() {
    if (!AuthService.isPrimaryAdmin(widget.authService.currentUserEmail)) return;

    final titleController = TextEditingController();
    final amountController = TextEditingController();
    String feeType = 'one_time';
    DateTime? dueDate;
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheet) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
                top: 12,
                left: 24,
                right: 24,
              ),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 18),
                        decoration: BoxDecoration(
                          color: _border,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    const Text(
                      'Add Custom Fee Item',
                      style: TextStyle(
                        color: _textDark,
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Add ad-hoc charges like Picnic, Uniform, Annual Charges, Books, etc.',
                      style: TextStyle(
                        color: _textMuted.withValues(alpha: 0.8),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 20),
                    FeeHeadField(
                      controller: titleController,
                      labelText: 'Fee Title (e.g. Picnic, Uniform, Exam Fee)',
                      fontSize: 14,
                      borderRadius: 14,
                      borderColor: _border,
                      textColor: _textDark,
                      primaryColor: _primary,
                      fillColor: _surface,
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Enter fee title' : null,
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: amountController,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(color: _textDark),
                            decoration: _inputDecor(
                              label: 'Amount (₹)',
                              icon: Icons.currency_rupee_rounded,
                            ),
                            validator: (v) =>
                                (v == null || v.trim().isEmpty) ? 'Enter amount' : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: feeType,
                            dropdownColor: _surface,
                            style: const TextStyle(color: _textDark, fontSize: 13.5),
                            decoration: _inputDecor(
                              label: 'Frequency',
                              icon: Icons.repeat_rounded,
                            ),
                            items: const [
                              DropdownMenuItem(value: 'one_time', child: Text('One-Time')),
                              DropdownMenuItem(value: 'annual', child: Text('Annual')),
                              DropdownMenuItem(value: 'monthly', child: Text('Monthly')),
                            ],
                            onChanged: (v) => setSheet(() => feeType = v ?? 'one_time'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.event_rounded, color: _primary),
                      title: Text(
                        dueDate == null
                            ? 'Set Optional Due Date'
                            : 'Due: ${dueDate!.day}/${dueDate!.month}/${dueDate!.year}',
                        style: const TextStyle(color: _textDark, fontSize: 13.5),
                      ),
                      trailing: TextButton(
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: ctx,
                            initialDate: dueDate ?? DateTime.now().add(const Duration(days: 7)),
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                          );
                          if (picked != null) setSheet(() => dueDate = picked);
                        },
                        child: Text(dueDate == null ? 'Pick' : 'Change'),
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () async {
                          if (!formKey.currentState!.validate()) return;
                          final amt = double.tryParse(amountController.text.trim()) ?? 0.0;
                          final title = titleController.text.trim();
                          Navigator.pop(ctx);
                          final now = DateTime.now();
                          final period = feeType == 'monthly'
                              ? '${now.year}-${now.month.toString().padLeft(2, '0')}'
                              : (feeType == 'annual'
                                  ? '${now.year}-${(now.year + 1).toString().substring(2)}'
                                  : 'ONE_TIME');
                          await _feeService.addFeeItem(
                            studentId: _student['id']?.toString() ?? '',
                            title: title,
                            feeType: feeType,
                            amount: amt,
                            periodKey: period,
                            dueDate: dueDate,
                            createdBy: widget.authService.currentUserEmail,
                          );
                          await _loadFeeItems();
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              _snack('Added fee: $title (₹${amt.toStringAsFixed(0)})', success: true),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: const Text('Add Fee Item', style: TextStyle(fontWeight: FontWeight.w700)),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFeeItemTile(FeeItem item) {
    final typeLabel = item.feeType == 'one_time'
        ? 'One-Time'
        : (item.feeType == 'annual' ? 'Annual' : 'Monthly');
    final isPrimary = AuthService.isPrimaryAdmin(widget.authService.currentUserEmail);

    Color statusColor = AppColors.amber;
    String statusText = 'Pending';
    if (item.isPaid) {
      statusColor = _success;
      statusText = item.paidVia != null ? 'Paid (${item.paidVia})' : 'Paid';
    } else if (item.isWaived) {
      statusColor = _textMuted;
      statusText = 'Waived';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              item.isPaid ? Icons.check_circle_rounded : Icons.label_important_rounded,
              color: statusColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: _textDark,
                        ),
                      ),
                    ),
                    Text(
                      '₹${item.amount.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: _textDark,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: _bg,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: _border),
                      ),
                      child: Text(
                        typeLabel,
                        style: const TextStyle(fontSize: 11, color: _textMuted, fontWeight: FontWeight.w600),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        statusText,
                        style: TextStyle(
                          fontSize: 11,
                          color: statusColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (item.dueDate != null) ...[
                      const SizedBox(width: 8),
                      Text(
                        'Due: ${item.dueDate!.day}/${item.dueDate!.month}',
                        style: const TextStyle(fontSize: 11, color: _textMuted),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          if (isPrimary && !item.isPaid) ...[
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert_rounded, color: _textMuted, size: 20),
              color: _surface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              onSelected: (action) async {
                if (action == 'pay') {
                  await _feeService.markFeeItemPaid(item.id, paidVia: 'Cash');
                  await _loadFeeItems();
                } else if (action == 'waive') {
                  await _feeService.updateFeeItem(item.id, {'status': 'waived'});
                  await _loadFeeItems();
                } else if (action == 'delete') {
                  await _feeService.deleteFeeItem(item.id);
                  await _loadFeeItems();
                }
              },
              itemBuilder: (ctx) => [
                const PopupMenuItem(
                  value: 'pay',
                  child: Row(
                    children: [
                      Icon(Icons.check_rounded, color: _success, size: 18),
                      SizedBox(width: 8),
                      Text('Mark Paid (Cash)'),
                    ],
                  ),
                ),
                if (!item.isWaived)
                  const PopupMenuItem(
                    value: 'waive',
                    child: Row(
                      children: [
                        Icon(Icons.block_rounded, color: _textMuted, size: 18),
                        SizedBox(width: 8),
                        Text('Waive Fee'),
                      ],
                    ),
                  ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline_rounded, color: _danger, size: 18),
                      SizedBox(width: 8),
                      Text('Delete Item', style: TextStyle(color: _danger)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _removeStudent() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Remove Student?',
          style: TextStyle(color: _textDark, fontWeight: FontWeight.w800),
        ),
        content: Text(
          'Are you sure you want to permanently remove ${_student['name']}?\n\nThis will delete all their attendance records, chat messages, and student account details. This action cannot be undone.',
          style: const TextStyle(color: _textMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: _textMuted)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: _danger,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirm != true) return;
    setState(() => _saving = true);
    try {
      await widget.authService.removeStudent(_student['id']);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          _snack('Successfully removed ${_student['name']}', success: true),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() => _saving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          _snack('Failed to remove student. Try again.', success: false),
        );
      }
    }
  }

  Future<void> _doUpgrade(
    String type,
    double fees, {
    Map<String, dynamic>? extraFeeItem,
  }) async {
    setState(() => _saving = true);
    try {
      await widget.authService.updateStudent(
        _student['id'],
        studentType: type,
        fees: fees,
      );
      if (extraFeeItem != null) {
        await _feeService.addFeeItem(
          studentId: _student['id']?.toString() ?? '',
          title: extraFeeItem['title'] ?? 'Admission Fee',
          feeType: extraFeeItem['fee_type'] ?? 'one_time',
          amount: (extraFeeItem['amount'] as num).toDouble(),
          periodKey: extraFeeItem['period_key'] ?? 'ONE_TIME',
          createdBy: widget.authService.currentUserEmail,
        );
        await _loadFeeItems();
      }
      setState(() {
        _student['student_type'] = type;
        _student['fees'] = fees;
        _saving = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(_snack('Student updated successfully!', success: true));
      }
    } catch (e) {
      setState(() => _saving = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(_snack('Update failed. Try again.', success: false));
      }
    }
  }

  // ── Helpers ──────────────────────────────────────────────────────────
  String _formatMonthKey(String key) {
    // "2024-07" → "July 2024"
    final parts = key.split('-');
    if (parts.length != 2) return key;
    final months = [
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
    final m = int.tryParse(parts[1]) ?? 0;
    return '${months[m]} ${parts[0]}';
  }

  static InputDecoration _inputDecor({
    required String label,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: _textMuted, fontSize: 14),
      prefixIcon: Icon(icon, color: _primary, size: 20),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: _border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: _primary, width: 1.6),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: _danger),
      ),
      filled: true,
      fillColor: _bg,
    );
  }

  static SnackBar _snack(String msg, {required bool success}) {
    return SnackBar(
      content: Row(
        children: [
          Icon(
            success ? Icons.check_circle_rounded : Icons.error_rounded,
            color: Colors.white,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              msg,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
      backgroundColor: success ? _success : _danger,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      margin: const EdgeInsets.all(16),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final name = _student['name'] ?? 'Student';
    final email = _student['email'] ?? '';
    final photoUrl = _student['photo_url'] as String?;
    final type = _student['student_type'] ?? '—';
    final fees = _student['fees'];
    final feesDisplay = fees != null
        ? '₹${fees.toStringAsFixed(0)}/month'
        : '—';
    final paid = _paidMonths..sort((a, b) => b.compareTo(a));
    final paidFeeItems = _feeItems.where((i) => i.isPaid).toList();
    final totalPaid = paid.length + paidFeeItems.length;

    return Scaffold(
      backgroundColor: _bg,
      body: CustomScrollView(
        slivers: [
          // ── App bar with photo ───────────────────────────────────────
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            backgroundColor: _surface,
            foregroundColor: _textDark,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            scrolledUnderElevation: 0,
            shape: const Border(bottom: BorderSide(color: _border, width: 1)),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [_primary, _accentPeach],
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 40),
                      // Profile photo
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.3),
                        ),
                        child: StudentAvatar(
                          photoUrl: photoUrl,
                          name: name,
                          size: 88,
                          fontSize: 34,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        type,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              if (AuthService.isPrimaryAdmin(widget.authService.currentUserEmail))
                IconButton(
                  icon: const Icon(
                    Icons.delete_outline_rounded,
                    color: Colors.white,
                  ),
                  tooltip: 'Remove Student',
                  onPressed: _saving ? null : _removeStudent,
                ),
              if (_saving)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: BtnLoader(),
                ),
            ],
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Attendance History ───────────────────────────────
                  _sectionTitle('Attendance'),
                  const SizedBox(height: 10),
                  InkWell(
                    onTap: _openAttendanceHistory,
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: _border),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: _primarySoft,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.calendar_month_rounded,
                              color: _primary,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 14),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Attendance History',
                                  style: TextStyle(
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w700,
                                    color: _textDark,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'View calendar, present/absent/late days & percentage',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: _textMuted,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.chevron_right_rounded,
                            color: _textMuted,
                            size: 22,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── Contact Info ────────────────────────────────────
                  _sectionTitle('Contact Info'),
                  const SizedBox(height: 10),
                  _infoCard(
                    children: [
                      _infoRow(
                        icon: Icons.email_rounded,
                        label: 'Email',
                        value: email.isEmpty ? '—' : email,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // ── Academic Info ───────────────────────────────────
                  _sectionTitle('Academic Info'),
                  const SizedBox(height: 10),
                  _infoCard(
                    children: [
                      _infoRow(
                        icon: Icons.school_rounded,
                        label: 'Category',
                        value: type,
                      ),
                      if (AuthService.isPrimaryAdmin(widget.authService.currentUserEmail)) ...[
                        const Divider(color: _border, height: 1),
                        _infoRow(
                          icon: Icons.currency_rupee_rounded,
                          label: 'Monthly Fees',
                          value: feesDisplay,
                        ),
                      ],
                      const Divider(color: _border, height: 1),
                      _infoRow(
                        icon: Icons.receipt_long_rounded,
                        label: 'Months Paid',
                        value: '$totalPaid month${totalPaid == 1 ? '' : 's'}',
                        valueColor: _success,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // ── Configured Fee Heads (Primary Admin only) ───────
                  if (AuthService.isPrimaryAdmin(widget.authService.currentUserEmail)) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _sectionTitle('Configured Fee Heads'),
                        GestureDetector(
                          onTap: _saving ? null : _openAddFeeItemSheet,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: _primarySoft,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Row(
                              children: [
                                Icon(
                                  Icons.add_rounded,
                                  color: _primaryDark,
                                  size: 16,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'Add Fee Item',
                                  style: TextStyle(
                                    color: _primaryDark,
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    if (_loadingFeeItems)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: CircularProgressIndicator(strokeWidth: 2, color: _primary),
                        ),
                      )
                    else if (_feeItems.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: _surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: _border),
                        ),
                        child: const Center(
                          child: Text(
                            'No custom fee items added (e.g. Picnic, Uniform, Books).\nTap + Add Fee Item to add extra charges.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: _textMuted, fontSize: 13),
                          ),
                        ),
                      )
                    else
                      Column(
                        children: _feeItems.map((item) => _buildFeeItemTile(item)).toList(),
                      ),
                    const SizedBox(height: 20),
                  ],

                  // ── Fees Payment History ─────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _sectionTitle('Payment History'),
                      GestureDetector(
                        onTap: _saving ? null : _showMarkFeeDialog,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: _primarySoft,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Row(
                            children: [
                              Icon(
                                Icons.add_rounded,
                                color: _primaryDark,
                                size: 16,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Mark Paid',
                                style: TextStyle(
                                  color: _primaryDark,
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (paid.isEmpty && paidFeeItems.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: _surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: _border),
                      ),
                      child: const Center(
                        child: Text(
                          'No payment records yet.',
                          style: TextStyle(color: _textMuted, fontSize: 14),
                        ),
                      ),
                    )
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        // Paid tuition months
                        ...paid.map((m) {
                          return GestureDetector(
                            onLongPress: () => _unmarkPaid(m),
                            child: Chip(
                              label: Text(_formatMonthKey(m)),
                              backgroundColor: _success.withValues(alpha: 0.1),
                              labelStyle: const TextStyle(
                                color: _success,
                                fontWeight: FontWeight.w600,
                                fontSize: 12.5,
                              ),
                              avatar: const Icon(
                                Icons.check_circle_rounded,
                                color: _success,
                                size: 16,
                              ),
                              deleteIcon: const Icon(
                                Icons.close_rounded,
                                size: 14,
                                color: _textMuted,
                              ),
                              onDeleted: () => _unmarkPaid(m),
                              side: BorderSide(color: _success.withValues(alpha: 0.3)),
                            ),
                          );
                        }),
                        // Paid custom fee items
                        ...paidFeeItems.map((item) {
                          final isPrimary = AuthService.isPrimaryAdmin(widget.authService.currentUserEmail);
                          return GestureDetector(
                            onLongPress: () => _unmarkFeeItemPaid(item),
                            child: Chip(
                              label: Text(
                                isPrimary
                                    ? '${item.title} (₹${item.amount.toInt()})'
                                    : item.title,
                              ),
                              backgroundColor: _primarySoft,
                              labelStyle: const TextStyle(
                                color: _primaryDark,
                                fontWeight: FontWeight.w600,
                                fontSize: 12.5,
                              ),
                              avatar: const Icon(
                                Icons.verified_rounded,
                                color: _primary,
                                size: 16,
                              ),
                              deleteIcon: const Icon(
                                Icons.close_rounded,
                                size: 14,
                                color: _textMuted,
                              ),
                              onDeleted: () => _unmarkFeeItemPaid(item),
                              side: BorderSide(color: _primary.withValues(alpha: 0.3)),
                            ),
                          );
                        }),
                      ],
                    ),
                  const SizedBox(height: 6),
                  if (paid.isNotEmpty || paidFeeItems.isNotEmpty)
                    Text(
                      'Long-press or tap ✕ on a chip to remove a payment record.',
                      style: TextStyle(
                        color: _textMuted.withValues(alpha: 0.7),
                        fontSize: 11.5,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),

      // ── Floating Upgrade button ──────────────────────────────────────
      floatingActionButton: AuthService.isPrimaryAdmin(widget.authService.currentUserEmail)
          ? FloatingActionButton.extended(
              onPressed: _saving ? null : _openUpgradeSheet,
              backgroundColor: _primary,
              foregroundColor: Colors.white,
              elevation: 3,
              icon: const Icon(Icons.upgrade_rounded),
              label: const Text(
                'Upgrade Student',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            )
          : null,
    );
  }

  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w800,
        color: _textDark,
        letterSpacing: 0.1,
      ),
    );
  }

  Widget _infoCard({required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: Column(children: children),
    );
  }

  Widget _infoRow({
    required IconData icon,
    required String label,
    required String value,
    Color valueColor = _textDark,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _primarySoft,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: _primary, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: _textMuted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: valueColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
