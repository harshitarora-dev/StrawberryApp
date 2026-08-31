import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:strawberry/features/auth/auth_service.dart';
import 'package:excel/excel.dart' hide Border;
import 'package:file_saver/file_saver.dart';
import 'package:share_plus/share_plus.dart';

import 'package:strawberry/core/theme/app_colors.dart';
import 'package:strawberry/core/widgets/playschool_animations.dart';

/// Admin "Review & Analysis" dashboard.
/// - Total students / new admissions this month
/// - Category-wise student breakdown
/// - Day-wise present/absent/late summary (pick any date)
/// - Attendance trend across the selected month
class ReviewAnalyticsPage extends StatefulWidget {
  final AuthService authService;
  const ReviewAnalyticsPage({super.key, required this.authService});

  @override
  State<ReviewAnalyticsPage> createState() => _ReviewAnalyticsPageState();
}

class _ReviewAnalyticsPageState extends State<ReviewAnalyticsPage> {
  // ── Palette ──────────────────────────────────────────────────────────
  static const _primary = AppColors.primary;
  static const _primaryDark = AppColors.primaryDark;
  static const _primarySoft = AppColors.primarySoft;
  static const _accentPeach = AppColors.primaryLight;
  static const _violet = AppColors.violet;
  static const _blueAccent = AppColors.sky;

  static const _bg = AppColors.background;
  static const _surface = AppColors.surface;
  static const _border = AppColors.borderSubtle;
  static const _textDark = AppColors.textDark;
  static const _textMuted = AppColors.textMuted;

  static const _success = AppColors.emerald;
  static const _successSoft = AppColors.emeraldSoft;
  static const _amber = AppColors.amber;
  static const _amberSoft = AppColors.amberSoft;
  static const _danger = AppColors.danger;
  static const _dangerSoft = AppColors.dangerSoft;

  bool _loading = true;
  bool _exporting = false;
  String? _error;

  List<Map<String, dynamic>> _students = [];
  List<Map<String, dynamic>> _monthAttendance = []; // for _visibleMonth
  List<Map<String, dynamic>> _monthHolidays = []; // holiday rows for _visibleMonth
  DateTime _visibleMonth = DateTime(DateTime.now().year, DateTime.now().month);
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final firstDay = DateTime(_visibleMonth.year, _visibleMonth.month, 1);
      final lastDay = DateTime(_visibleMonth.year, _visibleMonth.month + 1, 0);

      final results = await Future.wait([
        widget.authService.getAllStudents(),
        widget.authService.getAttendanceInRange(start: firstDay, end: lastDay),
        widget.authService.getHolidaysForMonth(_visibleMonth.year, _visibleMonth.month),
      ]);

