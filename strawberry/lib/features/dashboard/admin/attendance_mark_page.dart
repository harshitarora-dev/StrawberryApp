import 'package:flutter/material.dart';
import 'package:strawberry/features/auth/auth_service.dart';
import 'package:intl/intl.dart';

import 'package:strawberry/core/theme/app_colors.dart';

/// ---------------------------------------------------------------------
/// Design tokens — unified with AppTheme
/// ---------------------------------------------------------------------
class _Palette {
  static const primary = AppColors.primary;
  static const primaryDark = AppColors.primaryDark;
  static const primarySoft = AppColors.primarySoft;

  static const bg = AppColors.background;
  static const surface = AppColors.surface;
  static const border = AppColors.borderSubtle;

  static const textDark = AppColors.textDark;
  static const textMuted = AppColors.textMuted;
  static const textFaint = AppColors.textFaint;

  static const success = AppColors.emerald;
  static const successSoft = AppColors.emeraldSoft;
  static const danger = AppColors.danger;
  static const dangerSoft = AppColors.dangerSoft;
  static const amber = AppColors.amber;
  static const amberSoft = AppColors.amberSoft;
}

class AttendanceMarkPage extends StatefulWidget {
  final AuthService authService;
  const AttendanceMarkPage({super.key, required this.authService});

  @override
  State<AttendanceMarkPage> createState() => _AttendanceMarkPageState();
}

class _AttendanceMarkPageState extends State<AttendanceMarkPage> {
  DateTime? _selectedDate;
  String? _selectedCategory;
  List<Map<String, dynamic>> _students = [];
  Map<String, String> _attendanceStatus = {};
  Map<String, TimeOfDay?> _inTimes = {};
  Map<String, TimeOfDay?> _outTimes = {};
  bool _loading = true;
  bool _saving = false;

