import 'package:flutter/material.dart';
import 'package:strawberry/core/theme/app_colors.dart';
import 'package:strawberry/core/theme/app_typography.dart';
import 'package:strawberry/core/theme/app_decorations.dart';
import 'package:strawberry/core/utils/responsive.dart';
import 'package:strawberry/core/widgets/app_button.dart';
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
          _todayHighlights = photos.take(8).toList();
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
    await _authService.logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const AuthScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: Image.asset('assets/images/logo.png', fit: BoxFit.contain),
            ),
            const SizedBox(width: 10),
            Text('Strawberry', style: AppTypography.h2),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline_rounded, color: AppColors.primary),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const AboutPage()),
            ),
            tooltip: 'About Strawberry',
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: AppColors.primary),
            onPressed: _logout,
            tooltip: 'Log Out',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : Stack(
              children: [
                RefreshIndicator(
                  onRefresh: _loadProfile,
                  color: AppColors.primary,
                  child: Center(
                    child: ResponsiveContentWrapper(
                      maxWidth: 780,
                      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                        children: [
                          // Profile Hero Card
                          _buildProfileHero(),
                          const SizedBox(height: 20),

                          // Today's Highlights Reel
                          _buildHighlightsSection(),
                          const SizedBox(height: 24),

                          // Academic Overview Section
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Academic Overview', style: AppTypography.h2),
                              if (_profile?['student_type'] != null)
                                AppBadge(
                                  label: _profile!['student_type'].toString(),
                                  type: AppBadgeType.info,
                                ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          _buildAcademicCards(),
                          const SizedBox(height: 28),

                          Center(
                            child: InkWell(
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => const AboutPage()),
                              ),
                              borderRadius: AppDecorations.radiusMd,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.info_outline_rounded, size: 16, color: AppColors.primary),
                                    const SizedBox(width: 6),
                                    Text(
                                      'About Strawberry Preschool & Daycare',
                                      style: AppTypography.caption.copyWith(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 90), // Space for floating speed dial
                        ],
                      ),
                    ),
                  ),
                ),

                // Scrim overlay when FAB is opened
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
      floatingActionButton: _loading ? null : _buildSpeedDialMenu(),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning, Superstar! ☀️';
    if (hour < 17) return 'Good Afternoon, Champ! 🌟';
    return 'Good Evening, Little Star! 🌙';
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

  Widget _buildProfileHero() {
    final photoUrl = _profile?['photo_url'] as String?;
    final hasPhoto = photoUrl != null && photoUrl.isNotEmpty;
    final name = _profile?['name'] ?? 'Student';
    final studentType = _profile?['student_type'] as String? ?? 'Playgroup';
    final emoji = _getCategoryEmoji(studentType);

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF5274), Color(0xFFE94464), Color(0xFFC72847)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: AppDecorations.radiusXl,
        boxShadow: AppDecorations.primaryGlow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              FloatingWobble(
                verticalOffset: 3,
                rotationAngle: 0.03,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.35),
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                    backgroundImage: hasPhoto ? NetworkImage(photoUrl) : null,
                    child: !hasPhoto
                        ? const Text('🍓', style: TextStyle(fontSize: 28))
                        : null,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            _getGreeting(),
                            style: AppTypography.caption.copyWith(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        const PlayfulSparkle(size: 14, color: Colors.amberAccent),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      name,
                      style: AppTypography.h1.copyWith(color: Colors.white, fontSize: 20),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              BouncyTap(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: AppDecorations.radiusFull,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FloatingWobble(
                        verticalOffset: 2,
                        duration: const Duration(milliseconds: 1800),
                        child: Text(emoji, style: const TextStyle(fontSize: 14)),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        studentType,
                        style: AppTypography.badge.copyWith(
                          color: AppColors.primaryDark,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHighlightsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.amberSoft,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text('✨', style: TextStyle(fontSize: 15)),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Today's Moments 📸", style: AppTypography.h2),
                    Text(
                      'Preschool activities & daily smiles',
                      style: AppTypography.caption.copyWith(color: AppColors.textMuted),
                    ),
                  ],
                ),
              ],
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const GalleryPage()),
                );
              },
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('All Albums', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5)),
                  SizedBox(width: 2),
                  Icon(Icons.arrow_forward_rounded, size: 14),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_todayHighlights.isEmpty)
          InkWell(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const GalleryPage()),
            ),
            borderRadius: BorderRadius.circular(18),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.borderSubtle),
                boxShadow: AppDecorations.shadowSm,
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.primarySoft,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Center(
                      child: Text('🎨', style: TextStyle(fontSize: 24)),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Preschool Memory Book',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppColors.textDark,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Explore fun classroom moments, celebrations & art',
                          style: AppTypography.caption.copyWith(color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
                ],
              ),
            ),
          )
        else
          SizedBox(
            height: 175,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: _todayHighlights.length,
              itemBuilder: (context, index) {
                final photo = _todayHighlights[index];
                final url = photo['image_url'] as String;
                final cat = (photo['category'] as String?) ?? 'Fun Moment';
                final emoji = _getHighlightEmoji(cat);

                return StaggeredEntrance(
                  index: index,
                  slideOffset: 20,
                  child: Container(
                    width: 135,
                    margin: const EdgeInsets.only(right: 12),
                    child: BouncyTap(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const GalleryPage()),
                        );
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: AppColors.borderSubtle),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.network(
                              url,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Container(
                                color: AppColors.surfaceAlt,
                                child: const Icon(Icons.image_outlined, color: AppColors.textMuted),
                              ),
                            ),
                            Positioned(
                              left: 0,
                              right: 0,
                              bottom: 0,
                              child: Container(
                                padding: const EdgeInsets.fromLTRB(8, 20, 8, 8),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.transparent,
                                      Colors.black.withValues(alpha: 0.8),
                                    ],
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(emoji, style: const TextStyle(fontSize: 11)),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        cat,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  String _getHighlightEmoji(String cat) {
    final lower = cat.toLowerCase();
    if (lower.contains('art') || lower.contains('craft') || lower.contains('paint')) return '🎨';
    if (lower.contains('rhyme') || lower.contains('music') || lower.contains('dance')) return '🎪';
    if (lower.contains('play') || lower.contains('fun') || lower.contains('zone')) return '🛝';
    if (lower.contains('celebrat') || lower.contains('event') || lower.contains('festival')) return '🎉';
    if (lower.contains('snack') || lower.contains('circle') || lower.contains('fruit')) return '🍎';
    if (lower.contains('daycare') || lower.contains('tiny') || lower.contains('tot')) return '🧸';
    return '🍓';
  }

  Widget _buildAcademicCards() {
    final studentType = _profile?['student_type'] as String? ?? 'Preschool';
    final emoji = _getCategoryEmoji(studentType);
    final fee = _profile?['fees'] ?? 0;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildInfoCard(
                emoji: emoji,
                icon: Icons.school_rounded,
                title: 'Class / Group',
                value: studentType,
                color: AppColors.sky,
                bgColor: AppColors.skySoft,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildInfoCard(
                emoji: '💳',
                icon: Icons.account_balance_wallet_rounded,
                title: 'Tuition Fee',
                value: '₹$fee / mo',
                color: AppColors.emerald,
                bgColor: AppColors.emeraldSoft,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: AppDecorations.radiusLg,
            border: Border.all(color: AppColors.borderSubtle),
            boxShadow: AppDecorations.shadowSm,
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.violetSoft,
                  borderRadius: AppDecorations.radiusMd,
                ),
                child: const Text('📅', style: TextStyle(fontSize: 24)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Attendance & Holiday Tracker', style: AppTypography.h3.copyWith(fontSize: 15)),
                    const SizedBox(height: 2),
                    Text('View present days, leaves & festival holidays', style: AppTypography.bodySmall),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: AppColors.primary),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AttendancePage()),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        AppButton(
          label: 'Pay Monthly Fees via UPI ⚡',
          icon: Icons.bolt_rounded,
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
          variant: AppButtonVariant.primary,
          height: 50,
        ),
      ],
    );
  }

  Widget _buildInfoCard({
    required String emoji,
    required IconData icon,
    required String title,
    required String value,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppDecorations.radiusLg,
        border: Border.all(color: AppColors.borderSubtle),
        boxShadow: AppDecorations.shadowSm,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: AppDecorations.radiusSm,
            ),
            child: Text(emoji, style: const TextStyle(fontSize: 20)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTypography.caption),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: AppTypography.h3.copyWith(fontSize: 15),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
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