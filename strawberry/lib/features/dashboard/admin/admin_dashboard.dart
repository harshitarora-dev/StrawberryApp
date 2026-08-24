import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:strawberry/features/auth/auth_screen.dart';
import 'package:strawberry/features/auth/auth_service.dart';
import 'package:strawberry/features/dashboard/admin/review_analytics_page.dart';
import 'attendance_mark_page.dart';
import 'gallery_admin_page.dart';
import 'notice_admin_page.dart';
import 'student_detail_page.dart';
import 'categories_admin_page.dart';
import 'manage_admins_page.dart';
import 'fee_payments_admin_page.dart';
import 'holiday_admin_page.dart';
import 'package:strawberry/features/chat/chat_page.dart';

import 'package:strawberry/core/theme/app_colors.dart';

/// ---------------------------------------------------------------------
/// Design tokens — Strawberry admin panel (Bridged with AppTheme)
/// ---------------------------------------------------------------------
class _Palette {
  static const primary = AppColors.primary;
  static const primaryDark = AppColors.primaryDark;
  static const primarySoft = AppColors.primarySoft;
  static const accentPeach = AppColors.primaryLight;
  static const leafGreen = AppColors.emerald;
  static const amber = AppColors.amber;
  static const violet = AppColors.violet;
  static const blueAccent = AppColors.sky;

  static const bg = AppColors.background;
  static const surface = AppColors.surface;
  static const border = AppColors.borderSubtle;

  static const textDark = AppColors.textDark;
  static const textMuted = AppColors.textMuted;
  static const textFaint = AppColors.textFaint;

  static const success = AppColors.emerald;
  static const danger = AppColors.danger;
}

