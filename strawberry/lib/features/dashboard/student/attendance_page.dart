import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:strawberry/core/theme/app_colors.dart';
import 'package:strawberry/core/theme/app_typography.dart';
import 'package:strawberry/core/theme/app_decorations.dart';
import 'package:strawberry/core/widgets/app_badge.dart';
import 'package:strawberry/core/widgets/playschool_animations.dart';
import 'package:strawberry/features/auth/auth_service.dart';

class AttendancePage extends StatefulWidget {
  const AttendancePage({super.key});

  @override
  State<AttendancePage> createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage> {
  final AuthService _authService = AuthService();
  
  bool _loading = true;
  Map<String, dynamic>? _profile;
  List<Map<String, dynamic>> _attendanceRecords = [];
  List<Map<String, dynamic>> _monthHolidays = [];
  
  DateTime _visibleMonth = DateTime(DateTime.now().year, DateTime.now().month);
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final uid = _authService.currentUserId;
      if (uid != null) {
        final profileFuture = _authService.getCurrentProfile();
        final attendanceFuture = _authService.getStudentAttendance(uid);
        final holidaysFuture = _authService.getHolidaysForMonth(
          _visibleMonth.year,
          _visibleMonth.month,
        );

        final results = await Future.wait([
          profileFuture,
          attendanceFuture,
          holidaysFuture,
        ]);

        if (!mounted) return;
        setState(() {
          _profile = results[0] as Map<String, dynamic>?;
          _attendanceRecords = results[1] as List<Map<String, dynamic>>;
          _monthHolidays = results[2] as List<Map<String, dynamic>>;
          _loading = false;
        });
      } else {
        if (!mounted) return;
        setState(() => _loading = false);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  void _changeMonth(int delta) {
    setState(() {
      _visibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month + delta, 1);
    });
    _loadData();
  }

  // ── Derived Stats & Helper Methods ────────────────────────────────────

  String get _category => (_profile?['student_type'] as String?)?.trim() ?? 'All';

  Map<String, Map<String, dynamic>> get _recordsByDate {
    final map = <String, Map<String, dynamic>>{};
    for (final r in _attendanceRecords) {
      final d = r['date']?.toString();
      if (d != null) map[d] = r;
    }
    return map;
  }

  /// Map of holidays for visible month (Sunday, Saturday if applicable, or explicit DB holiday)
  Map<String, Map<String, dynamic>> get _holidaysByDate {
    final holidayMap = <String, Map<String, dynamic>>{};
    final isSatDefault = _authService.isSaturdayDefaultHoliday(_category);
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

    for (final h in _monthHolidays) {
      final dateStr = h['date']?.toString();
      if (dateStr == null) continue;
      if (h['type'] == 'holiday' &&
          (h['category'] == 'All' || h['category'] == _category)) {
        holidayMap[dateStr] = {
          'type': 'holiday',
          'title': h['title'],
          'category': h['category'],
        };
      }
      if (h['type'] == 'working_day' && h['category'] == _category) {
        holidayMap[dateStr] = {
          'type': 'working_day',
          'title': h['title'],
        };
      }
    }

    return holidayMap;
  }

  // Attendance Overall Stats
  int get _presentCount =>
      _recordsByDate.values.where((r) => r['status'] == 'Present').length;
  int get _absentCount =>
      _recordsByDate.values.where((r) => r['status'] == 'Absent').length;
  int get _lateCount =>
      _recordsByDate.values.where((r) => r['status'] == 'Late').length;

  int get _totalWorkingDaysMarked => _recordsByDate.length;

  double get _attendancePercentage {
    if (_totalWorkingDaysMarked == 0) return 0.0;
    return ((_presentCount + _lateCount) / _totalWorkingDaysMarked) * 100;
  }

  String _formatTimeString(String? timeStr) {
    if (timeStr == null || timeStr.isEmpty) return '';
    try {
      final parts = timeStr.split(':');
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);
      final tod = TimeOfDay(hour: hour, minute: minute);
      final period = tod.period == DayPeriod.am ? 'AM' : 'PM';
      final hourOfPeriod = tod.hourOfPeriod == 0 ? 12 : tod.hourOfPeriod;
      final minStr = tod.minute.toString().padLeft(2, '0');
      return '$hourOfPeriod:$minStr $period';
    } catch (_) {
      return timeStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('My Attendance', style: AppTypography.h2),
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        shape: const Border(bottom: BorderSide(color: AppColors.borderSubtle, width: 1)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : RefreshIndicator(
              onRefresh: _loadData,
              color: AppColors.primary,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isDesktop = constraints.maxWidth >= 960;
                  final isTablet = constraints.maxWidth >= 640 && constraints.maxWidth < 960;
                  final horizontalPadding = isDesktop ? 36.0 : (isTablet ? 24.0 : 16.0);

                  return ListView(
                    padding: EdgeInsets.symmetric(
                      horizontal: horizontalPadding,
                      vertical: 20,
                    ),
                    physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                    children: isDesktop
                        ? [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Left Column: Overview, Selected Date & Activity History
                                Expanded(
                                  flex: 5,
                                  child: Column(
                                    children: [
                                      _buildPercentageOverviewCard(),
                                      const SizedBox(height: 18),
                                      _buildSelectedDateDetailCard(),
                                      const SizedBox(height: 18),
                                      _buildAttendanceLogCard(),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 24),
                                // Right Column: Interactive Monthly Register Calendar
                                Expanded(
                                  flex: 5,
                                  child: _buildMonthlyRegisterCard(),
                                ),
                              ],
                            ),
                          ]
                        : [
                            _buildPercentageOverviewCard(),
                            const SizedBox(height: 16),
                            _buildMonthlyRegisterCard(),
                            const SizedBox(height: 16),
                            _buildSelectedDateDetailCard(),
                            const SizedBox(height: 16),
                            _buildAttendanceLogCard(),
                          ],
                  );
                },
              ),
            ),
    );
  }

  // ── 1. Attendance Percentage Summary Card ──────────────────────────────
  Widget _buildPercentageOverviewCard() {
    final pctStr = _attendancePercentage.toStringAsFixed(1);
    final isStar = _attendancePercentage >= 85;
    final color = _attendancePercentage >= 75
        ? AppColors.emerald
        : _attendancePercentage >= 50
            ? AppColors.amber
            : AppColors.danger;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppDecorations.radiusXl,
        border: Border.all(color: AppColors.borderSubtle),
        boxShadow: AppDecorations.shadowSm,
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        isStar ? '🌟 Star Attendance' : 'Attendance Rate',
                        style: AppTypography.caption.copyWith(
                          fontWeight: FontWeight.w700,
                          color: isStar ? AppColors.amberDark : AppColors.textMuted,
                        ),
                      ),
                      if (isStar) ...[
                        const SizedBox(width: 4),
                        const PlayfulSparkle(size: 14, color: Colors.amber),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        '$pctStr%',
                        style: AppTypography.display.copyWith(color: color, fontSize: 32),
                      ),
                      const SizedBox(width: 8),
                      AppBadge(
                        label: _attendancePercentage >= 85
                            ? '⭐ Outstanding'
                            : (_attendancePercentage >= 70 ? '👍 Great' : '🌱 Growing'),
                        type: _attendancePercentage >= 70 ? AppBadgeType.success : AppBadgeType.warning,
                      ),
                    ],
                  ),
                ],
              ),
              // Circular Progress Badge
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 62,
                    height: 62,
                    child: CircularProgressIndicator(
                      value: _totalWorkingDaysMarked == 0 ? 0 : _attendancePercentage / 100,
                      strokeWidth: 6,
                      backgroundColor: AppColors.background,
                      color: color,
                    ),
                  ),
                  FloatingWobble(
                    verticalOffset: 2,
                    duration: const Duration(milliseconds: 2000),
                    child: Text(
                      _attendancePercentage >= 85 ? '🌟' : (_attendancePercentage >= 70 ? '🍓' : '🌱'),
                      style: const TextStyle(fontSize: 22),
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),

          // Mini metrics breakdown row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMiniMetric('Present', '$_presentCount', AppColors.emerald, AppColors.emeraldSoft, '🟢'),
              _buildMiniMetric('Late', '$_lateCount', AppColors.amber, AppColors.amberSoft, '🟡'),
              _buildMiniMetric('Absent', '$_absentCount', AppColors.danger, AppColors.dangerSoft, '🔴'),
              _buildMiniMetric('Total Days', '$_totalWorkingDaysMarked', AppColors.primary, AppColors.primarySoft, '🎒'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniMetric(String label, String value, Color color, Color bg, String emoji) {
    return BouncyTap(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: AppDecorations.radiusSm,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(emoji, style: const TextStyle(fontSize: 10)),
                const SizedBox(width: 4),
                Text(
                  value,
                  style: AppTypography.h3.copyWith(color: color, fontSize: 14),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: AppTypography.caption.copyWith(fontSize: 11),
          ),
        ],
      ),
    );
  }

  // ── 3. Monthly Register Card (Calendar) ─────────────────────────────────
  Widget _buildMonthlyRegisterCard() {
    final monthLabel = DateFormat('MMMM yyyy').format(_visibleMonth);
    final daysInMonth = DateTime(_visibleMonth.year, _visibleMonth.month + 1, 0).day;
    final firstWeekday = DateTime(_visibleMonth.year, _visibleMonth.month, 1).weekday;
    final paddingDays = firstWeekday % 7; // Sunday = 7 -> 0 offset

    final weekDays = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderSubtle),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Title + Month Switcher
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primarySoft,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.calendar_month_rounded, color: AppColors.primary, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Text('Monthly Register', style: AppTypography.h3),
                ],
              ),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surfaceAlt,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left_rounded, size: 18),
                      visualDensity: VisualDensity.compact,
                      onPressed: () => _changeMonth(-1),
                    ),
                    Text(
                      monthLabel,
                      style: AppTypography.bodySmall.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right_rounded, size: 18),
                      visualDensity: VisualDensity.compact,
                      onPressed: () => _changeMonth(1),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          // Weekday Labels
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: weekDays.map((d) {
              final isSun = d == 'Sun';
              return SizedBox(
                width: 36,
                child: Text(
                  d,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isSun ? AppColors.danger : AppColors.textMuted,
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 10),

          // Days Grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: paddingDays + daysInMonth,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
            ),
            itemBuilder: (context, index) {
              if (index < paddingDays) {
                return const SizedBox.shrink();
              }

              final dayNumber = index - paddingDays + 1;
              final dateObj = DateTime(_visibleMonth.year, _visibleMonth.month, dayNumber);
              final dateStr = DateFormat('yyyy-MM-dd').format(dateObj);

              final rec = _recordsByDate[dateStr];
              final hol = _holidaysByDate[dateStr];

              final isSelected = DateFormat('yyyy-MM-dd').format(_selectedDate) == dateStr;
              final isWorkingDayException = hol?['type'] == 'working_day';
              final isHoliday = hol != null && !isWorkingDayException;

              Color cellBg = AppColors.surfaceAlt;
              Color textColor = AppColors.textDark;
              Widget? badgeWidget;

              if (rec != null) {
                final status = rec['status'];
                if (status == 'Present') {
                  cellBg = AppColors.emeraldSoft;
                  textColor = AppColors.emeraldDark;
                  badgeWidget = const Icon(Icons.check_circle_rounded, size: 11, color: AppColors.emerald);
                } else if (status == 'Absent') {
                  cellBg = AppColors.dangerSoft;
                  textColor = AppColors.danger;
                  badgeWidget = const Icon(Icons.cancel_rounded, size: 11, color: AppColors.danger);
                } else if (status == 'Late') {
                  cellBg = AppColors.amberSoft;
                  textColor = AppColors.amberDark;
                  badgeWidget = const Icon(Icons.access_time_filled_rounded, size: 11, color: AppColors.amber);
                }
              } else if (isHoliday) {
                cellBg = AppColors.violetSoft;
                textColor = AppColors.violetDark;
                badgeWidget = Text(
                  'H',
                  style: TextStyle(
                    color: AppColors.violetDark,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                );
              }

              return InkWell(
                onTap: () => setState(() => _selectedDate = dateObj),
                borderRadius: BorderRadius.circular(12),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.white : cellBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primary
                          : (isHoliday ? AppColors.violet.withValues(alpha: 0.3) : AppColors.borderSubtle),
                      width: isSelected ? 2.0 : 1.0,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Text(
                        '$dayNumber',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                          color: isSelected ? AppColors.primary : textColor,
                        ),
                      ),
                      if (badgeWidget != null)
                        Positioned(
                          top: 4,
                          right: 4,
                          child: badgeWidget,
                        ),
                    ],
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 18),
          const Divider(height: 1),
          const SizedBox(height: 14),

          // Legend
          Wrap(
            spacing: 14,
            runSpacing: 8,
            children: [
              _buildLegendPill('Present', AppColors.emerald, AppColors.emeraldSoft),
              _buildLegendPill('Late', AppColors.amber, AppColors.amberSoft),
              _buildLegendPill('Absent', AppColors.danger, AppColors.dangerSoft),
              _buildLegendPill('Holiday', AppColors.violet, AppColors.violetSoft),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendPill(String label, Color color, Color bg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // ── 4. Selected Date Detail Card ───────────────────────────────────────
  Widget _buildSelectedDateDetailCard() {
    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
    final formattedTitle = DateFormat('EEEE, dd MMMM yyyy').format(_selectedDate);

    final rec = _recordsByDate[dateStr];
    final hol = _holidaysByDate[dateStr];
    final isWorkingDayException = hol?['type'] == 'working_day';
    final isHoliday = hol != null && !isWorkingDayException;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderSubtle),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.event_note_rounded, color: AppColors.primary, size: 18),
                  const SizedBox(width: 8),
                  Text(formattedTitle, style: AppTypography.h3),
                ],
              ),
              if (isHoliday)
                const AppBadge(
                  label: 'Holiday',
                  type: AppBadgeType.info,
                ),
            ],
          ),
          const SizedBox(height: 12),

          if (isHoliday) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.violetSoft,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.beach_access_rounded, color: AppColors.violet, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '${hol['title'] ?? "Holiday"} — School is closed today.',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.violetDark,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ] else if (rec != null) ...[
            Row(
              children: [
                Icon(
                  rec['status'] == 'Present'
                      ? Icons.check_circle_rounded
                      : rec['status'] == 'Late'
                          ? Icons.access_time_filled_rounded
                          : Icons.cancel_rounded,
                  color: rec['status'] == 'Present'
                      ? AppColors.emerald
                      : rec['status'] == 'Late'
                          ? AppColors.amber
                          : AppColors.danger,
                  size: 22,
                ),
                const SizedBox(width: 8),
                Text(
                  'Status: ${rec['status']}',
                  style: AppTypography.h3.copyWith(
                    color: rec['status'] == 'Present'
                        ? AppColors.emerald
                        : rec['status'] == 'Late'
                            ? AppColors.amber
                            : AppColors.danger,
                  ),
                ),
              ],
            ),
            if (rec['in_time'] != null || rec['out_time'] != null) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.surfaceAlt,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    if (rec['in_time'] != null) ...[
                      const Icon(Icons.login_rounded, size: 14, color: AppColors.textMuted),
                      const SizedBox(width: 4),
                      Text(
                        'Check In: ${_formatTimeString(rec['in_time'])}',
                        style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.w600),
                      ),
                    ],
                    if (rec['in_time'] != null && rec['out_time'] != null)
                      const SizedBox(width: 16),
                    if (rec['out_time'] != null) ...[
                      const Icon(Icons.logout_rounded, size: 14, color: AppColors.textMuted),
                      const SizedBox(width: 4),
                      Text(
                        'Check Out: ${_formatTimeString(rec['out_time'])}',
                        style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ] else ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.surfaceAlt,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded, size: 16, color: AppColors.textMuted),
                  const SizedBox(width: 8),
                  Text(
                    'No attendance record marked for this date.',
                    style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── 5. Attendance Log Card ─────────────────────────────────────────────
  Widget _buildAttendanceLogCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderSubtle),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
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
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: const Icon(Icons.history_rounded, color: AppColors.primary, size: 17),
              ),
              const SizedBox(width: 10),
              Text('Recent Attendance Logs', style: AppTypography.h3),
            ],
          ),
          const SizedBox(height: 14),
          if (_attendanceRecords.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'No attendance records found yet.',
                  style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
                ),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _attendanceRecords.length > 6 ? 6 : _attendanceRecords.length,
              itemBuilder: (context, index) {
                final rec = _attendanceRecords[index];
                final date = rec['date'] ?? '';
                final status = rec['status'] ?? '';
                final isPresent = status == 'Present';
                final isLate = status == 'Late';

                final color = isPresent ? AppColors.emerald : (isLate ? AppColors.amber : AppColors.danger);
                final bg = isPresent ? AppColors.emeraldSoft : (isLate ? AppColors.amberSoft : AppColors.dangerSoft);

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceAlt,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.borderSubtle),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: bg,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isPresent
                              ? Icons.check_circle_rounded
                              : isLate
                                  ? Icons.access_time_filled_rounded
                                  : Icons.cancel_rounded,
                          color: color,
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          date,
                          style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: bg,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          status,
                          style: TextStyle(
                            color: color,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
