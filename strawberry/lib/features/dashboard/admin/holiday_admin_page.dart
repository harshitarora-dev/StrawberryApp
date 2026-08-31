import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:strawberry/features/auth/auth_service.dart';
import 'package:strawberry/features/auth/push_notification_service.dart';

import 'package:strawberry/core/theme/app_colors.dart';
import 'package:strawberry/core/widgets/playschool_animations.dart';

class _Palette {
  static const primary = AppColors.violet; // Violet theme for Holidays
  static const primaryDark = AppColors.violetDark;
  static const primarySoft = AppColors.violetSoft;

  static const bg = AppColors.background;
  static const surface = AppColors.surface;
  static const border = AppColors.borderSubtle;

  static const textDark = AppColors.textDark;
  static const textMuted = AppColors.textMuted;

  static const success = AppColors.emerald;
  static const danger = AppColors.danger;
}

class HolidayAdminPage extends StatefulWidget {
  final AuthService authService;
  const HolidayAdminPage({super.key, required this.authService});

  @override
  State<HolidayAdminPage> createState() => _HolidayAdminPageState();
}

class _HolidayAdminPageState extends State<HolidayAdminPage> {
  DateTime _visibleMonth = DateTime(DateTime.now().year, DateTime.now().month, 1);
  List<Map<String, dynamic>> _holidays = [];
  List<String> _categories = [];
  String? _selectedCategory; // Null means 'All' / Filter All
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final cats = await widget.authService.getCategories();
      final hols = await widget.authService.getHolidaysForMonth(
        _visibleMonth.year,
        _visibleMonth.month,
      );
      if (!mounted) return;
      setState(() {
        _categories = cats;
        _holidays = hols;
        _loading = false;
      });
    } catch (e) {
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

  Future<void> _deleteHoliday(int id) async {
    try {
      await widget.authService.deleteHoliday(id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Holiday entry removed from calendar 🗑️')),
      );
      _loadData();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to delete holiday entry')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _Palette.bg,
      appBar: AppBar(
        backgroundColor: _Palette.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text(
          'Holiday Management',
          style: TextStyle(
            color: _Palette.textDark,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        iconTheme: const IconThemeData(color: _Palette.textDark),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadData,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: _Palette.primary,
        onPressed: _openAddHolidayDialog,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text(
          'Add Holiday / Exception',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
      ),
      body: _loading
          ? const StrawberryLoader(message: 'Loading the holiday calendar... 🎉')
          : LayoutBuilder(
              builder: (context, constraints) {
                final isDesktop = constraints.maxWidth >= 900;
                final isTablet = constraints.maxWidth >= 600 && constraints.maxWidth < 900;
                final horizontalPadding = isDesktop ? 32.0 : (isTablet ? 24.0 : 16.0);

          return Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1100),
              child: Column(
                children: [
                  _buildMonthSelector(),
                  _buildCategoryFilters(),
                  Expanded(
                    child: ListView(
                      padding: EdgeInsets.fromLTRB(horizontalPadding, 16, horizontalPadding, 80),
                      children: isDesktop
                          ? [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    flex: 5,
                                    child: _buildCalendarGrid(),
                                  ),
                                  const SizedBox(width: 20),
                                  Expanded(
                                    flex: 5,
                                    child: _buildHolidayList(),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 80),
                            ]
                          : [
                              _buildCalendarGrid(),
                              const SizedBox(height: 20),
                              _buildHolidayList(),
                              const SizedBox(height: 80),
                            ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMonthSelector() {
    final title = DateFormat('MMMM yyyy').format(_visibleMonth);
    return Container(
      color: _Palette.surface,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left_rounded, color: _Palette.textDark),
            onPressed: () => _changeMonth(-1),
          ),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: _Palette.textDark,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right_rounded, color: _Palette.textDark),
            onPressed: () => _changeMonth(1),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryFilters() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          FilterChip(
            selected: _selectedCategory == null,
            label: const Text('All Categories'),
            selectedColor: _Palette.primarySoft,
            checkmarkColor: _Palette.primary,
            labelStyle: TextStyle(
              color: _selectedCategory == null ? _Palette.primaryDark : _Palette.textMuted,
              fontWeight: FontWeight.w700,
            ),
            onSelected: (_) => setState(() => _selectedCategory = null),
          ),
          const SizedBox(width: 8),
          ..._categories.map((cat) {
            final isSelected = _selectedCategory == cat;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                selected: isSelected,
                label: Text(cat),
                selectedColor: _Palette.primarySoft,
                checkmarkColor: _Palette.primary,
                labelStyle: TextStyle(
                  color: isSelected ? _Palette.primaryDark : _Palette.textMuted,
                  fontWeight: FontWeight.w700,
                ),
                onSelected: (_) => setState(() => _selectedCategory = cat),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildCalendarGrid() {
    final daysInMonth = DateTime(_visibleMonth.year, _visibleMonth.month + 1, 0).day;
    final firstWeekday = DateTime(_visibleMonth.year, _visibleMonth.month, 1).weekday; // 1 = Mon, 7 = Sun

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _Palette.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _Palette.border),
      ),
      child: Column(
        children: [
          // Days of week header
          Row(
            children: ['M', 'T', 'W', 'T', 'F', 'S', 'S'].map((day) {
              return Expanded(
                child: Center(
                  child: Text(
                    day,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: _Palette.textMuted,
                      fontSize: 13,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          // Days grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
            ),
            itemCount: (firstWeekday - 1) + daysInMonth,
            itemBuilder: (context, index) {
              if (index < firstWeekday - 1) {
                return const SizedBox.shrink();
              }
              final dayNumber = index - (firstWeekday - 1) + 1;
              final date = DateTime(_visibleMonth.year, _visibleMonth.month, dayNumber);
              final dateStr = DateFormat('yyyy-MM-dd').format(date);

              return _buildDayCell(date, dateStr, dayNumber);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDayCell(DateTime date, String dateStr, int dayNumber) {
    final activeCat = _selectedCategory ?? 'All';
    
    // Resolution check for calendar cell color
    final exception = _holidays.firstWhere(
      (h) => h['date'] == dateStr && h['type'] == 'working_day' && (h['category'] == activeCat || _selectedCategory == null),
      orElse: () => {},
    );

    final explicitHoliday = _holidays.firstWhere(
      (h) => h['date'] == dateStr && h['type'] == 'holiday' && (h['category'] == 'All' || h['category'] == activeCat || _selectedCategory == null),
      orElse: () => {},
    );

    final isSun = date.weekday == DateTime.sunday;
    final isSat = date.weekday == DateTime.saturday && widget.authService.isSaturdayDefaultHoliday(activeCat);

    Color dotColor = Colors.transparent;
    bool hasDot = false;

    if (exception.isNotEmpty) {
      // Working day override!
      hasDot = true;
      dotColor = _Palette.success; // Green
    } else if (isSun || isSat) {
      hasDot = true;
      dotColor = _Palette.danger; // Red for default weekend
    } else if (explicitHoliday.isNotEmpty) {
      hasDot = true;
      if (explicitHoliday['category'] == 'All') {
        dotColor = _Palette.danger; // Red for All
      } else {
        dotColor = _Palette.primary; // Purple for specific category
      }
    }

    return InkWell(
      onTap: () => _showDayDetailSheet(date, dateStr, exception, explicitHoliday, isSun, isSat),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        decoration: BoxDecoration(
          color: _Palette.bg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _Palette.border.withValues(alpha: 0.5)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '$dayNumber',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: (isSun || isSat) ? _Palette.danger : _Palette.textDark,
              ),
            ),
            if (hasDot) ...[
              const SizedBox(height: 2),
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: dotColor,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showDayDetailSheet(
    DateTime date,
    String dateStr,
    Map<String, dynamic> exception,
    Map<String, dynamic> holiday,
    bool isSun,
    bool isSat,
  ) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                DateFormat('EEEE, dd MMMM yyyy').format(date),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: _Palette.textDark,
                ),
              ),
              const SizedBox(height: 16),
              if (exception.isNotEmpty) ...[
                ListTile(
                  leading: const Icon(Icons.check_circle_rounded, color: _Palette.success),
                  title: Text(exception['title'] ?? 'Working Day Exception'),
                  subtitle: Text('Category: ${exception['category']} (Working Day Override)'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, color: _Palette.danger),
                    onPressed: () {
                      Navigator.pop(context);
                      _deleteHoliday(exception['id']);
                    },
                  ),
                ),
              ] else if (holiday.isNotEmpty) ...[
                ListTile(
                  leading: const Icon(Icons.event_busy_rounded, color: _Palette.primary),
                  title: Text(holiday['title'] ?? 'Holiday'),
                  subtitle: Text('Category: ${holiday['category']}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, color: _Palette.danger),
                    onPressed: () {
                      Navigator.pop(context);
                      _deleteHoliday(holiday['id']);
                    },
                  ),
                ),
              ] else if (isSun) ...[
                const ListTile(
                  leading: Icon(Icons.event_busy_rounded, color: _Palette.danger),
                  title: Text('Sunday'),
                  subtitle: Text('Default Off Day for all categories'),
                ),
              ] else if (isSat) ...[
                const ListTile(
                  leading: Icon(Icons.event_busy_rounded, color: _Palette.danger),
                  title: Text('Saturday'),
                  subtitle: Text('Default Off Day for LKG, Nursery, Playgroup, UKG'),
                ),
              ] else ...[
                const ListTile(
                  leading: Icon(Icons.work_rounded, color: _Palette.textMuted),
                  title: Text('Normal Working Day'),
                  subtitle: Text('No holiday or exception configured'),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildHolidayList() {
    final filtered = _holidays.where((h) {
      if (_selectedCategory == null) return true;
      return h['category'] == 'All' || h['category'] == _selectedCategory;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Configured Holidays & Exceptions',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: _Palette.textDark,
          ),
        ),
        const SizedBox(height: 12),
        if (filtered.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _Palette.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _Palette.border),
            ),
            child: const Center(
              child: Text(
                'No explicit holidays set for this month.\n(Default weekends apply)',
                textAlign: TextAlign.center,
                style: TextStyle(color: _Palette.textMuted),
              ),
            ),
          )
        else
          ...filtered.map((h) {
            final isWorkingDay = h['type'] == 'working_day';
            final emoji = isWorkingDay ? '✏️' : (h['category'] == 'All' ? '🏖️' : '🎈');

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _Palette.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _Palette.border),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isWorkingDay
                          ? AppColors.emeraldSoft
                          : (h['category'] == 'All'
                              ? AppColors.dangerSoft
                              : AppColors.violetSoft),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(emoji, style: const TextStyle(fontSize: 16)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          h['title'] ?? (isWorkingDay ? 'Working Day' : 'Holiday'),
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: _Palette.textDark,
                            fontSize: 14.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${DateFormat('EEEE, d MMMM yyyy').format(DateTime.parse(h['date']))} · Category: ${h['category']}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: _Palette.textMuted,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, color: _Palette.danger, size: 20),
                    onPressed: () => _deleteHoliday(h['id']),
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }

  void _openAddHolidayDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _AddHolidaySheet(
        categories: _categories,
        onSave: (date, title, category, type, description) async {
          await widget.authService.addHoliday(
            date: date,
            title: title,
            category: category,
            type: type,
            description: description,
          );

          // Send Push Notification to desired categories (even when app is closed)
          try {
            final parsedDate = DateTime.tryParse(date);
            final formattedDate = parsedDate != null
                ? DateFormat('dd MMM yyyy (EEEE)').format(parsedDate)
                : date;
            final isHoliday = type == 'holiday';

            final notifTitle = isHoliday
                ? '🎉 Holiday Declared: $title'
                : '📅 Special Working Day: $title';
            final notifBody = isHoliday
                ? 'Notice: $formattedDate is declared as a Holiday for ${category == "All" ? "all categories" : category}.'
                : 'Notice: $formattedDate will be a working day for $category category.';

            await PushNotificationService().sendNoticeNotification(
              title: notifTitle,
              body: notifBody,
              audience: category,
            );
          } catch (e) {
            // Push notification fail should not break holiday creation
          }

          _loadData();
        },
      ),
    );
  }
}

class _AddHolidaySheet extends StatefulWidget {
  final List<String> categories;
  final Future<void> Function(String date, String title, String category, String type, String? desc) onSave;

  const _AddHolidaySheet({
    required this.categories,
    required this.onSave,
  });

  @override
  State<_AddHolidaySheet> createState() => _AddHolidaySheetState();
}

class _AddHolidaySheetState extends State<_AddHolidaySheet> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  String _selectedCategory = 'All';
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TabBar(
            controller: _tabController,
            labelColor: _Palette.primary,
            unselectedLabelColor: _Palette.textMuted,
            indicatorColor: _Palette.primary,
            tabs: const [
              Tab(text: 'Mark Holiday'),
              Tab(text: 'Weekend Class Exception'),
            ],
            onTap: (index) {
              setState(() {
                if (index == 1 && _selectedCategory == 'All' && widget.categories.isNotEmpty) {
                  _selectedCategory = widget.categories.first;
                }
              });
            },
          ),
          const SizedBox(height: 16),
          // Form fields
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Date', style: TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text(DateFormat('yyyy-MM-dd (EEEE)').format(_selectedDate)),
            trailing: const Icon(Icons.calendar_today_rounded, color: _Palette.primary),
            onTap: () async {
              DateTime initial = _selectedDate;
              if (_tabController.index == 1 &&
                  initial.weekday != DateTime.saturday &&
                  initial.weekday != DateTime.sunday) {
                final daysUntilSat = (DateTime.saturday - initial.weekday) % 7;
                initial = initial.add(Duration(days: daysUntilSat == 0 ? 7 : daysUntilSat));
              }

              final picked = await showDatePicker(
                context: context,
                initialDate: initial,
                firstDate: DateTime(2025),
                lastDate: DateTime(2030),
                selectableDayPredicate: (date) {
                  if (_tabController.index == 1) {
                    // Weekend class exception: allow Sat or Sun
                    return date.weekday == DateTime.saturday || date.weekday == DateTime.sunday;
                  }
                  return true;
                },
              );
              if (picked != null) {
                setState(() => _selectedDate = picked);
              }
            },
          ),
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: 'Title (e.g. Diwali / Special Class)',
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _selectedCategory,
            decoration: const InputDecoration(labelText: 'Category'),
            items: [
              if (_tabController.index == 0)
                const DropdownMenuItem(value: 'All', child: Text('All Categories')),
              ...widget.categories.map((c) => DropdownMenuItem(value: c, child: Text(c))),
            ],
            onChanged: (val) {
              if (val != null) setState(() => _selectedCategory = val);
            },
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _Palette.primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _saving
                  ? null
                  : () async {
                      if (_titleController.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Hold up! Give this holiday or event a title 🎉')),
                        );
                        return;
                      }
                      setState(() => _saving = true);
                      final type = _tabController.index == 0 ? 'holiday' : 'working_day';
                      final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
                      await widget.onSave(
                        dateStr,
                        _titleController.text.trim(),
                        _selectedCategory,
                        type,
                        _descController.text.trim().isEmpty ? null : _descController.text.trim(),
                      );
                      if (mounted) Navigator.pop(context);
                    },
              child: _saving
                  ? const BtnLoader()
                  : Text(
                      _tabController.index == 0 ? 'Save Holiday' : 'Save Exception',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
