import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/app_colors.dart';
import '../../providers/tutorial_provider.dart';
import '../../providers/social_provider.dart';
import '../../providers/user_provider.dart';
import '../../utils/haptic_utils.dart';

class DashboardShell extends ConsumerStatefulWidget {
  final StatefulNavigationShell navigationShell;

  const DashboardShell({super.key, required this.navigationShell});

  @override
  ConsumerState<DashboardShell> createState() => _DashboardShellState();
}

class _DashboardShellState extends ConsumerState<DashboardShell> {
  @override
  Widget build(BuildContext context) {
    final tutorialStep = ref.watch(tutorialStepProvider);
    final isTutorialActive = tutorialStep != TutorialStep.none;

    // Auto-advance if we are already on the Social tab (index 1)
    if (widget.navigationShell.currentIndex == 1 && tutorialStep == TutorialStep.step1SocialTab) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ref.read(tutorialStepProvider.notifier).setStep(TutorialStep.step2AcceptRequest);
        }
      });
    }

    return Stack(
      children: [
        Scaffold(
          body: Stack(
            children: [
              widget.navigationShell,
              // ponytail: overlay only for step1 (block page, social tab is in nav bar above)
              if (tutorialStep == TutorialStep.step1SocialTab)
                Positioned.fill(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {},
                    child: Container(
                      color: Colors.white.withOpacity(0.75),
                    ),
                  ),
                ),
            ],
          ),
          extendBody: true,
          bottomNavigationBar: Opacity(
            opacity: (isTutorialActive && tutorialStep != TutorialStep.step1SocialTab) ? 0.25 : 1.0,
            child: IgnorePointer(
              ignoring: isTutorialActive && tutorialStep != TutorialStep.step1SocialTab,
              child: _FloatingBottomNav(
                currentIndex: widget.navigationShell.currentIndex,
                socialTabKey: socialTabKey,
                tutorialStep: tutorialStep,
                onTap: (index) {
                  if (isTutorialActive) {
                    if (tutorialStep != TutorialStep.step1SocialTab) return;
                    if (index != 1) return;
                  }
                  HapticUtils.light();
                  widget.navigationShell.goBranch(
                    index,
                    initialLocation: index == widget.navigationShell.currentIndex,
                  );
                  if (tutorialStep == TutorialStep.step1SocialTab && index == 1) {
                    ref.read(tutorialStepProvider.notifier).nextStep();
                  }
                },
              ),
            ),
          ),
        ),
        // Coach card for step 1 only (Steps 2 & 3 now use the standardized TutorialOverlay with cutouts!)
        if (isTutorialActive && tutorialStep == TutorialStep.step1SocialTab)
          Positioned(
            left: 20,
            right: 20,
            bottom: 110,
            child: TweenAnimationBuilder<double>(
              key: ValueKey(tutorialStep),
              tween: Tween<double>(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeOutBack,
              builder: (_, animValue, child) {
                return Opacity(
                  opacity: animValue.clamp(0.0, 1.0),
                  child: Transform.translate(
                    offset: Offset(0, (1 - animValue) * 24),
                    child: child,
                  ),
                );
              },
              child: _buildCoachCard(
                'Congratulations on completing your first book! 🎉',
                'Now let\'s send a blind box to a friend to start a streak. Tap the Social tab to begin!',
                showArrow: true,
              ),
            ),
          ),
        // Step 4: full-screen overlay + custom bottom sheet + floating coach card
        if (isTutorialActive && tutorialStep == TutorialStep.step4SendBlindBox) ...[
          // Dimming overlay (leaves bottom navigation bar clickable)
          Positioned(
            left: 0, right: 0, top: 0, bottom: 90,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {},
              child: Container(color: Colors.white.withOpacity(0.75)),
            ),
          ),
          // Custom bottom sheet (slides up)
          Positioned(
            left: 0, right: 0, bottom: 0,
            child: TweenAnimationBuilder<double>(
              key: const ValueKey('step4sheet'),
              tween: Tween<double>(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOutCubic,
              builder: (_, value, child) {
                return Transform.translate(
                  offset: Offset(0, (1 - value) * 250),
                  child: Opacity(opacity: value, child: child),
                );
              },
              child: _Step4Sheet(
                onSendBlindBox: () async {
                  try {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Generating and sending...')),
                    );
                    const botId = '10000000-1000-1000-1000-100000000000';
                    await ref.read(socialProvider.notifier).sendDrop(botId);
                    ref.read(tutorialStepProvider.notifier).setStep(TutorialStep.step5StreakExplanation);
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text(e.toString().replaceAll('Exception: ', '')),
                        backgroundColor: AppColors.error,
                      ));
                    }
                  }
                },
              ),
            ),
          ),
          // Floating coach card (at top, like step 3)
          Positioned(
            left: 20, right: 20, top: 80,
            child: TweenAnimationBuilder<double>(
              key: const ValueKey('step4coach'),
              tween: Tween<double>(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeOutBack,
              builder: (_, animValue, child) {
                return Opacity(
                  opacity: animValue.clamp(0.0, 1.0),
                  child: Transform.translate(
                    offset: Offset(0, (1.0 - animValue) * 24),
                    child: child,
                  ),
                );
              },
              child: _buildCoachCard(
                'Send a Blind Box! 🎁',
                'Tap "Send Blind Box (AI)" to send Clooo Buddy an AI-generated mystery book!',
              ),
            ),
          ),
        ],
        // Tutorial overlays (Steps 2, 3, and 5)
        if (isTutorialActive &&
            (tutorialStep == TutorialStep.step2AcceptRequest ||
             tutorialStep == TutorialStep.step3SendDrop ||
             tutorialStep == TutorialStep.step5StreakExplanation))
          Positioned.fill(
            child: _buildTutorialOverlay(tutorialStep),
          ),
      ],
    );
  }


  Widget _buildTutorialOverlay(TutorialStep step) {
    switch (step) {
      case TutorialStep.step1SocialTab:
      case TutorialStep.step4SendBlindBox:
        return const SizedBox.shrink(); // Handled inline in their respective widgets/sheets
      case TutorialStep.step2AcceptRequest:
        return TutorialOverlay(
          targetKey: acceptRequestKey,
          text: 'Accept Clooo Buddy\'s friend request to begin your very first streak! 🤝',
        );
      case TutorialStep.step3SendDrop:
        return TutorialOverlay(
          targetKey: sendDropButtonKey,
          text: 'Now send a drop to Clooo Buddy to start your streak! 🔥',
          isCentered: true,
        );
      case TutorialStep.step5StreakExplanation:
        // ponytail: highlight Clooo Buddy's streak tile to celebrate the streak!
        return TutorialOverlay(
          targetKey: cloooStreakKey,
          text: '', // Text is dynamically handled inside TutorialOverlay based on stages
          onNext: () async {
            ref.read(tutorialStepProvider.notifier).completeTutorial();
            try {
              final user = ref.read(userProvider).valueOrNull;
              if (user != null) {
                await Supabase.instance.client
                    .from('profiles')
                    .update({'has_completed_tutorial': true})
                    .eq('id', user.id);
                
                ref.invalidate(userProvider);
              }
            } catch (e) {
              debugPrint('Failed to save tutorial completion: $e');
            }
          },
        );
      case TutorialStep.none:
        return const SizedBox.shrink();
    }
  }


  Widget _buildCoachCard(String title, String body, {bool showArrow = false}) {
    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.playfairDisplay(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.grey900,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              body,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppColors.grey700,
                height: 1.5,
              ),
            ),
            if (showArrow) ...[
              const SizedBox(height: 12),
              const _BouncingArrow(),
            ],
          ],
        ),
      ),
    );
  }
}

