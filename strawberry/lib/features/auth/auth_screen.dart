import 'package:flutter/material.dart';
import 'package:strawberry/core/theme/app_colors.dart';
import 'package:strawberry/core/theme/app_typography.dart';
import 'package:strawberry/core/theme/app_decorations.dart';
import 'package:strawberry/core/utils/responsive.dart';
import 'package:strawberry/core/widgets/playschool_animations.dart';
import 'package:strawberry/features/auth/auth_service.dart';
import 'package:strawberry/features/dashboard/student/wait_screen.dart';
import 'package:strawberry/features/dashboard/student/home_screen.dart';
import 'package:strawberry/features/dashboard/admin/admin_dashboard.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen>
    with SingleTickerProviderStateMixin {
  final _authService = AuthService();
  bool _loading = false;
  String? _error;

  late final AnimationController _animController;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
    );
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _animController,
            curve: const Interval(0.15, 1.0, curve: Curves.easeOutCubic),
          ),
        );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _signInWithGoogle() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final userCredential = await _authService.signInWithGoogle();

      if (userCredential == null) {
        // User cancelled
        if (mounted) setState(() => _loading = false);
        return;
      }

      // Check if profile exists in Supabase
      final profile = await _authService.getCurrentProfile();

      if (!mounted) return;

      if (profile == null) {
        // New user — create profile using Google name automatically
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
        // Existing user — route based on role and status
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
            _error = 'Invalid profile status. Please contact support.';
            _loading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Sign-in failed. Please try again. $e';
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

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
            // Decorative background accents
            Positioned(
              top: -60,
              right: -60,
              child: _blob(200, AppColors.primaryLight.withValues(alpha: 0.15)),
            ),
            Positioned(
              bottom: -80,
              left: -60,
              child: _blob(240, AppColors.primary.withValues(alpha: 0.08)),
            ),
            Positioned(
              top: size.height * 0.35,
              right: -30,
              child: _blob(100, AppColors.violet.withValues(alpha: 0.06)),
            ),

            // Main content
            SafeArea(
              child: Center(
                child: ResponsiveContentWrapper(
                  maxWidth: 460,
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: FadeTransition(
                      opacity: _fadeAnim,
                      child: SlideTransition(
                        position: _slideAnim,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Logo Hero
                            Center(
                              child: Stack(
                                alignment: Alignment.center,
                                clipBehavior: Clip.none,
                                children: [
                                  FloatingWobble(
                                    verticalOffset: 6,
                                    rotationAngle: 0.04,
                                    child: Container(
                                      width: 104,
                                      height: 104,
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.white,
                                        boxShadow: [
                                          BoxShadow(
                                            color: AppColors.primary.withValues(alpha: 0.18),
                                            blurRadius: 28,
                                            offset: const Offset(0, 10),
                                          ),
                                        ],
                                        border: Border.all(
                                          color: AppColors.primarySoft,
                                          width: 2,
                                        ),
                                      ),
                                      child: Image.asset(
                                        'assets/images/logo.png',
                                        fit: BoxFit.contain,
                                      ),
                                    ),
                                  ),
                                  const Positioned(
                                    top: -4,
                                    right: -8,
                                    child: PlayfulSparkle(size: 20, color: Colors.amber),
                                  ),
                                  const Positioned(
                                    bottom: 0,
                                    left: -8,
                                    child: PlayfulSparkle(size: 14, color: AppColors.sky),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 24),

                            // App name
                            Text(
                              'Strawberry',
                              textAlign: TextAlign.center,
                              style: AppTypography.display.copyWith(
                                color: AppColors.primaryDark,
                                fontSize: 32,
                              ),
                            ),
                            const SizedBox(height: 4),

                            Text(
                              'Preschool & Daycare ERP',
                              textAlign: TextAlign.center,
                              style: AppTypography.bodySmall.copyWith(
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                              ),
                            ),

                            const SizedBox(height: 36),

                            // Welcome Card
                            Container(
                              padding: const EdgeInsets.all(28),
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
                                  Text(
                                    'Welcome Parents & Teachers! 🍓',
                                    textAlign: TextAlign.center,
                                    style: AppTypography.h1.copyWith(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Sign in to access attendance, fee payments, notice board & campus memories',
                                    textAlign: TextAlign.center,
                                    style: AppTypography.bodySmall.copyWith(
                                      color: AppColors.textMuted,
                                      height: 1.4,
                                    ),
                                  ),

                                  const SizedBox(height: 20),

                                  // Cute Preschool Feature Tags
                                  Wrap(
                                    alignment: WrapAlignment.center,
                                    spacing: 6,
                                    runSpacing: 6,
                                    children: [
                                      _featureTag('📅 Attendance', AppColors.emeraldSoft, AppColors.emeraldDark),
                                      _featureTag('💳 UPI Fees', AppColors.primarySoft, AppColors.primaryDark),
                                      _featureTag('🎨 Memories', AppColors.amberSoft, AppColors.amberDark),
                                      _featureTag('📢 Alerts', AppColors.skySoft, AppColors.skyDark),
                                    ],
                                  ),

                                  const SizedBox(height: 24),

                                  // Google Sign-In Button
                                  _GoogleSignInButton(
                                    loading: _loading,
                                    onTap: _signInWithGoogle,
                                  ),

                                  // Error message
                                  if (_error != null) ...[
                                    const SizedBox(height: 16),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 14,
                                        vertical: 10,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.dangerSoft,
                                        borderRadius: AppDecorations.radiusSm,
                                        border: Border.all(
                                          color: AppColors.danger.withValues(alpha: 0.3),
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(
                                            Icons.error_outline_rounded,
                                            color: AppColors.danger,
                                            size: 18,
                                          ),
                                          const SizedBox(width: 8),
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
                                ],
                              ),
                            ),

                            const SizedBox(height: 24),

                            // Privacy note
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.shield_outlined, size: 14, color: AppColors.textFaint),
                                const SizedBox(width: 6),
                                Text(
                                  'Secure preschool portal protected with encryption',
                                  textAlign: TextAlign.center,
                                  style: AppTypography.caption,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
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

  static Widget _featureTag(String text, Color bg, Color textCol) {
    return BouncyTap(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: textCol,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
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
}

class _GoogleSignInButton extends StatefulWidget {
  final bool loading;
  final VoidCallback onTap;

  const _GoogleSignInButton({required this.loading, required this.onTap});

  @override
  State<_GoogleSignInButton> createState() => _GoogleSignInButtonState();
}

class _GoogleSignInButtonState extends State<_GoogleSignInButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        if (!widget.loading) widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 15),
          decoration: BoxDecoration(
            color: _pressed ? const Color(0xFFF5F5F5) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE0E0E0), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: _pressed ? 0.03 : 0.08),
                blurRadius: _pressed ? 4 : 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: widget.loading
              ? const SizedBox(
                  height: 22,
                  width: 22,
                  child: Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Color(0xFFE94464),
                      ),
                    ),
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Google "G" logo using SVG-like approach with text
                    _GoogleLogo(),
                    const SizedBox(width: 12),
                    const Text(
                      'Continue with Google',
                      style: TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF3C4043),
                        letterSpacing: 0.1,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _GoogleLogo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 22,
      height: 22,
      child: CustomPaint(painter: _GoogleLogoPainter()),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double cx = size.width / 2;
    final double cy = size.height / 2;
    final double r = size.width / 2;

    // Draw the 4 colored quadrants of the Google "G"
    final segments = [
      // Blue segment (top-right)
      {'color': const Color(0xFF4285F4), 'start': -90.0, 'sweep': 90.0},
      // Red segment (top-left)
      {'color': const Color(0xFFEA4335), 'start': 180.0, 'sweep': 90.0},
      // Yellow segment (bottom-left)
      {'color': const Color(0xFFFBBC04), 'start': 90.0, 'sweep': 90.0},
      // Green segment (bottom-right)
      {'color': const Color(0xFF34A853), 'start': 0.0, 'sweep': 90.0},
    ];

    for (final seg in segments) {
      final paint = Paint()
        ..color = seg['color'] as Color
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * 0.38
        ..strokeCap = StrokeCap.butt;

      canvas.drawArc(
        Rect.fromCircle(center: Offset(cx, cy), radius: r * 0.7),
        _toRad(seg['start'] as double),
        _toRad(seg['sweep'] as double),
        false,
        paint,
      );
    }

    // White cutout center
    final cutout = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(cx, cy), r * 0.46, cutout);

    // Blue horizontal bar (right side of G)
    final barPaint = Paint()
      ..color = const Color(0xFF4285F4)
      ..style = PaintingStyle.fill;

    final barRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(cx, cy - r * 0.13, r * 0.82, r * 0.26),
      Radius.circular(r * 0.13),
    );
    canvas.drawRRect(barRect, barPaint);
  }

  double _toRad(double deg) => deg * 3.14159265 / 180;

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
