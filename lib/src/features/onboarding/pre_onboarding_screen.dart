import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/app_colors.dart';
import '../../core/app_typography.dart';

class PreOnboardingState {
  static bool hasSeen = false;
}

class PreOnboardingScreen extends StatefulWidget {
  const PreOnboardingScreen({super.key});

  @override
  State<PreOnboardingScreen> createState() => _PreOnboardingScreenState();
}

class _PreOnboardingScreenState extends State<PreOnboardingScreen> {
  final _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _onGetStarted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasSeenPreOnboarding', true);
    PreOnboardingState.hasSeen = true;
    if (mounted) context.go('/login');
  }

  void _onSkip() {
    _onGetStarted();
  }

  void _onNext() {
    if (_currentPage == 2) {
      _onGetStarted();
    } else {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.baseBackground,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
          // Content that slides together (Image + Text)
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: (i) => setState(() => _currentPage = i),
              children: [
                _buildPage(
                  image: 'assets/images/onboarding-illustration1.webp',
                  subtitle: 'DAILY DROP',
                  titleNormal: 'One summary\n',
                  titleItalic: 'a day.',
                  description: 'A book summary and\none action step, daily.',
                ),
                _buildPage(
                  image: 'assets/images/onboarding-illustration2.webp',
                  subtitle: 'SOCIAL DROPS',
                  titleNormal: 'Share the\n',
                  titleItalic: 'spark.',
                  description: 'Send a book rec or a\nblind box to a friend.',
                ),
                _buildPage(
                  image: 'assets/images/onboarding-illustration3.webp',
                  subtitle: 'READ TOGETHER',
                  titleNormal: 'Grow\n',
                  titleItalic: 'together.',
                  description: 'Keep a streak with friends\nand read more.',
                ),
              ],
            ),
          ),
          // Fixed Bottom Controls
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              children: [
                // Button
                GestureDetector(
                  onTap: _onNext,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.warning,
                          AppColors.pinkLight,
                          _currentPage == 2 ? AppColors.primary : AppColors.primaryLight,
                        ],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(100),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.15),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _currentPage == 2 ? 'Get Started' : 'Next',
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            color: AppColors.white,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.arrow_forward_rounded,
                          color: AppColors.white,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                // Pagination
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(3, (i) {
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _currentPage == i
                            ? AppColors.primaryLight
                            : AppColors.grey200,
                      ),
                    );
                  }),
                ),
                const SafeArea(top: false, child: SizedBox(height: 16)),
              ],
            ),
          ),
        ],
      ),
      ),
    );
  }

  Widget _buildPage({
    required String image,
    required String subtitle,
    required String titleNormal,
    required String titleItalic,
    required String description,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.only(top: 20),
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage(image),
                fit: BoxFit.contain,
                alignment: Alignment.center,
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: _SlideContent(
            subtitle: subtitle,
            titleNormal: titleNormal,
            titleItalic: titleItalic,
            description: description,
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }
}

class _SlideContent extends StatelessWidget {
  final String subtitle;
  final String titleNormal;
  final String titleItalic;
  final String description;

  const _SlideContent({
    required this.subtitle,
    required this.titleNormal,
    required this.titleItalic,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          subtitle,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.5,
            color: AppColors.primaryLight,
          ),
        ),
        const SizedBox(height: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              titleNormal.replaceAll('\n', ''), // strip newline
              style: AppTypography.bodyInter.copyWith(
                color: AppColors.grey900,
                fontSize: 46,
                fontWeight: FontWeight.w800,
                letterSpacing: -1.5,
                height: 1.05,
              ),
            ),
            Transform.translate(
              offset: const Offset(0, -8), // pull up the italic text to tighten spacing
              child: ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [AppColors.warning, AppColors.pink, AppColors.primary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ).createShader(bounds),
                child: Text(
                  titleItalic,
                  style: AppTypography.h1Playfair.copyWith(
                    color: AppColors.white, // Masked out
                    fontSize: 50,
                    fontWeight: FontWeight.w700,
                    fontStyle: FontStyle.italic,
                    letterSpacing: -1.0,
                    height: 1.2, // Prevent clipping
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          description,
          style: AppTypography.bodyInter.copyWith(
            fontSize: 17,
            height: 1.5,
            color: AppColors.grey500,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }
}
