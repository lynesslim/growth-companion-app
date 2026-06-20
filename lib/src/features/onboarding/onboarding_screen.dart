import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/app_colors.dart';
import '../../providers/user_provider.dart';
import '../../utils/haptic_utils.dart';
import 'widgets/onboarding_widgets.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  final _pageController = PageController();
  int _currentPage = 0;
  late AnimationController _pulseController;

  String _name = '';
  String _age = '';
  final Set<String> _goals = {};
  final Set<String> _interests = {};
  final Set<String> _time = {};
  final Set<String> _moments = {};
  final List<bool?> _motivation = [null, null, null];
  bool _reminders = true;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _next() {
    HapticUtils.light();
    if (_currentPage < 9) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOut,
      );
    }
  }

  void _goTo(int page) {
    _pageController.animateToPage(page,
        duration: const Duration(milliseconds: 350), curve: Curves.easeOut);
  }

  Future<void> _submit() async {
    final answersMap = <String, String>{
      'name': _name,
      'age': _age,
      'goals': _goals.join(', '),
      'interests': _interests.join(', '),
      'time': _time.join(', '),
      'moments': _moments.join(', '),
      'motivation': _motivation.map((v) => v == true ? 'yes' : 'no').join(', '),
      'reminders': _reminders ? 'yes' : 'no',
    };
    final currentUser = ref.read(userProvider).valueOrNull;
    if (currentUser != null) {
      final updated = currentUser.copyWith(
        name: _name.trim().isNotEmpty ? _name.trim() : currentUser.name,
        onboardingProfile: answersMap
      );
      await ref.read(userProvider.notifier).saveOnboardingData(updated);
    }
    if (mounted) _goTo(10);
  }

  double get _progress {
    if (_currentPage < 1) return 0;
    if (_currentPage >= 10) return 1;
    return (_currentPage - 1) / 8;
  }

  @override
  Widget build(BuildContext context) {
    return OnboardingLayout(
      progress: _progress,
      child: PageView.builder(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        onPageChanged: (i) => setState(() => _currentPage = i),
        itemCount: 12,
        itemBuilder: (_, i) => _buildScreen(i),
      ),
    );
  }

  Widget _buildScreen(int i) {
    switch (i) {
      case 0:
        return _WelcomeScreen(onStart: () => _goTo(1));
      case 1:
        return _NameScreen(
          value: _name,
          onChanged: (v) => setState(() => _name = v),
          onNext: _name.trim().isNotEmpty ? _next : null,
        );
      case 2:
        return _QuestionScreen(
          title: "What's your age?",
          subtitle: 'Select your age range',
          options: ['Under 18', '18-24', '25-34', '35-44', '45+'],
          selected: _age,
          onSelect: (v) => setState(() => _age = v),
          onNext: _age.isNotEmpty ? _next : null,
        );
      case 3:
        return _QuestionScreen(
          title: 'What are your goals?',
          subtitle: 'Choose all that apply',
          options: [
            'Build better habits',
            'Grow my career',
            'Learn new skills',
            'Improve relationships',
            'Increase confidence',
            'Find focus',
            'Boost creativity',
            'Achieve balance',
          ],
          multi: true,
          selectedSet: _goals,
          onSelectSet: (v) => setState(() => _goals.toggle(v)),
          onNext: _goals.isNotEmpty ? _next : null,
        );
      case 4:
        return _TopicScreen(
          title: 'What interests you?',
          subtitle: 'Pick topics you love',
          options: [
            'Psychology', 'Business', 'Science', 'Philosophy',
            'Art', 'Technology', 'Health', 'History',
            'Spirituality', 'Leadership', 'Writing', 'Finance',
          ],
          selected: _interests,
          onToggle: (v) => setState(() => _interests.toggle(v)),
          onNext: _interests.isNotEmpty ? _next : null,
        );
      case 5:
        return _QuestionScreen(
          title: 'How much time do you have?',
          subtitle: 'Daily reading time',
          options: ['3 min', '5 min', '10 min', '15 min', '20 min+'],
          multi: true,
          selectedSet: _time,
          onSelectSet: (v) => setState(() => _time.toggle(v)),
          onNext: _time.isNotEmpty ? _next : null,
          extra: _time.isNotEmpty
              ? Text(
                  'About ${_time.length * 5} useful ideas every week',
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                )
              : null,
        );
      case 6:
        return _QuestionScreen(
          title: 'When do you read?',
          subtitle: 'Choose your moments',
          options: [
            'Morning routine',
            'Commute',
            'Lunch break',
            'After work',
            'Before bed',
            'Weekends',
          ],
          multi: true,
          selectedSet: _moments,
          onSelectSet: (v) => setState(() => _moments.toggle(v)),
          onNext: _moments.isNotEmpty ? _next : null,
        );
      case 7:
        return _MotivationScreen(
          answers: _motivation,
          onAnswer: (i, v) => setState(() => _motivation[i] = v),
          onNext: _motivation.every((v) => v != null) ? _next : null,
        );
      case 8:
        return _RemindersScreen(
          value: _reminders,
          onChanged: (v) => setState(() => _reminders = v),
          onNext: _next,
        );
      case 9:
        return _LoadingScreen(
          controller: _pulseController,
          onDone: _submit,
        );
      case 10:
        return _PlanScreen(onNext: () async {
          final prefs = await SharedPreferences.getInstance();
          final senderId = prefs.getString('sender_id');
          if (senderId != null && context.mounted) {
            context.push('/blind-box', extra: senderId);
          } else if (context.mounted) {
            context.push('/book');
          }
        });
      case 11:
        return _FirstSessionScreen(onStart: () async {
          final prefs = await SharedPreferences.getInstance();
          final senderId = prefs.getString('sender_id');
          if (senderId != null && context.mounted) {
            context.push('/blind-box', extra: senderId);
          } else if (context.mounted) {
            context.push('/book');
          }
        });
      default:
        return const SizedBox();
    }
  }
}

