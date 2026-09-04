import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:strawberry/features/auth/auth_service.dart';

import 'package:strawberry/core/theme/app_colors.dart';
import 'package:strawberry/core/widgets/playschool_animations.dart';

/// Admin-facing attendance history for a single student.
/// Shows overall stats (present/absent/late/percentage) + a GitHub-style
/// calendar heatmap the admin can page through month by month.
class StudentAttendanceHistoryPage extends StatefulWidget {
  final Map<String, dynamic> student;
  final AuthService authService;

  const StudentAttendanceHistoryPage({
    super.key,
    required this.student,
    required this.authService,
  });

  @override
  State<StudentAttendanceHistoryPage> createState() =>
      _StudentAttendanceHistoryPageState();
}

class _StudentAttendanceHistoryPageState
    extends State<StudentAttendanceHistoryPage> {
  // ── Palette (mirrors rest of admin panel) ──────────────────────────
  static const _primary = AppColors.primary;
  static const _primarySoft = AppColors.primarySoft;
  static const _primaryDark = AppColors.primaryDark;
  static const _bg = AppColors.background;
  static const _surface = AppColors.surface;
  static const _border = AppColors.borderSubtle;
  static const _textDark = AppColors.textDark;
  static const _textMuted = AppColors.textMuted;
  static const _success = AppColors.emerald;
  static const _successSoft = AppColors.emeraldSoft;
  static const _danger = AppColors.danger;
  static const _dangerSoft = AppColors.dangerSoft;
  static const _amber = AppColors.amber;
  static const _amberSoft = AppColors.amberSoft;

  bool _loading = true;
  String? _error;

  // date(yyyy-MM-dd) -> record map
  Map<String, Map<String, dynamic>> _recordsByDate = {};
  Map<String, Map<String, dynamic>> _holidaysByDate = {};

  DateTime _visibleMonth = DateTime(DateTime.now().year, DateTime.now().month);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final category = (widget.student['student_type'] as String?) ?? 'All';
      final recordsFuture = widget.authService
          .getStudentAttendance(widget.student['id'] as String);
      final holidaysFuture = widget.authService.getHolidaysForMonth(
        _visibleMonth.year,
        _visibleMonth.month,
      );

      final results = await Future.wait([recordsFuture, holidaysFuture]);
      final records = results[0];
      final holidays = results[1];

      final map = <String, Map<String, dynamic>>{};
      for (final r in records) {
        final date = r['date']?.toString();
        if (date != null) {
          map[date] = r;
        }
      }

      final holidayMap = <String, Map<String, dynamic>>{};
      final isSatDefault = widget.authService.isSaturdayDefaultHoliday(category);
      final daysInMonth = DateTime(_visibleMonth.year, _visibleMonth.month + 1, 0).day;
      
      for (int day = 1; day <= daysInMonth; day++) {
        final dt = DateTime(_visibleMonth.year, _visibleMonth.month, day);
        final dateStr = DateFormat('yyyy-MM-dd').format(dt);
        if (dt.weekday == DateTime.sunday) {
          holidayMap[dateStr] = {'type': 'sunday', 'title': 'Sunday'};
        } else if (dt.weekday == DateTime.saturday && isSatDefault) {
          holidayMap[dateStr] = {'type': 'saturday', 'title': 'Saturday'};
        }
      }

      for (final h in holidays) {
        final dateStr = h['date']?.toString();
        if (dateStr == null) continue;
        if (h['type'] == 'holiday' &&
            (h['category'] == 'All' || h['category'] == category)) {
          holidayMap[dateStr] = {
            'type': 'holiday',
            'title': h['title'],
            'category': h['category'],
          };
        }
        if (h['type'] == 'working_day' && h['category'] == category) {
          holidayMap[dateStr] = {
            'type': 'working_day',
            'title': h['title'],
          };
        }
      }

      if (!mounted) return;
      setState(() {
        _recordsByDate = map;
        _holidaysByDate = holidayMap;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to load attendance history.';
        _loading = false;
      });
    }
  }

  // ── Derived stats (all-time) ─────────────────────────────────────────
  int get _presentCount =>
      _recordsByDate.values.where((r) => r['status'] == 'Present').length;
  int get _absentCount =>
      _recordsByDate.values.where((r) => r['status'] == 'Absent').length;
  int get _lateCount =>
      _recordsByDate.values.where((r) => r['status'] == 'Late').length;
  int get _totalMarked => _recordsByDate.length;
  double get _percentage {
    if (_totalMarked == 0) return 0;
    // Present + Late both count as "attended" for the percentage.
    return ((_presentCount + _lateCount) / _totalMarked) * 100;
  }

  // ── Derived stats (for currently visible month) ─────────────────────
  Map<String, int> get _monthStats {
    int p = 0, a = 0, l = 0;
    _recordsByDate.forEach((date, r) {
      final d = DateTime.tryParse(date);
      if (d == null) return;
      if (d.year == _visibleMonth.year && d.month == _visibleMonth.month) {
        final status = r['status']?.toString();
        if (status == 'Present') p++;
        if (status == 'Absent') a++;
        if (status == 'Late') l++;
      }
    });
    return {'present': p, 'absent': a, 'late': l};
  }

  void _changeMonth(int delta) {
    setState(() {
      _visibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month + delta);
    });
    _load();
  }

  Color _colorFor(String? status) {
    switch (status) {
      case 'Present':
        return _success;
      case 'Absent':
        return _danger;
      case 'Late':
        return _amber;
      default:
        return _border;
    }
  }

  String _formatTimeStr(String? timeStr) {
    if (timeStr == null || timeStr.isEmpty) return '--:--';
    try {
      final parts = timeStr.split(':');
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);
      final period = hour >= 12 ? 'PM' : 'AM';
      final hour12 = hour % 12 == 0 ? 12 : hour % 12;
      final minStr = minute.toString().padLeft(2, '0');
      return '$hour12:$minStr $period';
    } catch (_) {
      return timeStr;
    }
  }

  void _showHolidayDetails(BuildContext context, DateTime date, String title, String type) {
    final formattedDate = DateFormat('dd MMMM yyyy').format(date);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                formattedDate,
                style: const TextStyle(
                  color: _textDark,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _dangerSoft,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.event_busy_rounded,
                    color: _danger,
                    size: 26,
                  ),
                ),
                title: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: _danger,
                  ),
                ),
                subtitle: Text(
                  type == 'sunday'
                      ? 'Sunday — Weekly Off Day'
                      : type == 'saturday'
                          ? 'Saturday — Weekend Off Day'
                          : 'School / Category Holiday',
                  style: const TextStyle(fontSize: 13, color: _textMuted),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
  void _showDayDetails(BuildContext context, DateTime date, String status, Map<String, dynamic>? record) {
    final formattedDate = DateFormat('dd MMMM yyyy').format(date);
    final inTime = record?['in_time'] as String?;
    final outTime = record?['out_time'] as String?;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                formattedDate,
                style: const TextStyle(
                  color: _textDark,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _colorFor(status).withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    status == 'Present'
                        ? Icons.check_circle_rounded
                        : status == 'Absent'
                            ? Icons.cancel_rounded
                            : Icons.schedule_rounded,
                    color: _colorFor(status),
                    size: 26,
                  ),
                ),
                title: const Text(
                  'Status',
                  style: TextStyle(fontSize: 13, color: _textMuted, fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  status,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: _colorFor(status),
                  ),
                ),
              ),
              if (status != 'Absent' && (inTime != null || outTime != null)) ...[
                const Divider(color: _border, height: 24),
                Row(
                  children: [
                    if (inTime != null)
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Check-in Time',
                              style: TextStyle(fontSize: 12, color: _textMuted, fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _formatTimeStr(inTime),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: _textDark,
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (outTime != null)
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Check-out Time',
                              style: TextStyle(fontSize: 12, color: _textMuted, fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _formatTimeStr(outTime),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: _textDark,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  elevation: 0,
                ),
                child: const Text('Close', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.student['name'] ?? 'Student';

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _surface,
        foregroundColor: _textDark,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        shape: const Border(bottom: BorderSide(color: _border, width: 1)),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Attendance History',
                style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w800, color: _textDark)),
            Text(name,
                style: const TextStyle(
                    fontSize: 12.5, fontWeight: FontWeight.w500, color: _textMuted)),
          ],
        ),
      ),
      body: _loading
          ? const StrawberryLoader(message: 'Loading attendance history... 📊')
          : _error != null
              ? _ErrorState(message: _error!, onRetry: _load)
              : RefreshIndicator(
                  onRefresh: _load,
                  color: _primary,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final isDesktop = constraints.maxWidth >= 900;
                      final isTablet = constraints.maxWidth >= 600 && constraints.maxWidth < 900;
                      final horizontalPadding = isDesktop ? 32.0 : (isTablet ? 24.0 : 16.0);

                      return ListView(
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
                                          _buildSummaryCards(),
                                          const SizedBox(height: 20),
                                          _buildPercentageRing(),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 20),
                                    Expanded(
                                      flex: 5,
                                      child: Column(
                                        children: [
                                          _buildCalendarHeader(),
                                          const SizedBox(height: 12),
                                          _buildCalendarGrid(),
                                          const SizedBox(height: 16),
                                          _buildLegend(),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ]
                            : [
                                _buildSummaryCards(),
                                const SizedBox(height: 22),
                                _buildPercentageRing(),
                                const SizedBox(height: 26),
                                _buildCalendarHeader(),
                                const SizedBox(height: 12),
                                _buildCalendarGrid(),
                                const SizedBox(height: 16),
                                _buildLegend(),
                              ],
                      );
                    },
                  ),
                ),
    );
  }

  // ── Widgets ───────────────────────────────────────────────────────────

  Widget _buildSummaryCards() {
    return Row(
      children: [
        Expanded(
          child: _StatTile(
            label: 'Present',
            value: '$_presentCount',
            color: _success,
            bg: _successSoft,
            icon: Icons.check_circle_rounded,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatTile(
            label: 'Absent',
            value: '$_absentCount',
            color: _danger,
            bg: _dangerSoft,
            icon: Icons.cancel_rounded,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatTile(
            label: 'Late',
            value: '$_lateCount',
            color: _amber,
            bg: _amberSoft,
            icon: Icons.schedule_rounded,
          ),
        ),
      ],
    );
  }

  Widget _buildPercentageRing() {
    final pct = _percentage.clamp(0, 100);
    final pctStr = pct.toStringAsFixed(pct.truncateToDouble() == pct ? 0 : 1);
    final isGood = pct >= 75;
    final isAverage = pct >= 50 && pct < 75;
    final color = _totalMarked == 0
        ? _textMuted
        : (isGood
            ? _success
            : (isAverage ? _amber : _danger));
    final bgSoft = _totalMarked == 0
        ? _bg
        : (isGood
            ? _successSoft
            : (isAverage ? _amberSoft : _dangerSoft));
    final statusLabel = _totalMarked == 0
        ? 'No Records'
        : (isGood ? 'Good Attendance' : (isAverage ? 'Moderate' : 'Needs Attention'));

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: bgSoft,
                  shape: BoxShape.circle,
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 52,
                      height: 52,
                      child: CircularProgressIndicator(
                        value: _totalMarked == 0 ? 0 : (pct / 100).clamp(0, 1),
                        strokeWidth: 5,
                        backgroundColor: color.withValues(alpha: 0.15),
                        valueColor: AlwaysStoppedAnimation<Color>(color),
                        strokeCap: StrokeCap.round,
                      ),
                    ),
                    Text(
                      '$pctStr%',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: color,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        const Text(
                          'Overall Attendance',
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w800,
                            color: _textDark,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: bgSoft,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            statusLabel,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: color,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _totalMarked == 0
                          ? 'No attendance records marked yet'
                          : '$_presentCount Present · $_absentCount Absent${_lateCount > 0 ? ' · $_lateCount Late' : ''} (out of $_totalMarked days)',
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: _textMuted,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (_totalMarked > 0) ...[
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: (pct / 100).clamp(0, 1),
                minHeight: 6,
                backgroundColor: color.withValues(alpha: 0.12),
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCalendarHeader() {
    final monthLabel = DateFormat('MMMM yyyy').format(_visibleMonth);
    final stats = _monthStats;
    final now = DateTime.now();
    final isCurrentOrFuture =
        _visibleMonth.year > now.year ||
            (_visibleMonth.year == now.year && _visibleMonth.month >= now.month);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Calendar', style: TextStyle(
                fontSize: 15, fontWeight: FontWeight.w800, color: _textDark)),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _RoundIconButton(
                  icon: Icons.chevron_left_rounded,
                  onTap: () => _changeMonth(-1),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Text(
                    monthLabel,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w700, color: _textDark),
                  ),
                ),
                _RoundIconButton(
                  icon: Icons.chevron_right_rounded,
                  onTap: isCurrentOrFuture ? null : () => _changeMonth(1),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Text('${stats['present']} present',
                style: const TextStyle(
                    color: _success, fontSize: 12, fontWeight: FontWeight.w700)),
            const SizedBox(width: 12),
            Text('${stats['absent']} absent',
                style: const TextStyle(
                    color: _danger, fontSize: 12, fontWeight: FontWeight.w700)),
            const SizedBox(width: 12),
            Text('${stats['late']} late',
                style: const TextStyle(
                    color: _amber, fontSize: 12, fontWeight: FontWeight.w700)),
          ],
        ),
      ],
    );
  }

  Widget _buildCalendarGrid() {
    final firstDayOfMonth = DateTime(_visibleMonth.year, _visibleMonth.month, 1);
    final daysInMonth =
        DateTime(_visibleMonth.year, _visibleMonth.month + 1, 0).day;
    // Weekday: Monday=1 ... Sunday=7. Convert so grid starts on Monday.
    final leadingBlanks = firstDayOfMonth.weekday - 1;

    const weekdayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _border),
      ),
      child: Column(
        children: [
          Row(
            children: weekdayLabels
                .map((d) => Expanded(
                      child: Center(
                        child: Text(d,
                            style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: _textMuted)),
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 8),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: leadingBlanks + daysInMonth,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 6,
              crossAxisSpacing: 6,
            ),
            itemBuilder: (context, index) {
              if (index < leadingBlanks) return const SizedBox.shrink();
              final day = index - leadingBlanks + 1;
              final date = DateTime(_visibleMonth.year, _visibleMonth.month, day);
              final dateKey = DateFormat('yyyy-MM-dd').format(date);
              final holidayInfo = _holidaysByDate[dateKey];
              final holidayType = holidayInfo?['type'];
              final holidayTitle = holidayInfo?['title'];

              final record = _recordsByDate[dateKey];
              final status = record?['status']?.toString();

              final isFuture = date.isAfter(DateTime.now());
              
              Color cellBg = Colors.transparent;
              Color textCol = isFuture ? _textMuted.withValues(alpha: 0.4) : _textDark;
              Widget? badge;

              if (holidayType == 'sunday' || holidayType == 'saturday' || holidayType == 'holiday') {
                cellBg = _dangerSoft;
                badge = Text(
                  'H',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    color: _danger,
                  ),
                );
              } else if (holidayType == 'working_day') {
                cellBg = _successSoft;
                badge = Icon(Icons.check, size: 10, color: _success);
              } else if (status != null) {
                cellBg = _colorFor(status).withValues(alpha: 0.18);
                badge = Container(
                  width: 5,
                  height: 5,
                  decoration: BoxDecoration(
                    color: _colorFor(status),
                    shape: BoxShape.circle,
                  ),
                );
              }

              final isToday = DateFormat('yyyy-MM-dd').format(DateTime.now()) == dateKey;

              String tooltipMsg = holidayTitle != null 
                  ? '$holidayTitle (Holiday)'
                  : (status ?? (isFuture ? '' : 'No record'));

              return InkWell(
                onTap: () {
                  if (holidayType != null && holidayType != 'working_day') {
                    _showHolidayDetails(context, date, holidayTitle ?? 'Holiday', holidayType);
                  } else if (status != null) {
                    _showDayDetails(context, date, status, record);
                  }
                },
                borderRadius: BorderRadius.circular(8),
                child: Tooltip(
                  message: tooltipMsg,
                  child: Container(
                    decoration: BoxDecoration(
                      color: isFuture ? Colors.transparent : cellBg,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isToday ? _primary : Colors.transparent,
                        width: 1.4,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '$day',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: textCol,
                          ),
                        ),
                        if (!isFuture && badge != null) ...[
                          const SizedBox(height: 1),
                          badge,
                        ],
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLegend() {
    Widget dot(Color c, String label) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(color: c, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            Text(label,
                style: const TextStyle(
                    fontSize: 11.5, color: _textMuted, fontWeight: FontWeight.w600)),
          ],
        );

    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: [
        dot(_success, 'Present'),
        dot(_danger, 'Absent'),
        dot(_amber, 'Late'),
        dot(_border, 'No record'),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final Color bg;
  final IconData icon;

  const _StatTile({
    required this.label,
    required this.value,
    required this.color,
    required this.bg,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 6),
          Text(value,
              style: TextStyle(
                  fontSize: 17, fontWeight: FontWeight.w800, color: color)),
          const SizedBox(height: 2),
          Text(label,
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: color.withValues(alpha: 0.85))),
        ],
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _RoundIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: disabled
              ? _StudentAttendanceHistoryPageState._bg
              : _StudentAttendanceHistoryPageState._primarySoft,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          size: 18,
          color: disabled
              ? _StudentAttendanceHistoryPageState._textMuted.withValues(alpha: 0.4)
              : _StudentAttendanceHistoryPageState._primaryDark,
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
            const Icon(Icons.error_outline_rounded,
                size: 40, color: _StudentAttendanceHistoryPageState._danger),
            const SizedBox(height: 12),
            Text(message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: _StudentAttendanceHistoryPageState._textMuted)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: _StudentAttendanceHistoryPageState._primary,
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
