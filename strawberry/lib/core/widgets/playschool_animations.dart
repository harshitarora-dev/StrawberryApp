import 'dart:math' as math;
import 'package:flutter/material.dart';

class BouncyTap extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double scaleFactor;
  final Duration duration;

  const BouncyTap({
    super.key,
    required this.child,
    this.onTap,
    this.scaleFactor = 0.93,
    this.duration = const Duration(milliseconds: 140),
  });

  @override
  State<BouncyTap> createState() => _BouncyTapState();
}

class _BouncyTapState extends State<BouncyTap> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
      reverseDuration: widget.duration,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: widget.scaleFactor,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeOutBack,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) => _controller.forward();

  void _onTapUp(TapUpDetails details) {
    Future.delayed(const Duration(milliseconds: 60), () {
      if (mounted) _controller.reverse();
    });
  }

  void _onTapCancel() {
    if (mounted) _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: widget.onTap != null ? _onTapDown : null,
      onTapUp: widget.onTap != null ? _onTapUp : null,
      onTapCancel: widget.onTap != null ? _onTapCancel : null,
      onTap: widget.onTap,
      child: ScaleTransition(scale: _scaleAnimation, child: widget.child),
    );
  }
}

class FloatingWobble extends StatefulWidget {
  final Widget child;
  final double verticalOffset;
  final double rotationAngle;
  final Duration duration;
  final Duration delay;

  const FloatingWobble({
    super.key,
    required this.child,
    this.verticalOffset = 6.0,
    this.rotationAngle = 0.04,
    this.duration = const Duration(milliseconds: 2400),
    this.delay = Duration.zero,
  });

  @override
  State<FloatingWobble> createState() => _FloatingWobbleState();
}

class _FloatingWobbleState extends State<FloatingWobble> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _offsetAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _offsetAnimation = Tween<double>(begin: -widget.verticalOffset, end: widget.verticalOffset)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine));
    _rotationAnimation = Tween<double>(begin: -widget.rotationAngle, end: widget.rotationAngle)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine));

    if (widget.delay == Duration.zero) {
      _controller.repeat(reverse: true);
    } else {
      Future.delayed(widget.delay, () {
        if (mounted) _controller.repeat(reverse: true);
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) => Transform.translate(
        offset: Offset(0, _offsetAnimation.value),
        child: Transform.rotate(angle: _rotationAnimation.value, child: widget.child),
      ),
    );
  }
}

class PulsingGlow extends StatefulWidget {
  final Widget child;
  final double minScale;
  final double maxScale;
  final Duration duration;

  const PulsingGlow({
    super.key,
    required this.child,
    this.minScale = 0.95,
    this.maxScale = 1.05,
    this.duration = const Duration(milliseconds: 1600),
  });

  @override
  State<PulsingGlow> createState() => _PulsingGlowState();
}

class _PulsingGlowState extends State<PulsingGlow> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration)..repeat(reverse: true);
    _scaleAnimation = Tween<double>(begin: widget.minScale, end: widget.maxScale)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(scale: _scaleAnimation, child: widget.child);
  }
}

class StaggeredEntrance extends StatefulWidget {
  final Widget child;
  final int index;
  final double slideOffset;
  final Duration delayStep;

  const StaggeredEntrance({
    super.key,
    required this.child,
    this.index = 0,
    this.slideOffset = 30.0,
    this.delayStep = const Duration(milliseconds: 70),
  });

  @override
  State<StaggeredEntrance> createState() => _StaggeredEntranceState();
}

class _StaggeredEntranceState extends State<StaggeredEntrance> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 480));
    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slideAnimation = Tween<Offset>(begin: Offset(0, widget.slideOffset / 100), end: Offset.zero)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));
    Future.delayed(widget.delayStep * widget.index, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(position: _slideAnimation, child: widget.child),
    );
  }
}

class PlayfulSparkle extends StatefulWidget {
  final double size;
  final Color color;

  const PlayfulSparkle({
    super.key,
    this.size = 18,
    this.color = const Color(0xFFFFD166),
  });

  @override
  State<PlayfulSparkle> createState() => _PlayfulSparkleState();
}

class _PlayfulSparkleState extends State<PlayfulSparkle> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final scale = 0.6 + (_controller.value * 0.5);
        final rot = _controller.value * math.pi * 0.4;
        return Transform.rotate(
          angle: rot,
          child: Transform.scale(
            scale: scale,
            child: Icon(Icons.star_rounded, color: widget.color, size: widget.size),
          ),
        );
      },
    );
  }
}

// =============================================================================
// PLAYFUL LOADING WIDGETS
// =============================================================================

class _PulsingDots extends StatelessWidget {
  final AnimationController controller;
  final Color color;
  final double dotSize;
  final double spacing;

