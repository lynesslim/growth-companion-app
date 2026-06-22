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
    _pageController.animateToPage(2,
        duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (i) => setState(() => _currentPage = i),
                children: const [
                  _Slide(
                    icon: Icons.auto_stories_rounded,
                    title: 'Read Smarter,\nEvery Day',
                    subtitle:
                        'Get curated book summaries delivered daily.\nGrow your mind without the time commitment.',
                  ),
                  _Slide(
                    icon: Icons.card_giftcard_rounded,
                    title: 'Your Daily Drop',
                    subtitle:
                        'A new actionable insight awaits you each day.\nRead, reflect, and apply it to your life.',
                  ),
                  _Slide(
                    icon: Icons.whatshot_rounded,
                    title: 'Grow Together',
                    subtitle:
                        'Send books to your friends and maintain daily\nreading streaks. Stay consistent and hold\neach other accountable!',
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(3, (i) {
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 5),
                        width: _currentPage == i ? 28 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          color: _currentPage == i
                              ? AppColors.primary
                              : AppColors.grey300,
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 32),
                  if (_currentPage == 2)
                    SizedBox(
                      width: double.infinity,
                      child: GestureDetector(
                        onTap: _onGetStarted,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [AppColors.primary, AppColors.pinkLight],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Center(
                            child: Text(
                              'Get Started',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w600,
                                color: AppColors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    )
                  else
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const SizedBox(width: 60),
                        GestureDetector(
                          onTap: _onSkip,
                          child: const Text(
                            'Skip',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: AppColors.grey400,
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            _pageController.nextPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 12),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [AppColors.primary, AppColors.pinkLight],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'Next',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: AppColors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Slide extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _Slide({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.pinkLight],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Icon(icon, color: AppColors.white, size: 56),
          ),
          const SizedBox(height: 40),
          Text(
            title,
            textAlign: TextAlign.center,
            style: AppTypography.h1Playfair.copyWith(
              fontSize: 28,
              color: AppColors.grey900,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              color: AppColors.grey500,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
