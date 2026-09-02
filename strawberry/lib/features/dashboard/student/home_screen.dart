import 'package:flutter/material.dart';
import 'package:strawberry/core/theme/app_colors.dart';
import 'package:strawberry/core/theme/app_typography.dart';
import 'package:strawberry/core/theme/app_decorations.dart';
import 'package:strawberry/core/widgets/app_badge.dart';
import 'package:strawberry/core/widgets/playschool_animations.dart';
import 'package:strawberry/features/auth/auth_screen.dart';
import 'package:strawberry/features/auth/auth_service.dart';
import 'package:strawberry/features/dashboard/student/attendance_page.dart';
import 'package:strawberry/features/dashboard/student/gallery_page.dart';
import 'package:strawberry/features/dashboard/student/notice_board_page.dart';
import 'package:strawberry/features/dashboard/student/pay_fees_page.dart';
import 'package:strawberry/features/about/about_page.dart';
import 'package:strawberry/features/chat/chat_page.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  final _authService = AuthService();
  Map<String, dynamic>? _profile;
  bool _loading = true;

  StreamSubscription? _noticesSubscription;
  int _unreadNoticesCount = 0;
  List<Map<String, dynamic>> _todayHighlights = [];
  List<Map<String, dynamic>> _recentNotices = [];

  late AnimationController _fabAnimationController;
  late Animation<double> _fabExpandAnimation;
  bool _isFabOpen = false;

  @override
  void initState() {
    super.initState();
    _fabAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    );
    _fabExpandAnimation = CurvedAnimation(
      parent: _fabAnimationController,
      curve: Curves.easeOutBack,
      reverseCurve: Curves.easeInCubic,
    );
    _loadProfile();
  }

  @override
  void dispose() {
    _fabAnimationController.dispose();
    _noticesSubscription?.cancel();
    super.dispose();
  }

  void _toggleFab() {
    setState(() {
      _isFabOpen = !_isFabOpen;
      if (_isFabOpen) {
        _fabAnimationController.forward();
      } else {
        _fabAnimationController.reverse();
      }
    });
  }

  void _closeFab() {
    if (_isFabOpen) {
      setState(() {
        _isFabOpen = false;
        _fabAnimationController.reverse();
      });
    }
  }

  Future<void> _loadProfile() async {
    setState(() => _loading = true);
    try {
      final profile = await _authService.getCurrentProfile();
      setState(() {
        _profile = profile;
        _loading = false;
      });
      _loadUnreadNoticesCount();
      _loadHighlights();
      _subscribeToNotices();
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Future<void> _loadHighlights() async {
    try {
      final photos = await _authService.getGalleryImages();
      if (mounted) {
        setState(() {
          _todayHighlights = photos.take(4).toList();
        });
      }
    } catch (_) {}
  }

  Future<void> _loadUnreadNoticesCount() async {
    final uid = _authService.currentUserId ?? '';
    final studentType = _profile?['student_type'] as String?;
    if (uid.isEmpty) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final lastViewedStr = prefs.getString('last_viewed_notices_time_$uid');
      final DateTime lastViewed = lastViewedStr != null
          ? DateTime.parse(lastViewedStr)
          : DateTime.fromMillisecondsSinceEpoch(0);

      final notices = await _authService.getNoticesForStudent(uid, studentType);
      int unread = 0;
      for (var n in notices) {
        final sentStr = (n['last_sent_at'] ?? n['created_at']) as String?;
        if (sentStr != null) {
          final sent = DateTime.tryParse(sentStr);
          if (sent != null && sent.isAfter(lastViewed)) {
            unread++;
          }
        }
      }
      if (mounted) {
        setState(() {
          _unreadNoticesCount = unread;
          _recentNotices = notices.take(2).toList();
        });
      }
    } catch (e) {
      print('Error loading unread notices count: $e');
    }
  }

  void _subscribeToNotices() {
    _noticesSubscription?.cancel();
    final uid = _authService.currentUserId ?? '';
    final studentType = _profile?['student_type'] as String?;
    if (uid.isEmpty) return;

    bool isFirstEmit = true;
    final Map<int, String?> seenSentAt = {};

    _noticesSubscription = _authService
        .getNoticesRealtimeStream(uid, studentType)
        .listen((notices) {
      if (isFirstEmit) {
        for (final n in notices) {
          seenSentAt[n['id'] as int] = n['last_sent_at'] as String?;
        }
        isFirstEmit = false;
        return;
      }

      for (var notice in notices) {
        final id = notice['id'] as int;
        final sentAt = notice['last_sent_at'] as String?;
        if (seenSentAt[id] != sentAt) {
          seenSentAt[id] = sentAt;
          _showInAppNotification(notice);
          _loadUnreadNoticesCount();
        }
      }
    });
  }

  void _showInAppNotification(Map<String, dynamic> notice) {
    if (!mounted) return;
    final title = notice['title'] ?? 'New Notice';
    final body = notice['body'] ?? '';
    final category = notice['category'] ?? 'General';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: AppDecorations.radiusLg),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.campaign_rounded, color: AppColors.primary, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'New Announcement',
                style: AppTypography.h2,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppBadge(
              label: category,
              type: AppBadgeType.primary,
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: AppTypography.h3,
            ),
            const SizedBox(height: 6),
            Text(
              body,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.bodySmall,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Dismiss', style: AppTypography.button.copyWith(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const NoticeBoardPage()),
              ).then((_) => _loadUnreadNoticesCount());
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: AppDecorations.radiusSm),
            ),
            child: const Text('View Board'),
          ),
        ],
      ),
    );
  }

  Future<void> _logout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        titlePadding: const EdgeInsets.fromLTRB(22, 22, 22, 8),
        contentPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 8),
        actionsPadding: const EdgeInsets.fromLTRB(16, 12, 18, 18),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: const BoxDecoration(
                color: AppColors.dangerSoft,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.logout_rounded, color: AppColors.danger, size: 22),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Heading out, Superstar? 🎒',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textDark,
                ),
              ),
            ),
          ],
        ),
        content: const Text(
          'Don\'t forget to pack your curiosity & smiles for tomorrow. See you soon!',
          style: TextStyle(
            fontSize: 13.5,
            color: AppColors.textMuted,
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text(
              'Keep Exploring',
              style: TextStyle(
                color: AppColors.textDark,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text(
              'Sign Out 👋',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
            ),
          ),
        ],
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

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 960;
        final isTablet = constraints.maxWidth >= 640 && constraints.maxWidth < 960;
        final horizontalPadding = isDesktop ? 32.0 : (isTablet ? 24.0 : 16.0);

        final studentName = _profile?['name'] ?? 'Student';
        final studentType = _profile?['student_type'] as String? ?? 'Preschool';
        final photoUrl = _profile?['photo_url'] as String?;

        return PopScope(
          canPop: false,
          child: Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          appBar: AppBar(
            toolbarHeight: 64,
            backgroundColor: Colors.white,
            elevation: 0,
            titleSpacing: isDesktop ? 24 : 12,
            title: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                  ),
                  child: ClipOval(
                    child: Image.asset('assets/images/logo.png', fit: BoxFit.cover),
                  ),
                ),
                const SizedBox(width: 10),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Strawberry',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: AppColors.textDark,
                              letterSpacing: -0.3,
                            ),
                          ),
                          if (constraints.maxWidth >= 420) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.primarySoft,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'PORTAL',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.primaryDark,
                                  letterSpacing: 0.4,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const Text(
                        'Preschool & Daycare',
                        style: TextStyle(
                          fontSize: 10.5,
                          color: AppColors.textMuted,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              if (isDesktop) ...[
                // Notice Board Shortcut
                TextButton.icon(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const NoticeBoardPage()),
                  ).then((_) => _loadUnreadNoticesCount()),
                  icon: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      const Icon(Icons.notifications_none_rounded, color: AppColors.textDark, size: 20),
                      if (_unreadNoticesCount > 0)
                        Positioned(
                          top: -3,
                          right: -3,
                          child: Container(
                            padding: const EdgeInsets.all(3),
                            decoration: const BoxDecoration(
                              color: AppColors.danger,
                              shape: BoxShape.circle,
                            ),
                            constraints: const BoxConstraints(minWidth: 14, minHeight: 14),
                            child: Text(
                              '$_unreadNoticesCount',
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                    ],
                  ),
                  label: const Text('Notices', style: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.w600, fontSize: 13)),
                  style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 12)),
                ),
                // Chat Shortcut
                TextButton.icon(
                  onPressed: () {
                    final uid = _authService.currentUserId ?? '';
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ChatPage(studentId: uid, studentName: studentName, isAdmin: false),
                      ),
                    );
                  },
                  icon: const Icon(Icons.chat_bubble_outline_rounded, color: AppColors.textDark, size: 19),
                  label: const Text('Chat with School', style: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.w600, fontSize: 13)),
                  style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 12)),
                ),
                // About Us Shortcut
                TextButton.icon(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const AboutPage()),
                  ),
                  icon: const Icon(Icons.info_outline_rounded, color: AppColors.textDark, size: 19),
                  label: const Text('About Us', style: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.w600, fontSize: 13)),
                  style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 12)),
                ),
                const SizedBox(width: 8),
                // Student Profile Chip
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 10),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircleAvatar(
                        radius: 13,
                        backgroundColor: AppColors.primarySoft,
                        backgroundImage: (photoUrl != null && photoUrl.isNotEmpty)
                            ? NetworkImage(photoUrl)
                            : null,
                        child: (photoUrl == null || photoUrl.isEmpty)
                            ? const Icon(Icons.person_rounded, color: AppColors.primary, size: 14)
                            : null,
                      ),
                      const SizedBox(width: 8),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            studentName,
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textDark,
                              height: 1.15,
                            ),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            studentType,
                            style: const TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primaryDark,
                              height: 1.15,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
              ] else ...[
                // Mobile Notice Icon
                IconButton(
                  icon: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      const Icon(Icons.notifications_none_rounded, color: AppColors.primary),
                      if (_unreadNoticesCount > 0)
                        Positioned(
                          top: -2,
                          right: -2,
                          child: Container(
                            padding: const EdgeInsets.all(3),
                            decoration: const BoxDecoration(
                              color: AppColors.danger,
                              shape: BoxShape.circle,
                            ),
                            constraints: const BoxConstraints(minWidth: 14, minHeight: 14),
                            child: Text(
                              '$_unreadNoticesCount',
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                    ],
                  ),
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const NoticeBoardPage()),
                  ).then((_) => _loadUnreadNoticesCount()),
                  tooltip: 'Notice Board',
                ),
                IconButton(
                  icon: const Icon(Icons.info_outline_rounded, color: AppColors.primary),
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const AboutPage()),
                  ),
                  tooltip: 'About Strawberry',
                ),
              ],
              IconButton(
                icon: const Icon(Icons.logout_rounded, color: AppColors.textMuted),
                onPressed: _logout,
                tooltip: 'Log Out',
              ),
              const SizedBox(width: 4),
            ],
          ),
          body: _loading
              ? const StrawberryLoader(message: 'Loading your profile... ✨')
              : Stack(
                  children: [
                    RefreshIndicator(
                      onRefresh: _loadProfile,
                      color: AppColors.primary,
                      child: ListView(
                        padding: EdgeInsets.symmetric(
                          horizontal: horizontalPadding,
                          vertical: 20.0,
                        ),
                        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                        children: [
                          _buildProfileHero(isDesktop),
                          const SizedBox(height: 20),
                          if (isDesktop)
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Left Column: Attendance, Finance & Tools
                                Expanded(
                                  child: Column(
                                    children: [
                                      _buildAttendanceCard(),
                                      const SizedBox(height: 18),
                                      _buildFeeCard(),
                                      const SizedBox(height: 18),
                                      _buildQuickActionsGrid(),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 24),
                                // Right Column: Memories, Notices & School Info
                                Expanded(
                                  child: Column(
                                    children: [
                                      _buildPreschoolMemoriesCard(),
                                      const SizedBox(height: 18),
                                      _buildRecentNoticesCard(),
                                      const SizedBox(height: 18),
                                      _buildCampusSupportCard(),
                                    ],
                                  ),
                                ),
                              ],
                            )
                          else ...[
                            _buildAttendanceCard(),
                            const SizedBox(height: 16),
                            _buildFeeCard(),
                            const SizedBox(height: 16),
                            _buildQuickActionsGrid(),
                            const SizedBox(height: 16),
                            _buildPreschoolMemoriesCard(),
                            const SizedBox(height: 16),
                            _buildRecentNoticesCard(),
                            const SizedBox(height: 16),
                            _buildCampusSupportCard(),
                            const SizedBox(height: 80),
                          ],
                          const SizedBox(height: 30),
                        ],
                      ),
                    ),
                    if (_isFabOpen)
                      Positioned.fill(
                        child: GestureDetector(
                          onTap: _closeFab,
                          child: Container(
                            color: Colors.black.withValues(alpha: 0.45),
                          ),
                        ),
                      ),
                  ],
                ),
          floatingActionButton: (_loading || isDesktop) ? null : _buildSpeedDialMenu(),
        ),
      );
    },
  );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Rise & Shine, Little Champion! ☀️';
    if (hour < 17) return 'Afternoon Adventures in Full Swing! 🚀';
    return 'Mission Accomplished Today, Superstar! 🌙';
  }

  String _getCategoryEmoji(String? category) {
    if (category == null) return '🍓';
    final lower = category.toLowerCase();
    if (lower.contains('playgroup')) return '🧸';
    if (lower.contains('nursery')) return '🎨';
    if (lower.contains('lkg')) return '📚';
    if (lower.contains('ukg')) return '🎓';
    if (lower.contains('daycare')) return '🌟';
    return '🍓';
  }

  Widget _buildProfileHero(bool isDesktop) {
    final photoUrl = _profile?['photo_url'] as String?;
    final hasPhoto = photoUrl != null && photoUrl.isNotEmpty;
    final name = _profile?['name'] ?? 'Student';
    final studentType = _profile?['student_type'] as String? ?? 'Preschool';
    final emoji = _getCategoryEmoji(studentType);
    final parentName = _profile?['parent_name'] as String? ?? '';
    final phone = _profile?['phone'] as String? ?? '';
    final fee = _profile?['fees'] ?? 0;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: isDesktop ? 26 : 18, vertical: isDesktop ? 22 : 18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFE93B61), Color(0xFFC72847)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE93B61).withValues(alpha: 0.22),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: isDesktop
          ? Row(
              children: [
                // Child Avatar
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.35),
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: CircleAvatar(
                    radius: 32,
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                    backgroundImage: hasPhoto ? NetworkImage(photoUrl) : null,
                    child: !hasPhoto
                        ? const Text('🍓', style: TextStyle(fontSize: 30))
                        : null,
                  ),
                ),
                const SizedBox(width: 18),
                // Child Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              _getGreeting(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const PlayfulSparkle(size: 14, color: Colors.amberAccent),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.5,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(emoji, style: const TextStyle(fontSize: 13)),
                                const SizedBox(width: 4),
                                Text(
                                  studentType,
                                  style: const TextStyle(
                                    color: AppColors.primaryDark,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (parentName.isNotEmpty || phone.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          [
                            if (parentName.isNotEmpty) 'Parent: $parentName',
                            if (phone.isNotEmpty) 'Phone: $phone',
                          ].join('  •  '),
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                // Quick KPI Frosted Cards on Right
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildHeroMetricPill(
                      icon: Icons.account_balance_wallet_rounded,
                      label: 'Monthly Fee',
                      value: '₹$fee',
                      subtext: 'Tuition',
                    ),
                    const SizedBox(width: 10),
                    _buildHeroMetricPill(
                      icon: Icons.check_circle_outline_rounded,
                      label: 'Status',
                      value: 'Enrolled',
                      subtext: 'Active',
                    ),
                    const SizedBox(width: 10),
                    _buildHeroMetricPill(
                      icon: Icons.calendar_today_rounded,
                      label: 'Academic',
                      value: '2026-27',
                      subtext: 'Session',
                    ),
                  ],
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(2.5),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.35),
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: CircleAvatar(
                        radius: 26,
                        backgroundColor: Colors.white.withValues(alpha: 0.2),
                        backgroundImage: hasPhoto ? NetworkImage(photoUrl) : null,
                        child: !hasPhoto
                            ? const Text('🍓', style: TextStyle(fontSize: 24))
                            : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _getGreeting(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(emoji, style: const TextStyle(fontSize: 12)),
                          const SizedBox(width: 4),
                          Text(
                            studentType,
                            style: const TextStyle(
                              color: AppColors.primaryDark,
                              fontWeight: FontWeight.w800,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (parentName.isNotEmpty || phone.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    [
                      if (parentName.isNotEmpty) 'Parent: $parentName',
                      if (phone.isNotEmpty) 'Phone: $phone',
                    ].join('  •  '),
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
    );
  }

  Widget _buildHeroMetricPill({
    required IconData icon,
    required String label,
    required String value,
    required String subtext,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
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
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  // --- BENTO CARDS ---

  Widget _buildFeeCard() {
    final fee = _profile?['fees'] ?? 0;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.emeraldSoft,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.account_balance_wallet_rounded, color: AppColors.emerald, size: 20),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Fee & Payment Center',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textDark,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.emeraldSoft,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'Instant UPI ⚡',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.emerald,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Monthly Tuition Fee',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '₹$fee / month',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textDark,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: const Text(
                    'Session 2026-27',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _profile == null
                      ? null
                      : () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => PayFeesPage(
                                authService: _authService,
                                profile: _profile!,
                              ),
                            ),
                          ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  icon: const Icon(Icons.bolt_rounded, size: 18),
                  label: const Text(
                    'Pay Monthly Fees via UPI',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.skySoft,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.calendar_month_rounded, color: AppColors.sky, size: 20),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Attendance & Holidays',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textDark,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.skySoft,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'Daily Logs',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.sky,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _buildMiniStat(
                  emoji: '✅',
                  label: 'Attendance',
                  value: 'Live Tracked',
                  color: AppColors.emerald,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMiniStat(
                  emoji: '🏖️',
                  label: 'School Holidays',
                  value: 'Synced',
                  color: AppColors.violet,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          OutlinedButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const AttendancePage()),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.textDark,
              side: const BorderSide(color: Color(0xFFE2E8F0)),
              padding: const EdgeInsets.symmetric(vertical: 12),
              minimumSize: const Size(double.infinity, 44),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'View Monthly Attendance & Holidays',
                  style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
                ),
                SizedBox(width: 6),
                Icon(Icons.arrow_forward_rounded, size: 14, color: AppColors.primary),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat({
    required String emoji,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 12)),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textMuted,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
              color: color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsGrid() {
    final actions = [
      {
        'title': 'School Chat',
        'subtitle': 'Direct Helpdesk',
        'icon': Icons.chat_bubble_outline_rounded,
        'color': AppColors.violet,
        'onTap': () {
          final uid = _authService.currentUserId ?? '';
          final name = _profile?['name'] ?? 'Student';
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ChatPage(studentId: uid, studentName: name, isAdmin: false),
            ),
          );
        },
      },
      {
        'title': 'Notice Board',
        'subtitle': _unreadNoticesCount > 0 ? '$_unreadNoticesCount New' : 'Circulars',
        'icon': Icons.campaign_rounded,
        'color': AppColors.amberDark,
        'onTap': () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const NoticeBoardPage()),
        ).then((_) => _loadUnreadNoticesCount()),
      },
      {
        'title': 'Photo Gallery',
        'subtitle': 'Campus Albums',
        'icon': Icons.photo_library_rounded,
        'color': AppColors.sky,
        'onTap': () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const GalleryPage()),
        ),
      },
      {
        'title': 'About Us',
        'subtitle': 'Campus & Vision',
        'icon': Icons.info_outline_rounded,
        'color': AppColors.primary,
        'onTap': () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const AboutPage()),
        ),
      },
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
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
              Icon(Icons.widgets_outlined, color: AppColors.primary, size: 20),
              SizedBox(width: 8),
              Text(
                'Campus Services',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 2.3,
            ),
            itemCount: actions.length,
            itemBuilder: (ctx, i) {
              final a = actions[i];
              final color = a['color'] as Color;
              return InkWell(
                onTap: a['onTap'] as VoidCallback,
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(a['icon'] as IconData, color: color, size: 17),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              a['title'] as String,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textDark,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              a['subtitle'] as String,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textMuted,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPreschoolMemoriesCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.photo_camera_rounded, color: AppColors.amberDark, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Preschool Memories',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textDark,
                    ),
                  ),
                ],
              ),
              InkWell(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const GalleryPage()),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'All Albums',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                    SizedBox(width: 2),
                    Icon(Icons.arrow_forward_rounded, size: 14, color: AppColors.primary),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (_todayHighlights.isEmpty)
            InkWell(
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const GalleryPage()),
              ),
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: const Row(
                  children: [
                    Text('🎨', style: TextStyle(fontSize: 24)),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Campus Photo Albums',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textDark,
                            ),
                          ),
                          Text(
                            'Explore classroom activities & celebration snaps',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
                  ],
                ),
              ),
            )
          else
            SizedBox(
              height: 140,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: _todayHighlights.length,
                itemBuilder: (ctx, i) {
                  final p = _todayHighlights[i];
                  final url = p['image_url'] as String;
                  final cat = (p['category'] as String?) ?? 'Fun Moment';
                  return Container(
                    width: 140,
                    margin: const EdgeInsets.only(right: 10),
                    child: InkWell(
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const GalleryPage()),
                      ),
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.network(
                              url,
                              fit: BoxFit.cover,
                              errorBuilder: (ctx, err, stack) => Container(
                                color: AppColors.surfaceAlt,
                                child: const Icon(Icons.image_outlined, color: AppColors.textMuted),
                              ),
                            ),
                            Positioned(
                              left: 0,
                              right: 0,
                              bottom: 0,
                              child: Container(
                                padding: const EdgeInsets.fromLTRB(6, 16, 6, 6),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.transparent,
                                      Colors.black.withValues(alpha: 0.75),
                                    ],
                                  ),
                                ),
                                child: Text(
                                  cat,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRecentNoticesCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.campaign_rounded, color: AppColors.primary, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Official Announcements',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textDark,
                    ),
                  ),
                ],
              ),
              InkWell(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const NoticeBoardPage()),
                ).then((_) => _loadUnreadNoticesCount()),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Notice Board',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                    SizedBox(width: 2),
                    Icon(Icons.arrow_forward_rounded, size: 14, color: AppColors.primary),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (_recentNotices.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.mark_email_read_outlined, color: AppColors.textMuted, size: 22),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'No new notices. All circulars are up to date.',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            Column(
              children: _recentNotices.map((n) {
                final title = n['title'] ?? 'Notice';
                final cat = n['category'] ?? 'General';
                final body = n['body'] ?? '';
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: InkWell(
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const NoticeBoardPage()),
                    ).then((_) => _loadUnreadNoticesCount()),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primarySoft,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            cat,
                            style: const TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primaryDark,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textDark,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (body.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(
                                  body,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textMuted,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.textMuted),
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

  Widget _buildCampusSupportCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1F2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFFCCD3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Text('🍓', style: TextStyle(fontSize: 22)),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Strawberry Preschool & Daycare',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primaryDark,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Main Campus • +91 9999249495',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textDark,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const AboutPage()),
            ),
            style: TextButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppColors.primaryDark,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            ),
            child: const Text(
              'Info',
              style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpeedDialMenu() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Expandable list of options
        if (_isFabOpen) ...[
          _buildSpeedDialItem(
            emoji: '💬',
            label: 'Helpdesk Chat',
            color: AppColors.violet,
            bgColor: AppColors.violetSoft,
            onTap: () {
              _closeFab();
              final uid = _authService.currentUserId ?? '';
              final name = _profile?['name'] ?? 'Student';
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ChatPage(
                    studentId: uid,
                    studentName: name,
                    isAdmin: false,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          _buildSpeedDialItem(
            emoji: '📢',
            label: 'Notice Board',
            color: AppColors.sky,
            bgColor: AppColors.skySoft,
            badgeCount: _unreadNoticesCount,
            onTap: () {
              _closeFab();
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const NoticeBoardPage()),
              ).then((_) => _loadUnreadNoticesCount());
            },
          ),
          const SizedBox(height: 12),
          _buildSpeedDialItem(
            emoji: '🎨',
            label: 'Preschool Gallery',
            color: AppColors.amber,
            bgColor: AppColors.amberSoft,
            onTap: () {
              _closeFab();
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const GalleryPage()),
              );
            },
          ),
          const SizedBox(height: 12),
          _buildSpeedDialItem(
            emoji: '💳',
            label: 'Pay School Fees',
            color: AppColors.primary,
            bgColor: AppColors.primarySoft,
            onTap: () {
              _closeFab();
              if (_profile == null) return;
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => PayFeesPage(
                    authService: _authService,
                    profile: _profile!,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          _buildSpeedDialItem(
            emoji: '📅',
            label: 'Daily Attendance',
            color: AppColors.emerald,
            bgColor: AppColors.emeraldSoft,
            onTap: () {
              _closeFab();
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AttendancePage()),
              );
            },
          ),
          const SizedBox(height: 16),
        ],

        // Main Primary Floating Action Button
        GestureDetector(
          onTap: _toggleFab,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF5274), Color(0xFFE94464), Color(0xFFC72847)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.4),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Center(
                  child: RotationTransition(
                    turns: _fabAnimationController.drive(
                      Tween<double>(begin: 0.0, end: 0.125),
                    ),
                    child: Icon(
                      _isFabOpen ? Icons.close_rounded : Icons.add_rounded,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                ),
              ),
              if (!_isFabOpen && _unreadNoticesCount > 0)
                Positioned(
                  top: -2,
                  right: -2,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.amber,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: Text(
                      '$_unreadNoticesCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSpeedDialItem({
    required String emoji,
    required String label,
    required Color color,
    required Color bgColor,
    required VoidCallback onTap,
    int badgeCount = 0,
  }) {
    return ScaleTransition(
      scale: _fabExpandAnimation,
      child: FadeTransition(
        opacity: _fabExpandAnimation,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(30),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Label pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: AppColors.textDark,
                      ),
                    ),
                    if (badgeCount > 0) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.danger,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '$badgeCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 10),

              // Circular icon button
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.25),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(emoji, style: const TextStyle(fontSize: 22)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}