import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

/// Hero media component for Explore School page.
///
/// 1. Displays `assets/images/school.jpg` initially.
/// 2. If the user stays on the screen for 3 seconds, transitions to play
///    `assets/videos/school-video.mp4` with audio enabled (with voice).
/// 3. When the video ends, smoothly returns to the school image.
class SchoolHeroMedia extends StatefulWidget {
  final double height;
  final BorderRadius? borderRadius;
  final bool isExploreActive;

  const SchoolHeroMedia({
    super.key,
    required this.height,
    this.borderRadius,
    this.isExploreActive = true,
  });

  @override
  State<SchoolHeroMedia> createState() => _SchoolHeroMediaState();
}

class _SchoolHeroMediaState extends State<SchoolHeroMedia> {
  Timer? _startTimer;
  VideoPlayerController? _controller;
  bool _isPlayingVideo = false;
  bool _isInitializing = false;
  bool _hasEnded = false;
  bool _isMuted = false;

  @override
  void initState() {
    super.initState();
    if (widget.isExploreActive) {
      _scheduleVideoStart();
    }
  }

  @override
  void didUpdateWidget(covariant SchoolHeroMedia oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isExploreActive != widget.isExploreActive) {
      if (widget.isExploreActive) {
        if (!_hasEnded && !_isPlayingVideo) {
          _scheduleVideoStart();
        }
      } else {
        _stopAndResetVideo();
      }
    }
  }

  void _scheduleVideoStart() {
    _startTimer?.cancel();
    _startTimer = Timer(const Duration(seconds: 3), () {
      if (mounted && widget.isExploreActive && !_hasEnded) {
        _initializeAndPlay();
      }
    });
  }

  Future<void> _initializeAndPlay() async {
    if (_isInitializing || _isPlayingVideo) return;
    _isInitializing = true;

    try {
      final controller = VideoPlayerController.asset(
        'assets/videos/school-video.mp4',
        videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
      );

      await controller.initialize();
      if (!mounted || !widget.isExploreActive) {
        await controller.dispose();
        return;
      }

      await controller.setLooping(false);

      if (!kIsWeb) {
        // Native mobile app: Full volume audio playback allowed directly without browser restrictions
        await controller.setVolume(1.0);
        await controller.play();
        _isMuted = false;
      } else {
        // Web: Browsers block unmuted autoplay without prior user click, throwing NotAllowedError
        // which pauses debuggers. We start muted (volume: 0.0) so it autoplays 100% reliably
        // without any error, and allow unmuting instantly on tap.
        await controller.setVolume(0.0);
        await controller.play();
        _isMuted = true;
      }

      controller.addListener(_videoListener);

      setState(() {
        _controller = controller;
        _isPlayingVideo = true;
        _isInitializing = false;
      });
    } catch (e) {
      _isInitializing = false;
      if (mounted) {
        setState(() {
          _isPlayingVideo = false;
        });
      }
    }
  }

  void _videoListener() {
    if (!mounted || _controller == null) return;
    final value = _controller!.value;

    if (value.isInitialized && value.duration > Duration.zero) {
      // Check if video completed playback
      if (value.position >= value.duration) {
        _onVideoFinished();
      }
    }
  }

  void _onVideoFinished() {
    if (!mounted || _hasEnded) return;
    _hasEnded = true;

    setState(() {
      _isPlayingVideo = false;
    });

    _controller?.removeListener(_videoListener);
    _controller?.pause();
    _controller?.dispose();
    _controller = null;
  }

  void _stopAndResetVideo() {
    _startTimer?.cancel();
    if (_controller != null) {
      _controller?.removeListener(_videoListener);
      _controller?.pause();
      _controller?.dispose();
      _controller = null;
    }
    if (mounted) {
      setState(() {
        _isPlayingVideo = false;
      });
    }
  }

  void _toggleMute() {
    if (_controller == null || !_controller!.value.isInitialized) return;
    setState(() {
      if (_isMuted) {
        _controller!.setVolume(1.0);
        _isMuted = false;
      } else {
        _controller!.setVolume(0.0);
        _isMuted = true;
      }
    });
  }

  @override
  void dispose() {
    _startTimer?.cancel();
    if (_controller != null) {
      _controller?.removeListener(_videoListener);
      _controller?.dispose();
      _controller = null;
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final radius = widget.borderRadius ?? BorderRadius.circular(24);

    return ClipRRect(
      borderRadius: radius,
      child: Container(
        height: widget.height,
        width: double.infinity,
        color: Colors.black,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Base School Image
            Image.asset(
              'assets/images/school.jpg',
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
            ),

            // Video Player Layer (Cross-fades in after 3 seconds)
            AnimatedOpacity(
              opacity: (_isPlayingVideo && _controller != null && _controller!.value.isInitialized)
                  ? 1.0
                  : 0.0,
              duration: const Duration(milliseconds: 500),
              child: (_controller != null && _controller!.value.isInitialized)
                  ? GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: _toggleMute,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          FittedBox(
                            fit: BoxFit.cover,
                            clipBehavior: Clip.hardEdge,
                            alignment: Alignment.center,
                            child: SizedBox(
                              width: _controller!.value.size.width > 0
                                  ? _controller!.value.size.width
                                  : 16,
                              height: _controller!.value.size.height > 0
                                  ? _controller!.value.size.height
                                  : 9,
                              child: VideoPlayer(_controller!),
                            ),
                          ),

                          // Voice/Audio status badge & tap-to-unmute pill
                          Positioned(
                            bottom: 14,
                            right: 14,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                              decoration: BoxDecoration(
                                color: _isMuted
                                    ? const Color(0xFFE94464).withValues(alpha: 0.92)
                                    : Colors.black.withValues(alpha: 0.70),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.4),
                                  width: 1,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.25),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    _isMuted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                                    color: Colors.white,
                                    size: 15,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    _isMuted ? 'Tap for Voice 🔊' : 'Voice ON',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.2,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}