  TimeOfDay? _parseTimeString(String? timeStr) {
    if (timeStr == null || timeStr.isEmpty) return null;
    try {
      final parts = timeStr.split(':');
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);
      return TimeOfDay(hour: hour, minute: minute);
    } catch (_) {
      return null;
    }
  }

  String? _formatTimeOfDay(TimeOfDay? time) {
    if (time == null) return null;
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute:00';
  }

  bool _isDaycareCategory(String? category) {
    if (category == null) return false;
    return category.toLowerCase().contains('daycare');
  }

  TimeOfDay _getDefaultInTime(String? category) {
    return _isDaycareCategory(category)
        ? const TimeOfDay(hour: 10, minute: 0)
        : const TimeOfDay(hour: 8, minute: 0);
  }

  TimeOfDay _getDefaultOutTime(String? category) {
    return _isDaycareCategory(category)
        ? const TimeOfDay(hour: 18, minute: 0)
        : const TimeOfDay(hour: 12, minute: 0);
  }

  void _toggleTimesForStudent(String studentId, bool enable, String category) {
    if (enable) {
      _inTimes[studentId] = _getDefaultInTime(category);
      _outTimes[studentId] = _getDefaultOutTime(category);
    } else {
      _inTimes[studentId] = null;
      _outTimes[studentId] = null;
    }
  }

  Future<void> _selectTime(BuildContext context, String studentId, bool isInTime, String category) async {
    final current = isInTime ? _inTimes[studentId] : _outTimes[studentId];
    final initial = current ?? (isInTime ? _getDefaultInTime(category) : _getDefaultOutTime(category));
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
    );
    if (picked != null) {
      setState(() {
        if (isInTime) {
          _inTimes[studentId] = picked;
        } else {
          _outTimes[studentId] = picked;
        }
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  Future<void> _loadStudents() async {
    setState(() => _loading = true);
    try {
      final students = await widget.authService.getAllStudents();
      // Sort students alphabetically by name
      students.sort((a, b) {
        final nameA = (a['name'] as String? ?? '').toLowerCase();
        final nameB = (b['name'] as String? ?? '').toLowerCase();
        return nameA.compareTo(nameB);
      });
      if (!mounted) return;
      setState(() {
        _students = students;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Map<String, dynamic>? _holidayInfo;

  Future<void> _checkHolidayForCurrentSelection() async {
    if (_selectedDate == null || _selectedCategory == null) return;

    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate!);
    final result = await widget.authService.checkHoliday(
      dateStr,
      _selectedCategory!,
    );

    if (!mounted) return;
    setState(() {
      _holidayInfo = result;
    });
  }

  Future<void> _loadExistingAttendance() async {
    if (_selectedDate == null || _selectedCategory == null) return;
    setState(() => _loading = true);
    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate!);
      final records = await widget.authService.getAttendanceForDate(dateStr);
      await _checkHolidayForCurrentSelection();
      if (!mounted) return;
      setState(() {
        _attendanceStatus.clear();
        _inTimes.clear();
        _outTimes.clear();
        final existingMap = {
          for (var r in records) r['student_id'] as String: r
        };
        final filteredStudents = _students.where((s) =>
            (s['student_type'] as String? ?? 'Other') == _selectedCategory).toList();
        for (var s in filteredStudents) {
          final id = s['id'] as String;
          final rec = existingMap[id];
          if (rec != null) {
            _attendanceStatus[id] = rec['status'] as String? ?? 'Present';
            _inTimes[id] = _parseTimeString(rec['in_time'] as String?);
            _outTimes[id] = _parseTimeString(rec['out_time'] as String?);
          } else {
            _attendanceStatus[id] = 'Present';
            _inTimes[id] = null;
            _outTimes[id] = null;
          }
        }
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final earliestAllowedDate = today.subtract(const Duration(days: 7));
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? today,
      firstDate: earliestAllowedDate, // Restrict to 7 days in the past
      lastDate: today, // Restrict to today's date or earlier
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: _Palette.primary,
              onPrimary: Colors.white,
              onSurface: _Palette.textDark,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
      // Date selected, now ask for category
      await _selectCategory();
    }
  }

  Future<void> _selectCategory() async {
    List<String> categories = [];
    try {
      categories = await widget.authService.getCategories();
    } catch (_) {}
    if (categories.isEmpty) {
      categories = _students
          .map((s) => s['student_type'] as String? ?? 'Other')
          .where((c) => c.isNotEmpty)
          .toSet()
          .toList();
      if (categories.isEmpty) {
        categories.addAll(['Playgroup', 'Nursery', 'LKG', 'UKG', 'Tution']);
      }
    }

    if (!mounted) return;
    final selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Select Category',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _Palette.textDark,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Choose the student category to mark attendance for',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _Palette.textMuted,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 20),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: categories.length,
                  itemBuilder: (context, idx) {
                    final cat = categories[idx];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: InkWell(
                        onTap: () => Navigator.pop(context, cat),
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                          decoration: BoxDecoration(
                            color: _Palette.bg,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: _Palette.border),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.class_rounded, color: _Palette.primary, size: 20),
                              const SizedBox(width: 12),
                              Text(
                                  cat,
                                  style: const TextStyle(
                                    color: _Palette.textDark,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              const Spacer(),
                              const Icon(Icons.chevron_right_rounded, color: _Palette.textFaint),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              _buildHolidayBanner(),
            ],
          ),
        );
      },
    );

    if (selected != null) {
      setState(() {
        _selectedCategory = selected;
      });
      await _loadExistingAttendance();
    }
  }

  Future<void> _saveAttendance() async {
    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        _snack('Select a date first', success: false),
      );
      return;
    }
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        _snack('Select a category first', success: false),
      );
      return;
    }
    setState(() => _saving = true);

    // Save attendance only for the filtered category students
    final filteredStudents = _students.where((s) =>
        (s['student_type'] as String? ?? 'Other') == _selectedCategory).toList();

    final entries = filteredStudents
        .map(
          (s) {
            final id = s['id'] as String;
            return {
              'student_id': id,
              'status': _attendanceStatus[id] ?? 'Present',
              'in_time': _formatTimeOfDay(_inTimes[id]),
              'out_time': _formatTimeOfDay(_outTimes[id]),
            };
          },
        )
        .toList();
    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate!);
    try {
      await widget.authService.markAttendance(dateStr, entries);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        _snack('Attendance saved for $_selectedCategory', success: true),
      );
      setState(() {
        _selectedDate = null;
        _selectedCategory = null;
        _attendanceStatus = {};
        _inTimes = {};
        _outTimes = {};
      });
      _loadStudents();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  SnackBar _snack(String message, {required bool success}) {
    return SnackBar(
      content: Text(message, style: const TextStyle(fontWeight: FontWeight.w600)),
      backgroundColor: success ? _Palette.success : _Palette.danger,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
    );
  }

  ({int present, int absent, int late}) get _counts {
    int present = 0, absent = 0, late = 0;
    final filteredIds = _students
        .where((s) => (s['student_type'] as String? ?? 'Other') == _selectedCategory)
        .map((s) => s['id'] as String)
        .toSet();

    for (final entry in _attendanceStatus.entries) {
      if (filteredIds.contains(entry.key)) {
        if (entry.value == 'Present') present++;
        if (entry.value == 'Absent') absent++;
        if (entry.value == 'Late') late++;
      }
    }
    return (present: present, absent: absent, late: late);
  }

  void _markAllAsHoliday() {
    final filteredStudents = _students
        .where((s) => (s['student_type'] as String? ?? 'Other') == _selectedCategory)
        .toList();
    setState(() {
      for (final s in filteredStudents) {
        final id = s['id'] as String;
        _attendanceStatus[id] = 'Holiday';
        _inTimes[id] = null;
        _outTimes[id] = null;
      }
    });
  }

  Widget _buildHolidayBanner() {
    final info = _holidayInfo;
    if (info == null) return const SizedBox.shrink();

    final isHoliday = info['isHoliday'] as bool;
    final isSundayException = info['isSundayException'] as bool;
    final title = info['title'] as String?;

    if (isSundayException) {
      return Container(
        margin: const EdgeInsets.only(top: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _Palette.successSoft,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _Palette.success.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.school_rounded, color: _Palette.success, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '$title — Class scheduled for $_selectedCategory',
                style: const TextStyle(
                  color: _Palette.success,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (!isHoliday) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _Palette.dangerSoft,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _Palette.danger.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.event_busy_rounded, color: _Palette.danger, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '$title — Holiday for $_selectedCategory',
                  style: const TextStyle(
                    color: _Palette.danger,
                    fontWeight: FontWeight.w700,
                    fontSize: 13.5,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, size: 18, color: _Palette.danger),
                onPressed: () => setState(() => _holidayInfo = null),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _Palette.danger,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.check_rounded, size: 16),
                label: const Text('Mark All as Holiday', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                onPressed: _markAllAsHoliday,
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredStudents = _students.where((s) =>
        (s['student_type'] as String? ?? 'Other') == _selectedCategory).toList();

    return Scaffold(
      backgroundColor: _Palette.bg,
      appBar: AppBar(
        title: const Text(
          'Mark Attendance',
          style: TextStyle(color: _Palette.textDark, fontWeight: FontWeight.w800, fontSize: 19),
        ),
        backgroundColor: _Palette.surface,
        surfaceTintColor: Colors.transparent,
        foregroundColor: _Palette.textDark,
        elevation: 0,
        scrolledUnderElevation: 0,
        shape: const Border(bottom: BorderSide(color: _Palette.border, width: 1)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _Palette.primary))
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Date picker button
                      InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: _pickDate,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                          decoration: BoxDecoration(
                            color: _Palette.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: _Palette.border),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.03),
                                blurRadius: 14,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: _Palette.primarySoft,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.calendar_today_rounded,
                                    color: _Palette.primary, size: 18),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Attendance Date',
                                        style: TextStyle(
                                            fontSize: 11.5,
                                            color: _Palette.textMuted,
                                            fontWeight: FontWeight.w600)),
                                    const SizedBox(height: 2),
                                    Text(
                                      _selectedDate == null
                                          ? 'Select a date'
                                          : DateFormat('dd MMM yyyy').format(_selectedDate!),
                                      style: const TextStyle(
                                        fontSize: 15.5,
                                        color: _Palette.textDark,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.chevron_right_rounded, color: _Palette.textFaint),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Category picker button (shows selection state)
                      InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: _selectedDate == null ? null : _selectCategory,
                        child: Opacity(
                          opacity: _selectedDate == null ? 0.6 : 1.0,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                            decoration: BoxDecoration(
                              color: _Palette.surface,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: _Palette.border),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.03),
                                  blurRadius: 14,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: _Palette.primarySoft,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(Icons.class_rounded,
                                      color: _Palette.primary, size: 18),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('Student Category',
                                          style: TextStyle(
                                              fontSize: 11.5,
                                              color: _Palette.textMuted,
                                              fontWeight: FontWeight.w600)),
                                      const SizedBox(height: 2),
                                      Text(
                                        _selectedCategory == null
                                            ? (_selectedDate == null ? 'Select date first' : 'Select a category')
                                            : _selectedCategory!,
                                        style: TextStyle(
                                          fontSize: 15.5,
                                          color: _selectedCategory == null ? _Palette.textMuted : _Palette.textDark,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.chevron_right_rounded, color: _Palette.textFaint),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Quick summary row
                      if (_selectedDate != null && _selectedCategory != null && filteredStudents.isNotEmpty) ...[
                        Row(
                          children: [
                            Expanded(
                              child: _CountChip(
                                label: 'Present',
                                count: _counts.present,
                                color: _Palette.success,
                                bg: _Palette.successSoft,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _CountChip(
                                label: 'Absent',
                                count: _counts.absent,
                                color: _Palette.danger,
                                bg: _Palette.dangerSoft,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _CountChip(
                                label: 'Late',
                                count: _counts.late,
                                color: _Palette.amber,
                                bg: _Palette.amberSoft,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        InkWell(
                          onTap: () {
                            bool anyHaveTimes = filteredStudents.any((s) => _inTimes[s['id']] != null);
                            setState(() {
                              for (var s in filteredStudents) {
                                final id = s['id'] as String;
                                final status = _attendanceStatus[id] ?? 'Present';
                                if (status == 'Present' || status == 'Late') {
                                  _toggleTimesForStudent(id, !anyHaveTimes, s['student_type'] as String? ?? 'Other');
                                }
                              }
                            });
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                            decoration: BoxDecoration(
                              color: _Palette.primarySoft.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: _Palette.border),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.auto_awesome_rounded, size: 16, color: _Palette.primary),
                                const SizedBox(width: 8),
                                Text(
                                  filteredStudents.any((s) => _inTimes[s['id']] != null)
                                      ? 'Clear times for all students'
                                      : 'Set default times for all Present/Late',
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w700,
                                    color: _Palette.primaryDark,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                Expanded(
                  child: (_selectedDate == null || _selectedCategory == null)
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(22),
                                decoration: const BoxDecoration(
                                  color: _Palette.primarySoft,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.event_available_rounded, size: 46, color: _Palette.primary),
                              ),
                              const SizedBox(height: 18),
                              const Text('Setup Attendance',
                                  style: TextStyle(
                                      fontSize: 17, color: _Palette.textDark, fontWeight: FontWeight.w800)),
                              const SizedBox(height: 6),
                              Text(
                                  _selectedDate == null
                                      ? 'Choose a date to begin'
                                      : 'Select student category next',
                                  style: const TextStyle(
                                      fontSize: 13.5, color: _Palette.textMuted, fontWeight: FontWeight.w500)),
                            ],
                          ),
                        )
                      : filteredStudents.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(22),
                                    decoration: BoxDecoration(
                                      color: _Palette.textFaint.withValues(alpha: 0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.groups_rounded, size: 46, color: _Palette.textFaint),
                                  ),
                                  const SizedBox(height: 16),
                                  Text('No Students in $_selectedCategory',
                                      style: const TextStyle(
                                          fontSize: 16.5, color: _Palette.textDark, fontWeight: FontWeight.w700)),
                                ],
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                              itemCount: filteredStudents.length,
                              itemBuilder: (context, index) {
                                final student = filteredStudents[index];
                                final id = student['id'] as String;
                                final name = student['name'] as String? ?? 'Student';
                                final type = student['student_type'] as String? ?? 'Unknown';
                                final status = _attendanceStatus[id] ?? 'Present';

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 10),
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: _Palette.surface,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: _Palette.border),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.03),
                                        blurRadius: 12,
                                        offset: const Offset(0, 5),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          const CircleAvatar(
                                            radius: 19,
                                            backgroundColor: _Palette.bg,
                                            child: Icon(Icons.person_rounded, color: _Palette.textMuted, size: 18),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(name,
                                                    style: const TextStyle(
                                                        fontSize: 15,
                                                        fontWeight: FontWeight.w700,
                                                        color: _Palette.textDark)),
                                                const SizedBox(height: 2),
                                                Text(type,
                                                    style: const TextStyle(
                                                        fontSize: 12.5,
                                                        color: _Palette.textMuted,
                                                        fontWeight: FontWeight.w500)),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      _StatusSegmented(
                                        value: status,
                                        onChanged: (val) {
                                          setState(() {
                                            _attendanceStatus[id] = val;
                                            if (val == 'Absent') {
                                              _inTimes[id] = null;
                                              _outTimes[id] = null;
                                            }
                                          });
                                        },
                                      ),
                                      if (status == 'Present' || status == 'Late') ...[
                                        const Padding(
                                          padding: EdgeInsets.symmetric(vertical: 8.0),
                                          child: Divider(color: _Palette.border, height: 1),
                                        ),
                                        Row(
                                          children: [
                                            SizedBox(
                                              width: 24,
                                              height: 24,
                                              child: Checkbox(
                                                value: _inTimes[id] != null,
                                                activeColor: _Palette.primary,
                                                onChanged: (val) {
                                                  setState(() {
                                                    _toggleTimesForStudent(id, val ?? false, type);
                                                  });
                                                },
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: GestureDetector(
                                                onTap: () {
                                                  setState(() {
                                                    final val = _inTimes[id] == null;
                                                    _toggleTimesForStudent(id, val, type);
                                                  });
                                                },
                                                child: const Text(
                                                  'Specify check-in/out times',
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w600,
                                                    color: _Palette.textDark,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        if (_inTimes[id] != null && _outTimes[id] != null) ...[
                                          const SizedBox(height: 10),
                                          Row(
                                            children: [
                                              Expanded(
                                                child: InkWell(
                                                  onTap: () => _selectTime(context, id, true, type),
                                                  borderRadius: BorderRadius.circular(10),
                                                  child: Container(
                                                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                                                    decoration: BoxDecoration(
                                                      color: _Palette.bg,
                                                      border: Border.all(color: _Palette.border),
                                                      borderRadius: BorderRadius.circular(10),
                                                    ),
                                                    child: Row(
                                                      children: [
                                                        const Icon(Icons.login_rounded, size: 14, color: _Palette.success),
                                                        const SizedBox(width: 8),
                                                        Expanded(
                                                          child: Column(
                                                            crossAxisAlignment: CrossAxisAlignment.start,
                                                            children: [
                                                              const Text(
                                                                'In Time',
                                                                style: TextStyle(fontSize: 10, color: _Palette.textMuted, fontWeight: FontWeight.w600),
                                                              ),
                                                              const SizedBox(height: 2),
                                                              Text(
                                                                _inTimes[id]!.format(context),
                                                                style: const TextStyle(fontSize: 13, color: _Palette.textDark, fontWeight: FontWeight.w700),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 10),
                                              Expanded(
                                                child: InkWell(
                                                  onTap: () => _selectTime(context, id, false, type),
                                                  borderRadius: BorderRadius.circular(10),
                                                  child: Container(
                                                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                                                    decoration: BoxDecoration(
                                                      color: _Palette.bg,
                                                      border: Border.all(color: _Palette.border),
                                                      borderRadius: BorderRadius.circular(10),
                                                    ),
                                                    child: Row(
                                                      children: [
                                                        const Icon(Icons.logout_rounded, size: 14, color: _Palette.danger),
                                                        const SizedBox(width: 8),
                                                        Expanded(
                                                          child: Column(
                                                            crossAxisAlignment: CrossAxisAlignment.start,
                                                            children: [
                                                              const Text(
                                                                'Out Time',
                                                                style: TextStyle(fontSize: 10, color: _Palette.textMuted, fontWeight: FontWeight.w600),
                                                              ),
                                                              const SizedBox(height: 2),
                                                              Text(
                                                                _outTimes[id]!.format(context),
                                                                style: const TextStyle(fontSize: 13, color: _Palette.textDark, fontWeight: FontWeight.w700),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ],
                                    ],
                                  ),
                                );
                              },
                            ),
                ),

                // Save button
                if (_selectedDate != null && _selectedCategory != null && filteredStudents.isNotEmpty)
                  Container(
                    padding: EdgeInsets.fromLTRB(
                      16, 12, 16, MediaQuery.of(context).padding.bottom + 12,
                    ),
                    decoration: BoxDecoration(
                      color: _Palette.surface,
                      border: const Border(top: BorderSide(color: _Palette.border)),
                    ),
                    child: SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _saving ? null : _saveAttendance,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _Palette.primary,
                          disabledBackgroundColor: _Palette.primary.withValues(alpha: 0.6),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: _saving
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.4,
                                ),
                              )
                            : const Text('Save Attendance',
                                style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}

/// Small pill showing a live count for a status, matching card palette.
class _CountChip extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  final Color bg;

  const _CountChip({
    required this.label,
    required this.count,
    required this.color,
    required this.bg,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Text('$count',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: color)),
          const SizedBox(height: 2),
          Text(label,
              style: TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w600, color: color.withValues(alpha: 0.85))),
        ],
      ),
    );
  }
}

/// Segmented Present / Absent / Late selector — replaces the old dropdown
/// with a tappable, color-coded control that fits the playful theme.
class _StatusSegmented extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;

  const _StatusSegmented({required this.value, required this.onChanged});

  static const _options = [
    ('Present', Icons.check_circle_rounded, _Palette.success, _Palette.successSoft),
    ('Absent', Icons.cancel_rounded, _Palette.danger, _Palette.dangerSoft),
    ('Late', Icons.schedule_rounded, _Palette.amber, _Palette.amberSoft),
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: _options.map((opt) {
        final (label, icon, color, bg) = opt;
        final selected = value == label;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: label == 'Late' ? 0 : 8),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => onChanged(label),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(vertical: 9),
                decoration: BoxDecoration(
                  color: selected ? bg : _Palette.bg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: selected ? color.withValues(alpha: 0.4) : _Palette.border,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, size: 17, color: selected ? color : _Palette.textFaint),
                    const SizedBox(height: 3),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: selected ? color : _Palette.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}