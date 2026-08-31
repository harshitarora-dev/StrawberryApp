import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:strawberry/features/auth/auth_screen.dart';
import 'package:strawberry/features/auth/auth_service.dart';
import 'package:strawberry/features/dashboard/student/home_screen.dart';
import 'package:strawberry/features/dashboard/student/wait_screen.dart';
import 'package:strawberry/features/dashboard/admin/admin_dashboard.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _entranceController;
  late final Animation<double> _logoScale;
  late final Animation<double> _logoOpacity;
  late final Animation<Offset> _textSlide;
  late final Animation<double> _textOpacity;

  late final AnimationController _pulseController;

  // Strawberry brand palette
  static const Color _primary = Color(0xFFE94464); // strawberry red-pink
  static const Color _primaryDark = Color(0xFFD32F52);
  static const Color _accent = Color(0xFFFFB4A2); // soft peach
  static const Color _leafGreen = Color(0xFF5FAD6B);
  static const Color _bgTop = Color(0xFFFFFFFF);
  static const Color _bgBottom = Color(0xFFFFF5F6);
  static const Color _textMuted = Color(0xFF9B9B9B);

  @override
  void initState() {
    super.initState();

    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _logoScale = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.0, 0.65, curve: Curves.elasticOut),
      ),
    );

    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
      ),
    );

    _textSlide = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _entranceController,
            curve: const Interval(0.35, 0.85, curve: Curves.easeOutCubic),
          ),
        );

    _textOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.35, 0.85, curve: Curves.easeOut),
      ),
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _entranceController.forward();
    _navigateAfterDelay();
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _navigateAfterDelay() async {
    await Future<void>.delayed(const Duration(seconds: 1));

    if (!mounted) return;

    try {
      final authService = AuthService();
      final loggedIn = authService.isLoggedIn();

      if (!mounted) return;

      if (!loggedIn) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const AuthScreen()),
        );
        return;
      }

      Map<String, dynamic>? profile = await authService.getCurrentProfile();

      if (!mounted) return;

      if (profile == null) {
        profile = await authService.createProfile();
        if (!mounted) return;
      }

      final role = profile['role'];
      final status = profile['status'];

      if (status == 'pending') {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const WaitScreen()),
        );
      } else if (status == 'rejected') {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const WaitScreen(isRejected: true)),
        );
      } else if (status == 'approved') {
        if (role == 'admin') {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const AdminDashboard()),
          );
        } else {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const HomeScreen()),
          );
        }
      } else {
        await authService.logout();
        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const AuthScreen()),
        );
      }
    } catch (_) {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const AuthScreen()),
      );
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
            colors: [_bgTop, _bgBottom],
          ),
        ),
        child: Stack(
          children: [
            // Soft decorative blobs for premium feel
            Positioned(
              top: -60,
              right: -60,
              child: _blob(180, _accent.withValues(alpha: 0.18)),
            ),
            Positioned(
              bottom: -80,
              left: -60,
              child: _blob(220, _primary.withValues(alpha: 0.08)),
            ),
            Positioned(
              top: size.height * 0.15,
              left: -40,
              child: _blob(90, _leafGreen.withValues(alpha: 0.10)),
            ),

            // Main content
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Animated logo
                  AnimatedBuilder(
                    animation: _entranceController,
                    builder: (context, child) {
                      return Opacity(
                        opacity: _logoOpacity.value,
                        child: Transform.scale(
                          scale: _logoScale.value,
                          child: child,
                        ),
                      );
                    },
                    child: const _StrawberryLogo(
                      primary: _primary,
                      primaryDark: _primaryDark,
                      leafGreen: _leafGreen,
                    ),
                  ),

                  const SizedBox(height: 28),

                  // App name + tagline
                  SlideTransition(
                    position: _textSlide,
                    child: FadeTransition(
                      opacity: _textOpacity,
                      child: Column(
                        children: [
                          ShaderMask(
                            shaderCallback: (bounds) => const LinearGradient(
                              colors: [_primary, _primaryDark],
                            ).createShader(bounds),
                            child: const Text(
                              'Strawberry',
                              style: TextStyle(
                                fontSize: 34,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                                color: Colors.white,
                                height: 1.1,
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Little steps, big adventures',
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w500,
                              color: _textMuted,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 56),

                  // Custom pulsing loader
                  FadeTransition(
                    opacity: _textOpacity,
                    child: AnimatedBuilder(
                      animation: _pulseController,
                      builder: (context, _) {
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(3, (i) {
                            final t = (_pulseController.value - i * 0.2).clamp(
                              0.0,
                              1.0,
                            );
                            final scale =
                                0.6 + 0.4 * math.sin(t * math.pi).abs();
                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 5,
                              ),
                              child: Transform.scale(
                                scale: scale,
                                child: Container(
                                  width: 9,
                                  height: 9,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Color.lerp(_accent, _primary, scale),
                                  ),
                                ),
                              ),
                            );
                          }),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

            // Bottom branding
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: FadeTransition(
                opacity: _textOpacity,
                child: Text(
                  'Preschool & Daycare',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.8,
                    color: _textMuted.withValues(alpha: 0.7),
                  ),
                ),
              ),
            ),
          ],
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

/// Logo mark — shows the actual logo.png asset directly,
/// with no circular container or background wrapper.
class _StrawberryLogo extends StatelessWidget {
  final Color primary;
  final Color primaryDark;
  final Color leafGreen;

  const _StrawberryLogo({
    required this.primary,
    required this.primaryDark,
    required this.leafGreen,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(32),
      child: Image.asset(
        'assets/images/logo_square.png',
        width: 140,
        height: 140,
        fit: BoxFit.contain,
      ),
    );
  }
}