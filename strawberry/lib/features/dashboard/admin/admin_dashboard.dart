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
import 'package:strawberry/features/about/about_page.dart';
import 'package:strawberry/features/chat/chat_page.dart';

import 'package:strawberry/core/theme/app_colors.dart';
import 'package:strawberry/core/widgets/playschool_animations.dart';

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
  Widget? _activeCustomSubPage;
  String? _activeSubPageTitle;

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
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.white,
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: const BoxDecoration(
                        color: AppColors.dangerSoft,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.logout_rounded, color: AppColors.danger, size: 22),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Leaving the cockpit, Chief? ☕',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: _Palette.textDark,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                const Text(
                  'We\'ll keep the school fort locked & safe while you take a breather.',
                  style: TextStyle(
                    fontSize: 13.5,
                    color: _Palette.textMuted,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 22),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _Palette.textDark,
                          side: const BorderSide(color: Color(0xFFCBD5E1), width: 1.2),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text(
                          'Stay Here',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _Palette.danger,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text(
                          'Log Out 👋',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (shouldLogout == true) {
      await _authService.logout();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const AuthScreen()),
        (route) => false,
      );
    }
  }

  // ---------------------------------------------------------------------
  // Navigation helpers — Unified for Mobile (Push) and Web (Embedded Shell)
  // ---------------------------------------------------------------------
  void _openPage(Widget page, {String? title, VoidCallback? onBack}) {
    final isDesktop = MediaQuery.of(context).size.width >= 960;
    if (isDesktop) {
      setState(() {
        _activeCustomSubPage = page;
        _activeSubPageTitle = title;
      });
    } else {
      Navigator.of(context)
          .push(MaterialPageRoute(builder: (_) => page))
          .then((_) {
            if (onBack != null) onBack();
          });
    }
  }

  void _closeCustomSubPage() {
    setState(() {
      _activeCustomSubPage = null;
      _activeSubPageTitle = null;
    });
  }

  void _openAttendancePage() {
    _openPage(
      AttendanceMarkPage(authService: _authService),
      title: 'Mark Attendance',
    );
  }

  void _openGalleryPage() {
    _openPage(
      GalleryAdminPage(authService: _authService),
      title: 'Photo Gallery',
    );
  }

  void _openNoticePage() {
    _openPage(
      NoticeAdminPage(authService: _authService),
      title: 'Notice Board Broadcast',
    );
  }

  void _openAdminsPage() {
    if (_authService.currentUserEmail != 'dev.harshitcreations@gmail.com') {
      return;
    }
    _openPage(
      ManageAdminsPage(authService: _authService),
      title: 'Manage Administrators',
    );
  }

  void _openFeePaymentsPage() {
    _openPage(
      FeePaymentsAdminPage(authService: _authService),
      title: 'Fee Records & UPI Logs',
    );
  }

  void _openHolidayPage() {
    _openPage(
      HolidayAdminPage(authService: _authService),
      title: 'Holiday Calendar',
    );
  }

  void _openReviewPage() {
    _openPage(
      ReviewAnalyticsPage(authService: _authService),
      title: 'Review & Analytics',
    );
  }

  void _openCategoriesPage() {
    _openPage(
      CategoriesAdminPage(authService: _authService),
      title: 'Categories & Grades',
      onBack: () {
        _loadCategories();
        _loadStudents();
      },
    );
  }

  void _openAboutPage() {
    _openPage(
      const AboutPage(),
      title: 'About Strawberry',
    );
  }

  void _goToNav(int index) => setState(() {
    _activeCustomSubPage = null;
    _activeSubPageTitle = null;
    _navIndex = index;
  });

  // ---------------------------------------------------------------------
  // Approval bottom sheet
  // ---------------------------------------------------------------------
  void _openApprovalSheet(Map<String, dynamic> request) {
    final name = request['name'] ?? 'Unknown';
    final uid = request['id'] ?? '';

    String? selectedStudentType;
    final feesController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      constraints: const BoxConstraints(maxWidth: 580),
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
                          'Roll out the Red Carpet! ⭐',
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
                      value: selectedStudentType,
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
                          selectedStudentType = value;
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

                          final type = selectedStudentType!;
                          final fees =
                              double.tryParse(feesController.text.trim()) ??
                              0.0;

                          try {
                            await _authService.approveStudent(uid, type, fees);
                            if (!mounted) return;
                            Navigator.of(context).pop(); // Close bottom sheet
                            ScaffoldMessenger.of(context).showSnackBar(
                              _adminSnackBar(
                                'Woohoo! $name is now officially part of the Strawberry family! 🎉',
                                success: true,
                              ),
                            );
                            _loadRequests();
                          } catch (e) {
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              _adminSnackBar(
                                'Oops! Couldn\'t approve right now. Give it another tap! 🔄',
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
                          'Approve & Welcome to Strawberry 🎓',
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 960;

        return PopScope(
          canPop: _activeCustomSubPage == null && _navIndex == 0,
          onPopInvokedWithResult: (didPop, result) {
            if (didPop) return;
            if (_activeCustomSubPage != null) {
              _closeCustomSubPage();
              return;
            }
            if (_navIndex != 0) {
              setState(() => _navIndex = 0);
            }
          },
          child: Scaffold(
            backgroundColor: _Palette.bg,
            body: SafeArea(
              bottom: false,
              child: isDesktop
                  ? Row(
                      children: [
                        _buildDesktopSidebar(),
                        Expanded(
                          child: _activeCustomSubPage != null
                              ? Column(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                      decoration: const BoxDecoration(
                                        color: _Palette.surface,
                                        border: Border(bottom: BorderSide(color: _Palette.border, width: 1.2)),
                                      ),
                                      child: Row(
                                        children: [
                                          Material(
                                            color: _Palette.bg,
                                            borderRadius: BorderRadius.circular(10),
                                            child: InkWell(
                                              onTap: _closeCustomSubPage,
                                              borderRadius: BorderRadius.circular(10),
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                                                decoration: BoxDecoration(
                                                  borderRadius: BorderRadius.circular(10),
                                                  border: Border.all(color: _Palette.border),
                                                ),
                                                child: const Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Icon(Icons.arrow_back_rounded, size: 16, color: _Palette.textDark),
                                                    SizedBox(width: 6),
                                                    Text(
                                                      'Back to Overview',
                                                      style: TextStyle(
                                                        fontSize: 13,
                                                        fontWeight: FontWeight.w700,
                                                        color: _Palette.textDark,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                          if (_activeSubPageTitle != null) ...[
                                            const SizedBox(width: 14),
                                            Container(width: 1, height: 20, color: _Palette.border),
                                            const SizedBox(width: 14),
                                            Text(
                                              _activeSubPageTitle!,
                                              style: const TextStyle(
                                                fontSize: 16.5,
                                                fontWeight: FontWeight.w800,
                                                color: _Palette.textDark,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                    Expanded(child: _activeCustomSubPage!),
                                  ],
                                )
                              : IndexedStack(
                                  index: _navIndex,
                                  sizing: StackFit.expand,
                                  children: [
                                    _buildHomeTab(),
                                    _buildPendingTab(),
                                    _buildStudentsTab(),
                                    _buildChatInboxTab(),
                                    _buildMoreTab(),
                                  ],
                                ),
                        ),
                      ],
                    )
                  : IndexedStack(
                      index: _navIndex,
                      sizing: StackFit.expand,
                      children: [
                        _buildHomeTab(),
                        _buildPendingTab(),
                        _buildStudentsTab(),
                        _buildChatInboxTab(),
                        _buildMoreTab(),
                      ],
                    ),
            ),
            bottomNavigationBar: isDesktop
                ? null
                : SafeArea(
                    child: Container(
                      alignment: Alignment.center,
                      height: 72,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 620),
                        child: _buildNavBar(),
                      ),
                    ),
                  ),
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------
  // Desktop Navigation Sidebar
  // ---------------------------------------------------------------------
  Widget _buildDesktopSidebar() {
    final navItems = [
      (Icons.dashboard_rounded, 'Dashboard', 0, 0),
      (Icons.pending_actions_rounded, 'Admissions', 1, _pendingRequests.length),
      (Icons.school_rounded, 'Students', 2, 0),
      (Icons.chat_bubble_rounded, 'Chat Inbox', 3, 0),
      (Icons.apps_rounded, 'All Tools', 4, 0),
    ];

    final quickLinks = [
      (Icons.insights_rounded, 'Review & Analytics', _openReviewPage),
      (Icons.event_available_rounded, 'Mark Attendance', _openAttendancePage),
      (Icons.payments_rounded, 'Fee Records', _openFeePaymentsPage),
      (Icons.campaign_rounded, 'Notice Board', _openNoticePage),
      (Icons.photo_library_rounded, 'Photo Gallery', _openGalleryPage),
      (Icons.category_rounded, 'Categories & Grades', _openCategoriesPage),
      (Icons.storefront_rounded, 'About Strawberry', _openAboutPage),
    ];

    return Container(
      width: 270,
      decoration: const BoxDecoration(
        color: _Palette.surface,
        border: Border(
          right: BorderSide(color: _Palette.border, width: 1.2),
        ),
      ),
      child: Column(
        children: [
          // Sidebar Header / Brand
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
            child: Row(
              children: [
                ClipOval(
                  child: Image.asset(
                    'assets/images/logo.png',
                    width: 44,
                    height: 44,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 44,
                      height: 44,
                      color: _Palette.primarySoft,
                      child: const Icon(
                        Icons.school_rounded,
                        color: _Palette.primary,
                        size: 24,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Strawberry ERP',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: _Palette.textDark,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: _Palette.primarySoft,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'ADMIN PORTAL',
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w800,
                            color: _Palette.primaryDark,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: _Palette.border),

          // Scrollable Nav List
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  child: Text(
                    'MAIN NAVIGATION',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: _Palette.textMuted,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                ...navItems.map((item) {
                  final active = _navIndex == item.$3;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 4),
                    child: Material(
                      color: active ? _Palette.primarySoft : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      child: InkWell(
                        onTap: () => _goToNav(item.$3),
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          child: Row(
                            children: [
                              Icon(
                                item.$1,
                                size: 20,
                                color: active ? _Palette.primaryDark : _Palette.textDark,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  item.$2,
                                  style: TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: active ? FontWeight.w700 : FontWeight.w600,
                                    color: active ? _Palette.primaryDark : _Palette.textDark,
                                  ),
                                ),
                              ),
                              if (item.$4 > 0)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: _Palette.danger,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    '${item.$4}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }),

                const SizedBox(height: 20),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  child: Text(
                    'QUICK MODULES',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: _Palette.textMuted,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                ...quickLinks.map((ql) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 2),
                    child: Material(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      child: InkWell(
                        onTap: ql.$3,
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                          child: Row(
                            children: [
                              Icon(ql.$1, size: 18, color: _Palette.textMuted),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  ql.$2,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: _Palette.textDark,
                                  ),
                                ),
                              ),
                              const Icon(Icons.chevron_right_rounded, size: 16, color: _Palette.textFaint),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),

          const Divider(height: 1, color: _Palette.border),

          // Sidebar Footer / User & Logout
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 18,
                  backgroundColor: _Palette.primarySoft,
                  child: Icon(Icons.admin_panel_settings_rounded, color: _Palette.primary, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Administrator',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: _Palette.textDark,
                        ),
                      ),
                      Text(
                        _authService.currentUserEmail ?? 'Admin',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          color: _Palette.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.logout_rounded, color: _Palette.danger, size: 20),
                  tooltip: 'Logout',
                  onPressed: _logout,
                ),
              ],
            ),
          ),
        ],
      ),
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
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 6),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      decoration: BoxDecoration(
        color: _Palette.surface,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, 8),
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
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                padding: const EdgeInsets.symmetric(vertical: 6),
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
                          size: 20,
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
                      const SizedBox(height: 2),
                      Text(
                        item.label,
                        style: const TextStyle(
                          fontSize: 10,
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 960;
        final isWide = constraints.maxWidth >= 600;
        final horizontalPadding = isDesktop ? 36.0 : (isWide ? 24.0 : 16.0);

        return RefreshIndicator(
          onRefresh: _loadData,
          color: _Palette.primary,
          child: ListView(
            padding: EdgeInsets.fromLTRB(horizontalPadding, 20, horizontalPadding, 100),
            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
            children: [
              _buildGreetingHeader(isDesktop),
              const SizedBox(height: 20),
              if (isDesktop)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                        // Left Column: Operations & Admissions
                        Expanded(
                          child: Column(
                            children: [
                              _buildAdminAdmissionsCard(),
                              const SizedBox(height: 18),
                              _buildAdminAttendanceCard(),
                              const SizedBox(height: 18),
                              _buildAdminFeeCard(),
                            ],
                          ),
                        ),
                        const SizedBox(width: 20),
                        // Right Column: Comms, Media & Tools
                        Expanded(
                          child: Column(
                            children: [
                              _buildAdminChatsCard(),
                              const SizedBox(height: 18),
                              _buildAdminNoticeCard(),
                              const SizedBox(height: 18),
                              _buildAdminGalleryToolsCard(),
                            ],
                          ),
                        ),
                      ],
                    )
                  else ...[
                    _buildAdminAdmissionsCard(),
                    const SizedBox(height: 16),
                    _buildAdminAttendanceCard(),
                    const SizedBox(height: 16),
                    _buildAdminFeeCard(),
                    const SizedBox(height: 16),
                    _buildAdminChatsCard(),
                    const SizedBox(height: 16),
                    _buildAdminNoticeCard(),
                    const SizedBox(height: 16),
                    _buildAdminGalleryToolsCard(),
                  ],
                ],
              ),
            );
          },
        );
      }

  Widget _buildGreetingHeader(bool isDesktop) {
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Good morning'
        : (hour < 17 ? 'Good afternoon' : 'Good evening');

    return Container(
      padding: EdgeInsets.symmetric(horizontal: isDesktop ? 26 : 18, vertical: isDesktop ? 22 : 18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_Palette.primary, _Palette.accentPeach],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: _Palette.primary.withValues(alpha: 0.25),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: isDesktop
          ? Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$greeting, Admin 👋',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 3),
                      const Text(
                        'Preschool Command Center',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.4,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _authService.currentUserEmail ?? 'Admin Access',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildAdminHeaderPill(
                      icon: Icons.school_rounded,
                      label: 'Students',
                      value: '${_allStudents.length}',
                    ),
                    const SizedBox(width: 10),
                    _buildAdminHeaderPill(
                      icon: Icons.pending_actions_rounded,
                      label: 'Pending',
                      value: '${_pendingRequests.length}',
                    ),
                    const SizedBox(width: 10),
                    _buildAdminHeaderPill(
                      icon: Icons.chat_bubble_rounded,
                      label: 'Inquiries',
                      value: '${_chatStudents.length}',
                    ),
                  ],
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$greeting, Admin 👋',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Command Center',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                    InkWell(
                      onTap: _logout,
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.logout_rounded, color: Colors.white, size: 18),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildAdminHeaderPill(
                        icon: Icons.school_rounded,
                        label: 'Students',
                        value: '${_allStudents.length}',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildAdminHeaderPill(
                        icon: Icons.pending_actions_rounded,
                        label: 'Pending',
                        value: '${_pendingRequests.length}',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildAdminHeaderPill(
                        icon: Icons.chat_bubble_rounded,
                        label: 'Inquiries',
                        value: '${_chatStudents.length}',
                      ),
                    ),
                  ],
                ),
              ],
            ),
    );
  }

  Widget _buildAdminHeaderPill({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white, size: 14),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.85),
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  // --- ADMIN BENTO CARDS ---

  Widget _buildAdminAdmissionsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _Palette.surface,
        borderRadius: BorderRadius.circular(20),
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
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _Palette.amber.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.pending_actions_rounded, color: _Palette.amber, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Admissions (${_pendingRequests.length})',
                  style: _AdminTextStyles.cardTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: () => _goToNav(1),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'View All',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _Palette.primary),
                    ),
                    SizedBox(width: 2),
                    Icon(Icons.arrow_forward_rounded, size: 14, color: _Palette.primary),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (_pendingRequests.isEmpty)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _Palette.bg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _Palette.border),
              ),
              child: const Row(
                children: [
                  Icon(Icons.check_circle_outline_rounded, color: _Palette.success, size: 20),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'All student admission requests have been reviewed.',
                      style: TextStyle(fontSize: 12, color: _Palette.textMuted, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            )
          else
            Column(
              children: _pendingRequests.take(2).map((req) {
                final name = req['name'] ?? 'Unknown';
                final email = req['email'] ?? '';
                final photoUrl = req['photo_url'] as String?;
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _Palette.bg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _Palette.border),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: _Palette.primarySoft,
                        backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
                        child: photoUrl == null
                            ? const Icon(Icons.person_rounded, color: _Palette.primary, size: 16)
                            : null,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _Palette.textDark),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              email,
                              style: const TextStyle(fontSize: 11, color: _Palette.textMuted),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () => _openApprovalSheet(req),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _Palette.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text('Review', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildAdminAttendanceCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _Palette.surface,
        borderRadius: BorderRadius.circular(20),
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
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _Palette.leafGreen.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.event_available_rounded, color: _Palette.leafGreen, size: 20),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Attendance Management',
                  style: _AdminTextStyles.cardTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _Palette.leafGreen.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'Daily Roster',
                  style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: _Palette.leafGreen),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 360;
              if (isNarrow) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ElevatedButton.icon(
                      onPressed: _openAttendancePage,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _Palette.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.check_circle_outline_rounded, size: 16),
                      label: const Text('Mark Daily Attendance', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: _openHolidayPage,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _Palette.textDark,
                        side: const BorderSide(color: _Palette.border),
                        padding: const EdgeInsets.symmetric(vertical: 11),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.beach_access_rounded, size: 16, color: _Palette.leafGreen),
                      label: const Text('Holidays & Calendar', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
                    ),
                  ],
                );
              }
              return Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _openAttendancePage,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _Palette.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.check_circle_outline_rounded, size: 16),
                      label: const Text('Mark Daily Attendance', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  OutlinedButton(
                    onPressed: _openHolidayPage,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _Palette.textDark,
                      side: const BorderSide(color: _Palette.border),
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Holidays', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAdminFeeCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _Palette.surface,
        borderRadius: BorderRadius.circular(20),
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
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _Palette.blueAccent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.account_balance_wallet_rounded, color: _Palette.blueAccent, size: 20),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Fee Records & UPI Logs',
                  style: _AdminTextStyles.cardTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: _openFeePaymentsPage,
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Open Logs', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _Palette.primary)),
                    SizedBox(width: 2),
                    Icon(Icons.arrow_forward_rounded, size: 14, color: _Palette.primary),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Track instant UPI payments, pending student fees & monthly ledger reconciliation.',
            style: TextStyle(fontSize: 12, color: _Palette.textMuted, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildAdminChatsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _Palette.surface,
        borderRadius: BorderRadius.circular(20),
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
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _Palette.violet.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.chat_bubble_rounded, color: _Palette.violet, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Parent Inquiries (${_chatStudents.length})',
                  style: _AdminTextStyles.cardTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: () => _goToNav(3),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Chat Inbox', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _Palette.primary)),
                    SizedBox(width: 2),
                    Icon(Icons.arrow_forward_rounded, size: 14, color: _Palette.primary),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (_chatStudents.isEmpty)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _Palette.bg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _Palette.border),
              ),
              child: const Row(
                children: [
                  Icon(Icons.chat_outlined, color: _Palette.textMuted, size: 20),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'No active parent chats yet.',
                      style: TextStyle(fontSize: 12, color: _Palette.textMuted, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            )
          else
            Column(
              children: _chatStudents.take(2).map((c) {
                final name = c['name'] ?? 'Student';
                final type = c['student_type'] ?? 'Preschool';
                final uid = c['id'] ?? '';
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _Palette.bg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _Palette.border),
                  ),
                  child: InkWell(
                    onTap: () => _openPage(
                      ChatPage(studentId: uid, studentName: name, isAdmin: true),
                      title: 'Chat: $name',
                    ),
                    child: Row(
                      children: [
                        const CircleAvatar(
                          radius: 16,
                          backgroundColor: _Palette.primarySoft,
                          child: Icon(Icons.person_rounded, color: _Palette.primary, size: 16),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(name, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: _Palette.textDark)),
                              Text(type, style: const TextStyle(fontSize: 11, color: _Palette.textMuted)),
                            ],
                          ),
                        ),
                        const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: _Palette.textMuted),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildAdminNoticeCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _Palette.surface,
        borderRadius: BorderRadius.circular(20),
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
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _Palette.amber.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.campaign_rounded, color: _Palette.amber, size: 20),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Notice Board Broadcast',
                  style: _AdminTextStyles.cardTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: _openNoticePage,
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Manage', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _Palette.primary)),
                    SizedBox(width: 2),
                    Icon(Icons.arrow_forward_rounded, size: 14, color: _Palette.primary),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _openNoticePage,
            style: OutlinedButton.styleFrom(
              foregroundColor: _Palette.textDark,
              side: const BorderSide(color: _Palette.border),
              padding: const EdgeInsets.symmetric(vertical: 12),
              minimumSize: const Size(double.infinity, 44),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(Icons.add_circle_outline_rounded, size: 16, color: _Palette.primary),
            label: const Text('Post New Circular / Notice', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Widget _buildAdminGalleryToolsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _Palette.surface,
        borderRadius: BorderRadius.circular(20),
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
          const Row(
            children: [
              Icon(Icons.widgets_outlined, color: _Palette.primary, size: 20),
              SizedBox(width: 8),
              Text('Core Management Tools', style: _AdminTextStyles.cardTitle),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _buildAdminToolTile(
                  icon: Icons.photo_library_rounded,
                  label: 'Campus Gallery',
                  color: _Palette.blueAccent,
                  onTap: _openGalleryPage,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildAdminToolTile(
                  icon: Icons.insights_rounded,
                  label: 'Analytics',
                  color: _Palette.violet,
                  onTap: _openReviewPage,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildAdminToolTile(
                  icon: Icons.category_rounded,
                  label: 'Grades',
                  color: _Palette.leafGreen,
                  onTap: _openCategoriesPage,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAdminToolTile({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: _Palette.bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _Palette.border),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: _Palette.textDark),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------
  // More tab — remaining tools
  // ---------------------------------------------------------------------
  Widget _buildMoreTab() {
    final tools = [
      _QuickActionCard(
        title: 'Mark Attendance',
        subtitle: 'Daily student attendance',
        icon: Icons.event_available_rounded,
        color: _Palette.leafGreen,
        onTap: _openAttendancePage,
      ),
      _QuickActionCard(
        title: 'Gallery',
        subtitle: 'Manage photos & albums',
        icon: Icons.photo_library_rounded,
        color: _Palette.blueAccent,
        onTap: _openGalleryPage,
      ),
      _QuickActionCard(
        title: 'Notices',
        subtitle: 'Post announcements',
        icon: Icons.campaign_rounded,
        color: _Palette.amber,
        onTap: _openNoticePage,
      ),
      _QuickActionCard(
        title: 'Fee Payments',
        subtitle: 'Track UPI fee payments',
        icon: Icons.account_balance_wallet_rounded,
        color: _Palette.leafGreen,
        onTap: _openFeePaymentsPage,
      ),
      _QuickActionCard(
        title: 'Holidays',
        subtitle: 'Configure category holidays & weekends',
        icon: Icons.event_busy_rounded,
        color: _Palette.violet,
        onTap: _openHolidayPage,
      ),
      _QuickActionCard(
        title: 'Manage Categories',
        subtitle: 'Create, add or remove categories',
        icon: Icons.category_rounded,
        color: _Palette.primary,
        onTap: _openCategoriesPage,
      ),
      _QuickActionCard(
        title: 'Review & Analysis',
        subtitle: 'Admissions, categories & attendance insights',
        icon: Icons.insights_rounded,
        color: _Palette.violet,
        onTap: _openReviewPage,
      ),
      if (_authService.currentUserEmail ==
          'dev.harshitcreations@gmail.com') ...[
        _QuickActionCard(
          title: 'Manage Admins',
          subtitle: 'Add or review admin access',
          icon: Icons.admin_panel_settings_rounded,
          color: _Palette.violet,
          onTap: _openAdminsPage,
        ),
        _QuickActionCard(
          title: 'Institute Info & Story',
          subtitle: 'Edit About page, photos & founder journey',
          icon: Icons.auto_stories_rounded,
          color: _Palette.primary,
          onTap: _openAboutPage,
        ),
      ],
      _QuickActionCard(
        title: 'Log Out',
        subtitle: 'Sign out of the admin panel',
        icon: Icons.logout_rounded,
        color: _Palette.danger,
        onTap: _logout,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 960;
        final isWide = constraints.maxWidth >= 600;
        final horizontalPadding = isDesktop ? 32.0 : (isWide ? 24.0 : 16.0);

        return Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: ListView(
              padding: EdgeInsets.fromLTRB(horizontalPadding, 20, horizontalPadding, 100),
              children: [
                const Text('More Tools', style: _AdminTextStyles.sectionHeading),
                const SizedBox(height: 4),
                const Text(
                  'Everything else you need to manage',
                  style: _AdminTextStyles.cardSubtitle,
                ),
                const SizedBox(height: 18),
                if (isWide)
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: isDesktop ? 3 : 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 14,
                      mainAxisExtent: 88,
                    ),
                    itemCount: tools.length,
                    itemBuilder: (_, i) => tools[i],
                  )
                else
                  ...tools.expand((t) => [t, const SizedBox(height: 10)]),
              ],
            ),
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------
  // Pending tab
  // ---------------------------------------------------------------------
  Widget _buildPendingTab() {
    if (_loadingRequests) {
      return const StrawberryLoader(message: 'Checking pending admissions... 📝');
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
              title: 'All Caught Up! 🍪',
              subtitle: 'Zero pending admissions. Grab a cookie or coffee!',
            ),
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 960;
        final isWide = constraints.maxWidth >= 600;
        final horizontalPadding = isDesktop ? 32.0 : (isWide ? 24.0 : 16.0);

        return Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: RefreshIndicator(
              onRefresh: _loadRequests,
              color: _Palette.primary,
              child: ListView.builder(
                padding: EdgeInsets.fromLTRB(horizontalPadding, 20, horizontalPadding, 24),
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
        ),
      ),
    );
      },
    );
  }

  // ---------------------------------------------------------------------
  // Students tab — categorized & searchable
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
          hintText: 'Search superstars by name or category...',
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
      return const StrawberryLoader(message: 'Rounding up the squad... 🌟');
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
              title: 'No Students Enrolled Yet 🌱',
              subtitle: 'Approved students will populate your classes here.',
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

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 960;
        final isWide = constraints.maxWidth >= 600;
        final horizontalPadding = isDesktop ? 32.0 : (isWide ? 24.0 : 16.0);

        return Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(horizontalPadding, 16, horizontalPadding, 8),
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
                            padding: EdgeInsets.fromLTRB(horizontalPadding, 4, horizontalPadding, 24),
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
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            '${list.length}',
                                            style: const TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                              color: _Palette.primaryDark,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    children: list.isEmpty
                                        ? [
                                            const Padding(
                                              padding: EdgeInsets.all(16),
                                              child: Text(
                                                'No students in this category yet',
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  color: _Palette.textMuted,
                                                ),
                                              ),
                                            ),
                                          ]
                                        : list.map((student) {
                                            final sName = student['name'] ?? 'Student';
                                            final pName = (student['parent_name'] as String?)?.trim() ?? '';
                                            final pPhone = (student['parent_phone'] as String?)?.trim() ?? '';
                                            final sEmail = (student['email'] as String?)?.trim() ?? '';
                                            final sPhone = (student['phone'] as String?)?.trim() ?? '';
                                            final photo = student['photo_url'] as String?;

                                            String subtitleText;
                                            if (pName.isNotEmpty && pPhone.isNotEmpty) {
                                              subtitleText = 'Parent: $pName • $pPhone';
                                            } else if (pName.isNotEmpty) {
                                              subtitleText = 'Parent: $pName';
                                            } else if (pPhone.isNotEmpty) {
                                              subtitleText = 'Phone: $pPhone';
                                            } else if (sPhone.isNotEmpty) {
                                              subtitleText = 'Phone: $sPhone';
                                            } else if (sEmail.isNotEmpty) {
                                              subtitleText = sEmail;
                                            } else {
                                              subtitleText = 'Enrolled in ${student['student_type'] ?? 'Class'}';
                                            }

                                            return ListTile(
                                              contentPadding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 16,
                                                vertical: 2,
                                              ),
                                              leading: CircleAvatar(
                                                radius: 19,
                                                backgroundColor: _Palette.primarySoft,
                                                backgroundImage: photo != null
                                                    ? NetworkImage(photo)
                                                    : null,
                                                child: photo == null
                                                    ? const Icon(
                                                        Icons.person_rounded,
                                                        color: _Palette.primary,
                                                        size: 20,
                                                      )
                                                    : null,
                                              ),
                                              title: Text(
                                                sName,
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w700,
                                                  color: _Palette.textDark,
                                                ),
                                              ),
                                              subtitle: Text(
                                                subtitleText,
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  color: _Palette.textMuted,
                                                ),
                                              ),
                                              trailing: const Icon(
                                                Icons.chevron_right_rounded,
                                                color: _Palette.textFaint,
                                              ),
                                              onTap: () {
                                                _openPage(
                                                  StudentDetailPage(
                                                    student: student,
                                                    authService: _authService,
                                                  ),
                                                  title: student['name'] ?? 'Student Profile',
                                                );
                                              },
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
            ),
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------
  // Chat inbox tab
  // ---------------------------------------------------------------------
  Widget _buildChatInboxTab() {
    if (_loadingChats) {
      return const StrawberryLoader(message: 'Fetching support messages... 💬');
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
              title: 'Quiet on the Support Front 🤫',
              subtitle: 'Direct messages from parents will ping right here.',
            ),
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 960;
        final isWide = constraints.maxWidth >= 600;
        final horizontalPadding = isDesktop ? 32.0 : (isWide ? 24.0 : 16.0);

        return Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: RefreshIndicator(
              onRefresh: _loadChats,
              color: _Palette.primary,
              child: ListView.builder(
                padding: EdgeInsets.fromLTRB(horizontalPadding, 20, horizontalPadding, 24),
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
                      _openPage(
                        ChatPage(
                          studentId: student['id'] as String,
                          studentName: name,
                          isAdmin: true,
                        ),
                        title: 'Chat: $name',
                        onBack: _loadChats,
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(2.5),
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [_Palette.primary, _Palette.accentPeach],
                              ),
                            ),
                            child: CircleAvatar(
                              radius: 20,
                              backgroundColor: Colors.white,
                              backgroundImage: (student['photo_url'] != null &&
                                      (student['photo_url'] as String).isNotEmpty)
                                  ? NetworkImage(student['photo_url'])
                                  : null,
                              child: (student['photo_url'] == null ||
                                      (student['photo_url'] as String).isEmpty)
                                  ? const Icon(
                                      Icons.chat_bubble_rounded,
                                      color: _Palette.primary,
                                      size: 18,
                                    )
                                  : null,
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
            ),
          ),
        );
      },
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
              color: iconColor.withValues(alpha: 0.10),
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
            color: Colors.black.withValues(alpha: 0.03),
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
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: _Palette.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _Palette.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color, color.withValues(alpha: 0.7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: _AdminTextStyles.cardTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: _AdminTextStyles.cardSubtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right_rounded, color: _Palette.textFaint),
          ],
        ),
      ),
    );
  }
}