class _Step4Sheet extends StatelessWidget {
  final VoidCallback onSendBlindBox;
  const _Step4Sheet({required this.onSendBlindBox});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: AppColors.grey300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              const SizedBox(height: 20),
              const Text(
                'Send to Clooo Buddy',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.grey900),
              ),
              const SizedBox(height: 24),
              _Step4PulsingTile(onTap: onSendBlindBox),
              const Divider(),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.menu_book_rounded, color: AppColors.grey400),
                ),
                title: const Text('Send from Journal', style: TextStyle(color: AppColors.grey400)),
                subtitle: const Text(
                  "Choose a book you've read",
                  style: TextStyle(color: AppColors.grey400),
                ),
                enabled: false,
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

// ponytail: stateful pulsing tile for step4 blind box option
class _Step4PulsingTile extends StatefulWidget {
  final VoidCallback onTap;
  const _Step4PulsingTile({required this.onTap});

  @override
  State<_Step4PulsingTile> createState() => _Step4PulsingTileState();
}

class _Step4PulsingTileState extends State<_Step4PulsingTile> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, child) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.15 + _ctrl.value * 0.25),
                blurRadius: 8.0 + _ctrl.value * 8.0,
                spreadRadius: _ctrl.value * 2,
              ),
            ],
          ),
          child: child,
        );
      },
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.card_giftcard, color: AppColors.primary),
        ),
        title: const Text('Send Blind Box (AI)'),
        subtitle: const Text(
          'AI generates a book based on their goals',
          style: TextStyle(color: AppColors.grey600),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        tileColor: Colors.white,
        onTap: widget.onTap,
      ),
    );
  }
}