extension on Set<String> {
  void toggle(String v) {
    if (contains(v)) {
      remove(v);
    } else {
      add(v);
    }
  }
}

// Screen 0
class _WelcomeScreen extends StatelessWidget {
  final VoidCallback onStart;
  const _WelcomeScreen({required this.onStart});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.pinkLight],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(28),
            ),
            child: const Icon(Icons.auto_stories_rounded,
                color: AppColors.white, size: 48),
          ),
          const SizedBox(height: 32),
          Text(
            'Your Daily\nGrowth Companion',
            textAlign: TextAlign.center,
            style: GoogleFonts.playfairDisplay(
              fontSize: 34,
              fontWeight: FontWeight.w700,
              color: AppColors.grey900,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Personalized book drops and micro-actions\nto grow a little every day.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              color: AppColors.grey500,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 48),
          SizedBox(
            width: double.infinity,
            child: GestureDetector(
              onTap: onStart,
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
          ),
        ],
      ),
    );
  }
}

// Screen 1
class _NameScreen extends StatefulWidget {
  final String value;
  final ValueChanged<String> onChanged;
  final VoidCallback? onNext;

  const _NameScreen({
    required this.value,
    required this.onChanged,
    this.onNext,
  });

  @override
  State<_NameScreen> createState() => _NameScreenState();
}

class _NameScreenState extends State<_NameScreen> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 48),
          Text(
            "What's your name?",
            style: GoogleFonts.playfairDisplay(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: AppColors.grey900,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "We'll personalize your journey.",
            style: TextStyle(fontSize: 15, color: AppColors.grey500),
          ),
          const SizedBox(height: 32),
          TextField(
            controller: _controller,
            autofocus: true,
            onChanged: widget.onChanged,
            decoration: InputDecoration(
              hintText: 'Enter your name',
              filled: true,
              fillColor: AppColors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
            ),
            style: const TextStyle(fontSize: 16, color: AppColors.grey900),
          ),
          const Spacer(),
          _ContinueButton(onTap: widget.onNext),
        ],
      ),
    );
  }
}

