import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supa;
import '../../core/app_colors.dart';
import '../../domain/models/weekly_goal.dart';
import '../../providers/growth_drop_provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/weekly_goal_provider.dart';
import '../../utils/haptic_utils.dart';

class WeeklyFocusScreen extends ConsumerStatefulWidget {
  const WeeklyFocusScreen({super.key});

  @override
  ConsumerState<WeeklyFocusScreen> createState() => _WeeklyFocusScreenState();
}

class _WeeklyFocusScreenState extends ConsumerState<WeeklyFocusScreen> {
  int _step = 0;
  String? _intent;
  String? _struggle;
  bool _loading = false;

  final List<String> _intents = [
    'Build a new skill',
    'Improve productivity',
    'Deepen self-awareness',
    'Advance my career',
    'Boost creativity',
    'Strengthen relationships',
  ];

  final List<String> _struggles = [
    'Finding time',
    'Staying motivated',
    'Overcoming doubts',
    'Dealing with distractions',
    'Turning knowledge into action',
    'Keeping consistency',
  ];

  Future<void> _next() async {
    HapticUtils.light();
    if (_step == 0) {
      setState(() => _step = 1);
      return;
    }
    setState(() => _loading = true);
    try {
      final user = ref.read(userProvider).valueOrNull;
      if (user == null) throw Exception('User not loaded');
      await supa.Supabase.instance.client.functions.invoke(
        'generate-growth-drop',
        body: {
          'user_id': user.id,
          'onboarding_profile': user.onboardingProfile,
          'weekly_intent': _intent,
          'weekly_struggle': _struggle,
          'drop_date': DateTime.now().toIso8601String().split('T')[0],
        },
      );
      if (mounted) {
        final goal = WeeklyGoal(
          id: '',
          userId: user.id,
          focusArea: _intent ?? '',
          intent: _intent ?? '',
          struggle: _struggle ?? '',
          status: 'active',
          startDate: DateTime.now(),
          endDate: DateTime.now().add(const Duration(days: 7)),
        );
        ref.read(currentWeeklyGoalProvider.notifier).setGoal(goal);
        ref.invalidate(growthDropProvider);
        setState(() => _loading = false);
        context.push('/book');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 10),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: (_step + 1) / 2,
                      minHeight: 4,
                      backgroundColor: AppColors.grey200,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  Text(
                    _step == 0 ? "This week's focus" : 'What is in your way?',
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
                    _step == 0
                        ? 'What do you want to work on this week?'
                        : 'What might make it harder this week?',
                    style: const TextStyle(
                      fontSize: 15,
                      color: AppColors.grey500,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 32),
                  Expanded(
                    child: ListView.separated(
                      itemCount: (_step == 0 ? _intents : _struggles).length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final items = _step == 0 ? _intents : _struggles;
                        final item = items[index];
                        final isSelected =
                            _step == 0 ? _intent == item : _struggle == item;
                        return GestureDetector(
                          onTap: () {
                            HapticUtils.light();
                            setState(() {
                              if (_step == 0) {
                                _intent = item;
                              } else {
                                _struggle = item;
                              }
                            });
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 16,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.primary.withValues(alpha: 0.1)
                                  : AppColors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.primary
                                    : AppColors.grey200,
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
                                    color: isSelected
                                        ? AppColors.primary
                                        : Colors.transparent,
                                    border: Border.all(
                                      color: isSelected
                                          ? AppColors.primary
                                          : AppColors.grey400,
                                      width: 2,
                                    ),
                                  ),
                                  child: isSelected
                                      ? const Icon(
                                          Icons.check,
                                          color: AppColors.white,
                                          size: 14,
                                        )
                                      : null,
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Text(
                                    item,
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: isSelected
                                          ? FontWeight.w600
                                          : FontWeight.w400,
                                      color: isSelected
                                          ? AppColors.primary
                                          : AppColors.grey800,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 32),
                    child: SizedBox(
                      width: double.infinity,
                      child: GestureDetector(
                        onTap:
                            (_step == 0 ? _intent != null : _struggle != null)
                                ? _next
                                : null,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          decoration: BoxDecoration(
                            gradient: (_step == 0 ? _intent != null : _struggle != null)
                                ? const LinearGradient(
                                    colors: [
                                      AppColors.primary,
                                      AppColors.pinkLight,
                                    ],
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                  )
                                : null,
                            color: (_step == 0 ? _intent != null : _struggle != null)
                                ? null
                                : AppColors.grey200,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Center(
                            child: Text(
                              _step == 0 ? 'Continue' : 'Show me books',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppColors.white,
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
          ),
        ),
        if (_loading)
          Container(
            color: AppColors.white.withValues(alpha: 0.95),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(
                    width: 48,
                    height: 48,
                    child: CircularProgressIndicator(
                      color: AppColors.primary,
                      strokeWidth: 3,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'AI is designing your\ngrowth plan...',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppColors.grey900,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
