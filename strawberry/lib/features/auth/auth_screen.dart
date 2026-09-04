import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:strawberry/core/theme/app_colors.dart';
import 'package:strawberry/core/theme/app_typography.dart';
import 'package:strawberry/core/theme/app_decorations.dart';
import 'package:strawberry/core/widgets/app_button.dart';
import 'package:strawberry/features/auth/auth_service.dart';
import 'package:strawberry/features/about/about_service.dart';
import 'package:strawberry/features/about/about_model.dart';
import 'package:strawberry/features/dashboard/student/wait_screen.dart';
import 'package:strawberry/features/dashboard/student/home_screen.dart';
import 'package:strawberry/features/dashboard/student/gallery_page.dart';
import 'package:strawberry/features/dashboard/admin/admin_dashboard.dart';
import 'package:strawberry/core/widgets/playschool_animations.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen>
    with SingleTickerProviderStateMixin {
  final _authService = AuthService();
  final _aboutService = AboutService();

  int _activeTab = 0; // 0: 🌟 Explore School, 1: 🔐 Parent Portal
  int _previousTab = 0;
  bool _loading = false;
  String? _error;

  List<String> _categories = [];
  List<Map<String, dynamic>> _galleryPhotos = [];
  AboutInfo _aboutInfo = AboutInfo.defaults();
  bool _loadingData = true;

  final ScrollController _exploreScrollController = ScrollController();
  final GlobalKey _heroKey = GlobalKey();
  final GlobalKey _aboutKey = GlobalKey();
  final GlobalKey _programsKey = GlobalKey();
  final GlobalKey _tourKey = GlobalKey();
  final GlobalKey _whyUsKey = GlobalKey();
  final GlobalKey _locationKey = GlobalKey();

  StreamSubscription<User?>? _authSubscription;
  bool _navigating = false;

  late final AnimationController _animController;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
    );
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _animController,
            curve: const Interval(0.08, 1.0, curve: Curves.easeOutCubic),
          ),
        );
    _animController.forward();
    _loadDiscoveryData();

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      _activeTab = 1;
      _loading = true;
      _navigating = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _routeUser(currentUser);
      });
    }

    // Listen to Firebase Auth state for mobile web redirect completions
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen((user) async {
      if (user != null && mounted && !_navigating) {
        _navigating = true;
        _activeTab = 1;
        _routeUser(user);
      }
    });
  }

  void _switchTab(int index) {
    if (_activeTab == index) return;
    setState(() {
      _previousTab = _activeTab;
      _activeTab = index;
    });
  }

  Future<void> _loadDiscoveryData() async {
    try {
      final cats = await _authService.getCategories();
      final photos = await _authService.getGalleryImages();
      final about = await _aboutService.getAboutInfo();
      if (!mounted) return;
      setState(() {
        _categories = cats;
        _galleryPhotos = photos.take(8).toList();
        _aboutInfo = about;
        _loadingData = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingData = false);
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _animController.dispose();
    _exploreScrollController.dispose();
    super.dispose();
  }

  void _scrollToKey(GlobalKey key) {
    if (_activeTab != 0) {
      _switchTab(0);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _performScrollToKey(key);
      });
    } else {
      _performScrollToKey(key);
    }
  }

  void _performScrollToKey(GlobalKey key) {
    final ctx = key.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  Future<void> _launchExternalUrl(String url) async {
    final uri = Uri.parse(url);
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  Future<void> _launchWhatsApp([String? program]) async {
    final text = program != null && program.isNotEmpty
        ? 'Hello Strawberry Playschool, I am interested in admission for the $program program. Please share details regarding the admission process and campus visit.'
        : 'Hello Strawberry Playschool, I would like to enquire about new admissions and book a campus visit.';
    final uri = Uri.parse(
      'https://wa.me/919999249495?text=${Uri.encodeComponent(text)}',
    );
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  Future<void> _launchCall() async {
    final uri = Uri.parse('tel:+919999249495');
    try {
      await launchUrl(uri);
    } catch (_) {}
  }

  void _openPhotoLightbox(String url) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Stack(
          alignment: Alignment.center,
          children: [
            ClipRRect(
              borderRadius: AppDecorations.radiusLg,
              child: Image.network(
                url,
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) => const Icon(
                  Icons.image_not_supported_rounded,
                  color: Colors.white,
                  size: 48,
                ),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                icon: const Icon(Icons.close_rounded, color: Colors.white, size: 28),
                onPressed: () => Navigator.pop(ctx),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEnquirySheet([String? preselectedProgram]) {
    final parentNameCtrl = TextEditingController();
    final childNameCtrl = TextEditingController();
    final childAgeCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final standardPrograms = [
      'Playgroup',
      'Nursery',
      'LKG (Junior KG)',
      'UKG (Senior KG)',
      'Daycare & Creche',
      'Tuition Classes',
    ];

    String normalizeProgram(String? input) {
      if (input == null || input.trim().isEmpty) return standardPrograms.first;
      final clean = input.toLowerCase().trim();

      if (clean.contains('tuition') || clean.contains('tution')) {
        return 'Tuition Classes';
      }
      if (clean.contains('daycare') || clean.contains('creche')) {
        return 'Daycare & Creche';
      }
      if (clean.contains('ukg') || clean.contains('senior')) {
        return 'UKG (Senior KG)';
      }
      if (clean.contains('lkg') || clean.contains('junior')) {
        return 'LKG (Junior KG)';
      }
      if (clean.contains('nursery')) {
        return 'Nursery';
      }
      if (clean.contains('play')) {
        return 'Playgroup';
      }

      for (final p in standardPrograms) {
        if (p.toLowerCase() == clean) return p;
      }
      return standardPrograms.first;
    }

    final availableCategories = [
      ...standardPrograms,
      for (final c in _categories)
        if (!standardPrograms.any((sp) => sp.toLowerCase() == c.toLowerCase()))
          c,
    ];
    String selectedProgram = normalizeProgram(preselectedProgram);
    bool submitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (bCtx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 44,
                        height: 5,
                        decoration: BoxDecoration(
                          color: AppColors.borderSubtle,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            gradient: AppColors.primaryGradient,
                            borderRadius: AppDecorations.radiusMd,
                            boxShadow: AppDecorations.primaryGlow,
                          ),
                          child: const Icon(Icons.school_rounded, color: Colors.white, size: 24),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Admission Enquiry', style: AppTypography.h2),
                              const SizedBox(height: 2),
                              Text(
                                'Book a campus tour or receive fee & curriculum details',
                                style: AppTypography.caption.copyWith(color: AppColors.textMuted),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    TextField(
                      controller: parentNameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Parent / Guardian Name *',
                        prefixIcon: Icon(Icons.person_rounded, color: AppColors.primary),
                      ),
                    ),
                    const SizedBox(height: 14),

                    TextField(
                      controller: phoneCtrl,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Mobile Number *',
                        prefixIcon: Icon(Icons.phone_rounded, color: AppColors.primary),
                        prefixText: '+91 ',
                      ),
                    ),
                    const SizedBox(height: 14),

                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: TextField(
                            controller: childNameCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Child\'s Name (Optional)',
                              prefixIcon: Icon(Icons.face_rounded, color: AppColors.primary),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: TextField(
                            controller: childAgeCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Age (e.g. 2.5 yrs)',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    DropdownButtonFormField<String>(
                      initialValue: selectedProgram,
                      decoration: const InputDecoration(
                        labelText: 'Interested Program',
                        prefixIcon: Icon(Icons.category_rounded, color: AppColors.primary),
                      ),
                      items: availableCategories
                          .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                          .toList(),
                      onChanged: (v) {
                        if (v != null) setSheetState(() => selectedProgram = v);
                      },
                    ),
                    const SizedBox(height: 22),

                    AppButton(
                      label: submitting ? 'Submitting...' : 'Submit & Connect on WhatsApp',
                      icon: Icons.send_rounded,
                      loading: submitting,
                      onPressed: submitting
                          ? null
                          : () async {
                              final pName = parentNameCtrl.text.trim();
                              final phone = phoneCtrl.text.trim();
                              if (pName.isEmpty || phone.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Hold up! We need your Parent Name & Mobile Number 🎒✨'),
                                    backgroundColor: AppColors.danger,
                                  ),
                                );
                                return;
                              }

                              setSheetState(() => submitting = true);
                              await _authService.submitAdmissionEnquiry(
                                parentName: pName,
                                phone: phone,
                                childName: childNameCtrl.text.trim(),
                                childAge: childAgeCtrl.text.trim(),
                                program: selectedProgram,
                              );

                              if (!ctx.mounted) return;
                              Navigator.pop(ctx);

                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Woohoo! Enquiry recorded. Connecting you with our campus team... 🚀🍓'),
                                  backgroundColor: AppColors.emerald,
                                ),
                              );

                              _launchWhatsApp(selectedProgram);
                            },
                      variant: AppButtonVariant.primary,
                      height: 52,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _routeUser(User user) async {
    if (!mounted) return;
    setState(() => _loading = true);

    try {
      final profile = await _authService.getCurrentProfile();
      if (!mounted) return;

      if (profile == null) {
        final newProfile = await _authService.createProfile();
        if (!mounted) return;

        final role = newProfile['role'];
        if (role == 'admin') {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const AdminDashboard()),
            (route) => false,
          );
        } else {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const WaitScreen()),
            (route) => false,
          );
        }
      } else {
        final role = profile['role'];
        final status = profile['status'];

        if (status == 'pending') {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const WaitScreen()),
            (route) => false,
          );
        } else if (status == 'rejected') {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (_) => const WaitScreen(isRejected: true),
            ),
            (route) => false,
          );
        } else if (status == 'approved') {
          if (role == 'admin') {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const AdminDashboard()),
              (route) => false,
            );
          } else {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const HomeScreen()),
              (route) => false,
            );
          }
        } else {
          setState(() {
            _error = 'Oops! Profile status unknown. Please buzz the school office 📞';
            _loading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'Failed to load profile: $e';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Login note: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Future<void> _signInWithGoogle() async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final userCredential = await _authService.signInWithGoogle();

      if (userCredential == null) {
        final current = FirebaseAuth.instance.currentUser;
        if (current != null) {
          _navigating = true;
          await _routeUser(current);
          return;
        }
        if (mounted) {
          setState(() {
            _loading = false;
            _error = null;
          });
        }
        return;
      }

      if (userCredential.user != null) {
        _navigating = true;
        await _routeUser(userCredential.user!);
      }
    } catch (e) {
      if (mounted) {
        final msg = e.toString().toLowerCase();
        if (msg.contains('popup-closed') ||
            msg.contains('popup_closed') ||
            msg.contains('closed') ||
            msg.contains('cancel')) {
          setState(() {
            _loading = false;
            _error = null;
          });
        } else {
          setState(() {
            _error = 'Couldn\'t sign in this time. Let\'s give it another spin! 🔄';
            _loading = false;
          });
        }
      }
    } finally {
      if (mounted && _loading && FirebaseAuth.instance.currentUser == null) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  // ── Top Segmented Pill Switcher & Transparent Header ───────────────────
  Widget _buildTabSwitcher(bool isDesktop) {
    final screenWidth = MediaQuery.of(context).size.width;
    final horizontalPad = isDesktop ? (screenWidth >= 1200 ? 36.0 : 20.0) : 16.0;

    return Container(
      color: Colors.transparent,
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPad,
        vertical: isDesktop ? 12.0 : 8.0,
      ),
      child: isDesktop
          ? LayoutBuilder(
              builder: (context, navConstraints) {
                final navWidth = navConstraints.maxWidth;
                final showAllNavLinks = navWidth >= 1080;
                final showCompactNavLinks = navWidth >= 880 && navWidth < 1080;
                final showFullBrandTitle = navWidth >= 960;

                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.94),
                    borderRadius: BorderRadius.circular(36),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // Left Brand Pill
                      Flexible(
                        flex: 0,
                        child: InkWell(
                          onTap: () {
                            if (_activeTab != 0) _switchTab(0);
                            _scrollToKey(_heroKey);
                          },
                          borderRadius: BorderRadius.circular(30),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 38,
                                height: 38,
                                decoration: const BoxDecoration(shape: BoxShape.circle),
                                child: ClipOval(
                                  child: Image.asset(
                                    'assets/images/logo.png',
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    showFullBrandTitle
                                        ? 'Strawberry Preschool & Daycare'
                                        : 'Strawberry Preschool',
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w900,
                                      color: AppColors.textDark,
                                      letterSpacing: -0.2,
                                    ),
                                  ),
                                  const Text(
                                    'Sector 85, Faridabad',
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),

                      const Spacer(),

                      // Center Quick Navigation links
                      if (_activeTab == 0) ...[
                        if (showAllNavLinks) ...[
                          _buildDesktopNavLink('About School', () => _scrollToKey(_aboutKey)),
                          _buildDesktopNavLink('Programs', () => _scrollToKey(_programsKey)),
                          _buildDesktopNavLink('Campus Gallery', () => _scrollToKey(_tourKey)),
                          _buildDesktopNavLink('Why Us', () => _scrollToKey(_whyUsKey)),
                          _buildDesktopNavLink('Visit Campus', () => _scrollToKey(_locationKey)),
                          const SizedBox(width: 6),
                        ] else if (showCompactNavLinks) ...[
                          _buildDesktopNavLink('About', () => _scrollToKey(_aboutKey), true),
                          _buildDesktopNavLink('Programs', () => _scrollToKey(_programsKey), true),
                          _buildDesktopNavLink('Gallery', () => _scrollToKey(_tourKey), true),
                          _buildDesktopNavLink('Visit', () => _scrollToKey(_locationKey), true),
                          const SizedBox(width: 4),
                        ],
                      ],

                      // WhatsApp SVG Button
                      Tooltip(
                        message: 'Chat on WhatsApp',
                        child: InkWell(
                          onTap: () => _launchWhatsApp(),
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF25D366).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: const Color(0xFF25D366).withValues(alpha: 0.3)),
                            ),
                            child: SvgPicture.asset(
                              'assets/images/whatsapp.svg',
                              width: 20,
                              height: 20,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),

                      // Right Switcher Button
                      ElevatedButton.icon(
                        onPressed: () => _switchTab(_activeTab == 0 ? 1 : 0),
                        icon: Icon(
                          _activeTab == 0 ? Icons.lock_person_rounded : Icons.explore_rounded,
                          size: 15,
                        ),
                        label: Text(
                          _activeTab == 0 ? 'Parent Portal' : 'Explore Website',
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _activeTab == 0 ? AppColors.primary : AppColors.textDark,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                        ),
                      ),
                    ],
                  ),
                );
              },
            )
          : Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 380),
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 12,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildSwitcherPill(
                        index: 0,
                        icon: Icons.auto_awesome_rounded,
                        label: 'Explore School',
                      ),
                    ),
                    Expanded(
                      child: _buildSwitcherPill(
                        index: 1,
                        icon: Icons.login_rounded,
                        label: 'Parent Portal',
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildDesktopNavLink(String title, VoidCallback onTap, [bool compact = false]) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: compact ? 2 : 4),
      child: TextButton(
        onPressed: onTap,
        style: TextButton.styleFrom(
          foregroundColor: AppColors.textDark,
          padding: EdgeInsets.symmetric(horizontal: compact ? 8 : 10, vertical: 6),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: Text(
          title,
          style: TextStyle(
            fontSize: compact ? 12 : 13,
            fontWeight: FontWeight.w700,
            color: AppColors.textDark,
          ),
        ),
      ),
    );
  }

  Widget _buildSwitcherPill({
    required int index,
    required IconData icon,
    required String label,
  }) {
    final active = _activeTab == index;
    return GestureDetector(
      onTap: () => _switchTab(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8.5),
        decoration: BoxDecoration(
          color: active ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
          boxShadow: active
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 15,
              color: active ? Colors.white : AppColors.textMuted,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: active ? Colors.white : AppColors.textDark,
                fontSize: 13,
                fontWeight: active ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── UX Pillar 1: Hero Banner & Trust Badges ───────────────────────────
  Widget _buildHeroBanner(bool isDesktop, [double? screenWidth]) {
    if (isDesktop) {
      return Container(
        key: _heroKey,
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 44, vertical: 48),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFE93B61), Color(0xFFC72847), Color(0xFFA61C37)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFE93B61).withValues(alpha: 0.35),
              blurRadius: 36,
              offset: const Offset(0, 14),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Left Hero Column: Headings, Badges, Trust Metrics, CTAs
            Expanded(
              flex: 6,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Brand Row: Large Round Logo + School Title & Location Badge
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Round School Logo (bada size)
                      Container(
                        width: 116,
                        height: 116,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.22),
                              blurRadius: 20,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(4),
                        child: ClipOval(
                          child: Image.asset(
                            'assets/images/logo.png',
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(width: 22),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _aboutInfo.schoolName.isNotEmpty
                                  ? _aboutInfo.schoolName
                                  : 'Strawberry Preschool & Daycare',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 26,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.3,
                                height: 1.15,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.22),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.white.withValues(alpha: 0.45)),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.location_on_rounded, color: Colors.white, size: 14),
                                  SizedBox(width: 6),
                                  Flexible(
                                    child: Text(
                                      'BPTP Parklands, Sector 85, Faridabad • Admissions Open 2026-27',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.2,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Big Headline
                  const Text(
                    'Where Happy Childhoods Begin & Little Minds Blossom! 🍓',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 38,
                      fontWeight: FontWeight.w900,
                      height: 1.2,
                      letterSpacing: -0.6,
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Subtitle
                  Text(
                    'Faridabad’s leading early learning sanctuary. We offer playgroup, nursery, kindergarten, and full-day daycare with joyful Montessori methods, personal attention, and live parent updates.',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.94),
                      fontSize: 15.5,
                      height: 1.55,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 26),

                  // 4 Hero Trust Metric Pills
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.28)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildHeroMetricItem('5+ Yrs', 'Preschool Legacy'),
                        _dividerLine(),
                        _buildHeroMetricItem('1:1 Care', 'Individual Attention'),
                        _dividerLine(),
                        _buildHeroMetricItem('100% Safe', 'CCTV Monitored'),
                        _dividerLine(),
                        _buildHeroMetricItem('4.7 ★', 'Google Rating'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 26),

                  // CTAs
                  Wrap(
                    spacing: 14,
                    runSpacing: 12,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () => _showEnquirySheet(),
                        icon: const Icon(Icons.assignment_turned_in_rounded, size: 18),
                        label: const Text(
                          'Apply for Admission',
                          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppColors.primaryDark,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => _launchWhatsApp(),
                        icon: const Icon(Icons.chat_bubble_rounded, size: 18, color: Colors.white),
                        label: const Text(
                          'WhatsApp Campus Desk',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.white, width: 2),
                          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () => _scrollToKey(_tourKey),
                        icon: const Icon(Icons.photo_library_rounded, size: 20, color: Colors.white),
                        label: const Text(
                          'Explore Photo Gallery',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                            decoration: TextDecoration.underline,
                            decorationColor: Colors.white,
                          ),
                        ),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 36),

            // Right Hero Column: Campus Image Card with floating badges
            Expanded(
              flex: 5,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    height: (screenWidth != null && screenWidth >= 1400) ? 480 : 450,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(26),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.25),
                          blurRadius: 30,
                          offset: const Offset(0, 14),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(26),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.asset(
                            'assets/images/school.jpg',
                            fit: BoxFit.cover,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Floating Badge 1: Top Right (Google Rating)
                  Positioned(
                    top: -14,
                    right: 18,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.12),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.star_rounded, color: Color(0xFFF59E0B), size: 18),
                          SizedBox(width: 6),
                          Text(
                            '4.7 Rating • Sector 85',
                            style: TextStyle(
                              color: AppColors.textDark,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Floating Badge 2: Bottom Left (Safety)
                  Positioned(
                    bottom: -14,
                    left: 18,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.12),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.verified_user_rounded, color: Color(0xFF10B981), size: 18),
                          SizedBox(width: 6),
                          Text(
                            'Child-Safe & CCTV Campus',
                            style: TextStyle(
                              color: AppColors.textDark,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // Mobile / Compact Hero Banner
    return Container(
      key: _heroKey,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, Color(0xFFE11D48), Color(0xFFBE123C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.28),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: -24,
            right: -24,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
          ),
          Positioned(
            bottom: -30,
            left: 40,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.05),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Tag Row
                Row(
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.20),
                            blurRadius: 14,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(3),
                      child: ClipOval(
                        child: Image.asset(
                          'assets/images/logo.png',
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _aboutInfo.schoolName.isNotEmpty
                                ? _aboutInfo.schoolName
                                : 'Strawberry Preschool & Daycare',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.2,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.22),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
                                ),
                                child: const Text(
                                  '✨ Admissions Open 2026-27',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.18),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Text(
                                  'Sector 85 Faridabad',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                const Text(
                  'Nurturing Young Minds with Love, Discovery & Joyful Learning! 🍓',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    height: 1.4,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'A warm, child-centric second home offering activity-based preschool education and reliable daycare with real-time parent updates.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 12.5,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 18),

                // Key Stats & Trust Metrics Matrix
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildHeroMetricItem('5+ Yrs', 'Legacy'),
                      _dividerLine(),
                      _buildHeroMetricItem('1:1 Care', 'Attention'),
                      _dividerLine(),
                      _buildHeroMetricItem('100% Safe', 'CCTV'),
                      _dividerLine(),
                      _buildHeroMetricItem('4.7 ★', 'Google'),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _showEnquirySheet(),
                        icon: const Icon(Icons.assignment_turned_in_rounded, size: 15),
                        label: const Text(
                          'Apply Online',
                          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppColors.primaryDark,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _launchWhatsApp(),
                        icon: const Icon(Icons.chat_bubble_rounded, size: 15, color: Colors.white),
                        label: const Text(
                          'WhatsApp',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.white, width: 1.5),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Center(
                  child: TextButton.icon(
                    onPressed: () => _scrollToKey(_tourKey),
                    icon: const Icon(Icons.photo_library_rounded, color: Colors.white, size: 18),
                    label: const Text(
                      'View Campus Photo Gallery 📸',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        decoration: TextDecoration.underline,
                        decorationColor: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroMetricItem(String value, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.85),
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _dividerLine() {
    return Container(
      width: 1,
      height: 28,
      color: Colors.white.withValues(alpha: 0.3),
    );
  }

  // ── UX Pillar 2: Complete School Story & Philosophy (From About Page) ──
  Widget _buildAboutSchoolSection(bool isDesktop) {
    return Container(
      key: _aboutKey,
      padding: EdgeInsets.all(isDesktop ? 32 : 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header Tag
          Wrap(
            spacing: 8,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'WELCOME TO STRAWBERRY',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.8,
                    color: AppColors.primaryDark,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Sector 85, Faridabad',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textMuted,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Nurturing With Love, Care & Joyful Discovery',
            style: TextStyle(
              fontSize: isDesktop ? 26 : 20,
              fontWeight: FontWeight.w900,
              color: AppColors.textDark,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '“${_aboutInfo.schoolTagline.isNotEmpty ? _aboutInfo.schoolTagline : "Nurturing young minds with love, care & joyful discovery."}”',
            style: const TextStyle(
              fontSize: 13.5,
              fontStyle: FontStyle.italic,
              color: AppColors.primaryDark,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 24),

          if (isDesktop)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left Column: School Philosophy & 4 Highlights Grid
                Expanded(
                  flex: 6,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _aboutInfo.aboutSchool.isNotEmpty
                            ? _aboutInfo.aboutSchool
                            : 'Welcome to Strawberry Playschool & Daycare! We are dedicated to creating a vibrant, safe, and happy learning sanctuary where each child can explore their natural curiosity, build early cognitive and social skills, and blossom with confidence.',
                        textAlign: TextAlign.justify,
                        style: const TextStyle(
                          color: AppColors.textBody,
                          fontSize: 14.5,
                          height: 1.65,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // 4 Core Highlights
                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisSpacing: 14,
                        mainAxisSpacing: 14,
                        childAspectRatio: 2.8,
                        children: [
                          _buildHighlightTile(
                            Icons.security_rounded,
                            'Child-Safe Campus',
                            '24/7 Monitored & Secure',
                            AppColors.emerald,
                          ),
                          _buildHighlightTile(
                            Icons.palette_rounded,
                            'Activity-Based',
                            'Montessori Curriculum',
                            AppColors.violet,
                          ),
                          _buildHighlightTile(
                            Icons.favorite_rounded,
                            'Loving Mentors',
                            'Trained & Caring Educators',
                            AppColors.primary,
                          ),
                          _buildHighlightTile(
                            Icons.wb_sunny_rounded,
                            'Hygienic Daycare',
                            'Clean & Healthy Spaces',
                            AppColors.amberDark,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 32),

                // Right Column: Aarti Arora's Founder Journey Card
                Expanded(
                  flex: 5,
                  child: _buildFounderCard(true),
                ),
              ],
            )
          else ...[
            Text(
              _aboutInfo.aboutSchool.isNotEmpty
                  ? _aboutInfo.aboutSchool
                  : 'Welcome to Strawberry Playschool & Daycare! We are dedicated to creating a vibrant, safe, and happy learning sanctuary where each child can explore their natural curiosity, build early cognitive and social skills, and blossom with confidence.',
              textAlign: TextAlign.start,
              style: const TextStyle(
                color: AppColors.textBody,
                fontSize: 13.5,
                height: 1.6,
                fontWeight: FontWeight.w400,
              ),
            ),
            const SizedBox(height: 18),

            // 4 Core Highlights (Mobile)
            ListView(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildHighlightTile(
                  Icons.security_rounded,
                  'Child-Safe Campus',
                  '24/7 Monitored & Secure',
                  AppColors.emerald,
                ),
                const SizedBox(height: 10),
                _buildHighlightTile(
                  Icons.palette_rounded,
                  'Activity-Based',
                  'Montessori Curriculum',
                  AppColors.violet,
                ),
                const SizedBox(height: 10),
                _buildHighlightTile(
                  Icons.favorite_rounded,
                  'Loving Mentors',
                  'Trained & Caring Educators',
                  AppColors.primary,
                ),
                const SizedBox(height: 10),
                _buildHighlightTile(
                  Icons.wb_sunny_rounded,
                  'Hygienic Daycare',
                  'Clean & Healthy Spaces',
                  AppColors.amberDark,
                ),
              ],
            ),
            const SizedBox(height: 20),

            _buildFounderCard(false),
          ],
        ],
      ),
    );
  }

  Widget _buildHighlightTile(IconData icon, String title, String subtitle, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                    color: AppColors.textDark,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 11,
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
    );
  }

  Widget _buildFounderCard([bool isDesktop = false]) {
    return Container(
      padding: EdgeInsets.all(isDesktop ? 22 : 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFF9FA), Color(0xFFFFF2F5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primarySoft),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.05),
            blurRadius: 14,
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
                width: isDesktop ? 62 : 52,
                height: isDesktop ? 62 : 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.primary, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: Image.asset(
                    'assets/images/founder.jpg',
                    fit: BoxFit.cover,
                    alignment: Alignment.topCenter,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _aboutInfo.founderName.isNotEmpty ? _aboutInfo.founderName : 'Aarti Arora',
                      style: TextStyle(
                        fontSize: isDesktop ? 18 : 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textDark,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.primarySoft),
                      ),
                      child: Text(
                        _aboutInfo.founderTitle.isNotEmpty ? _aboutInfo.founderTitle : 'Founder & Director',
                        style: const TextStyle(
                          color: AppColors.primaryDark,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(isDesktop ? 16 : 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.12)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppColors.primarySoft,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(Icons.format_quote_rounded, color: AppColors.primary, size: 16),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Founder’s Vision & Message',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primaryDark,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  _aboutInfo.founderJourney.isNotEmpty
                      ? _aboutInfo.founderJourney
                      : 'Strawberry was born out of a heartfelt dream to provide children with a warm, joyful "second home" filled with love and encouragement.\n\nBeginning with a humble classroom and a handful of eager young learners, our mission has always been deeply personal: ensuring every child feels cherished, valued, and excited to learn.',
                  textAlign: TextAlign.start,
                  style: TextStyle(
                    color: AppColors.textDark.withValues(alpha: 0.88),
                    fontSize: isDesktop ? 13 : 12.5,
                    height: 1.6,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── UX Pillar 3: Academic Programs Grid (Responsive 3-Col Desktop) ─────
  Widget _buildProgramsSection(bool isDesktop, [double? screenWidth]) {
    final programs = [
      {
        'title': 'Playgroup',
        'age': 'Age 1.5 - 2.5 Yrs',
        'desc': 'Sensory play, tactile motor stimulation, rhymes, social comfort & joyful curiosity.',
        'icon': Icons.child_care_rounded,
        'bg': AppColors.primarySoft,
        'accent': AppColors.primary,
      },
      {
        'title': 'Nursery',
        'age': 'Age 2.5 - 3.5 Yrs',
        'desc': 'Vocabulary expansion, colors, creative arts, rhythm movements & basic phonics sounds.',
        'icon': Icons.palette_rounded,
        'bg': AppColors.violetSoft,
        'accent': AppColors.violetDark,
      },
      {
        'title': 'LKG (Junior KG)',
        'age': 'Age 3.5 - 4.5 Yrs',
        'desc': 'Phonics mastery, pre-math concepts, pencil grip, logic puzzles & environmental studies.',
        'icon': Icons.menu_book_rounded,
        'bg': AppColors.emeraldSoft,
        'accent': AppColors.emeraldDark,
      },
      {
        'title': 'UKG (Senior KG)',
        'age': 'Age 4.5 - 6.0 Yrs',
        'desc': 'Primary school readiness, sentence reading, mathematical fluency & independent thinking.',
        'icon': Icons.auto_stories_rounded,
        'bg': AppColors.amberSoft,
        'accent': AppColors.amberDark,
      },
      {
        'title': 'Daycare & Creche',
        'age': 'Ages 1.5 - 10 Yrs',
        'desc': 'Safe home sanctuary, warm meal assistance, supervised resting pods & homework guidance.',
        'icon': Icons.wb_sunny_rounded,
        'bg': AppColors.skySoft,
        'accent': AppColors.skyDark,
      },
      {
        'title': 'Tuition Classes',
        'age': 'Class 1st - 8th • All Subjects',
        'desc': 'Personalized academic coaching, daily homework guidance, concept clarity & focused exam preparation.',
        'icon': Icons.school_rounded,
        'bg': const Color(0xFFEDE9FE),
        'accent': const Color(0xFF6D28D9),
      },
    ];

    return Container(
      key: _programsKey,
      padding: EdgeInsets.all(isDesktop ? 32 : 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 14,
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.violetSoft,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        'OUR CURRICULUM',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.8,
                          color: AppColors.violetDark,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Programs Designed for Every Milestone',
                      style: TextStyle(
                        fontSize: isDesktop ? 24 : 18,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textDark,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Playgroup to UKG • Daycare & Creche • Class 1st to 8th Tuitions',
                      style: TextStyle(fontSize: 12.5, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: () => _showEnquirySheet(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Enquire All →', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800)),
              ),
            ],
          ),
          const SizedBox(height: 24),

          if (isDesktop)
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: (screenWidth != null && screenWidth >= 1500)
                    ? 1.85
                    : ((screenWidth != null && screenWidth >= 1200) ? 1.7 : 1.55),
              ),
              itemCount: programs.length,
              itemBuilder: (ctx, i) {
                final p = programs[i];
                return _buildProgramCardDesktop(p);
              },
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: programs.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (ctx, i) {
                final p = programs[i];
                return _buildProgramCardMobile(p);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildProgramCardDesktop(Map<String, dynamic> p) {
    final title = p['title'] as String;
    final age = p['age'] as String;
    final desc = p['desc'] as String;
    final icon = p['icon'] as IconData;
    final bg = p['bg'] as Color;
    final accent = p['accent'] as Color;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: accent, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: bg,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        age,
                        style: TextStyle(
                          color: accent,
                          fontWeight: FontWeight.w800,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Text(
              desc,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textMuted,
                height: 1.4,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => _showEnquirySheet(title),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: accent.withValues(alpha: 0.5)),
                foregroundColor: accent,
                padding: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Enquire for Admission', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgramCardMobile(Map<String, dynamic> p) {
    final title = p['title'] as String;
    final age = p['age'] as String;
    final desc = p['desc'] as String;
    final icon = p['icon'] as IconData;
    final bg = p['bg'] as Color;
    final accent = p['accent'] as Color;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: accent, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textDark,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: bg,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        age,
                        style: TextStyle(
                          color: accent,
                          fontWeight: FontWeight.w800,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  desc,
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: AppColors.textMuted,
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          ElevatedButton(
            onPressed: () => _showEnquirySheet(title),
            style: ElevatedButton.styleFrom(
              backgroundColor: accent,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Enquire', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }

  // ── UX Pillar 4: Campus Moments & Photo Gallery Showcase ───
  Widget _buildCampusVideoAndGallerySection(bool isDesktop) {
    return Container(
      key: _tourKey,
      padding: EdgeInsets.all(isDesktop ? 32 : 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.skySoft,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        'CAMPUS MEMORIES',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.8,
                          color: AppColors.skyDark,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Campus Moments & Photo Gallery',
                      style: TextStyle(
                        fontSize: isDesktop ? 24 : 18,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textDark,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Take a peek inside our vibrant classrooms, play areas, and festive celebrations',
                      style: TextStyle(fontSize: 12.5, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
              TextButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const GalleryPage()),
                ),
                icon: const Icon(Icons.photo_library_rounded, size: 16, color: AppColors.primary),
                label: const Text(
                  'Full Gallery →',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          _buildGalleryReel(isDesktop),
        ],
      ),
    );
  }

  Widget _buildGalleryReel(bool isDesktop) {
    return SizedBox(
      height: isDesktop ? 220 : 160,
      child: _loadingData
          ? const SectionShimmer(height: 160, message: 'Loading gallery memories... 📸')
          : _galleryPhotos.isEmpty
              ? Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Text(
                    'Gallery photos syncing...',
                    style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                  ),
                )
              : ListView.separated(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  itemCount: _galleryPhotos.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 14),
                  itemBuilder: (ctx, i) {
                    final photo = _galleryPhotos[i];
                    final url = photo['image_url'] as String? ?? '';
                    final title = photo['title'] as String? ?? 'Campus Activity';

                    return MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                        onTap: () => _openPhotoLightbox(url),
                        child: Container(
                          width: isDesktop ? 220 : 180,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.14),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                Image.network(
                                  url,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, _, _) => Container(
                                    color: AppColors.primarySoft,
                                    child: const Icon(Icons.photo_rounded, color: AppColors.primary),
                                  ),
                                ),
                                Positioned(
                                  bottom: 0,
                                  left: 0,
                                  right: 0,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
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
                                    child: Text(
                                      title,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w700,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
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
    );
  }

  // ── UX Pillar 5: Why Choose Strawberry Pillars ────────────────────────
  Widget _buildWhyChooseSection(bool isDesktop) {
    final features = [
      {
        'icon': Icons.sentiment_very_satisfied_rounded,
        'color': AppColors.primary,
        'title': 'Joyful Play Learning',
        'sub': 'Experiential activity curriculum built for natural foundational milestones.',
      },
      {
        'icon': Icons.health_and_safety_rounded,
        'color': AppColors.emerald,
        'title': 'Child Safety & CCTV',
        'sub': '100% sanitized, child-proof campus with continuous camera coverage.',
      },
      {
        'icon': Icons.app_shortcut_rounded,
        'color': AppColors.violet,
        'title': 'Parent ERP Portal',
        'sub': 'Real-time attendance logs, fee receipts, digital notices & activity photos.',
      },
      {
        'icon': Icons.groups_rounded,
        'color': AppColors.amberDark,
        'title': '1:1 Personal Care',
        'sub': 'Individual care, affectionate mentoring, and dedicated personal attention.',
      },
    ];

    return Container(
      key: _whyUsKey,
      padding: EdgeInsets.all(isDesktop ? 32 : 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.emeraldSoft,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text(
              'WHY STRAWBERRY',
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.8,
                color: AppColors.emeraldDark,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Why Parents in Faridabad Choose Us',
            style: TextStyle(
              fontSize: isDesktop ? 24 : 18,
              fontWeight: FontWeight.w900,
              color: AppColors.textDark,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Core pillars of early childhood excellence and unwavering parent trust',
            style: TextStyle(fontSize: 12.5, color: AppColors.textMuted),
          ),
          const SizedBox(height: 24),

          if (isDesktop)
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                mainAxisExtent: 152,
              ),
              itemCount: features.length,
              itemBuilder: (ctx, i) {
                final f = features[i];
                final color = f['color'] as Color;
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(f['icon'] as IconData, color: color, size: 22),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        f['title'] as String,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 13.5,
                          color: AppColors.textDark,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        f['sub'] as String,
                        style: const TextStyle(fontSize: 11, color: AppColors.textMuted, height: 1.3),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                );
              },
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: features.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (ctx, i) {
                final f = features[i];
                final color = f['color'] as Color;
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(f['icon'] as IconData, color: color, size: 20),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              f['title'] as String,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 13.5,
                                color: AppColors.textDark,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              f['sub'] as String,
                              style: const TextStyle(
                                fontSize: 11.5,
                                color: AppColors.textMuted,
                                height: 1.3,
                              ),
                            ),
                          ],
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

  // ── UX Pillar 6: Campus Location & Contact Hub (Faridabad Local SEO) ──
  Widget _buildLocationAndContactHub(bool isDesktop, [double? screenWidth]) {
    return Container(
      key: _locationKey,
      padding: EdgeInsets.all(isDesktop ? 32 : 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text(
              'CAMPUS LOCATION & VISITING HOURS',
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.8,
                color: AppColors.primaryDark,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Conveniently Located in Sector 85, Faridabad',
            style: TextStyle(
              fontSize: isDesktop ? 24 : 18,
              fontWeight: FontWeight.w900,
              color: AppColors.textDark,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'We welcome parents for guided campus visits, counseling, and admission walkthroughs',
            style: TextStyle(fontSize: 12.5, color: AppColors.textMuted),
          ),
          const SizedBox(height: 24),

          if (isDesktop)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left 5 Flex: Address & Contact Details
                Expanded(
                  flex: 5,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildContactDetailItem(
                        Icons.location_on_rounded,
                        'Campus Address',
                        'BPTP Parklands, C-22, Sector 85, Faridabad, Haryana 121007',
                        AppColors.primary,
                        () => _launchExternalUrl('https://maps.app.goo.gl/efvVwz7AMGXp1EC68'),
                      ),
                      const SizedBox(height: 12),
                      _buildContactDetailItem(
                        Icons.access_time_filled_rounded,
                        'Visiting Hours',
                        'Monday to Saturday: 8:30 AM – 4:00 PM',
                        AppColors.emerald,
                      ),
                      const SizedBox(height: 12),
                      _buildContactDetailItem(
                        Icons.phone_in_talk_rounded,
                        'Helpline & WhatsApp Desk',
                        '+91 99992 49495',
                        AppColors.violet,
                        _launchCall,
                      ),
                      const SizedBox(height: 12),
                      _buildContactDetailItem(
                        Icons.email_rounded,
                        'Official Email',
                        'daycarestrawberry@gmail.com',
                        AppColors.amberDark,
                      ),
                      const SizedBox(height: 20),

                      // Social and Map Action Buttons
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          ElevatedButton.icon(
                            onPressed: () => _launchExternalUrl('https://maps.app.goo.gl/efvVwz7AMGXp1EC68'),
                            icon: Container(
                              padding: const EdgeInsets.all(3),
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: SvgPicture.asset('assets/images/google_maps.svg', width: 15, height: 15),
                            ),
                            label: const Text('Open in Google Maps', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                          OutlinedButton.icon(
                            onPressed: () => _launchExternalUrl('https://www.instagram.com/strawberry.preschool/'),
                            icon: SvgPicture.asset('assets/images/instagram.svg', width: 18, height: 18),
                            label: const Text('Instagram', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: Color(0xFFE1306C))),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Color(0xFFE1306C), width: 1.2),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                          OutlinedButton.icon(
                            onPressed: () => _launchExternalUrl('https://www.facebook.com/daycare.strawberry'),
                            icon: SvgPicture.asset('assets/images/facebook.svg', width: 18, height: 18),
                            label: const Text('Facebook', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: Color(0xFF1877F2))),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Color(0xFF1877F2), width: 1.2),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 28),

                // Right 5 Flex: Visual Map Card
                Expanded(
                  flex: 5,
                  child: _buildInteractiveMapCard(isDesktop, screenWidth),
                ),
              ],
            )
          else ...[
            _buildContactDetailItem(
              Icons.location_on_rounded,
              'Campus Address',
              'BPTP Parklands, C-22, Sector 85, Faridabad, Haryana 121007',
              AppColors.primary,
              () => _launchExternalUrl('https://maps.app.goo.gl/efvVwz7AMGXp1EC68'),
            ),
            const SizedBox(height: 10),
            _buildContactDetailItem(
              Icons.access_time_filled_rounded,
              'Visiting Hours',
              'Monday to Saturday: 8:30 AM – 4:00 PM',
              AppColors.emerald,
            ),
            const SizedBox(height: 10),
            _buildContactDetailItem(
              Icons.phone_in_talk_rounded,
              'Helpline & WhatsApp Desk',
              '+91 99992 49495',
              AppColors.violet,
              _launchCall,
            ),
            const SizedBox(height: 14),

            // Mobile Social and Map Buttons
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _launchExternalUrl('https://maps.app.goo.gl/efvVwz7AMGXp1EC68'),
                  icon: Container(
                    padding: const EdgeInsets.all(2.5),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: SvgPicture.asset('assets/images/google_maps.svg', width: 14, height: 14),
                  ),
                  label: const Text('Google Maps', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: () => _launchExternalUrl('https://www.instagram.com/strawberry.preschool/'),
                  icon: SvgPicture.asset('assets/images/instagram.svg', width: 16, height: 16),
                  label: const Text('Instagram', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFFE1306C))),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFE1306C), width: 1.2),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: () => _launchExternalUrl('https://www.facebook.com/daycare.strawberry'),
                  icon: SvgPicture.asset('assets/images/facebook.svg', width: 16, height: 16),
                  label: const Text('Facebook', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF1877F2))),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF1877F2), width: 1.2),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInteractiveMapCard(false),
          ],
        ],
      ),
    );
  }

  Widget _buildContactDetailItem(
    IconData icon,
    String title,
    String subtitle,
    Color color, [
    VoidCallback? onTap,
  ]) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textDark,
                    ),
                  ),
                ],
              ),
            ),
            if (onTap != null)
              const Icon(Icons.arrow_forward_ios_rounded, size: 13, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }

  Widget _buildInteractiveMapCard(bool isDesktop, [double? screenWidth]) {
    return InkWell(
      onTap: () => _launchExternalUrl('https://maps.app.goo.gl/efvVwz7AMGXp1EC68'),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        height: isDesktop ? ((screenWidth != null && screenWidth >= 1400) ? 360 : 300) : 230,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFCBD5E1)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 16,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Real Google Map of Sector 85 Faridabad
              Image.asset(
                'assets/images/campus_map.jpg',
                fit: BoxFit.cover,
                alignment: Alignment.center,
              ),

              // Top Left Floating Card: Google Maps Marker Badge
              Positioned(
                top: 12,
                left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.95),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SvgPicture.asset(
                        'assets/images/google_maps.svg',
                        width: 20,
                        height: 20,
                      ),
                      const SizedBox(width: 8),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Strawberry Playschool',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                              color: AppColors.textDark,
                            ),
                          ),
                          Text(
                            'BPTP Parklands, Sector 85',
                            style: TextStyle(
                              fontSize: 10,
                              color: AppColors.textMuted,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Top Right: Live Open on Google Maps link
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.95),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.open_in_new_rounded, size: 13, color: AppColors.primary),
                      SizedBox(width: 4),
                      Text(
                        'View on Maps',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Bottom Gradient & Driving Directions Bar
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
                  child: ElevatedButton.icon(
                    onPressed: () => _launchExternalUrl('https://maps.app.goo.gl/efvVwz7AMGXp1EC68'),
                    icon: SvgPicture.asset('assets/images/google_maps.svg', width: 18, height: 18),
                    label: const Text(
                      'Get Driving Directions on Google Maps 🗺️',
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.textDark,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Bottom Banner Card to Switch to Parent Portal ──────────────────────
  Widget _buildPortalBannerCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (ctx, constraints) {
          final isWide = constraints.maxWidth >= 600;
          return isWide
              ? Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: const BoxDecoration(
                        color: AppColors.primarySoft,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.lock_person_rounded, color: AppColors.primary, size: 24),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Enrolled Student, Parent or Staff Member?',
                            style: TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textDark,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Access real-time attendance, fee receipts, circulars & daily photo updates',
                            style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 14),
                    ElevatedButton(
                      onPressed: () => _switchTab(1),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text(
                        'Sign In to Parent Portal →',
                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                      ),
                    ),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: AppColors.primarySoft,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.lock_person_rounded, color: AppColors.primary, size: 20),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Enrolled Student or Parent?',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textDark,
                                ),
                              ),
                              Text(
                                'Live attendance, fee receipts & notices',
                                style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () => _switchTab(1),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 11),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text(
                        'Sign In to Parent Portal →',
                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                      ),
                    ),
                  ],
                );
        },
      ),
    );
  }

  // ── Modern 2026 Website Footer ────────────────────────────────────────
  Widget _buildWebsiteFooter() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
      decoration: const BoxDecoration(
        color: Color(0xFF0F172A),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: const BoxDecoration(shape: BoxShape.circle),
                child: ClipOval(
                  child: Image.asset('assets/images/logo.png', fit: BoxFit.cover),
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'Strawberry Preschool & Daycare',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'BPTP Parklands, C-22, Sector 85, Faridabad, Haryana 121007',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 18),

          Wrap(
            alignment: WrapAlignment.center,
            spacing: 16,
            runSpacing: 8,
            children: [
              InkWell(
                onTap: () => _scrollToKey(_aboutKey),
                child: Text('About School', style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 12)),
              ),
              InkWell(
                onTap: () => _scrollToKey(_programsKey),
                child: Text('Academic Programs', style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 12)),
              ),
              InkWell(
                onTap: () => _scrollToKey(_tourKey),
                child: Text('Campus Gallery', style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 12)),
              ),
              InkWell(
                onTap: () => _scrollToKey(_locationKey),
                child: Text('Location & Map', style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 12)),
              ),
              InkWell(
                onTap: () => _switchTab(1),
                child: Text('Parent Portal', style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 12)),
              ),
              InkWell(
                onTap: () => _launchExternalUrl('https://strawberrydaycare.co.in/privacy'),
                child: const Text('Privacy Policy', style: TextStyle(color: Color(0xFF38BDF8), fontSize: 12, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const Divider(color: Color(0xFF334155), height: 1),
          const SizedBox(height: 16),

          Text(
            '© 2026 Strawberry Preschool & Daycare. All rights reserved. • Designed & Developed by Harshit',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 11,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ── Tab 0: Complete Discovery View (Adaptive Desktop/Tablet/Mobile) ────
  Widget _buildExploreTab(double screenWidth) {
    final isDesktop = screenWidth >= 960;
    final isTablet = screenWidth >= 640 && screenWidth < 960;
    final horizontalPad = isDesktop ? (screenWidth >= 1200 ? 36.0 : 20.0) : (isTablet ? 24.0 : 16.0);
    final topPad = isDesktop ? 20.0 : 14.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(horizontalPad, topPad, horizontalPad, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeroBanner(isDesktop, screenWidth),
              SizedBox(height: isDesktop ? 32 : 18),

              _buildAboutSchoolSection(isDesktop),
              SizedBox(height: isDesktop ? 32 : 18),

              _buildProgramsSection(isDesktop, screenWidth),
              SizedBox(height: isDesktop ? 32 : 18),

              _buildCampusVideoAndGallerySection(isDesktop),
              SizedBox(height: isDesktop ? 32 : 18),

              _buildWhyChooseSection(isDesktop),
              SizedBox(height: isDesktop ? 32 : 18),

              _buildLocationAndContactHub(isDesktop, screenWidth),
              SizedBox(height: isDesktop ? 32 : 18),

              _buildPortalBannerCard(),
              SizedBox(height: isDesktop ? 40 : 28),
            ],
          ),
        ),

        _buildWebsiteFooter(),
      ],
    );
  }

  // ── Tab 1: Parent & Staff Portal View (Adaptive Desktop/Mobile) ────────
  Widget _buildPortalTab(double screenWidth) {
    final isDesktop = screenWidth >= 860;

    if (isDesktop) {
      // 💻 Desktop Split Card Layout
      return Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 900),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: AppDecorations.radiusXl,
            boxShadow: AppDecorations.shadowLg,
            border: Border.all(color: AppColors.borderSubtle),
          ),
          child: ClipRRect(
            borderRadius: AppDecorations.radiusXl,
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Left Showcase Panel
                  Expanded(
                    flex: 5,
                    child: Container(
                      padding: const EdgeInsets.all(32),
                      decoration: const BoxDecoration(
                        gradient: AppColors.primaryGradient,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 74,
                            height: 74,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.18),
                                  blurRadius: 14,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.all(2.5),
                            child: ClipOval(
                              child: Image.asset(
                                'assets/images/logo.png',
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          const SizedBox(height: 18),
                          Text(
                            'Strawberry ERP',
                            style: AppTypography.display.copyWith(color: Colors.white, fontSize: 26),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Smart School Management & Real-Time Parent Connect Platform.',
                            style: AppTypography.bodyMedium.copyWith(
                              color: Colors.white.withValues(alpha: 0.92),
                              height: 1.4,
                              fontSize: 13.5,
                            ),
                          ),
                          const SizedBox(height: 22),

                          _desktopFeatureRow(Icons.calendar_month_rounded, 'Real-Time Attendance Tracking'),
                          const SizedBox(height: 10),
                          _desktopFeatureRow(Icons.account_balance_wallet_rounded, 'Instant UPI Fee Payments & Receipts'),
                          const SizedBox(height: 10),
                          _desktopFeatureRow(Icons.photo_library_rounded, 'Classroom Photo Memories & Highlights'),
                          const SizedBox(height: 10),
                          _desktopFeatureRow(Icons.campaign_rounded, 'Instant Notices & Holiday Alerts'),
                        ],
                      ),
                    ),
                  ),

                  // Right Login Form Panel
                  Expanded(
                    flex: 5,
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Sign In to Portal 🍓',
                            style: AppTypography.h1.copyWith(fontSize: 21),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Continue with your registered Google account provided during admission.',
                            style: AppTypography.caption.copyWith(color: AppColors.textMuted),
                          ),
                          const SizedBox(height: 26),

                          _GoogleSignInButton(
                            loading: _loading,
                            onTap: _signInWithGoogle,
                          ),

                          if (_error != null) ...[
                            const SizedBox(height: 14),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              decoration: BoxDecoration(
                                color: AppColors.dangerSoft,
                                borderRadius: AppDecorations.radiusSm,
                                border: Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.error_outline_rounded, color: AppColors.danger, size: 18),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      _error!,
                                      style: AppTypography.bodySmall.copyWith(
                                        color: AppColors.danger,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],

                          const SizedBox(height: 24),

                          Center(
                            child: TextButton.icon(
                              onPressed: () => _switchTab(0),
                              icon: const Icon(Icons.explore_rounded, size: 18, color: AppColors.primary),
                              label: Text(
                                'New Parent? Explore Programs & Campus Tour',
                                style: AppTypography.bodySmall.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                ),
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
    }

    // 📱 Mobile Portal Card
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 480),
        padding: const EdgeInsets.all(26),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: AppDecorations.radiusXl,
          boxShadow: AppDecorations.shadowLg,
          border: Border.all(
            color: AppColors.borderSubtle,
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.18),
                      blurRadius: 16,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(3),
                child: ClipOval(
                  child: Image.asset(
                    'assets/images/logo.png',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 18),

            Text(
              'Parent & Staff Portal 🍓',
              textAlign: TextAlign.center,
              style: AppTypography.h1.copyWith(
                fontSize: 21,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Sign in with your registered Google account to track attendance, pay monthly fees & view classroom moments.',
              textAlign: TextAlign.center,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textMuted,
                height: 1.45,
              ),
            ),

            const SizedBox(height: 20),

            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                _featureTag('📅 Live Attendance', AppColors.emeraldSoft, AppColors.emeraldDark),
                _featureTag('💳 UPI Fee Portal', AppColors.primarySoft, AppColors.primaryDark),
                _featureTag('🎨 Class Highlights', AppColors.amberSoft, AppColors.amberDark),
                _featureTag('📢 Instant Alerts', AppColors.skySoft, AppColors.skyDark),
              ],
            ),

            const SizedBox(height: 26),

            _GoogleSignInButton(
              loading: _loading,
              onTap: _signInWithGoogle,
            ),

            if (_error != null) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.dangerSoft,
                  borderRadius: AppDecorations.radiusSm,
                  border: Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline_rounded, color: AppColors.danger, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _error!,
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.danger,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 24),

            Center(
              child: TextButton.icon(
                onPressed: () => _switchTab(0),
                icon: const Icon(Icons.explore_rounded, size: 18, color: AppColors.primary),
                label: Text(
                  'New Parent? Explore Programs & Campus Tour',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            if (!kIsWeb) ...[
              const SizedBox(height: 10),
              Center(
                child: InkWell(
                  onTap: () async {
                    final uri = Uri.parse('https://strawberrydaycare.co.in');
                    try {
                      await launchUrl(uri, mode: LaunchMode.externalApplication);
                    } catch (_) {}
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.language_rounded, size: 14, color: AppColors.primary),
                        const SizedBox(width: 5),
                        Text(
                          'Visit Website: strawberrydaycare.co.in 🌐',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.primary,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 4),
            Center(
              child: InkWell(
                onTap: () async {
                  final uri = Uri.parse('https://strawberrydaycare.co.in/privacy');
                  try {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  } catch (_) {}
                },
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  child: Text(
                    'Privacy Policy & Child Safety Terms 🛡️',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textMuted,
                      fontSize: 11.5,
                      decoration: TextDecoration.underline,
                      decorationColor: AppColors.textMuted.withValues(alpha: 0.5),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _desktopFeatureRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: Colors.white, size: 17),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  Widget _featureTag(String label, Color bg, Color text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: text),
      ),
    );
  }

  Widget _blob(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width >= 960;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFFFFF), Color(0xFFFFF4F6)],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: -60,
              right: -60,
              child: _blob(220, AppColors.primaryLight.withValues(alpha: 0.15)),
            ),
            Positioned(
              bottom: -80,
              left: -60,
              child: _blob(250, AppColors.primary.withValues(alpha: 0.08)),
            ),
            Positioned(
              top: size.height * 0.4,
              right: -30,
              child: _blob(120, AppColors.violet.withValues(alpha: 0.05)),
            ),

            SafeArea(
              child: FadeTransition(
                opacity: _fadeAnim,
                child: SlideTransition(
                  position: _slideAnim,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Top Transparent Floating Navbar
                      _buildTabSwitcher(isDesktop),

                      // Smooth swipeable tab content
                      Expanded(
                        child: GestureDetector(
                          behavior: HitTestBehavior.translucent,
                          onHorizontalDragEnd: (details) {
                            final vx = details.primaryVelocity ?? 0;
                            if (vx < -200) {
                              // Swiped left -> Switch to Parent Portal
                              _switchTab(1);
                            } else if (vx > 200) {
                              // Swiped right -> Switch to Explore School
                              _switchTab(0);
                            }
                          },
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 240),
                            switchInCurve: Curves.easeOutCubic,
                            switchOutCurve: Curves.easeInCubic,
                            layoutBuilder: (currentChild, previousChildren) {
                              return Stack(
                                alignment: Alignment.topCenter,
                                children: <Widget>[
                                  ...previousChildren,
                                  ?currentChild,
                                ],
                              );
                            },
                            transitionBuilder: (child, animation) {
                              final isCurrent = child.key == ValueKey(_activeTab);
                              final forward = _activeTab >= _previousTab;
                              final offset = forward ? const Offset(0.06, 0) : const Offset(-0.06, 0);
                              final anim = isCurrent
                                  ? Tween<Offset>(begin: offset, end: Offset.zero).animate(animation)
                                  : Tween<Offset>(begin: Offset.zero, end: -offset).animate(animation);

                              return SlideTransition(
                                position: anim,
                                child: FadeTransition(
                                  opacity: animation,
                                  child: child,
                                ),
                              );
                            },
                            child: _activeTab == 0
                                ? SingleChildScrollView(
                                    key: const ValueKey(0),
                                    controller: _exploreScrollController,
                                    physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                                    padding: EdgeInsets.zero,
                                    child: _buildExploreTab(size.width),
                                  )
                                : LayoutBuilder(
                                    key: const ValueKey(1),
                                    builder: (context, constraints) {
                                      return SingleChildScrollView(
                                        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                                        child: ConstrainedBox(
                                          constraints: BoxConstraints(
                                            minHeight: constraints.maxHeight,
                                          ),
                                          child: Center(
                                            child: Container(
                                              constraints: BoxConstraints(maxWidth: isDesktop ? 1100 : 540),
                                              padding: EdgeInsets.symmetric(
                                                horizontal: isDesktop ? 32.0 : 18.0,
                                                vertical: 14.0,
                                              ),
                                              child: _buildPortalTab(size.width),
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GoogleSignInButton extends StatelessWidget {
  final bool loading;
  final VoidCallback onTap;

  const _GoogleSignInButton({
    required this.loading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: AppDecorations.radiusMd,
        boxShadow: AppDecorations.shadowSm,
      ),
      child: Material(
        color: Colors.white,
        borderRadius: AppDecorations.radiusMd,
        child: InkWell(
          onTap: loading ? null : onTap,
          borderRadius: AppDecorations.radiusMd,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.border, width: 1.2),
              borderRadius: AppDecorations.radiusMd,
            ),
            child: loading
                ? const Center(child: BtnLoader(color: Color(0xFFE91E63), dotSize: 6))
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SvgPicture.asset(
                        'assets/images/google_logo.svg',
                        width: 22,
                        height: 22,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Continue with Google',
                        style: AppTypography.button.copyWith(
                          color: AppColors.textDark,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
