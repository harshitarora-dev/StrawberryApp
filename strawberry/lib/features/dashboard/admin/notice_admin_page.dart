import 'package:flutter/material.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:strawberry/features/auth/auth_service.dart';
import 'package:strawberry/features/auth/push_notification_service.dart';


import 'package:strawberry/core/theme/app_colors.dart';

/// ---------------------------------------------------------------------
/// Design tokens — unified with AppTheme
/// ---------------------------------------------------------------------
class _Palette {
  static const primary = AppColors.primary;

  static const bg = AppColors.background;
  static const surface = AppColors.surface;
  static const border = AppColors.borderSubtle;

  static const textDark = AppColors.textDark;
  static const textMuted = AppColors.textMuted;
  static const textFaint = AppColors.textFaint;

  static const success = AppColors.emerald;
  static const danger = AppColors.danger;

  // Category accent colors
  static const catGeneral = AppColors.sky;
  static const catFees = AppColors.amber;
  static const catHoliday = AppColors.violet;
  static const catEvent = AppColors.emerald;
}

class NoticeAdminPage extends StatefulWidget {
  final AuthService authService;
  const NoticeAdminPage({super.key, required this.authService});

  @override
  State<NoticeAdminPage> createState() => _NoticeAdminPageState();
}

class _NoticeAdminPageState extends State<NoticeAdminPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  String _audience = 'All';
  String _category = 'General';
  List<Map<String, dynamic>> _students = [];
  Map<String, dynamic>? _selectedStudent;
  bool _loadingStudents = true;
  bool _submitting = false;

  // ----- Scheduling state -----
  // 'now' | 'once' | 'daily' | 'weekly'
  String _scheduleType = 'now';
  DateTime? _scheduledDate; // date part for 'once'
  TimeOfDay? _scheduledTime; // time part for 'once', or the daily/weekly fire time
  final Set<int> _recurrenceDays = {}; // ISO weekday 1=Mon .. 7=Sun (for 'weekly')
  DateTime? _recurrenceEndDate; // optional stop date for daily/weekly

  static const List<Map<String, dynamic>> _weekdayOptions = [
    {'iso': 1, 'label': 'Mon'},
    {'iso': 2, 'label': 'Tue'},
    {'iso': 3, 'label': 'Wed'},
    {'iso': 4, 'label': 'Thu'},
    {'iso': 5, 'label': 'Fri'},
    {'iso': 6, 'label': 'Sat'},
    {'iso': 7, 'label': 'Sun'},
  ];

  List<Map<String, dynamic>> _historyNotices = [];
  bool _loadingHistory = true;

  List<String> _categories = [];

  @override
  void initState() {
    super.initState();
    _loadStudents();
    _loadHistory();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final list = await widget.authService.getCategories();
      if (!mounted) return;
      setState(() {
        _categories = list;
      });
    } catch (e) {
      // Ignore
    }
  }

  Future<void> _loadStudents() async {
    setState(() => _loadingStudents = true);
    final list = await widget.authService.getAllStudents();
    if (!mounted) return;
    setState(() {
      _students = list;
      _loadingStudents = false;
    });
  }

  Future<void> _loadHistory() async {
    setState(() => _loadingHistory = true);
    try {
      final history = await widget.authService.getSentNotices();
      if (!mounted) return;
      setState(() {
        _historyNotices = history;
        _loadingHistory = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingHistory = false);
    }
  }

  String? _validateScheduleFields() {
    if (_scheduleType == 'once') {
      if (_scheduledDate == null || _scheduledTime == null) {
        return 'Pick a date and time for the scheduled notice';
      }
      final when = DateTime(_scheduledDate!.year, _scheduledDate!.month, _scheduledDate!.day,
          _scheduledTime!.hour, _scheduledTime!.minute);
      if (!when.isAfter(DateTime.now())) {
        return 'Scheduled time must be in the future';
      }
    } else if (_scheduleType == 'daily') {
      if (_scheduledTime == null) return 'Pick a time for the daily notice';
    } else if (_scheduleType == 'weekly') {
      if (_scheduledTime == null) return 'Pick a time for the weekly notice';
      if (_recurrenceDays.isEmpty) return 'Pick at least one day of the week';
    }
    return null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final scheduleError = _validateScheduleFields();
    if (scheduleError != null) {
      ScaffoldMessenger.of(context).showSnackBar(_snack(scheduleError, success: false));
      return;
    }

    final title = _titleController.text.trim();
    final body = _bodyController.text.trim();
    final audience = _audience;
    final category = _category;
    final specificId = _selectedStudent != null ? _selectedStudent!['id'] as String : null;

    DateTime? scheduledAt;
    if (_scheduleType == 'once' && _scheduledDate != null && _scheduledTime != null) {
      scheduledAt = DateTime(_scheduledDate!.year, _scheduledDate!.month, _scheduledDate!.day,
          _scheduledTime!.hour, _scheduledTime!.minute);
    }

    setState(() => _submitting = true);
    try {
      await widget.authService.createNotice(
        title: title,
        body: body,
        audience: audience,
        specificStudentId: specificId,
        category: category,
        scheduleType: _scheduleType,
        scheduledAt: scheduledAt,
        recurrenceTime: (_scheduleType == 'daily' || _scheduleType == 'weekly') ? _scheduledTime : null,
        recurrenceDays: _scheduleType == 'weekly' ? _recurrenceDays.toList() : null,
        recurrenceEndDate: (_scheduleType == 'daily' || _scheduleType == 'weekly') ? _recurrenceEndDate : null,
      );

      // Only dispatch a push right now if the admin chose "Send Now".
      // Scheduled / recurring notices are picked up by the server-side
      // dispatch-scheduled-notices Edge Function (via pg_cron) when they're due.
      if (_scheduleType == 'now') {
        PushNotificationService().sendNoticeNotification(
          title: title,
          body: body,
          audience: audience,
          specificStudentId: specificId,
        ).catchError((err) {
          print("Push notification dispatch failed: $err");
        });
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(_snack(
        _scheduleType == 'now' ? 'Notice sent' : 'Notice scheduled',
        success: true,
      ));
      _titleController.clear();
      _bodyController.clear();
      setState(() {
        _audience = 'All';
        _category = 'General';
        _selectedStudent = null;
        _scheduleType = 'now';
        _scheduledDate = null;
        _scheduledTime = null;
        _recurrenceDays.clear();
        _recurrenceEndDate = null;
      });
      _loadHistory();
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _cancelSchedule(int id) async {
    await widget.authService.cancelScheduledNotice(id);
    _loadHistory();
  }

  Future<void> _pickScheduledDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _scheduledDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _scheduledDate = picked);
  }

  Future<void> _pickScheduledTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _scheduledTime ?? TimeOfDay.now(),
    );
    if (picked != null) setState(() => _scheduledTime = picked);
  }

  Future<void> _pickRecurrenceEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _recurrenceEndDate ?? DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );
    if (picked != null) setState(() => _recurrenceEndDate = picked);
  }

  Future<void> _deleteNotice(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _Palette.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _Palette.danger.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.delete_outline_rounded, color: _Palette.danger, size: 20),
            ),
            const SizedBox(width: 12),
            const Text('Delete Notice',
                style: TextStyle(color: _Palette.textDark, fontSize: 17, fontWeight: FontWeight.w800)),
          ],
        ),
        content: const Text(
          'Are you sure you want to delete this notice?',
          style: TextStyle(color: _Palette.textMuted, fontSize: 13.5, height: 1.4),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            style: TextButton.styleFrom(foregroundColor: _Palette.textMuted),
            child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: _Palette.danger,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Delete', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await widget.authService.deleteNotice(id);
      _loadHistory();
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

  static InputDecoration _fieldDecoration({required String label, IconData? icon}) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: _Palette.textMuted, fontSize: 14),
      prefixIcon: icon != null ? Icon(icon, color: _Palette.primary, size: 20) : null,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _Palette.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _Palette.primary, width: 1.6),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _Palette.danger),
      ),
      filled: true,
      fillColor: _Palette.surface,
    );
  }

  static Color _categoryColor(String category) {
    switch (category) {
      case 'Fees':
        return _Palette.catFees;
      case 'Holiday':
        return _Palette.catHoliday;
      case 'Event':
        return _Palette.catEvent;
      default:
        return _Palette.catGeneral;
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: _Palette.bg,
        appBar: AppBar(
          title: const Text('Notice Management',
              style: TextStyle(color: _Palette.textDark, fontWeight: FontWeight.w800, fontSize: 19)),
          backgroundColor: _Palette.surface,
          surfaceTintColor: Colors.transparent,
          foregroundColor: _Palette.textDark,
          elevation: 0,
          scrolledUnderElevation: 0,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(52),
            child: Container(
              color: _Palette.surface,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: Container(
                height: 44,
                decoration: BoxDecoration(
                  color: _Palette.bg,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: TabBar(
                  indicator: BoxDecoration(
                    color: _Palette.primary,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  indicatorPadding: const EdgeInsets.all(4),
                  dividerColor: Colors.transparent,
                  labelColor: Colors.white,
                  unselectedLabelColor: _Palette.textMuted,
                  labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                  unselectedLabelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  tabs: const [
                    Tab(text: 'Create Notice'),
                    Tab(text: 'History & Review'),
                  ],
                ),
              ),
            ),
          ),
          shape: const Border(bottom: BorderSide(color: _Palette.border, width: 1)),
        ),
        body: TabBarView(
          children: [_buildCreateNoticeTab(), _buildHistoryTab()],
        ),
      ),
    );
  }

  Widget _buildCreateNoticeTab() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 960;
        final isTablet = constraints.maxWidth >= 600 && constraints.maxWidth < 960;
        final horizontalPadding = isDesktop ? 32.0 : (isTablet ? 24.0 : 16.0);

        return Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Form(
              key: _formKey,
              child: ListView(
                padding: EdgeInsets.fromLTRB(horizontalPadding, 20, horizontalPadding, 32),
                children: [
                  Text('COMPOSE', style: TextStyle(
                    fontSize: 11.5, fontWeight: FontWeight.w700, color: _Palette.textFaint, letterSpacing: 1.2)),
              const SizedBox(height: 10),
              TextFormField(
                controller: _titleController,
                style: const TextStyle(color: _Palette.textDark, fontWeight: FontWeight.w600),
                decoration: _fieldDecoration(label: 'Title', icon: Icons.title_rounded),
                validator: (v) => v == null || v.isEmpty ? 'Enter title' : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _bodyController,
                maxLines: 4,
                style: const TextStyle(color: _Palette.textDark),
                decoration: _fieldDecoration(label: 'Body', icon: Icons.notes_rounded),
                validator: (v) => v == null || v.isEmpty ? 'Enter body' : null,
              ),
              const SizedBox(height: 22),
              Text('TARGETING', style: TextStyle(
                fontSize: 11.5, fontWeight: FontWeight.w700, color: _Palette.textFaint, letterSpacing: 1.2)),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                initialValue: _audience,
                dropdownColor: _Palette.surface,
                style: const TextStyle(color: _Palette.textDark, fontSize: 15, fontWeight: FontWeight.w600),
                decoration: _fieldDecoration(label: 'Audience', icon: Icons.groups_rounded),
                items: [
                  const DropdownMenuItem<String>(value: 'All', child: Text('All')),
                  ..._categories.map((cat) => DropdownMenuItem<String>(value: cat, child: Text(cat))),
                  const DropdownMenuItem<String>(value: 'Specific', child: Text('Specific Student')),
                ],
                onChanged: (v) => setState(() => _audience = v ?? 'All'),
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                initialValue: _category,
                dropdownColor: _Palette.surface,
                style: const TextStyle(color: _Palette.textDark, fontSize: 15, fontWeight: FontWeight.w600),
                decoration: _fieldDecoration(label: 'Category', icon: Icons.label_rounded),
                items: const <DropdownMenuItem<String>>[
                  DropdownMenuItem<String>(value: 'General', child: Text('General')),
                  DropdownMenuItem<String>(value: 'Fees', child: Text('Fees Notice')),
                  DropdownMenuItem<String>(value: 'Holiday', child: Text('Holiday Announcement')),
              DropdownMenuItem<String>(value: 'Event', child: Text('School Event')),
            ],
            onChanged: (v) => setState(() => _category = v ?? 'General'),
          ),
          if (_audience == 'Specific') ...[
            const SizedBox(height: 14),
            _loadingStudents
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Center(child: CircularProgressIndicator(color: _Palette.primary)),
                  )
                : DropdownSearch<Map<String, dynamic>>(
                    items: _students,
                    itemAsString: (s) => s['name'] as String,
                    selectedItem: _selectedStudent,
                    popupProps: PopupProps.menu(
                      showSearchBox: true,
                      containerBuilder: (context, popupWidget) => Container(
                        decoration: BoxDecoration(
                          color: _Palette.surface,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: popupWidget,
                      ),
                      searchFieldProps: TextFieldProps(
                        style: const TextStyle(color: _Palette.textDark),
                        decoration: _fieldDecoration(label: 'Search student', icon: Icons.search_rounded),
                      ),
                      itemBuilder: (context, item, isSelected) => ListTile(
                        title: Text(item['name'] ?? '',
                            style: const TextStyle(color: _Palette.textDark, fontWeight: FontWeight.w600)),
                        subtitle: Text(item['student_type'] ?? '',
                            style: const TextStyle(color: _Palette.textMuted, fontSize: 12)),
                      ),
                    ),
                    onChanged: (v) => setState(() => _selectedStudent = v),
                    dropdownDecoratorProps: DropDownDecoratorProps(
                      dropdownSearchDecoration: _fieldDecoration(label: 'Student', icon: Icons.person_rounded),
                    ),
                  ),
          ],
          const SizedBox(height: 22),
          Text('SCHEDULING', style: TextStyle(
            fontSize: 11.5, fontWeight: FontWeight.w700, color: _Palette.textFaint, letterSpacing: 1.2)),
          const SizedBox(height: 10),
          _buildScheduleTypeSelector(),
          const SizedBox(height: 14),
          if (_scheduleType == 'once') _buildOnceFields(),
          if (_scheduleType == 'daily') _buildDailyFields(),
          if (_scheduleType == 'weekly') _buildWeeklyFields(),
          const SizedBox(height: 26),
          SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: _submitting ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: _Palette.primary,
                disabledBackgroundColor: _Palette.primary.withValues(alpha: 0.6),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: _submitting
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.4),
                    )
                  : Text(_scheduleType == 'now' ? 'Send Notice Now' : 'Schedule Notice',
                      style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

  Widget _buildScheduleTypeSelector() {
    final options = <Map<String, dynamic>>[
      {'value': 'now', 'label': 'Send Now', 'icon': Icons.send_rounded},
      {'value': 'once', 'label': 'One Time', 'icon': Icons.event_rounded},
      {'value': 'daily', 'label': 'Daily', 'icon': Icons.repeat_rounded},
      {'value': 'weekly', 'label': 'Weekly', 'icon': Icons.date_range_rounded},
    ];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((opt) {
        final selected = _scheduleType == opt['value'];
        return ChoiceChip(
          showCheckmark: false,
          label: Text(opt['label'] as String,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: selected ? Colors.white : _Palette.textDark)),
          avatar: Icon(opt['icon'] as IconData, size: 16, color: selected ? Colors.white : _Palette.textMuted),
          selected: selected,
          onSelected: (_) => setState(() => _scheduleType = opt['value'] as String),
          selectedColor: _Palette.primary,
          backgroundColor: _Palette.surface,
          side: BorderSide(color: selected ? _Palette.primary : _Palette.border),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        );
      }).toList(),
    );
  }

  Widget _pickerTile({required IconData icon, required String label, required String value, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: _Palette.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _Palette.border),
        ),
        child: Row(
          children: [
            Icon(icon, color: _Palette.primary, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(color: _Palette.textMuted, fontSize: 11.5, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(value, style: const TextStyle(color: _Palette.textDark, fontSize: 14.5, fontWeight: FontWeight.w700)),
                ],
              ),
            ),
            const Icon(Icons.keyboard_arrow_down_rounded, color: _Palette.textFaint),
          ],
        ),
      ),
    );
  }

  Widget _buildOnceFields() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _pickerTile(
                icon: Icons.calendar_today_rounded,
                label: 'Date',
                value: _scheduledDate == null
                    ? 'Select date'
                    : '${_scheduledDate!.day.toString().padLeft(2, '0')}/${_scheduledDate!.month.toString().padLeft(2, '0')}/${_scheduledDate!.year}',
                onTap: _pickScheduledDate,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _pickerTile(
                icon: Icons.access_time_rounded,
                label: 'Time',
                value: _scheduledTime == null ? 'Select time' : _scheduledTime!.format(context),
                onTap: _pickScheduledTime,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        const Align(
          alignment: Alignment.centerLeft,
          child: Text('Notice will be sent once, automatically, at this date & time.',
              style: TextStyle(color: _Palette.textFaint, fontSize: 12, fontWeight: FontWeight.w500)),
        ),
      ],
    );
  }

  Widget _buildDailyFields() {
    return Column(
      children: [
        _pickerTile(
          icon: Icons.access_time_rounded,
          label: 'Time (every day)',
          value: _scheduledTime == null ? 'Select time' : _scheduledTime!.format(context),
          onTap: _pickScheduledTime,
        ),
        const SizedBox(height: 12),
        _pickerTile(
          icon: Icons.event_busy_rounded,
          label: 'Repeat until (optional)',
          value: _recurrenceEndDate == null
              ? 'No end date'
              : '${_recurrenceEndDate!.day.toString().padLeft(2, '0')}/${_recurrenceEndDate!.month.toString().padLeft(2, '0')}/${_recurrenceEndDate!.year}',
          onTap: _pickRecurrenceEndDate,
        ),
        if (_recurrenceEndDate != null)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => setState(() => _recurrenceEndDate = null),
              child: const Text('Clear end date', style: TextStyle(color: _Palette.primary, fontSize: 12.5)),
            ),
          ),
        const SizedBox(height: 4),
        const Align(
          alignment: Alignment.centerLeft,
          child: Text('Notice will repeat every day at this time.',
              style: TextStyle(color: _Palette.textFaint, fontSize: 12, fontWeight: FontWeight.w500)),
        ),
      ],
    );
  }

  Widget _buildWeeklyFields() {
    return Column(
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _weekdayOptions.map((d) {
            final iso = d['iso'] as int;
            final selected = _recurrenceDays.contains(iso);
            return FilterChip(
              label: Text(d['label'] as String,
                  style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: selected ? Colors.white : _Palette.textDark)),
              selected: selected,
              onSelected: (v) => setState(() {
                if (v) {
                  _recurrenceDays.add(iso);
                } else {
                  _recurrenceDays.remove(iso);
                }
              }),
              selectedColor: _Palette.primary,
              backgroundColor: _Palette.surface,
              side: BorderSide(color: selected ? _Palette.primary : _Palette.border),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
            );
          }).toList(),
        ),
        const SizedBox(height: 12),
        _pickerTile(
          icon: Icons.access_time_rounded,
          label: 'Time',
          value: _scheduledTime == null ? 'Select time' : _scheduledTime!.format(context),
          onTap: _pickScheduledTime,
        ),
        const SizedBox(height: 12),
        _pickerTile(
          icon: Icons.event_busy_rounded,
          label: 'Repeat until (optional)',
          value: _recurrenceEndDate == null
              ? 'No end date'
              : '${_recurrenceEndDate!.day.toString().padLeft(2, '0')}/${_recurrenceEndDate!.month.toString().padLeft(2, '0')}/${_recurrenceEndDate!.year}',
          onTap: _pickRecurrenceEndDate,
        ),
        if (_recurrenceEndDate != null)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => setState(() => _recurrenceEndDate = null),
              child: const Text('Clear end date', style: TextStyle(color: _Palette.primary, fontSize: 12.5)),
            ),
          ),
        const SizedBox(height: 4),
        const Align(
          alignment: Alignment.centerLeft,
          child: Text('Notice will repeat every selected day at this time.',
              style: TextStyle(color: _Palette.textFaint, fontSize: 12, fontWeight: FontWeight.w500)),
        ),
      ],
    );
  }

  Widget _buildHistoryTab() {
    if (_loadingHistory) {
      return const Center(child: CircularProgressIndicator(color: _Palette.primary));
    }

    if (_historyNotices.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadHistory,
        color: _Palette.primary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.7,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: _Palette.textFaint.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.campaign_rounded, size: 46, color: _Palette.textFaint),
                  ),
                  const SizedBox(height: 18),
                  const Text('No Notices Created Yet',
                      style: TextStyle(fontSize: 16.5, color: _Palette.textDark, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  const Text('Notices you create will show up here',
                      style: TextStyle(fontSize: 13, color: _Palette.textMuted, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadHistory,
      color: _Palette.primary,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = constraints.maxWidth >= 960;
          final isTablet = constraints.maxWidth >= 600 && constraints.maxWidth < 960;
          final horizontalPadding = isDesktop ? 32.0 : (isTablet ? 24.0 : 16.0);

          return Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1000),
              child: ListView.builder(
                padding: EdgeInsets.fromLTRB(horizontalPadding, 16, horizontalPadding, 32),
                itemCount: _historyNotices.length,
                itemBuilder: (context, index) {
              final notice = _historyNotices[index];
              final title = notice['title'] ?? '';
              final body = notice['body'] ?? '';
              final category = notice['category'] ?? 'General';
              final audience = notice['target_audience'] ?? '';
              final dateStr = notice['created_at'] != null
                  ? notice['created_at'].toString().split('T').first
                  : '';
              final scheduleType = notice['schedule_type'] as String? ?? 'now';
              final status = notice['status'] as String? ?? 'sent';
              final noticeId = notice['id'] as int;
              final categoryColor = _categoryColor(category);

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _Palette.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _Palette.border),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 10,
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
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: categoryColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            category,
                            style: TextStyle(
                              color: categoryColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _statusChip(scheduleType, status),
                        const Spacer(),
                        if (dateStr.isNotEmpty)
                          Text(
                            dateStr,
                            style: const TextStyle(
                              color: _Palette.textMuted,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        const SizedBox(width: 4),
                        PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert_rounded, size: 18, color: _Palette.textMuted),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          color: _Palette.surface,
                          onSelected: (val) {
                            if (val == 'delete') _deleteNotice(noticeId);
                            if (val == 'cancel') _cancelSchedule(noticeId);
                          },
                          itemBuilder: (_) => [
                            if (status == 'pending')
                              const PopupMenuItem(
                                value: 'cancel',
                                child: Row(
                                  children: [
                                    Icon(Icons.cancel_outlined, size: 18, color: _Palette.catFees),
                                    SizedBox(width: 8),
                                    Text('Cancel Schedule', style: TextStyle(color: _Palette.catFees, fontWeight: FontWeight.w600)),
                                  ],
                                ),
                              ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Icons.delete_outline_rounded, size: 18, color: _Palette.danger),
                                  SizedBox(width: 8),
                                  Text('Delete', style: TextStyle(color: _Palette.danger, fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w700,
                        color: _Palette.textDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      body,
                      style: const TextStyle(
                        fontSize: 13,
                        color: _Palette.textMuted,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Icon(Icons.people_alt_rounded, size: 13, color: _Palette.textFaint),
                        const SizedBox(width: 4),
                        Text(
                          audience,
                          style: const TextStyle(
                            color: _Palette.textFaint,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    if (scheduleType != 'now' && notice['next_run_at'] != null) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.schedule_rounded, size: 13, color: _Palette.primary),
                          const SizedBox(width: 4),
                          Text(
                            'Next: ${_formatNextRun(notice['next_run_at'].toString())}',
                            style: const TextStyle(color: _Palette.primary, fontSize: 11.5, fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
          ),
        );
      },
    ),
  );
}

  Widget _statusChip(String scheduleType, String status) {
    late Color color;
    late String label;
    late IconData icon;

    if (status == 'cancelled') {
      color = _Palette.textFaint;
      label = 'Cancelled';
      icon = Icons.block_rounded;
    } else if (status == 'sending') {
      color = _Palette.catFees;
      label = 'Sending…';
      icon = Icons.sync_rounded;
    } else if (status == 'completed') {
      color = _Palette.textMuted;
      label = 'Completed';
      icon = Icons.task_alt_rounded;
    } else if (status == 'pending') {
      color = _Palette.primary;
      label = scheduleType == 'daily'
          ? 'Repeats Daily'
          : scheduleType == 'weekly'
              ? 'Repeats Weekly'
              : 'Scheduled';
      icon = scheduleType == 'now' ? Icons.event_rounded : Icons.repeat_rounded;
    } else {
      color = _Palette.success;
      label = 'Sent';
      icon = Icons.check_circle_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  String _formatNextRun(String isoString) {
    try {
      final dt = DateTime.parse(isoString).toLocal();
      final hh = dt.hour.toString().padLeft(2, '0');
      final mm = dt.minute.toString().padLeft(2, '0');
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} $hh:$mm';
    } catch (_) {
      return isoString;
    }
  }
}