class _FloatingBottomNav extends StatelessWidget {
  final int currentIndex;
  final void Function(int) onTap;
  final GlobalKey? socialTabKey;
  final TutorialStep tutorialStep;

  const _FloatingBottomNav({
    required this.currentIndex,
    required this.onTap,
    this.socialTabKey,
    this.tutorialStep = TutorialStep.none,
  });

  Widget _buildItem({
    required int index,
    required IconData icon,
    required String label,
    Key? key,
  }) {
    final isSelected = currentIndex == index;
    final isSocialTutorial = index == 1 && tutorialStep == TutorialStep.step1SocialTab;

    Widget content = AnimatedContainer(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      decoration: BoxDecoration(
        color: isSelected
            ? Colors.white.withValues(alpha: 0.90)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 6),
          Icon(
            icon,
            color: isSelected
                ? const Color(0xFFF06A19)
                : AppColors.textSecondary,
            size: 24,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              color: isSelected
                  ? const Color(0xFFF06A19)
                  : AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 2),
          Container(
            width: 4,
            height: 4,
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFFF06A19)
                  : Colors.transparent,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );

    if (isSocialTutorial) {
      content = _PulsingTabWrapper(
        active: true,
        child: content,
      );
    }

    return Expanded(
      child: GestureDetector(
        key: key,
        onTap: () => onTap(index),
        child: content,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 21, right: 21, bottom: 21),
      height: 72,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(36),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.1),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(36),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            color: AppColors.secondarySurface.withValues(alpha: 0.50),
            child: Row(
              children: [
                _buildItem(
                  index: 0,
                  icon: Icons.home_rounded,
                  label: 'Home',
                ),
                _buildItem(
                  index: 1,
                  icon: Icons.people_rounded,
                  label: 'Social',
                ),
                _buildItem(
                  index: 2,
                  icon: Icons.auto_stories_rounded,
                  label: 'Journal',
                ),
                _buildItem(
                  index: 3,
                  icon: Icons.person_rounded,
                  label: 'Profile',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class TutorialOverlay extends StatefulWidget {
  final GlobalKey? targetKey;
  final Rect? computedRect;
  final String text;
  final bool isFullScreen;
  final VoidCallback? onNext;
  final bool isCentered;

  const TutorialOverlay({
    super.key,
    this.targetKey,
    this.computedRect,
    required this.text,
    this.isFullScreen = false,
    this.onNext,
    this.isCentered = false,
  });

  @override
  State<TutorialOverlay> createState() => _TutorialOverlayState();
}

class _TutorialOverlayState extends State<TutorialOverlay> {
  Rect? _targetRect;
  int _currentStage = 1;

  @override
  void initState() {
    super.initState();
    if (widget.computedRect != null) {
      _targetRect = widget.computedRect;
    } else {
      _updateRect();
    }
  }

  @override
  void didUpdateWidget(covariant TutorialOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.computedRect != null) {
      if (widget.computedRect != _targetRect) {
        setState(() => _targetRect = widget.computedRect);
      }
    } else {
      _updateRect();
    }
  }

  void _updateRect() {
    if (widget.isFullScreen) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final context = widget.targetKey?.currentContext;
      final renderBox = context?.findRenderObject() as RenderBox?;
      
      if (renderBox != null && renderBox.hasSize && renderBox.size.width > 0) {
        try {
          final position = renderBox.localToGlobal(Offset.zero);
          final size = renderBox.size;
          final newRect = position & size;
          if (newRect != _targetRect) {
            setState(() => _targetRect = newRect);
          }
        } catch (e) {
          debugPrint('TutorialOverlay: error getting rect: $e');
          _retry();
        }
      } else {
        _retry();
      }
    });
  }

  void _retry() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        setState(() {}); // Force rebuild to schedule a frame and retry layout resolution
        _updateRect();
      }
    });
  }

  Widget _buildCard(String text, {Widget? topWidget}) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      color: Colors.white,
      elevation: 8,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (topWidget != null) ...[
              topWidget,
              const SizedBox(height: 16),
            ],
            Text(
              text,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: AppColors.grey800,
                height: 1.45,
              ),
            ),
            if (widget.onNext != null) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: GestureDetector(
                  onTap: () {
                    if (widget.targetKey == cloooStreakKey && _currentStage == 1) {
                      setState(() {
                        _currentStage = 2;
                      });
                    } else {
                      widget.onNext?.call();
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.primary, AppColors.pinkLight],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        (widget.targetKey == cloooStreakKey && _currentStage == 1)
                            ? 'Next'
                            : 'Got it!',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    if (widget.isFullScreen) {
      return Container(
        color: Colors.white.withOpacity(0.85),
        child: Center(
          child: TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeOutBack, // Bouncy entrance!
            builder: (context, animValue, child) {
              return Transform.scale(
                scale: 0.85 + (animValue * 0.15),
                child: Opacity(
                  opacity: animValue.clamp(0.0, 1.0),
                  child: child,
                ),
              );
            },

            child: Card(
              margin: const EdgeInsets.all(24),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
              color: Colors.white,
              elevation: 12,
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('🔥', style: TextStyle(fontSize: 48)),
                    const SizedBox(height: 16),
                    Text(
                      'Streak Established!',
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.grey900,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      widget.text,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 15, color: AppColors.grey600, height: 1.5),
                    ),
                    const SizedBox(height: 28),
                    SizedBox(
                      width: double.infinity,
                      child: GestureDetector(
                        onTap: widget.onNext,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 16),
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
                              'Got it!',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    if (_targetRect == null) {
      return const SizedBox.shrink(); // Transparent while resolving target position
    }

    final rect = _targetRect!;
    final cardOnTop = rect.top > size.height / 2;
    final isCentered = widget.isCentered;

    // Handle Step 5 split text stage
    final isStep5 = widget.targetKey == cloooStreakKey;
    final displayText = isStep5
        ? (_currentStage == 1
            ? 'Drop sent successfully! 🎁\n\nClooo Buddy has immediately sent you a gift back! You now have a 1-day streak with Clooo Buddy! 🔥'
            : 'You can maintain the streak with any of your friends! 🤝 Keep the flame alive by sharing a blind box 🎁 or recommending a book daily! 📚🔥')
        : widget.text;

    Widget? topWidget;
    if (isStep5 && _currentStage == 2) {
      topWidget = Image.asset(
        'assets/images/onboarding-illustration3.webp',
        height: 250,
        fit: BoxFit.contain,
      );
    }

    return Stack(
      children: [
        Positioned(
          left: 20,
          right: 20,
          top: isCentered ? 0 : (cardOnTop ? null : rect.bottom + 20),
          bottom: isCentered ? 0 : (cardOnTop ? (size.height - rect.top) + 20 : null),
          child: isCentered
              ? Align(
                  alignment: Alignment.center,
                  child: _buildCard(displayText, topWidget: topWidget),
                )
              : _buildCard(displayText, topWidget: topWidget),
        ),
      ],
    );
  }
}

class _PulsingTabWrapper extends StatefulWidget {
  final Widget child;
  final bool active;

  const _PulsingTabWrapper({
    required this.child,
    required this.active,
  });

  @override
  State<_PulsingTabWrapper> createState() => _PulsingTabWrapperState();
}

class _PulsingTabWrapperState extends State<_PulsingTabWrapper>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.06).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );

    _glowAnimation = Tween<double>(begin: 2.0, end: 10.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );

    if (widget.active) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant _PulsingTabWrapper oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    } else if (!widget.active && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.active) return widget.child;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFF06A19).withValues(alpha: 0.4),
                  blurRadius: _glowAnimation.value,
                  spreadRadius: _glowAnimation.value / 3,
                ),
              ],
            ),
            child: widget.child,
          ),
        );
      },
    );
  }
}

class _BouncingArrow extends StatefulWidget {
  const _BouncingArrow();

  @override
  State<_BouncingArrow> createState() => _BouncingArrowState();
}

class _BouncingArrowState extends State<_BouncingArrow>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 0.0, end: 8.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _animation.value),
          child: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: Color(0xFFF06A19),
            size: 32,
          ),
        );
      },
    );
  }
}
