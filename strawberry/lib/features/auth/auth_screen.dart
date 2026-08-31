import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:strawberry/core/theme/app_colors.dart';
import 'package:strawberry/core/theme/app_typography.dart';
import 'package:strawberry/core/theme/app_decorations.dart';
import 'package:strawberry/core/widgets/app_button.dart';
import 'package:strawberry/core/widgets/app_badge.dart';
import 'package:strawberry/features/auth/auth_service.dart';
import 'package:strawberry/features/about/about_page.dart';
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
  bool _loading = false;
  String? _error;

  List<String> _categories = [];
  List<Map<String, dynamic>> _galleryPhotos = [];
  AboutInfo _aboutInfo = AboutInfo.defaults();
  bool _loadingData = true;

  late final AnimationController _animController;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
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
  }

  void _switchTab(int index) {
    if (_activeTab == index) return;
    setState(() => _activeTab = index);
    if (_pageController.hasClients) {
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeInOutCubic,
      );
    }
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
    _pageController.dispose();
    _animController.dispose();
    super.dispose();
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
    String selectedProgram = preselectedProgram ??
        (_categories.isNotEmpty ? _categories.first : 'Playgroup');
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

                    if (_categories.isNotEmpty) ...[
                      DropdownButtonFormField<String>(
                        value: _categories.contains(selectedProgram) ? selectedProgram : _categories.first,
                        decoration: const InputDecoration(
                          labelText: 'Interested Program',
                          prefixIcon: Icon(Icons.category_rounded, color: AppColors.primary),
                        ),
                        items: _categories
                            .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                            .toList(),
                        onChanged: (v) {
                          if (v != null) setSheetState(() => selectedProgram = v);
                        },
                      ),
                      const SizedBox(height: 22),
                    ],

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

  Future<void> _signInWithGoogle() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final userCredential = await _authService.signInWithGoogle();

      if (userCredential == null) {
        if (mounted) setState(() => _loading = false);
        return;
      }

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
          _error = 'Couldn\'t sign in this time. Let\'s give it another spin! 🔄';
          _loading = false;
        });
      }
    }
  }

  // ── Top Segmented Pill Switcher & Transparent Header ───────────────────
  Widget _buildTabSwitcher(bool isDesktop) {
    return Container(
      color: Colors.transparent,
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 36.0 : 16.0,
        vertical: 8.0,
      ),
      child: isDesktop
          ? Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Left Brand Pill
                InkWell(
                  onTap: () => _switchTab(0),
                  borderRadius: BorderRadius.circular(30),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.88),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.asset(
                              'assets/images/logo_square.png',
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Strawberry',
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textDark,
                          ),
                        ),
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
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Right Switcher Pill
                Container(
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
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildSwitcherPill(
                        index: 0,
                        icon: Icons.auto_awesome_rounded,
                        label: 'Explore School',
                      ),
                      _buildSwitcherPill(
                        index: 1,
                        icon: Icons.login_rounded,
                        label: 'Parent Portal',
                      ),
                    ],
                  ),
                ),
              ],
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
  Widget _buildHeroBanner() {
    return Container(
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
            padding: const EdgeInsets.all(26),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Tag Row
                Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.18),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          'assets/images/logo.png',
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
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
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.2,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.22),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
                                ),
                                child: const Text(
                                  '✨ Admissions Open 2026-27',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.18),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Text(
                                  'Ages 1.5 - 6 Years',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
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
                const SizedBox(height: 20),
                const Text(
                  'Nurturing Young Minds with Love, Discovery & Joyful Learning! 🍓',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    height: 1.4,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'A warm, child-centric second home offering activity-based preschool education and reliable daycare with real-time parent updates.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 13,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 22),

                // Key Stats & Trust Metrics Matrix
                LayoutBuilder(
                  builder: (ctx, constraints) {
                    final isDesktop = constraints.maxWidth >= 600;
                    return Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
                      ),
                      child: isDesktop
                          ? Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _buildHeroMetricItem('5+ Yrs', 'Preschool Legacy'),
                                _dividerLine(),
                                _buildHeroMetricItem('1:1 Attention', 'Personal Care'),
                                _dividerLine(),
                                _buildHeroMetricItem('100% Safe', 'CCTV Campus'),
                                _dividerLine(),
                                _buildHeroMetricItem('Live ERP', 'Parent App'),
                              ],
                            )
                          : GridView.count(
                              crossAxisCount: 2,
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              mainAxisSpacing: 10,
                              crossAxisSpacing: 10,
                              childAspectRatio: 2.8,
                              children: [
                                _buildHeroMetricItem('5+ Yrs', 'Preschool Legacy'),
                                _buildHeroMetricItem('1:1 Attention', 'Personal Care'),
                                _buildHeroMetricItem('100% Safe', 'CCTV Campus'),
                                _buildHeroMetricItem('Live ERP', 'Parent App'),
                              ],
                            ),
                    );
                  },
                ),
                const SizedBox(height: 20),

                // Call to actions
                Wrap(
                  spacing: 12,
                  runSpacing: 10,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => _showEnquirySheet(),
                      icon: const Icon(Icons.assignment_turned_in_rounded, size: 18),
                      label: const Text(
                        'Apply for Admission',
                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppColors.primaryDark,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => _launchWhatsApp(),
                      icon: const Icon(Icons.chat_bubble_rounded, size: 18, color: Colors.white),
                      label: const Text(
                        'WhatsApp Enquiry',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.white, width: 1.5),
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ],
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

  // ── UX Pillar 2: Dynamic Programs Offered (From Categories) ───────────
  Widget _buildProgramsSection(int columns) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE2E8F0)),
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primarySoft,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.school_rounded, color: AppColors.primary, size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Academic Programs',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textDark,
                        ),
                      ),
                      Text(
                        'Curriculum tailored for Ages 1.5 to 6 Years',
                        style: TextStyle(fontSize: 11.5, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ],
              ),
              TextButton(
                onPressed: () => _showEnquirySheet(),
                child: const Text(
                  'Enquire All →',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          if (_loadingData)
            const Padding(
              padding: EdgeInsets.all(24),
              child: StrawberryLoader(message: 'Scooping up categories... 🍓'),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _categories.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (ctx, i) {
                final cat = _categories[i];
                return _buildProgramCard(cat, i);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildProgramCard(String programName, int index) {
    final palettes = [
      {
        'bg': AppColors.primarySoft,
        'accent': AppColors.primary,
        'icon': Icons.child_care_rounded,
        'age': 'Age 1.5 - 2.5 Yrs',
        'desc': 'Sensory exploration, motor coordination & joyful social habits.',
      },
      {
        'bg': AppColors.violetSoft,
        'accent': AppColors.violetDark,
        'icon': Icons.palette_rounded,
        'age': 'Age 2.5 - 3.5 Yrs',
        'desc': 'Creative expression, vocabulary building, rhymes & rhythm play.',
      },
      {
        'bg': AppColors.emeraldSoft,
        'accent': AppColors.emeraldDark,
        'icon': Icons.menu_book_rounded,
        'age': 'Age 3.5 - 4.5 Yrs',
        'desc': 'Phonics fundamentals, number concepts & hands-on discovery.',
      },
      {
        'bg': AppColors.amberSoft,
        'accent': AppColors.amberDark,
        'icon': Icons.auto_stories_rounded,
        'age': 'Age 4.5 - 6.0 Yrs',
        'desc': 'Primary school readiness, reading fluency & logical thinking.',
      },
      {
        'bg': AppColors.skySoft,
        'accent': AppColors.skyDark,
        'icon': Icons.wb_sunny_rounded,
        'age': 'Daycare & Creche',
        'desc': 'Hygienic warm environment, meal assistance & supervised naps.',
      },
    ];

    final meta = palettes[index % palettes.length];
    final accent = meta['accent'] as Color;
    final bg = meta['bg'] as Color;

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
            child: Icon(meta['icon'] as IconData, color: accent, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      programName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textDark,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: bg,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        meta['age'] as String,
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
                  meta['desc'] as String,
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
            onPressed: () => _showEnquirySheet(programName),
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

  // ── UX Pillar 3: Why Choose Strawberry Pillars ────────────────────────
  Widget _buildWhyChooseSection(int columns) {
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
        'title': '1:1 Personal Attention',
        'sub': 'Individual care, affectionate mentoring, and dedicated personal attention.',
      },
    ];

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE2E8F0)),
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
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.violetSoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.stars_rounded, color: AppColors.violetDark, size: 20),
              ),
              const SizedBox(width: 12),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Why Parents Choose Strawberry',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textDark,
                    ),
                  ),
                  Text(
                    'Core pillars of early childhood excellence',
                    style: TextStyle(fontSize: 11.5, color: AppColors.textMuted),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              mainAxisExtent: 120,
            ),
            itemCount: features.length,
            itemBuilder: (ctx, i) {
              final f = features[i];
              final color = f['color'] as Color;
              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(f['icon'] as IconData, color: color, size: 18),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      f['title'] as String,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 12.5,
                        color: AppColors.textDark,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      f['sub'] as String,
                      style: const TextStyle(fontSize: 10.5, color: AppColors.textMuted, height: 1.25),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
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

  // ── UX Pillar 4: Founder's Story Spotlight Card ───────────────────────
  Widget _buildFounderSpotlight() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE2E8F0)),
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
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.primary, width: 2),
                ),
                child: const Center(
                  child: Icon(Icons.person_rounded, color: AppColors.primary, size: 26),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Founder\'s Message',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _aboutInfo.founderName.isNotEmpty ? _aboutInfo.founderName : 'Aarti Arora • Founder & Director',
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: AppColors.primaryDark,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Text(
              _aboutInfo.aboutSchool.isNotEmpty
                  ? _aboutInfo.aboutSchool
                  : '"Every child deserves a warm second home filled with encouragement, discovery, and joyful memories."',
              style: const TextStyle(
                color: AppColors.textDark,
                fontStyle: FontStyle.italic,
                fontSize: 12.5,
                height: 1.45,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const AboutPage()),
            ),
            borderRadius: BorderRadius.circular(8),
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Read Full Campus Story & Values',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                  SizedBox(width: 6),
                  Icon(Icons.arrow_forward_rounded, size: 14, color: AppColors.primary),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── UX Pillar: Campus Life Gallery Reel ──────────────────────────────
  Widget _buildGallerySection() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE2E8F0)),
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
                    child: const Icon(Icons.photo_library_rounded, color: AppColors.sky, size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Campus Moments & Activities',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textDark,
                        ),
                      ),
                      Text(
                        'Celebrations, workshops & daily highlights',
                        style: TextStyle(fontSize: 11.5, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ],
              ),
              TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const GalleryPage()),
                ),
                child: const Text(
                  'Full Gallery →',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          SizedBox(
            height: 160,
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

                          return GestureDetector(
                            onTap: () => _openPhotoLightbox(url),
                            child: Container(
                              width: 180,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.18),
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
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  // ── UX Pillar: High-Converting Admission Connect Hub ─────────────────
  Widget _buildAdmissionHub() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.emeraldSoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.support_agent_rounded, color: AppColors.emerald, size: 20),
              ),
              const SizedBox(width: 12),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Campus Admission Helpline',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textDark,
                    ),
                  ),
                  Text(
                    'Mon - Sat: 8:30 AM - 4:00 PM',
                    style: TextStyle(fontSize: 11.5, color: AppColors.textMuted),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Text(
            'Connect with our counseling team for fee breakdown, daycare availability, or campus tour appointment:',
            style: TextStyle(
              fontSize: 12.5,
              color: AppColors.textDark,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _launchWhatsApp(),
                  icon: const Icon(Icons.chat_rounded, size: 16),
                  label: const Text('WhatsApp Us', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF25D366),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _launchCall,
                  icon: const Icon(Icons.phone_in_talk_rounded, size: 16),
                  label: const Text('Call Campus', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          OutlinedButton.icon(
            onPressed: () => _showEnquirySheet(),
            icon: const Icon(Icons.assignment_rounded, size: 16, color: AppColors.primary),
            label: const Text(
              'Submit Online Admission Application Form',
              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: AppColors.textDark),
            ),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFFE2E8F0)),
              padding: const EdgeInsets.symmetric(vertical: 13),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ],
      ),
    );
  }

  // ── Tab 0: Complete Discovery View (Adaptive Desktop/Tablet/Mobile) ────
  Widget _buildExploreTab(double screenWidth) {
    final isDesktop = screenWidth >= 960;
    final isTablet = screenWidth >= 640 && screenWidth < 960;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildHeroBanner(),
        const SizedBox(height: 20),

        if (isDesktop)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left Column: Programs & Founder's Story
              Expanded(
                flex: 5,
                child: Column(
                  children: [
                    _buildProgramsSection(1),
                    const SizedBox(height: 20),
                    _buildFounderSpotlight(),
                  ],
                ),
              ),
              const SizedBox(width: 24),
              // Right Column: Gallery, Why Choose & Admissions
              Expanded(
                flex: 5,
                child: Column(
                  children: [
                    _buildGallerySection(),
                    const SizedBox(height: 20),
                    _buildWhyChooseSection(2),
                    const SizedBox(height: 20),
                    _buildAdmissionHub(),
                  ],
                ),
              ),
            ],
          )
        else ...[
          _buildProgramsSection(1),
          const SizedBox(height: 18),
          _buildGallerySection(),
          const SizedBox(height: 18),
          _buildWhyChooseSection(isTablet ? 4 : 2),
          const SizedBox(height: 18),
          _buildFounderSpotlight(),
          const SizedBox(height: 18),
          _buildAdmissionHub(),
        ],
        const SizedBox(height: 24),

        // Bottom CTA to switch to Portal
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.lock_person_rounded, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Enrolled Student, Parent or Staff?',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textDark,
                      ),
                    ),
                    Text(
                      'Access live attendance, fee receipts & notices',
                      style: TextStyle(fontSize: 11.5, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: () => _switchTab(1),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text(
                  'Sign In to Portal →',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 30),
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
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.18),
                                  blurRadius: 10,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Image.asset(
                                'assets/images/logo_square.png',
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
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.asset(
                    'assets/images/logo_square.png',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

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
    final isTablet = size.width >= 640 && size.width < 960;

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

                      // Full-width edge-to-edge scrollable PageView
                      Expanded(
                        child: PageView(
                          controller: _pageController,
                          onPageChanged: (index) {
                            setState(() => _activeTab = index);
                          },
                          physics: const BouncingScrollPhysics(),
                          children: [
                            // Tab 0: Explore School
                            SingleChildScrollView(
                              physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                              padding: EdgeInsets.symmetric(
                                horizontal: isDesktop ? 36.0 : (isTablet ? 24.0 : 16.0),
                                vertical: 16.0,
                              ),
                              child: _buildExploreTab(size.width),
                            ),

                            // Tab 1: Parent Portal
                            LayoutBuilder(
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
                          ],
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