class _AdminTextStyles {
  static const title = TextStyle(
    fontSize: 19,
    fontWeight: FontWeight.w800,
    color: _Palette.textDark,
    letterSpacing: 0.1,
  );
  static const sectionHeading = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w800,
    color: _Palette.textDark,
    letterSpacing: 0.1,
  );
  static const cardTitle = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w700,
    color: _Palette.textDark,
  );
  static const cardSubtitle = TextStyle(
    fontSize: 12.5,
    fontWeight: FontWeight.w500,
    color: _Palette.textMuted,
  );
}

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final _authService = AuthService();

  int _navIndex = 0;

  List<Map<String, dynamic>> _pendingRequests = [];
  bool _loadingRequests = true;

  List<Map<String, dynamic>> _allStudents = [];
  bool _loadingStudents = true;
  List<Map<String, dynamic>> _chatStudents = [];
  bool _loadingChats = true;

  List<String> _categories = [];

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    _loadRequests();
    _loadStudents();
    _loadChats();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final list = await _authService.getCategories();
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
    try {
      final list = await _authService.getAllStudents();
      if (!mounted) return;
      setState(() {
        _allStudents = list;
        _loadingStudents = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingStudents = false);
    }
  }

  Future<void> _loadChats() async {
    setState(() => _loadingChats = true);
    try {
      final chats = await _authService.getChatList();
      if (!mounted) return;
      setState(() {
        _chatStudents = chats;
        _loadingChats = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingChats = false);
    }
  }

  Future<void> _loadRequests() async {
    setState(() => _loadingRequests = true);
    try {
      final requests = await _authService.getPendingRequests();
      if (!mounted) return;
      setState(() {
        _pendingRequests = requests;
        _loadingRequests = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingRequests = false);
    }
  }

  Future<void> _logout() async {
    await _authService.logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const AuthScreen()),
      (route) => false,
    );
  }

  // ---------------------------------------------------------------------
  // Navigation helpers — sub pages
  // ---------------------------------------------------------------------
  // NOTE: AttendanceMarkPage / GalleryAdminPage / NoticeAdminPage already
  // manage their own Scaffold + AppBar internally (they were previously
  // used as raw TabBarView children). Pushing them directly — instead of
  // wrapping in a second Scaffold — avoids nested-Scaffold conflicts that
  // were causing the back button to crash out of the app.
  void _openAttendancePage() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AttendanceMarkPage(authService: _authService),
      ),
    );
  }

  void _openGalleryPage() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => GalleryAdminPage(authService: _authService),
      ),
    );
  }

  void _openNoticePage() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => NoticeAdminPage(authService: _authService),
      ),
    );
  }

  void _openAdminsPage() {
    if (_authService.currentUserEmail != 'dev.harshitcreations@gmail.com')
      return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ManageAdminsPage(authService: _authService),
      ),
    );
  }

  void _openFeePaymentsPage() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => FeePaymentsAdminPage(authService: _authService),
      ),
    );
  }

  void _openHolidayPage() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => HolidayAdminPage(authService: _authService),
      ),
    );
  }

  void _openReviewPage() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ReviewAnalyticsPage(authService: _authService),
      ),
    );
  }

  void _openCategoriesPage() {
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (_) => CategoriesAdminPage(authService: _authService),
          ),
        )
        .then((_) {
          _loadCategories();
          _loadStudents();
        });
  }

  void _goToNav(int index) => setState(() => _navIndex = index);

  // ---------------------------------------------------------------------
  // Approval bottom sheet
  // ---------------------------------------------------------------------
  void _openApprovalSheet(Map<String, dynamic> request) {
    final name = request['name'] ?? 'Unknown';
    final uid = request['id'] ?? '';

    String? _selectedStudentType;
    final feesController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _Palette.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
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
                    // Drag handle
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 18),
                        decoration: BoxDecoration(
                          color: _Palette.border,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Approve Student',
                          style: _AdminTextStyles.title,
                        ),
                        InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: _Palette.bg,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close_rounded,
                              color: _Palette.textMuted,
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // Student summary chip
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [_Palette.primarySoft, Colors.white],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: _Palette.border),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(2),
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  _Palette.primary,
                                  _Palette.accentPeach,
                                ],
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: CircleAvatar(
                              radius: 20,
                              backgroundColor: Colors.white,
                              backgroundImage:
                                  (request['photo_url'] as String?) != null
                                  ? NetworkImage(request['photo_url'] as String)
                                  : null,
                              child: (request['photo_url'] as String?) == null
                                  ? const Icon(
                                      Icons.person_rounded,
                                      color: _Palette.primary,
                                      size: 20,
                                    )
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name,
                                  style: const TextStyle(
                                    fontSize: 15.5,
                                    fontWeight: FontWeight.w700,
                                    color: _Palette.textDark,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  request['email'] ?? '',
                                  style: _AdminTextStyles.cardSubtitle,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Student Type Dropdown
                    DropdownButtonFormField<String>(
                      value: _selectedStudentType,
                      dropdownColor: _Palette.surface,
                      style: const TextStyle(
                        color: _Palette.textDark,
                        fontSize: 15,
                      ),
                      decoration: _adminInputDecoration(
                        label: 'Student Type',
                        icon: Icons.school_rounded,
                      ),
                      items: _categories.map((cat) {
                        return DropdownMenuItem<String>(
                          value: cat,
                          child: Text(cat),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setModalState(() {
                          _selectedStudentType = value;
                        });
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please select student type';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),

                    // Fees
                    TextFormField(
                      controller: feesController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      style: const TextStyle(color: _Palette.textDark),
                      decoration: _adminInputDecoration(
                        label: 'Fees',
                        icon: Icons.currency_rupee_rounded,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter fees';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 22),
                    SizedBox(
                      height: 54,
                      child: ElevatedButton(
                        onPressed: () async {
                          if (!formKey.currentState!.validate()) return;

                          final type = _selectedStudentType!;
                          final fees =
                              double.tryParse(feesController.text.trim()) ??
                              0.0;

                          try {
                            await _authService.approveStudent(uid, type, fees);
                            if (!mounted) return;
                            Navigator.of(context).pop(); // Close bottom sheet
                            ScaffoldMessenger.of(context).showSnackBar(
                              _adminSnackBar(
                                'Successfully approved $name!',
                                success: true,
                              ),
                            );
                            _loadRequests();
                          } catch (e) {
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              _adminSnackBar(
                                'Failed to approve student. Please try again.',
                                success: false,
                              ),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _Palette.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        child: const Text(
                          'Approve & Enroll',
                          style: TextStyle(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Reject button
                    SizedBox(
                      height: 48,
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (dialogCtx) => AlertDialog(
                              backgroundColor: _Palette.surface,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              title: const Text(
                                'Reject Application?',
                                style: TextStyle(
                                  color: _Palette.textDark,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              content: Text(
                                'Reject the application from $name? They will be notified and can re-apply.',
                                style: const TextStyle(
                                  color: _Palette.textMuted,
                                ),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(dialogCtx, false),
                                  child: const Text(
                                    'Cancel',
                                    style: TextStyle(color: _Palette.textMuted),
                                  ),
                                ),
                                ElevatedButton(
                                  onPressed: () =>
                                      Navigator.pop(dialogCtx, true),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _Palette.danger,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  child: const Text('Reject'),
                                ),
                              ],
                            ),
                          );
                          if (confirm == true) {
                            try {
                              if (!mounted) return;
                              Navigator.of(context).pop(); // Close bottom sheet
                              await _authService.rejectStudent(uid);
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                _adminSnackBar(
                                  'Application from $name has been rejected.',
                                  success: false,
                                ),
                              );
                              _loadRequests();
                            } catch (e) {
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                _adminSnackBar(
                                  'Failed to reject. Try again.',
                                  success: false,
                                ),
                              );
                            }
                          }
                        },
                        icon: const Icon(
                          Icons.close_rounded,
                          color: _Palette.danger,
                          size: 18,
                        ),
                        label: const Text(
                          'Reject Application',
                          style: TextStyle(
                            color: _Palette.danger,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: _Palette.danger),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
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

  static InputDecoration _adminInputDecoration({
    required String label,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: _Palette.textMuted, fontSize: 14),
      prefixIcon: Icon(icon, color: _Palette.primary, size: 20),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: _Palette.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: _Palette.primary, width: 1.6),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: _Palette.danger),
      ),
      filled: true,
      fillColor: _Palette.bg,
    );
  }

  static SnackBar _adminSnackBar(String message, {required bool success}) {
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
              message,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
      backgroundColor: success ? _Palette.success : _Palette.danger,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      margin: const EdgeInsets.all(16),
    );
  }

  // ---------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return PopScope(
      // If we're on any tab other than Home, back should take the admin
      // back to Home first — not exit the app. Only when already on Home
      // (nothing left to unwind inside the dashboard) does back behave
      // normally (pop this route / exit, same as before).
      canPop: _navIndex == 0,
      onPopInvoked: (didPop) {
        if (didPop) return;
        if (_navIndex != 0) {
          setState(() => _navIndex = 0);
        }
      },
      child: Scaffold(
        backgroundColor: _Palette.bg,
        body: SafeArea(
          bottom: false,
          child: _responsive(
            IndexedStack(
              index: _navIndex,
              children: [
                _buildHomeTab(),
                _buildPendingTab(),
                _buildStudentsTab(),
                _buildChatInboxTab(),
                _buildMoreTab(),
              ],
            ),
          ),
        ),
        bottomNavigationBar: SafeArea(child: _responsive(_buildNavBar())),
      ),
    );
  }

  /// Keeps content comfortably readable and centered on tablets / foldables /
  /// desktop-width windows, while behaving exactly like a normal full-width
  /// layout on phones (the vast majority of admin usage).
  Widget _responsive(Widget child) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const maxContentWidth = 680.0;
        if (constraints.maxWidth <= maxContentWidth) return child;
        return Align(
          alignment: Alignment.topCenter,
          child: SizedBox(width: maxContentWidth, child: child),
        );
      },
    );
  }

  // ---------------------------------------------------------------------
  // Bottom navigation — modern floating pill bar
  // ---------------------------------------------------------------------
  Widget _buildNavBar() {
    final items = <_NavItem>[
      const _NavItem(icon: Icons.dashboard_rounded, label: 'Home'),
      _NavItem(
        icon: Icons.pending_actions_rounded,
        label: 'Requests',
        badge: _pendingRequests.length,
      ),
      const _NavItem(icon: Icons.school_rounded, label: 'Students'),
      const _NavItem(icon: Icons.chat_bubble_rounded, label: 'Chats'),
      const _NavItem(icon: Icons.apps_rounded, label: 'More'),
    ];

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      decoration: BoxDecoration(
        color: _Palette.surface,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(items.length, (i) {
          final item = items[i];
          final active = _navIndex == i;
          return Expanded(
            child: InkWell(
              onTap: () => _goToNav(i),
              borderRadius: BorderRadius.circular(20),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOut,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: active ? _Palette.primarySoft : Colors.transparent,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Icon(
                          item.icon,
                          color: active
                              ? _Palette.primaryDark
                              : _Palette.textFaint,
                          size: 22,
                        ),
                        if (item.badge != null && item.badge! > 0)
                          Positioned(
                            right: -7,
                            top: -5,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 5,
                                vertical: 1,
                              ),
                              constraints: const BoxConstraints(minWidth: 16),
                              decoration: BoxDecoration(
                                color: _Palette.danger,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: _Palette.surface,
                                  width: 1.5,
                                ),
                              ),
                              child: Text(
                                '${item.badge}',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    if (active) ...[
                      const SizedBox(height: 4),
                      Text(
                        item.label,
                        style: const TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: _Palette.primaryDark,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Home tab — overview dashboard
  // ---------------------------------------------------------------------
  Widget _buildHomeTab() {
    return RefreshIndicator(
      onRefresh: _loadData,
      color: _Palette.primary,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          _buildGreetingHeader(),
          const SizedBox(height: 26),
          const Text('Overview', style: _AdminTextStyles.sectionHeading),
          const SizedBox(height: 12),
          GridView(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 210,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              mainAxisExtent: 128,
            ),
            children: [
              _StatCard(
                label: 'Review & Analysis',
                value: 'Insights',
                icon: Icons.insights_rounded,
                color: _Palette.violet,
                onTap: _openReviewPage,
              ),
              _StatCard(
                label: 'Mark Attendance',
                value: 'Daily',
                icon: Icons.event_available_rounded,
                color: _Palette.leafGreen,
                onTap: _openAttendancePage,
              ),
              _StatCard(
                label: 'Notices',
                value: 'Campaign',
                icon: Icons.campaign_rounded,
                color: _Palette.amber,
                onTap: _openNoticePage,
              ),
              _StatCard(
                label: 'Gallery',
                value: 'Albums',
                icon: Icons.photo_library_rounded,
                color: _Palette.blueAccent,
                onTap: _openGalleryPage,
              ),
            ],
          ),
          const SizedBox(height: 28),
          const Text('Quick Actions', style: _AdminTextStyles.sectionHeading),
          const SizedBox(height: 12),
          _QuickActionCard(
            title: 'Pending Requests',
            subtitle: _loadingRequests
                ? 'New student approvals'
                : '${_pendingRequests.length} awaiting approval',
            icon: Icons.pending_actions_rounded,
            color: _Palette.amber,
            onTap: () => _goToNav(1),
          ),
          const SizedBox(height: 10),
          _QuickActionCard(
            title: 'Total Students',
            subtitle: _loadingStudents
                ? 'Registered students'
                : '${_allStudents.length} registered students',
            icon: Icons.school_rounded,
            color: _Palette.leafGreen,
            onTap: () => _goToNav(2),
          ),
          const SizedBox(height: 10),
          _QuickActionCard(
            title: 'Active Chats',
            subtitle: _loadingChats
                ? 'Ongoing conversations'
                : '${_chatStudents.length} active chats',
            icon: Icons.chat_bubble_rounded,
            color: _Palette.blueAccent,
            onTap: () => _goToNav(3),
          ),
        ],
      ),
    );
  }

  Widget _buildGreetingHeader() {
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Good morning'
        : (hour < 17 ? 'Good afternoon' : 'Good evening');

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_Palette.primary, _Palette.accentPeach],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: _Palette.primary.withOpacity(0.28),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$greeting 👋',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Admin Dashboard',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  "Here's what's happening today",
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          InkWell(
            onTap: _logout,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(11),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.22),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.logout_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------
  // More tab — remaining tools
  // ---------------------------------------------------------------------
  Widget _buildMoreTab() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
      children: [
        const Text('More Tools', style: _AdminTextStyles.sectionHeading),
        const SizedBox(height: 4),
        const Text(
          'Everything else you need to manage',
          style: _AdminTextStyles.cardSubtitle,
        ),
        const SizedBox(height: 18),
        _QuickActionCard(
          title: 'Mark Attendance',
          subtitle: 'Daily student attendance',
          icon: Icons.event_available_rounded,
          color: _Palette.leafGreen,
          onTap: _openAttendancePage,
        ),
        const SizedBox(height: 10),
        _QuickActionCard(
          title: 'Gallery',
          subtitle: 'Manage photos & albums',
          icon: Icons.photo_library_rounded,
          color: _Palette.blueAccent,
          onTap: _openGalleryPage,
        ),
        const SizedBox(height: 10),
        _QuickActionCard(
          title: 'Notices',
          subtitle: 'Post announcements',
          icon: Icons.campaign_rounded,
          color: _Palette.amber,
          onTap: _openNoticePage,
        ),
        const SizedBox(height: 10),
        _QuickActionCard(
          title: 'Fee Payments',
          subtitle: 'Track UPI fee payments',
          icon: Icons.account_balance_wallet_rounded,
          color: _Palette.leafGreen,
          onTap: _openFeePaymentsPage,
        ),
        const SizedBox(height: 10),
        _QuickActionCard(
          title: 'Holidays',
          subtitle: 'Configure category holidays & weekends',
          icon: Icons.event_busy_rounded,
          color: _Palette.violet,
          onTap: _openHolidayPage,
        ),
        const SizedBox(height: 10),
        _QuickActionCard(
          title: 'Manage Categories',
          subtitle: 'Create, add or remove categories',
          icon: Icons.category_rounded,
          color: _Palette.primary,
          onTap: _openCategoriesPage,
        ),
        const SizedBox(height: 10),
        _QuickActionCard(
          title: 'Review & Analysis',
          subtitle: 'Admissions, categories & attendance insights',
          icon: Icons.insights_rounded,
          color: _Palette.violet,
          onTap: _openReviewPage,
        ),
        if (_authService.currentUserEmail ==
            'dev.harshitcreations@gmail.com') ...[
          const SizedBox(height: 10),
          _QuickActionCard(
            title: 'Manage Admins',
            subtitle: 'Add or review admin access',
            icon: Icons.admin_panel_settings_rounded,
            color: _Palette.violet,
            onTap: _openAdminsPage,
          ),
        ],
        const SizedBox(height: 10),
        _QuickActionCard(
          title: 'Log Out',
          subtitle: 'Sign out of the admin panel',
          icon: Icons.logout_rounded,
          color: _Palette.danger,
          onTap: _logout,
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------
  // Pending tab
  // ---------------------------------------------------------------------
  Widget _buildPendingTab() {
    if (_loadingRequests) {
      return const Center(
        child: CircularProgressIndicator(color: _Palette.primary),
      );
    }

    if (_pendingRequests.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadRequests,
        color: _Palette.primary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.7,
            child: _emptyState(
              icon: Icons.check_circle_rounded,
              iconColor: _Palette.success,
              title: 'No Pending Requests',
              subtitle: 'Pull down to refresh',
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadRequests,
      color: _Palette.primary,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
        itemCount: _pendingRequests.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 16, left: 4),
              child: Row(
                children: [
                  const Text(
                    'Pending Requests',
                    style: _AdminTextStyles.sectionHeading,
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: _Palette.primarySoft,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${_pendingRequests.length}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: _Palette.primaryDark,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          final request = _pendingRequests[index - 1];
          final name = request['name'] ?? 'Unknown User';
          final photoUrl = request['photo_url'] as String?;
          final reqEmail = request['email'] ?? '';

          return _AdminCard(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: _Palette.primarySoft,
                    backgroundImage: photoUrl != null
                        ? NetworkImage(photoUrl)
                        : null,
                    child: photoUrl == null
                        ? const Icon(
                            Icons.person_rounded,
                            color: _Palette.primary,
                          )
                        : null,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name, style: _AdminTextStyles.cardTitle),
                        const SizedBox(height: 3),
                        Text(reqEmail, style: _AdminTextStyles.cardSubtitle),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () => _openApprovalSheet(request),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _Palette.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'Review',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
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

  // ---------------------------------------------------------------------
  // Admins page (pushed as a full screen from Home / More)
  // ---------------------------------------------------------------------
  // _buildAdminsPage removed — replaced by ManageAdminsPage StatefulWidget

  // ---------------------------------------------------------------------
  // ---------------------------------------------------------------------
  // Students tab
  // ---------------------------------------------------------------------
  String _getCategoryEmoji(String category) {
    final lower = category.toLowerCase();
    if (lower.contains('playgroup')) return '🧸';
    if (lower.contains('nursery')) return '🎨';
    if (lower.contains('lkg')) return '📚';
    if (lower.contains('ukg')) return '🎓';
    if (lower.contains('daycare')) return '🌟';
    if (lower.contains('tution') || lower.contains('tuition')) return '✏️';
    return '🍓';
  }

  Widget _buildSearchField() {
    return Container(
      decoration: BoxDecoration(
        color: _Palette.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _Palette.border),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (v) => setState(() => _searchQuery = v),
        style: const TextStyle(color: _Palette.textDark, fontSize: 14),
        decoration: InputDecoration(
          hintText: 'Search students...',
          hintStyle: const TextStyle(color: _Palette.textFaint, fontSize: 14),
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: _Palette.textMuted,
            size: 20,
          ),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(
                    Icons.close_rounded,
                    color: _Palette.textMuted,
                    size: 18,
                  ),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 14,
            horizontal: 4,
          ),
        ),
      ),
    );
  }

  Widget _buildStudentsTab() {
    if (_loadingStudents) {
      return const Center(
        child: CircularProgressIndicator(color: _Palette.primary),
      );
    }

    if (_allStudents.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadStudents,
        color: _Palette.primary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.7,
            child: _emptyState(
              icon: Icons.school_rounded,
              iconColor: _Palette.textFaint,
              title: 'No Enrolled Students',
              subtitle: 'Approved students will show up here',
            ),
          ),
        ),
      );
    }

    final filtered = _searchQuery.trim().isEmpty
        ? _allStudents
        : _allStudents
              .where(
                (s) => (s['name'] ?? '').toString().toLowerCase().contains(
                  _searchQuery.trim().toLowerCase(),
                ),
              )
              .toList();

    // Group students by type
    final Map<String, List<Map<String, dynamic>>> grouped = {};
    for (var cat in _categories) {
      grouped[cat] = [];
    }
    for (var s in filtered) {
      final type = s['student_type'] as String? ?? 'Other';
      if (!grouped.containsKey(type)) {
        grouped[type] = [];
      }
      grouped[type]!.add(s);
    }
    for (final list in grouped.values) {
      list.sort(
        (a, b) => (a['name'] ?? '').toString().toLowerCase().compareTo(
          (b['name'] ?? '').toString().toLowerCase(),
        ),
      );
    }

    final allKeys = [..._categories];
    for (final key in grouped.keys) {
      if (!allKeys.contains(key)) {
        allKeys.add(key);
      }
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: _buildSearchField(),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadStudents,
            color: _Palette.primary,
            child: allKeys.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.5,
                        child: _emptyState(
                          icon: Icons.search_off_rounded,
                          iconColor: _Palette.textFaint,
                          title: 'No Matches',
                          subtitle: 'Try a different search term',
                        ),
                      ),
                    ],
                  )
                : ListView(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                    children: allKeys.map((type) {
                      final list = grouped[type] ?? [];
                      final emoji = _getCategoryEmoji(type);
                      return _AdminCard(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: EdgeInsets.zero,
                        child: Theme(
                          data: Theme.of(
                            context,
                          ).copyWith(dividerColor: Colors.transparent),
                          child: ExpansionTile(
                            tilePadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                            ),
                            childrenPadding: const EdgeInsets.only(bottom: 6),
                            title: Row(
                              children: [
                                Text(
                                  '$emoji $type',
                                  style: _AdminTextStyles.sectionHeading,
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _Palette.primarySoft,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    '${list.length}',
                                    style: const TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w700,
                                      color: _Palette.primaryDark,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            iconColor: _Palette.primary,
                            collapsedIconColor: _Palette.textMuted,
                            children: list.isEmpty
                                ? [
                                    const Padding(
                                      padding: EdgeInsets.symmetric(
                                        vertical: 16,
                                      ),
                                      child: Center(
                                        child: Text(
                                          'No students in this category',
                                          style: TextStyle(
                                            color: _Palette.textMuted,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ]
                                : list.map<Widget>((student) {
                                    final name = student['name'] ?? 'Student';
                                    final sPhotoUrl =
                                        student['photo_url'] as String?;
                                    return ListTile(
                                      onTap: () {
                                        Navigator.of(context)
                                            .push(
                                              MaterialPageRoute(
                                                builder: (_) =>
                                                    StudentDetailPage(
                                                      student: student,
                                                      authService: _authService,
                                                    ),
                                              ),
                                            )
                                            .then((_) => _loadStudents());
                                      },
                                      leading: CircleAvatar(
                                        radius: 18,
                                        backgroundColor: _Palette.primarySoft,
                                        backgroundImage: sPhotoUrl != null
                                            ? NetworkImage(sPhotoUrl)
                                            : null,
                                        child: sPhotoUrl == null
                                            ? const Icon(
                                                Icons.person_rounded,
                                                color: _Palette.primary,
                                                size: 18,
                                              )
                                            : null,
                                      ),
                                      title: Text(
                                        name,
                                        style: const TextStyle(
                                          color: _Palette.textDark,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      subtitle: Text(
                                        student['email'] ?? '',
                                        style: const TextStyle(
                                          color: _Palette.textMuted,
                                          fontSize: 11.5,
                                        ),
                                      ),
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(
                                            Icons.chevron_right_rounded,
                                            color: _Palette.textMuted,
                                            size: 20,
                                          ),
                                          IconButton(
                                            icon: const Icon(
                                              Icons.chat_bubble_rounded,
                                              color: _Palette.primary,
                                              size: 20,
                                            ),
                                            onPressed: () {
                                              Navigator.of(context)
                                                  .push(
                                                    MaterialPageRoute(
                                                      builder: (_) => ChatPage(
                                                        studentId:
                                                            student['id']
                                                                as String,
                                                        studentName: name,
                                                        isAdmin: true,
                                                      ),
                                                    ),
                                                  )
                                                  .then((_) => _loadChats());
                                            },
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------
  // Chat inbox tab
  // ---------------------------------------------------------------------
  Widget _buildChatInboxTab() {
    if (_loadingChats) {
      return const Center(
        child: CircularProgressIndicator(color: _Palette.primary),
      );
    }

    if (_chatStudents.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadChats,
        color: _Palette.primary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.7,
            child: _emptyState(
              icon: Icons.chat_bubble_outline_rounded,
              iconColor: _Palette.textFaint,
              title: 'No Active Chats',
              subtitle: 'Students will appear here when they send messages',
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadChats,
      color: _Palette.primary,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
        itemCount: _chatStudents.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return const Padding(
              padding: EdgeInsets.only(bottom: 16, left: 4),
              child: Text('Chats', style: _AdminTextStyles.sectionHeading),
            );
          }

          final student = _chatStudents[index - 1];
          final name = student['name'] ?? 'Unknown Student';
          final type = student['student_type'] ?? 'Regular';

          return _AdminCard(
            margin: const EdgeInsets.only(bottom: 12),
            onTap: () {
              Navigator.of(context)
                  .push(
                    MaterialPageRoute(
                      builder: (_) => ChatPage(
                        studentId: student['id'] as String,
                        studentName: name,
                        isAdmin: true,
                      ),
                    ),
                  )
                  .then((_) => _loadChats());
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [_Palette.primary, _Palette.accentPeach],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: const CircleAvatar(
                      radius: 20,
                      backgroundColor: Colors.white,
                      child: Icon(
                        Icons.chat_bubble_rounded,
                        color: _Palette.primary,
                        size: 18,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name, style: _AdminTextStyles.cardTitle),
                        const SizedBox(height: 3),
                        Text(type, style: _AdminTextStyles.cardSubtitle),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: _Palette.textFaint,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Shared empty state
  // ---------------------------------------------------------------------
  Widget _emptyState({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.10),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 46, color: iconColor),
          ),
          const SizedBox(height: 18),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16.5,
              color: _Palette.textDark,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 13,
              color: _Palette.textMuted,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

/// Bottom nav item descriptor.
class _NavItem {
  final IconData icon;
  final String label;
  final int? badge;
  const _NavItem({required this.icon, required this.label, this.badge});
}

/// Reusable soft-shadow card used across the admin panel.
class _AdminCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry margin;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  const _AdminCard({
    required this.child,
    this.margin = EdgeInsets.zero,
    this.padding = EdgeInsets.zero,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: _Palette.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _Palette.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: Padding(padding: padding, child: child),
          ),
        ),
      ),
    );
  }
}

/// Stat / metric card used on the home overview grid.
class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _Palette.surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: _Palette.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(icon, color: color, size: 19),
            ),
            const SizedBox(height: 10),
            Text(
              value,
              style: const TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.w800,
                color: _Palette.textDark,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _Palette.textMuted,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

/// Quick action row card — icon, title, subtitle, chevron.
class _QuickActionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _Palette.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _Palette.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color, color.withOpacity(0.7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: _AdminTextStyles.cardTitle),
                  const SizedBox(height: 2),
                  Text(subtitle, style: _AdminTextStyles.cardSubtitle),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: _Palette.textFaint),
          ],
        ),
      ),
    );
  }
}