// Screens 2, 3, 5, 6 — single/multi select
class _QuestionScreen extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<String> options;
  final String selected;
  final Set<String> selectedSet;
  final ValueChanged<String>? onSelect;
  final ValueChanged<String>? onSelectSet;
  final VoidCallback? onNext;
  final bool multi;
  final Widget? extra;

  const _QuestionScreen({
    required this.title,
    required this.subtitle,
    required this.options,
    this.selected = '',
    this.selectedSet = const {},
    this.onSelect,
    this.onSelectSet,
    this.onNext,
    this.multi = false,
    this.extra,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 48),
          Text(title,
              style: GoogleFonts.playfairDisplay(
                  fontSize: 28, fontWeight: FontWeight.w700, color: AppColors.grey900)),
          const SizedBox(height: 8),
          Text(subtitle,
              style: const TextStyle(fontSize: 15, color: AppColors.grey500)),
          const SizedBox(height: 24),
          if (extra != null) ...[extra!, const SizedBox(height: 16)],
          Expanded(
            child: ListView.separated(
              itemCount: options.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (_, i) {
                final opt = options[i];
                final sel = multi ? selectedSet.contains(opt) : selected == opt;
                return SelectionCard(
                  label: opt,
                  selected: sel,
                  multi: multi,
                    onTap: () {
                      if (multi) {
                        onSelectSet?.call(opt);
                      } else {
                        onSelect?.call(opt);
                      }
                  },
                );
              },
            ),
          ),
          _ContinueButton(onTap: onNext),
        ],
      ),
    );
  }
}

// Screen 4
class _TopicScreen extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<String> options;
  final Set<String> selected;
  final ValueChanged<String> onToggle;
  final VoidCallback? onNext;

  const _TopicScreen({
    required this.title,
    required this.subtitle,
    required this.options,
    required this.selected,
    required this.onToggle,
    this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 48),
          Text(title,
              style: GoogleFonts.playfairDisplay(
                  fontSize: 28, fontWeight: FontWeight.w700, color: AppColors.grey900)),
          const SizedBox(height: 8),
          Text(subtitle,
              style: const TextStyle(fontSize: 15, color: AppColors.grey500)),
          const SizedBox(height: 24),
          Expanded(
            child: SingleChildScrollView(
              child: Wrap(
                spacing: 10,
                runSpacing: 10,
                children: options.map((opt) => TopicPill(
                  label: opt,
                  selected: selected.contains(opt),
                  onTap: () => onToggle(opt),
                )).toList(),
              ),
            ),
          ),
          _ContinueButton(onTap: onNext),
        ],
      ),
    );
  }
}

// Screen 7
class _MotivationScreen extends StatelessWidget {
  final List<bool?> answers;
  final void Function(int, bool) onAnswer;
  final VoidCallback? onNext;

  static const _quotes = [
    'I want to become the best version of myself.',
    'I believe small daily steps lead to big changes.',
    'I am ready to invest time in my growth.',
  ];

  const _MotivationScreen({
    required this.answers,
    required this.onAnswer,
    this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 48),
          Text('What drives you?',
              style: GoogleFonts.playfairDisplay(
                  fontSize: 28, fontWeight: FontWeight.w700, color: AppColors.grey900)),
          const SizedBox(height: 8),
          const Text('React to each statement',
              style: TextStyle(fontSize: 15, color: AppColors.grey500)),
          const SizedBox(height: 24),
          Expanded(
            child: ListView.separated(
              itemCount: _quotes.length,
              separatorBuilder: (_, _) => const SizedBox(height: 16),
              itemBuilder: (_, i) => QuoteCard(
                quote: _quotes[i],
                answer: answers[i],
                onAnswer: (v) => onAnswer(i, v),
              ),
            ),
          ),
          _ContinueButton(onTap: onNext),
        ],
      ),
    );
  }
}

