import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/app_colors.dart';
import '../../providers/user_provider.dart';
import '../../utils/haptic_utils.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pageController = PageController();
  int _currentPage = 0;
  final Map<int, String> _answers = {};

  final List<_OnboardingQuestion> _questions = [
    _OnboardingQuestion(
      title: 'What are you working on?',
      subtitle: 'Choose your primary focus area',
      options: [
        'Confidence', 'Discipline', 'Career', 'Business',
        'Creativity', 'Communication', 'Mindset', 'Relationships',
      ],
    ),
    _OnboardingQuestion(
      title: "What's your current stage?",
      subtitle: 'This helps us tailor recommendations for you',
      options: [
        'Student', 'Young professional', 'Founder', 'Creator',
        'Freelancer', 'Manager', 'Exploring myself',
      ],
    ),
    _OnboardingQuestion(
      title: 'What do you struggle with?',
      subtitle: 'Be honest — this helps us help you',
      options: [
        'I procrastinate', 'I lack confidence', 'I get distracted easily',
        "I don't know what to focus on",
        'I consume but do not act',
        'I start but do not stay consistent',
      ],
    ),
    _OnboardingQuestion(
      title: 'Who do you want to become?',
      subtitle: "Choose the version of yourself you're building",
      options: [
        'More disciplined', 'More confident', 'More creative',
        'More strategic', 'More successful', 'More calm',
        'More influential', 'More productive',
      ],
    ),
    _OnboardingQuestion(
      title: 'How much time can you spare?',
      subtitle: 'Daily time you can dedicate to growth',
      iconOptions: [
        _IconOption(icon: Icons.coffee_rounded, label: '3 min'),
        _IconOption(icon: Icons.bolt_rounded, label: '5 min'),
        _IconOption(icon: Icons.timer_rounded, label: '10 min'),
        _IconOption(icon: Icons.self_improvement_rounded, label: '15 min'),
      ],
    ),
    _OnboardingQuestion(
      title: 'What motivates you?',
      subtitle: 'What keeps you going?',
      options: [
        'Seeing progress', 'New discoveries', 'Community & sharing',
        'Building identity', 'Overcoming challenges', 'Daily routine',
      ],
    ),
  ];

  void _onSelected(int pageIndex, String value) {
    setState(() => _answers[pageIndex] = value);
  }

  Future<void> _nextPage() async {
    HapticUtils.light();
    if (_currentPage < _questions.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOut,
      );
    } else {
      final answersMap = <String, String>{
        'focusArea': _answers[0] ?? '',
        'stage': _answers[1] ?? '',
        'struggle': _answers[2] ?? '',
        'aspiration': _answers[3] ?? '',
        'dailyTime': _answers[4] ?? '',
        'motivation': _answers[5] ?? '',
      };

      final currentUser = ref.read(userProvider).valueOrNull;
      if (currentUser != null) {
        final updatedUser = currentUser.copyWith(onboardingProfile: answersMap);
        await ref.read(userProvider.notifier).saveOnboardingData(updatedUser);
      }

      if (mounted) context.push('/companion-select');
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: (_currentPage + 1) / _questions.length,
                  minHeight: 4,
                  backgroundColor: AppColors.grey200,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    AppColors.primary,
                  ),
                ),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (index) {
                  setState(() => _currentPage = index);
                },
                itemCount: _questions.length,
                itemBuilder: (context, index) {
                  final q = _questions[index];
                  return _QuestionPage(
                    question: q,
                    selectedValue: _answers[index],
                    onSelected: (v) => _onSelected(index, v),
                    onNext: _nextPage,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingQuestion {
  final String title;
  final String subtitle;
  final List<String>? options;
  final List<_IconOption>? iconOptions;

  const _OnboardingQuestion({
    required this.title,
    required this.subtitle,
    this.options,
    this.iconOptions,
  });
}

class _IconOption {
  final IconData icon;
  final String label;

  const _IconOption({required this.icon, required this.label});
}

class _QuestionPage extends StatefulWidget {
  final _OnboardingQuestion question;
  final VoidCallback onNext;
  final ValueChanged<String> onSelected;
  final String? selectedValue;

  const _QuestionPage({
    required this.question,
    required this.onNext,
    required this.onSelected,
    this.selectedValue,
  });

  @override
  State<_QuestionPage> createState() => _QuestionPageState();
}

class _QuestionPageState extends State<_QuestionPage> {
  String? _selected;
  String? _iconSelected;

  @override
  void initState() {
    super.initState();
    _syncSelection();
  }

  @override
  void didUpdateWidget(_QuestionPage old) {
    super.didUpdateWidget(old);
    if (widget.selectedValue != old.selectedValue) {
      _syncSelection();
    }
  }

  void _syncSelection() {
    if (widget.question.iconOptions != null) {
      _iconSelected = widget.selectedValue;
    } else {
      _selected = widget.selectedValue;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 40),
          Text(
            widget.question.title,
            style: GoogleFonts.playfairDisplay(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
              height: 1.15,
              color: AppColors.grey900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.question.subtitle,
            style: const TextStyle(
              fontSize: 15,
              color: AppColors.grey500,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 32),
          Expanded(
            child: widget.question.iconOptions != null
                ? _buildIconOptions()
                : _buildTextOptions(),
          ),
          _buildContinueButton(),
        ],
      ),
    );
  }

  Widget _buildTextOptions() {
    return ListView.separated(
      itemCount: widget.question.options!.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final option = widget.question.options![index];
        final isSelected = _selected == option;
        return GestureDetector(
          onTap: () {
            HapticUtils.light();
            setState(() => _selected = option);
            widget.onSelected(option);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primary.withValues(alpha: 0.1)
                  : AppColors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected ? AppColors.primary : AppColors.grey200,
                width: isSelected ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected ? AppColors.primary : Colors.transparent,
                    border: Border.all(
                      color: isSelected ? AppColors.primary : AppColors.grey400,
                      width: 2,
                    ),
                  ),
                  child: isSelected
                      ? const Icon(Icons.check, color: AppColors.white, size: 14)
                      : null,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    option,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                      color: isSelected ? AppColors.primary : AppColors.grey800,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildIconOptions() {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: widget.question.iconOptions!.map((opt) {
        final isSelected = _iconSelected == opt.label;
        return GestureDetector(
          onTap: () {
            HapticUtils.light();
            setState(() => _iconSelected = opt.label);
            widget.onSelected(opt.label);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: (MediaQuery.of(context).size.width - 60) / 2,
            padding: const EdgeInsets.symmetric(vertical: 24),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primary.withValues(alpha: 0.1)
                  : AppColors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected ? AppColors.primary : AppColors.grey200,
                width: isSelected ? 1.5 : 1,
              ),
            ),
            child: Column(
              children: [
                Icon(
                  opt.icon,
                  color: isSelected ? AppColors.primary : AppColors.grey400,
                  size: 32,
                ),
                const SizedBox(height: 8),
                Text(
                  opt.label,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    color: isSelected ? AppColors.primary : AppColors.grey700,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildContinueButton() {
    final hasSelection = _selected != null || _iconSelected != null;
    return Padding(
      padding: const EdgeInsets.only(bottom: 32),
      child: SizedBox(
        width: double.infinity,
        child: GestureDetector(
          onTap: hasSelection ? widget.onNext : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(vertical: 18),
            decoration: BoxDecoration(
              gradient: hasSelection
                  ? const LinearGradient(
                      colors: [AppColors.primary, AppColors.pinkLight],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    )
                  : null,
              color: hasSelection ? null : AppColors.grey200,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Center(
              child: Text(
                'Continue',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.white,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
