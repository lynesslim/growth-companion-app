import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supa;
import '../../../core/app_colors.dart';
import '../../../providers/growth_drop_provider.dart';
import '../../../providers/user_provider.dart';
import '../../../providers/weekly_goal_provider.dart';

class GrowthDropCard extends ConsumerStatefulWidget {
  const GrowthDropCard({super.key});

  @override
  ConsumerState<GrowthDropCard> createState() => _GrowthDropCardState();
}

class _GrowthDropCardState extends ConsumerState<GrowthDropCard> {
  bool _generating = false;

  Future<void> _generateToday() async {
    final goal = ref.read(currentWeeklyGoalProvider).valueOrNull;
    final user = ref.read(userProvider).valueOrNull;
    if (goal == null && user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Set a weekly focus first'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }
    setState(() => _generating = true);
    try {
      final body = <String, dynamic>{
        'user_id': user?.id ?? goal!.userId,
        'drop_date': DateTime.now().toIso8601String().split('T')[0],
      };
      if (user != null) {
        body['onboarding_profile'] = user.onboardingProfile;
      }
      await supa.Supabase.instance.client.functions.invoke(
        'generate-growth-drop',
        body: body,
      );
      if (mounted) {
        ref.invalidate(growthDropProvider);
        setState(() => _generating = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _generating = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to generate: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final drop = ref.watch(growthDropProvider);
    final goal = ref.watch(currentWeeklyGoalProvider);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.pinkLight],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Center(
                  child: Icon(
                    Icons.water_drop_rounded,
                    color: AppColors.white,
                    size: 22,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Today's Growth Drop",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.grey900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      drop.valueOrNull?.focusArea ?? '',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: AppColors.grey500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_generating)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 10),
                  Text(
                    'Generating...',
                    style: TextStyle(fontSize: 14, color: AppColors.grey500),
                  ),
                ],
              ),
            )
          else if (drop.valueOrNull != null) ...[
            Text(
              'Discover ${drop.valueOrNull!.bookTitle} tailored to your growth journey.',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: AppColors.grey600,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: GestureDetector(
                onTap: () => context.push('/book'),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primary, AppColors.pinkLight],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        drop.valueOrNull!.isRead ? 'Review Drop' : 'Start',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.white,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Icon(
                        drop.valueOrNull!.isRead
                            ? Icons.refresh_rounded
                            : Icons.arrow_forward_rounded,
                        color: AppColors.white,
                        size: 18,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ] else if (goal.valueOrNull != null) ...[
            const Text(
              'You have a weekly goal set. Generate today\'s personalised drop!',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: AppColors.grey600,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: GestureDetector(
                onTap: _generateToday,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primary, AppColors.pinkLight],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Generate Today's Drop",
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.white,
                        ),
                      ),
                      SizedBox(width: 6),
                      Icon(
                        Icons.auto_awesome_rounded,
                        color: AppColors.white,
                        size: 18,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ] else ...[
            const Text(
              'Ready for your next drop?',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: AppColors.grey600,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: GestureDetector(
                onTap: () => context.push('/weekly-focus'),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primary, AppColors.pinkLight],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Set Weekly Focus',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.white,
                        ),
                      ),
                      SizedBox(width: 6),
                      Icon(
                        Icons.arrow_forward_rounded,
                        color: AppColors.white,
                        size: 18,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
