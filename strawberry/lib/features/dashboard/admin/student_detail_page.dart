import 'package:flutter/material.dart';
import 'package:strawberry/features/auth/auth_service.dart';
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

  @override
  void initState() {
    super.initState();
    _student = Map<String, dynamic>.from(widget.student);
    _loadCategories();
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

  List<String> get _paidMonths =>
      List<String>.from((_student['fees_paid_months'] as List?) ?? []);

  // ── Mark month as paid ──────────────────────────────────────────────
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

    // Allow from admission month up to next month (advance payment)
    final endMonth = DateTime(now.year, now.month + 1, 1);

    final List<String> allEligibleMonths = [];
    DateTime cur = endMonth;
    while (!cur.isBefore(startMonth)) {
      final key = '${cur.year}-${cur.month.toString().padLeft(2, '0')}';
      allEligibleMonths.add(key);
      cur = DateTime(cur.year, cur.month - 1, 1);
    }

    // Only show months that haven't been paid yet
    final availableMonths = allEligibleMonths
        .where((m) => !_paidMonths.contains(m))
        .toList();

    if (availableMonths.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          _snack('All fees are already marked as paid up to date!', success: true),
        );
      }
      return;
    }

    String? selected = availableMonths.first;
    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDlg) {
            return AlertDialog(
              backgroundColor: _surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              title: const Text(
                'Mark Month as Paid',
                style: TextStyle(
                  color: _textDark,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Select the month for which fees have been received:',
                    style: TextStyle(color: _textMuted, fontSize: 13),
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    value: selected,
                    dropdownColor: _surface,
                    style: const TextStyle(color: _textDark),
                    decoration: InputDecoration(
                      labelText: 'Month',
                      labelStyle: const TextStyle(color: _textMuted),
                      prefixIcon: const Icon(
                        Icons.calendar_month_rounded,
                        color: _primary,
                        size: 20,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: _border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: _primary,
                          width: 1.6,
                        ),
                      ),
                      filled: true,
                      fillColor: _bg,
                    ),
                    items: availableMonths
                        .map(
                          (m) => DropdownMenuItem(
                            value: m,
                            child: Text(_formatMonthKey(m)),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setDlg(() => selected = v),
                  ),
                ],
              ),
              actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: TextButton.styleFrom(foregroundColor: _textMuted),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                ElevatedButton(
                  onPressed: selected == null
                      ? null
                      : () async {
                          Navigator.pop(ctx);
                          await _markPaid(selected!);
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _success,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Confirm',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _markPaid(String monthKey) async {
    setState(() => _saving = true);
    try {
      await widget.authService.markFeesPaid(_student['id'], monthKey);
      final updated = List<String>.from(_paidMonths);
      if (!updated.contains(monthKey)) updated.add(monthKey);
      updated.sort((a, b) => b.compareTo(a)); // newest first
      setState(() {
        _student['fees_paid_months'] = updated;
        _saving = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          _snack(
            'Fees marked paid for ${_formatMonthKey(monthKey)}',
            success: true,
          ),
        );
      }
    } catch (e) {
      setState(() => _saving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          _snack('Failed to mark fees. Try again.', success: false),
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
                      'Upgrade Student',
                      style: TextStyle(
                        color: _textDark,
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 20),
                    DropdownButtonFormField<String>(
                      value: selectedType,
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
                          Navigator.pop(ctx);
                          await _doUpgrade(type, fees);
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
            );
          },
        );
      },
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

  Future<void> _doUpgrade(String type, double fees) async {
    setState(() => _saving = true);
    try {
      await widget.authService.updateStudent(
        _student['id'],
        studentType: type,
        fees: fees,
      );
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
    final totalPaid = paid.length;

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
                        child: CircleAvatar(
                          radius: 44,
                          backgroundColor: Colors.white,
                          backgroundImage: photoUrl != null
                              ? NetworkImage(photoUrl)
                              : null,
                          child: photoUrl == null
                              ? const Icon(
                                  Icons.person_rounded,
                                  size: 44,
                                  color: _primary,
                                )
                              : null,
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
              if (widget.authService.currentUserEmail ==
                  'dev.harshitcreations@gmail.com')
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
                      const Divider(color: _border, height: 1),
                      _infoRow(
                        icon: Icons.currency_rupee_rounded,
                        label: 'Monthly Fees',
                        value: feesDisplay,
                      ),
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
                  if (paid.isEmpty)
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
                      children: paid.map((m) {
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
                      }).toList(),
                    ),
                  const SizedBox(height: 6),
                  if (paid.isNotEmpty)
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _saving ? null : _openUpgradeSheet,
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        elevation: 3,
        icon: const Icon(Icons.upgrade_rounded),
        label: const Text(
          'Upgrade Student',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
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