  const _PulsingDots({
    required this.controller,
    this.color = const Color(0xFFE91E63),
    this.dotSize = 6,
    this.spacing = 5,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            final phase = (controller.value - i * 0.28).clamp(0.0, 1.0);
            final bounce = math.sin(phase * math.pi).clamp(0.0, 1.0);
            final translateY = -bounce * (dotSize * 1.8);
            final scale = 0.7 + bounce * 0.5;
            return Padding(
              padding: EdgeInsets.symmetric(horizontal: spacing / 2),
              child: Transform.translate(
                offset: Offset(0, translateY),
                child: Transform.scale(
                  scale: scale,
                  child: Container(
                    width: dotSize,
                    height: dotSize,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.5 + bounce * 0.5),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}

/// Bouncing strawberry + pulsing dots. Replaces Center(CircularProgressIndicator).
class StrawberryLoader extends StatefulWidget {
  final String message;
  final double size;

  const StrawberryLoader({
    super.key,
    this.message = 'Loading the good stuff... 🌟',
    this.size = 52,
  });

  @override
  State<StrawberryLoader> createState() => _StrawberryLoaderState();
}

class _StrawberryLoaderState extends State<StrawberryLoader> with TickerProviderStateMixin {
  late AnimationController _bounceCtrl;
  late AnimationController _dotCtrl;
  late Animation<double> _bounceAnim;

  @override
  void initState() {
    super.initState();
    _bounceCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 700))
      ..repeat(reverse: true);
    _dotCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat();
    _bounceAnim = Tween<double>(begin: 0, end: -14)
        .animate(CurvedAnimation(parent: _bounceCtrl, curve: Curves.easeInOutSine));
  }

  @override
  void dispose() {
    _bounceCtrl.dispose();
    _dotCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _bounceAnim,
            builder: (_, __) => Transform.translate(
              offset: Offset(0, _bounceAnim.value),
              child: Text('🍓', style: TextStyle(fontSize: widget.size)),
            ),
          ),
          const SizedBox(height: 14),
          _PulsingDots(controller: _dotCtrl),
          const SizedBox(height: 10),
          Text(
            widget.message,
            style: const TextStyle(fontSize: 12, color: Color(0xFF9E9E9E), fontWeight: FontWeight.w500),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// 3 dancing dots inside buttons. Replaces CircularProgressIndicator(color: Colors.white).
class BtnLoader extends StatefulWidget {
  final Color color;
  final double dotSize;

  const BtnLoader({
    super.key,
    this.color = Colors.white,
    this.dotSize = 7,
  });

  @override
  State<BtnLoader> createState() => _BtnLoaderState();
}

class _BtnLoaderState extends State<BtnLoader> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.dotSize * 2.2,
      child: _PulsingDots(controller: _ctrl, dotSize: widget.dotSize, color: widget.color),
    );
  }
}

/// Shimmer card with floating 🍓. Replaces inline spinners inside cards/lists.
class SectionShimmer extends StatefulWidget {
  final double height;
  final String message;
  final Color? baseColor;

  const SectionShimmer({
    super.key,
    this.height = 140,
    this.message = 'Fetching the good stuff... 🍓',
    this.baseColor,
  });

  @override
  State<SectionShimmer> createState() => _SectionShimmerState();
}

class _SectionShimmerState extends State<SectionShimmer> with TickerProviderStateMixin {
  late AnimationController _shimmerCtrl;
  late AnimationController _floatCtrl;
  late AnimationController _dotCtrl;
  late Animation<double> _floatAnim;

  @override
  void initState() {
    super.initState();
    _shimmerCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600))..repeat();
    _floatCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800))
      ..repeat(reverse: true);
    _dotCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat();
    _floatAnim = Tween<double>(begin: -5, end: 5)
        .animate(CurvedAnimation(parent: _floatCtrl, curve: Curves.easeInOutSine));
  }

  @override
  void dispose() {
    _shimmerCtrl.dispose();
    _floatCtrl.dispose();
    _dotCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final base = widget.baseColor ?? const Color(0xFFFCE4EC);
    return AnimatedBuilder(
      animation: _shimmerCtrl,
      builder: (_, __) {
        final so = _shimmerCtrl.value * 2 - 0.5;
        return Container(
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment(-1 + so * 2, 0),
              end: Alignment(1 + so * 2, 0),
              colors: [base, Color.lerp(base, Colors.white, 0.55)!, base],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedBuilder(
                  animation: _floatAnim,
                  builder: (_, __) => Transform.translate(
                    offset: Offset(0, _floatAnim.value),
                    child: const Text('🍓', style: TextStyle(fontSize: 32)),
                  ),
                ),
                const SizedBox(height: 10),
                _PulsingDots(controller: _dotCtrl, color: const Color(0xFFE91E63)),
                const SizedBox(height: 6),
                Text(
                  widget.message,
                  style: const TextStyle(fontSize: 11, color: Color(0xFFAD1457), fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