      if (!mounted) return;
      setState(() {
        _students = results[0];
        _monthAttendance = results[1];
        _monthHolidays = results[2];
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to load analytics. Pull down to retry.';
        _loading = false;
      });
    }
  }

  bool _changingMonth = false;

  Future<void> _changeMonth(int delta) async {
    final newMonth = DateTime(_visibleMonth.year, _visibleMonth.month + delta);
    final daysInNewMonth = DateTime(newMonth.year, newMonth.month + 1, 0).day;
    final clampedDay = _selectedDate.day.clamp(1, daysInNewMonth);
    var newSelectedDate = DateTime(newMonth.year, newMonth.month, clampedDay);

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    if (newSelectedDate.isAfter(today)) {
      newSelectedDate = today;
    }

    setState(() {
      _visibleMonth = newMonth;
      _selectedDate = newSelectedDate;
      _changingMonth = true;
    });

    try {
      final firstDay = DateTime(newMonth.year, newMonth.month, 1);
      final lastDay = DateTime(newMonth.year, newMonth.month + 1, 0);

      final results = await Future.wait([
        widget.authService.getAttendanceInRange(start: firstDay, end: lastDay),
        widget.authService.getHolidaysForMonth(newMonth.year, newMonth.month),
      ]);

      if (!mounted) return;
      setState(() {
        _monthAttendance = results[0];
        _monthHolidays = results[1];
        _changingMonth = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _changingMonth = false;
      });
    }
  }

  // ── Derived: overview ────────────────────────────────────────────────
  int get _totalStudents => _students.length;

  int get _newThisMonth {
    final now = DateTime.now();
    return _students.where((s) {
      final created = DateTime.tryParse(s['created_at']?.toString() ?? '');
      if (created == null) return false;
      return created.year == now.year && created.month == now.month;
    }).length;
  }

  Map<String, int> get _categoryBreakdown {
    final map = <String, int>{};
    for (final s in _students) {
      final cat = (s['student_type'] as String?)?.trim();
      final key = (cat == null || cat.isEmpty) ? 'Uncategorized' : cat;
      map[key] = (map[key] ?? 0) + 1;
    }
    return map;
  }

  // ── Derived: selected date breakdown ─────────────────────────────────
  String get _selectedDateKey => DateFormat('yyyy-MM-dd').format(_selectedDate);

  /// Returns true if the given date is a holiday for ANY category
  /// (Sunday by default, Saturday for LKG/Nursery/Playgroup/UKG, or explicit DB holiday)
  bool _isDateHoliday(DateTime date) {
    if (date.weekday == DateTime.sunday) return true;
    final dateStr = DateFormat('yyyy-MM-dd').format(date);
    // Check explicit holiday in DB (type='holiday')
    final dbHol = _monthHolidays.any(
      (h) => h['date']?.toString() == dateStr && h['type'] == 'holiday',
    );
    if (dbHol) return true;
    // Saturday for small categories
    if (date.weekday == DateTime.saturday) {
      return _monthHolidays.any(
        (h) =>
            h['date']?.toString() == dateStr &&
            h['type'] == 'holiday' &&
            widget.authService.isSaturdayDefaultHoliday(h['category']?.toString() ?? ''),
      ) ||
      // If no specific category override, treat Saturday as holiday for those categories
      // but in Review Analytics we check all categories — if any LKG/Nursery/Playgroup/UKG student exists, Saturday is holiday
      _students.any((s) => widget.authService.isSaturdayDefaultHoliday(
            (s['student_type'] as String?) ?? ''));
    }
    return false;
  }

  String? _holidayTitleForDate(DateTime date) {
    if (date.weekday == DateTime.sunday) return 'Sunday';
    if (date.weekday == DateTime.saturday &&
        _students.any((s) => widget.authService
            .isSaturdayDefaultHoliday((s['student_type'] as String?) ?? ''))) {
      return 'Saturday';
    }
    final dateStr = DateFormat('yyyy-MM-dd').format(date);
    final h = _monthHolidays.firstWhere(
      (h) => h['date']?.toString() == dateStr && h['type'] == 'holiday',
      orElse: () => {},
    );
    return h.isEmpty ? null : h['title'] as String?;
  }

  Map<String, int> get _selectedDateStats {
    int p = 0, a = 0, l = 0;
    for (final r in _monthAttendance) {
      if (r['date']?.toString() != _selectedDateKey) continue;
      switch (r['status']?.toString()) {
        case 'Present':
          p++;
          break;
        case 'Absent':
          a++;
          break;
        case 'Late':
          l++;
          break;
      }
    }
    final marked = p + a + l;
    // Holiday wale din notMarked = 0 (misleading nahi hoga)
    final isHol = _isDateHoliday(_selectedDate);
    final notMarked = isHol ? 0 : (_totalStudents - marked).clamp(0, _totalStudents);
    return {'present': p, 'absent': a, 'late': l, 'notMarked': notMarked};
  }

  // ── Derived: month-long trend (% attended per day that has records) ──
  List<MapEntry<int, double>> get _monthTrend {
    final byDay = <int, List<String>>{};
    for (final r in _monthAttendance) {
      final d = DateTime.tryParse(r['date']?.toString() ?? '');
      if (d == null) continue;
      byDay.putIfAbsent(d.day, () => []).add(r['status']?.toString() ?? '');
    }
    final entries = byDay.entries.map((e) {
      final statuses = e.value;
      final attended =
          statuses.where((s) => s == 'Present' || s == 'Late').length;
      final pct = statuses.isEmpty ? 0.0 : (attended / statuses.length) * 100;
      return MapEntry(e.key, pct);
    }).toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    return entries;
  }

  Future<void> _pickDate() async {
    final firstDay = DateTime(_visibleMonth.year, _visibleMonth.month, 1);
    final lastDayOfVisibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month + 1, 0);

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Effective last selectable date cannot exceed today nor the visible month's end
    DateTime effectiveLastDate = lastDayOfVisibleMonth.isAfter(today) ? today : lastDayOfVisibleMonth;
    if (effectiveLastDate.isBefore(firstDay)) {
      effectiveLastDate = firstDay;
    }

    // Effective initial date must be strictly clamped between firstDay and effectiveLastDate
    DateTime effectiveInitialDate = _selectedDate;
    if (effectiveInitialDate.isBefore(firstDay)) {
      effectiveInitialDate = firstDay;
    } else if (effectiveInitialDate.isAfter(effectiveLastDate)) {
      effectiveInitialDate = effectiveLastDate;
    }

    final picked = await showDatePicker(
      context: context,
      initialDate: effectiveInitialDate,
      firstDate: firstDay,
      lastDate: effectiveLastDate,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: _primary,
              onPrimary: Colors.white,
              onSurface: _textDark,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  String _formatTimeShort(String timeStr) {
    try {
      final parts = timeStr.split(':');
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);
      final minStr = minute.toString().padLeft(2, '0');
      return '${hour.toString().padLeft(2, '0')}:$minStr';
    } catch (_) {
      return timeStr;
    }
  }

  // ── Build the month-wise attendance Excel bytes (no I/O side-effects) ─
  Future<({Uint8List bytes, String fileName})> _buildMonthExcel() async {
    final daysInMonth =
          DateTime(_visibleMonth.year, _visibleMonth.month + 1, 0).day;
      final monthFileLabel = DateFormat('MMMM_yyyy').format(_visibleMonth);

      // studentId -> day -> record, built from the currently loaded month's
      // attendance records.
      final Map<String, Map<int, Map<String, dynamic>>> byStudent = {};
      for (final r in _monthAttendance) {
        final sid = r['student_id']?.toString();
        final dateStr = r['date']?.toString();
        if (sid == null || dateStr == null) continue;
        final d = DateTime.tryParse(dateStr);
        if (d == null) continue;
        byStudent.putIfAbsent(sid, () => {})[d.day] = r;
      }

      final sortedStudents = List<Map<String, dynamic>>.from(_students)
        ..sort((a, b) => ((a['name'] as String?) ?? '')
            .toLowerCase()
            .compareTo(((b['name'] as String?) ?? '').toLowerCase()));

      final excel = Excel.createExcel();
      final originalDefaultSheet = excel.getDefaultSheet();

      // ── Sheet 1: per-student, per-day grid ───────────────────────────
      final detail = excel['Attendance Detail'];
      final header = <CellValue>[
        TextCellValue('Student Name'),
        TextCellValue('Category'),
      ];
      for (int d = 1; d <= daysInMonth; d++) {
        header.add(TextCellValue('$d'));
      }
      header.addAll([
        TextCellValue('Present'),
        TextCellValue('Absent'),
        TextCellValue('Late'),
        TextCellValue('Attendance %'),
      ]);
      detail.appendRow(header);

      for (final s in sortedStudents) {
        final sid = s['id'] as String;
        final name = (s['name'] as String?) ?? 'Student';
        final category = (s['student_type'] as String?) ?? '—';
        final dayMap = byStudent[sid] ?? {};

        int p = 0, a = 0, l = 0;
        final row = <CellValue>[TextCellValue(name), TextCellValue(category)];
        for (int d = 1; d <= daysInMonth; d++) {
          final date = DateTime(_visibleMonth.year, _visibleMonth.month, d);
          final dateStr = DateFormat('yyyy-MM-dd').format(date);
          final rec = dayMap[d];
          final status = rec?['status']?.toString();
          final inTime = rec?['in_time']?.toString();
          final outTime = rec?['out_time']?.toString();

          // Check if this day is a holiday for this student's category
          final isSun = date.weekday == DateTime.sunday;
          final isSatForCat = date.weekday == DateTime.saturday &&
              widget.authService.isSaturdayDefaultHoliday(category);
          final hasWorkingDayOverride = _monthHolidays.any(
            (h) => h['date']?.toString() == dateStr &&
                h['type'] == 'working_day' &&
                (h['category'] == category || h['category'] == 'All'),
          );
          final isDbHoliday = _monthHolidays.any(
            (h) => h['date']?.toString() == dateStr &&
                h['type'] == 'holiday' &&
                (h['category'] == 'All' || h['category'] == category),
          );
          final isHoliday = (isSun || isSatForCat || isDbHoliday) && !hasWorkingDayOverride;

          String cellVal = '-';
          if (isHoliday && status == null) {
            // No attendance marked and it's a holiday — label it
            final holTitle = isSun
                ? 'Sunday'
                : isSatForCat
                    ? 'Saturday'
                    : (_monthHolidays.firstWhere(
                            (h) =>
                                h['date']?.toString() == dateStr &&
                                h['type'] == 'holiday',
                            orElse: () => {})['title'] as String?) ??
                        'Holiday';
            cellVal = 'H — $holTitle';
          } else if (status == 'Present') {
            p++;
            if (inTime != null || outTime != null) {
              final inStr = inTime != null ? _formatTimeShort(inTime) : '--';
              final outStr = outTime != null ? _formatTimeShort(outTime) : '--';
              cellVal = 'P ($inStr - $outStr)';
            } else {
              cellVal = 'P';
            }
          } else if (status == 'Absent') {
            a++;
            cellVal = 'A';
          } else if (status == 'Late') {
            l++;
            if (inTime != null || outTime != null) {
              final inStr = inTime != null ? _formatTimeShort(inTime) : '--';
              final outStr = outTime != null ? _formatTimeShort(outTime) : '--';
              cellVal = 'L ($inStr - $outStr)';
            } else {
              cellVal = 'L';
            }
          } else if (status == 'Holiday') {
            cellVal = 'H';
          }
          row.add(TextCellValue(cellVal));
        }
        final marked = p + a + l;
        final pct = marked == 0 ? 0.0 : ((p + l) / marked) * 100;
        row.addAll([
          IntCellValue(p),
          IntCellValue(a),
          IntCellValue(l),
          DoubleCellValue(double.parse(pct.toStringAsFixed(1))),
        ]);
        detail.appendRow(row);
      }

      // ── Sheet 2: day-wise summary across all students ────────────────
      final summary = excel['Daily Summary'];
      summary.appendRow([
        TextCellValue('Date'),
        TextCellValue('Holiday'),
        TextCellValue('Present'),
        TextCellValue('Absent'),
        TextCellValue('Late'),
        TextCellValue('Attendance %'),
      ]);
      for (int d = 1; d <= daysInMonth; d++) {
        int p = 0, a = 0, l = 0;
        for (final entry in byStudent.values) {
          final rec = entry[d];
          final status = rec?['status']?.toString();
          if (status == 'Present') p++;
          if (status == 'Absent') a++;
          if (status == 'Late') l++;
        }
        final marked = p + a + l;
        final pct = marked == 0 ? 0.0 : ((p + l) / marked) * 100;
        final date = DateTime(_visibleMonth.year, _visibleMonth.month, d);
        final holTitle = _holidayTitleForDate(date);
        final dateStr = DateFormat('yyyy-MM-dd').format(date);
        final isHoliday = holTitle != null ||
            _monthHolidays.any((h) =>
                h['date']?.toString() == dateStr && h['type'] == 'holiday');
        summary.appendRow([
          TextCellValue(DateFormat('d MMM yyyy').format(date)),
          TextCellValue(isHoliday ? (holTitle ?? 'Holiday') : ''),
          IntCellValue(p),
          IntCellValue(a),
          IntCellValue(l),
          DoubleCellValue(double.parse(pct.toStringAsFixed(1))),
        ]);
      }

      // ── Sheet 3: Detailed check-in/out log ─────────────────────────────
      final logSheet = excel['Detailed Log'];
      logSheet.appendRow([
        TextCellValue('Student Name'),
        TextCellValue('Category'),
        TextCellValue('Date'),
        TextCellValue('Status'),
        TextCellValue('Check-in Time'),
        TextCellValue('Check-out Time'),
      ]);
      for (final s in sortedStudents) {
        final sid = s['id'] as String;
        final name = (s['name'] as String?) ?? 'Student';
        final category = (s['student_type'] as String?) ?? '—';
        final dayMap = byStudent[sid] ?? {};
        for (int d = 1; d <= daysInMonth; d++) {
          final rec = dayMap[d];
          if (rec == null) continue;
          final date = DateTime(_visibleMonth.year, _visibleMonth.month, d);
          final status = rec['status']?.toString() ?? '—';
          final inTime = rec['in_time']?.toString() ?? '—';
          final outTime = rec['out_time']?.toString() ?? '—';
          logSheet.appendRow([
            TextCellValue(name),
            TextCellValue(category),
            TextCellValue(DateFormat('dd MMM yyyy').format(date)),
            TextCellValue(status),
            TextCellValue(inTime != '—' ? _formatTimeShort(inTime) : '—'),
            TextCellValue(outTime != '—' ? _formatTimeShort(outTime) : '—'),
          ]);
        }
      }

      // Drop the blank default sheet Excel.createExcel() ships with.
      if (originalDefaultSheet != 'Attendance Detail' &&
          originalDefaultSheet != 'Daily Summary' &&
          originalDefaultSheet != 'Detailed Log') {
        excel.delete(originalDefaultSheet!);
      }
      excel.setDefaultSheet('Attendance Detail');

      final bytes = excel.encode();
      if (bytes == null) {
        throw Exception('Could not generate the Excel file.');
      }

      final fileName = 'Attendance_$monthFileLabel';
      return (bytes: Uint8List.fromList(bytes), fileName: fileName);
  }

  void _showSnack(String message, {required bool success}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(children: [
          Icon(
            success ? Icons.check_circle_rounded : Icons.error_outline_rounded,
            color: Colors.white,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(message,
                style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
        ]),
        backgroundColor: success ? _success : _danger,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  // ── Download the Excel file — lets the user pick a visible location ──
  // ── Download the Excel file — lets the user pick a visible location ──
  Future<void> _downloadMonthExcel() async {
    if (_exporting) return;
    setState(() => _exporting = true);
    try {
      final (:bytes, :fileName) = await _buildMonthExcel();

      if (kIsWeb) {
        await FileSaver.instance.saveFile(
          name: fileName,
          bytes: bytes,
          ext: 'xlsx',
          mimeType: MimeType.microsoftExcel,
        );
        if (!mounted) return;
        setState(() => _exporting = false);
        _showSnack('$fileName.xlsx downloaded successfully', success: true);
        return;
      }

      final savedPath = await FileSaver.instance.saveAs(
        name: fileName,
        bytes: bytes,
        ext: 'xlsx',
        mimeType: MimeType.other,
      );
      if (!mounted) return;
      setState(() => _exporting = false);

      if (savedPath == null || savedPath.isEmpty) {
        // User backed out of the save dialog — not an error.
        return;
      }
      _showSnack('$fileName.xlsx saved successfully', success: true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _exporting = false);
      _showSnack('Failed to download: $e', success: false);
    }
  }

  // ── Share the Excel file via WhatsApp / Email / Drive / etc. ────────
  Future<void> _shareMonthExcel() async {
    if (_exporting) return;
    setState(() => _exporting = true);
    try {
      final (:bytes, :fileName) = await _buildMonthExcel();

      if (kIsWeb) {
        final result = await SharePlus.instance.share(
          ShareParams(
            files: [
              XFile.fromData(
                bytes,
                mimeType:
                    'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
                name: '$fileName.xlsx',
              ),
            ],
            subject: '$fileName Attendance Report',
            text: 'Attendance report for $fileName',
          ),
        );
        if (!mounted) return;
        setState(() => _exporting = false);
        if (result.status == ShareResultStatus.success && mounted) {
          _showSnack('$fileName.xlsx shared successfully', success: true);
        }
        return;
      }

      // Share plugins on Android & iOS need a real file path, so we write
      // the bytes to the app's temp directory first, then hand that off
      // to the native share sheet.
      final tempDir = await getTemporaryDirectory();
      final filePath = '${tempDir.path}/$fileName.xlsx';
      final file = File(filePath);
      await file.writeAsBytes(bytes, flush: true);

      if (!mounted) return;
      setState(() => _exporting = false);

      final result = await SharePlus.instance.share(
        ShareParams(
          files: [
            XFile(
              filePath,
              mimeType:
                  'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
              name: '$fileName.xlsx',
            ),
          ],
          subject: '$fileName Attendance Report',
          text: 'Attendance report for $fileName',
        ),
      );

      if (result.status == ShareResultStatus.success && mounted) {
        _showSnack('$fileName.xlsx shared successfully', success: true);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _exporting = false);
      _showSnack('Failed to share: $e', success: false);
    }
  }

  // ── Bottom sheet: let the user pick Download or Share ────────────────
  void _showExportOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: _surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 18),
                    decoration: BoxDecoration(
                      color: _border,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const Text('Export Attendance',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w800, color: _textDark)),
                const SizedBox(height: 4),
                const Text('Choose how you want to get this month\'s report.',
                    style: TextStyle(fontSize: 12.5, color: _textMuted)),
                const SizedBox(height: 16),
                _ExportOptionTile(
                  icon: Icons.download_rounded,
                  iconColor: _blueAccent,
                  title: 'Download to device',
                  subtitle: 'Pick a folder (e.g. Downloads) to save the file',
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    _downloadMonthExcel();
                  },
                ),
                if (!kIsWeb) ...[
                  const SizedBox(height: 10),
                  _ExportOptionTile(
                    icon: Icons.share_rounded,
                    iconColor: _primaryDark,
                    title: 'Share',
                    subtitle: 'Send via WhatsApp, Email, Drive, etc.',
                    onTap: () {
                      Navigator.of(sheetContext).pop();
                      _shareMonthExcel();
                    },
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _surface,
        foregroundColor: _textDark,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        shape: const Border(bottom: BorderSide(color: _border, width: 1)),
        title: const Text('Review & Analysis',
            style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.w800, color: _textDark)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: _exporting
                ? const Padding(
                    padding: EdgeInsets.all(14),
                    child: BtnLoader(color: _primary, dotSize: 5),
                  )
                : IconButton(
                    icon: const Icon(Icons.file_download_rounded, color: _primaryDark),
                    tooltip: kIsWeb ? 'Download this month as Excel' : 'Download or share this month as Excel',
                    onPressed: _loading ? null : (kIsWeb ? _downloadMonthExcel : _showExportOptions),
                  ),
          ),
        ],
      ),
      body: _loading
          ? const StrawberryLoader(message: 'Crunching school analytics... 📊')
          : _error != null
              ? _ErrorState(message: _error!, onRetry: _loadAll)
              : RefreshIndicator(
                  onRefresh: _loadAll,
                  color: _primary,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final isDesktop = constraints.maxWidth >= 900;
                      final isTablet = constraints.maxWidth >= 600 && constraints.maxWidth < 900;
                      final horizontalPadding = isDesktop ? 32.0 : (isTablet ? 24.0 : 16.0);

                      return Align(
                        alignment: Alignment.topCenter,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 1100),
                          child: ListView(
                            padding: EdgeInsets.fromLTRB(horizontalPadding, 18, horizontalPadding, 40),
                            children: isDesktop
                                ? [
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          flex: 5,
                                          child: Column(
                                            children: [
                                              _buildOverviewCards(),
                                              const SizedBox(height: 20),
                                              _buildCategoryBreakdown(),
                                              const SizedBox(height: 20),
                                              _buildDateSelector(),
                                              const SizedBox(height: 12),
                                              _buildDateBreakdown(),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 20),
                                        Expanded(
                                          flex: 5,
                                          child: _buildMonthTrend(),
                                        ),
                                      ],
                                    ),
                                  ]
                                : [
                                    _buildOverviewCards(),
                                    const SizedBox(height: 26),
                                    _buildCategoryBreakdown(),
                                    const SizedBox(height: 26),
                                    _buildDateSelector(),
                                    const SizedBox(height: 12),
                                    _buildDateBreakdown(),
                                    const SizedBox(height: 26),
                                    _buildMonthTrend(),
                                  ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }

  // ── Section: overview cards ──────────────────────────────────────────
  Widget _buildOverviewCards() {
    return Row(
      children: [
        Expanded(
          child: _OverviewCard(
            label: 'Total Students',
            value: '$_totalStudents',
            icon: Icons.school_rounded,
            color: _blueAccent,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _OverviewCard(
            label: 'New This Month',
            value: '$_newThisMonth',
            icon: Icons.person_add_alt_1_rounded,
            color: _success,
          ),
        ),
      ],
    );
  }

  // ── Section: category breakdown ──────────────────────────────────────
  Widget _buildCategoryBreakdown() {
    final data = _categoryBreakdown;
    final total = _totalStudents == 0 ? 1 : _totalStudents;
    final colors = [_primary, _violet, _blueAccent, _amber, _success, _accentPeach];
    final entries = data.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Students by Category',
              style: TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w800, color: _textDark)),
          const SizedBox(height: 14),
          if (entries.isEmpty)
            const Text('No students yet.',
                style: TextStyle(color: _textMuted, fontSize: 13))
          else
            ...entries.asMap().entries.map((e) {
              final idx = e.key;
              final cat = e.value.key;
              final count = e.value.value;
              final pct = count / total;
              final color = colors[idx % colors.length];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(cat,
                            style: const TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w700, color: _textDark)),
                        Text('$count',
                            style: TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w800, color: color)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: pct,
                        minHeight: 8,
                        backgroundColor: _bg,
                        valueColor: AlwaysStoppedAnimation(color),
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  // ── Section: date selector ───────────────────────────────────────────
  Widget _buildDateSelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Day-wise Attendance',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: _textDark,
          ),
        ),
        InkWell(
          onTap: _pickDate,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: _primarySoft,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today_rounded,
                    size: 14, color: _primaryDark),
                const SizedBox(width: 6),
                Text(
                  DateFormat('d MMM, yyyy').format(_selectedDate),
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: _primaryDark,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── Section: date breakdown ──────────────────────────────────────────
  Widget _buildDateBreakdown() {
    final stats = _selectedDateStats;
    final marked = stats['present']! + stats['absent']! + stats['late']!;
    final pct = marked == 0
        ? 0.0
        : ((stats['present']! + stats['late']!) / marked) * 100;
    final isHol = _isDateHoliday(_selectedDate);
    final holTitle = _holidayTitleForDate(_selectedDate);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Holiday banner
          if (isHol) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(
                color: _violet.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _violet.withValues(alpha: 0.30)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.beach_access_rounded,
                      size: 16, color: _violet),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      holTitle != null
                          ? 'Holiday — $holTitle'
                          : 'This day is a holiday',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: _violet,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          Row(
            children: [
              Expanded(
                child: _MiniStat(
                    label: 'Present', value: stats['present']!, color: _success, bg: _successSoft),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _MiniStat(
                    label: 'Absent', value: stats['absent']!, color: _danger, bg: _dangerSoft),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _MiniStat(
                    label: 'Late', value: stats['late']!, color: _amber, bg: _amberSoft),
              ),
              if (!isHol) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: _MiniStat(
                      label: 'Not Marked',
                      value: stats['notMarked']!,
                      color: _textMuted,
                      bg: _bg),
                ),
              ],
            ],
          ),
          if (marked > 0) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Icon(Icons.insights_rounded, size: 16, color: _primaryDark),
                const SizedBox(width: 6),
                Text(
                  '${pct.toStringAsFixed(0)}% attendance on this day',
                  style: const TextStyle(
                      fontSize: 12.5, fontWeight: FontWeight.w700, color: _textDark),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // ── Section: month trend ─────────────────────────────────────────────
  Widget _buildMonthTrend() {
    final trend = _monthTrend;
    final monthLabel = DateFormat('MMMM yyyy').format(_visibleMonth);
    final now = DateTime.now();
    final isCurrentOrFuture = _visibleMonth.year > now.year ||
        (_visibleMonth.year == now.year && _visibleMonth.month >= now.month);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Text(
                    'Attendance Trend',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: _textDark,
                    ),
                  ),
                  if (_changingMonth) ...[
                    const SizedBox(width: 8),
                    const BtnLoader(color: _primary, dotSize: 5),
                  ],
                ],
              ),
              Row(
                children: [
                  _RoundIconBtn(
                    icon: Icons.chevron_left_rounded,
                    onTap: _changingMonth ? null : () => _changeMonth(-1),
                  ),
                  const SizedBox(width: 6),
                  SizedBox(
                    width: 100,
                    child: Text(
                      monthLabel,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: _textDark,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  _RoundIconBtn(
                    icon: Icons.chevron_right_rounded,
                    onTap: (isCurrentOrFuture || _changingMonth)
                        ? null
                        : () => _changeMonth(1),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (trend.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text('No attendance marked this month yet.',
                    style: TextStyle(color: _textMuted, fontSize: 13)),
              ),
            )
          else
            SizedBox(
              height: 120,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: trend.map((e) {
                  final barHeight = (e.value / 100) * 96;
                  final color = e.value >= 75
                      ? _success
                      : (e.value >= 50 ? _amber : _danger);
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 1.5),
                      child: Tooltip(
                        message: 'Day ${e.key}: ${e.value.toStringAsFixed(0)}%',
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Container(
                              height: barHeight.clamp(4, 96),
                              decoration: BoxDecoration(
                                color: color,
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text('${e.key}',
                                style: const TextStyle(fontSize: 8, color: _textMuted)),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }
}

class _OverviewCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _OverviewCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFEDEDF4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 10),
          Text(value,
              style: const TextStyle(
                  fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF1E1B24))),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF8A8794))),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  final Color bg;

  const _MiniStat({
    required this.label,
    required this.value,
    required this.color,
    required this.bg,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Text('$value',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: color)),
          const SizedBox(height: 2),
          Text(label,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 9.5, fontWeight: FontWeight.w700, color: color.withValues(alpha: 0.85))),
        ],
      ),
    );
  }
}

class _RoundIconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _RoundIconBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: disabled ? const Color(0xFFF6F6FB) : const Color(0xFFFFE7EC),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          size: 17,
          color: disabled
              ? const Color(0xFF8A8794).withValues(alpha: 0.4)
              : const Color(0xFFD32F52),
        ),
      ),
    );
  }
}

class _ExportOptionTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ExportOptionTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFF6F6FB),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFEDEDF4)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF1E1B24))),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: const TextStyle(fontSize: 11.5, color: Color(0xFF8A8794))),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Color(0xFF8A8794), size: 20),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded, size: 40, color: Color(0xFFEF4949)),
            const SizedBox(height: 12),
            Text(message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFF8A8794))),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE94464),
                foregroundColor: Colors.white,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}