// Screen 8
class _RemindersScreen extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  final VoidCallback? onNext;

  const _RemindersScreen({
    required this.value,
    required this.onChanged,
    this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 48),
          Text('Daily Reminders',
              style: GoogleFonts.playfairDisplay(
                  fontSize: 28, fontWeight: FontWeight.w700, color: AppColors.grey900)),
          const SizedBox(height: 8),
          const Text('Get a gentle nudge to read every day',
              style: TextStyle(fontSize: 15, color: AppColors.grey500)),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.grey200),
            ),
            child: Row(
              children: [
                const Icon(Icons.notifications_rounded,
                    color: AppColors.primary, size: 24),
                const SizedBox(width: 16),
                const Expanded(
                  child: Text(
                    'Push notifications',
                    style: TextStyle(fontSize: 16, color: AppColors.grey800),
                  ),
                ),
                GestureDetector(
                  onTap: () => onChanged(!value),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 48,
                    height: 28,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      color: value ? AppColors.primary : AppColors.grey300,
                    ),
                    child: AnimatedAlign(
                      duration: const Duration(milliseconds: 200),
                      alignment: value ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.all(3),
                        width: 22,
                        height: 22,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          _ContinueButton(onTap: onNext),
        ],
      ),
    );
  }
}

// Screen 9
class _LoadingScreen extends StatelessWidget {
  final AnimationController controller;
  final VoidCallback onDone;

  const _LoadingScreen({required this.controller, required this.onDone});

  @override
  Widget build(BuildContext context) {
    Future.microtask(onDone);
    return AnimatedBuilder(
      animation: controller,
      builder: (_, _) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80 + controller.value * 20,
              height: 80 + controller.value * 20,
              decoration: BoxDecoration(
                gradient: const RadialGradient(
                  center: Alignment.center,
                  colors: [AppColors.primary, AppColors.pinkLight],
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.auto_stories_rounded,
                  color: AppColors.white, size: 40),
            ),
            const SizedBox(height: 32),
            Text(
              'Crafting Your\nGrowth Path',
              textAlign: TextAlign.center,
              style: GoogleFonts.playfairDisplay(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: AppColors.grey900,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Analyzing your responses to create\na personalized reading plan...',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                color: AppColors.grey500,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 40),
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            ),
          ],
        ),
      ),
    );
  }
}

// Screen 10
class _PlanScreen extends StatelessWidget {
  final VoidCallback onNext;
  const _PlanScreen({required this.onNext});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Icon(Icons.check_rounded,
                color: AppColors.success, size: 40),
          ),
          const SizedBox(height: 24),
          Text(
            "You're all set!",
            style: GoogleFonts.playfairDisplay(
              fontSize: 30,
              fontWeight: FontWeight.w700,
              color: AppColors.grey900,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Your personalized growth plan is ready.\nStart with your first book drop.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              color: AppColors.grey500,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 40),
          SizedBox(
            width: double.infinity,
            child: GestureDetector(
              onTap: onNext,
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
                    'View My Plan',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: AppColors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Screen 11
class _FirstSessionScreen extends StatelessWidget {
  final VoidCallback onStart;
  const _FirstSessionScreen({required this.onStart});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.pinkLight],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(28),
            ),
            child: const Icon(Icons.menu_book_rounded,
                color: AppColors.white, size: 48),
          ),
          const SizedBox(height: 32),
          Text(
            'Your First Session',
            style: GoogleFonts.playfairDisplay(
              fontSize: 30,
              fontWeight: FontWeight.w700,
              color: AppColors.grey900,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Flip through your first personalized\nbook and discover lessons\nmade for you.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              color: AppColors.grey500,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 40),
          SizedBox(
            width: double.infinity,
            child: GestureDetector(
              onTap: onStart,
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
                    'Start Reading',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: AppColors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ContinueButton extends StatelessWidget {
  final VoidCallback? onTap;
  const _ContinueButton({this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 32),
      child: SizedBox(
        width: double.infinity,
        child: GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(vertical: 18),
            decoration: BoxDecoration(
              gradient: onTap != null
                  ? const LinearGradient(
                      colors: [AppColors.primary, AppColors.pinkLight],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    )
                  : null,
              color: onTap != null ? null : AppColors.grey200,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(
                'Continue',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: onTap != null ? AppColors.white : AppColors.grey400,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
