import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:video_player/video_player.dart';
import '../../core/app_colors.dart';
import '../../core/app_typography.dart';
import '../../core/router.dart';

class SplashState {
  static bool hasFinished = false;
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  late VideoPlayerController _videoController;
  bool _isVideoVisible = false;
  bool _showForeground = false;
  bool _fadeToWhite = false;
  Timer? _navigationTimer;

  @override
  void initState() {
    super.initState();
    _initVideo();
  }

  Future<void> _initVideo() async {
    _videoController = VideoPlayerController.asset('assets/videos/entrance-vid2.mp4');
    
    try {
      await _videoController.initialize();
      await _videoController.setVolume(0.0); // Mute required for web autoplay
      await _videoController.setLooping(false);
      await _videoController.play();
      
      if (mounted) {
        setState(() {
          _isVideoVisible = true;
        });
      }
      
      // Trigger fade in after 2 seconds
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() {
            _showForeground = true;
          });
        }
      });

      // Get exact video duration
      final duration = _videoController.value.duration;

      // Trigger fade to white at the end of the video
      _navigationTimer = Timer(duration, () {
        if (mounted) {
          setState(() {
            _fadeToWhite = true;
          });
          // Wait for the white fade animation to finish, then navigate
          Future.delayed(const Duration(milliseconds: 600), _finishSplash);
        }
      });
    } catch (e) {
      // Fallback if video fails to load (e.g. format issues)
      debugPrint('Video failed to load: $e');
      if (mounted) {
        setState(() {
          _showForeground = true;
        });
      }
      _navigationTimer = Timer(const Duration(milliseconds: 2500), _finishSplash);
    }
  }

  void _finishSplash() {
    if (!mounted) return;
    SplashState.hasFinished = true;
    // Calling router.go('/') will re-trigger the router's redirect logic
    // to put the user in the correct place (login vs home vs pre-onboarding)
    context.go('/');
  }

  @override
  void dispose() {
    _videoController.dispose();
    _navigationTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.baseBackground,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background Video
          AnimatedOpacity(
            opacity: _isVideoVisible ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 1000),
            child: _videoController.value.isInitialized
                ? SizedBox.expand(
                    child: FittedBox(
                      fit: BoxFit.cover,
                      child: SizedBox(
                        width: _videoController.value.size.width,
                        height: _videoController.value.size.height,
                        child: VideoPlayer(_videoController),
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
            
          // Foreground Content
          AnimatedOpacity(
            opacity: _showForeground ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 800),
            child: AnimatedSlide(
              offset: _showForeground ? Offset.zero : const Offset(0, 0.05),
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeOutCubic,
              child: SafeArea(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    const SizedBox(height: 60), // Push down slightly from top
                    // App Icon
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.2),
                            blurRadius: 30,
                            offset: const Offset(0, 10),
                          ),
                        ],
                        image: const DecorationImage(
                          image: AssetImage('assets/images/app-icon.webp'),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Title
                    Text(
                      'Clooo',
                      style: AppTypography.h1Playfair.copyWith(
                        fontSize: 48,
                        color: AppColors.grey900,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -1.0,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Tagline
                    Text(
                      'Books are better together.',
                      style: AppTypography.bodyInter.copyWith(
                        fontSize: 16,
                        color: AppColors.grey500,
                        fontWeight: FontWeight.w400,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // White Fade Transition
          IgnorePointer(
            child: AnimatedOpacity(
              opacity: _fadeToWhite ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeInOut,
              child: Container(
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
