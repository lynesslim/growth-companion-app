import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/app_colors.dart';
import '../../utils/haptic_utils.dart';
import '../../providers/growth_drop_provider.dart';

class GrowthDropScreen extends ConsumerWidget {
  const GrowthDropScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final drop = ref.watch(growthDropProvider).valueOrNull;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () => context.pop(),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.06),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.arrow_back_rounded,
                    color: AppColors.grey700,
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.pinkLight],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.water_drop_rounded,
                        color: AppColors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "Today's Growth Drop",
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: AppColors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      drop?.focusArea ?? '',
                      style: const TextStyle(
                        fontSize: 15,
                        color: AppColors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              _SectionCard(
                icon: Icons.person_rounded,
                title: 'Why this book for you',
                content: drop?.whyThisBook ?? '',
              ),
              const SizedBox(height: 16),
              _SectionCard(
                icon: Icons.menu_book_rounded,
                title: 'What it\'s about',
                content: drop?.whatItsAbout ?? '',
              ),
              const SizedBox(height: 16),
              const Text(
                'Three lessons for you',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.grey900,
                ),
              ),
              const SizedBox(height: 12),
              _LessonCard(
                number: 1,
                title: (drop?.lessons ?? []).isNotEmpty ? _extractTitle((drop?.lessons ?? [])[0]) : '',
                description: (drop?.lessons ?? []).isNotEmpty ? (drop?.lessons ?? [])[0] : '',
              ),
              const SizedBox(height: 10),
              _LessonCard(
                number: 2,
                title: (drop?.lessons ?? []).length > 1 ? _extractTitle((drop?.lessons ?? [])[1]) : '',
                description: (drop?.lessons ?? []).length > 1 ? (drop?.lessons ?? [])[1] : '',
              ),
              const SizedBox(height: 10),
              _LessonCard(
                number: 3,
                title: (drop?.lessons ?? []).length > 2 ? _extractTitle((drop?.lessons ?? [])[2]) : '',
                description: (drop?.lessons ?? []).length > 2 ? (drop?.lessons ?? [])[2] : '',
              ),
              const SizedBox(height: 20),
              _SectionCard(
                icon: Icons.bookmark_rounded,
                title: 'Chapter to read first',
                content: drop?.firstChapter ?? '',
              ),
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary.withValues(alpha: 0.05),
                      AppColors.pinkLight.withValues(alpha: 0.05),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.1),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.track_changes_rounded,
                          color: AppColors.primary,
                          size: 22,
                        ),
                        SizedBox(width: 10),
                        Text(
                          "Today's Action",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.grey900,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      drop?.dailyAction ?? '',
                      style: const TextStyle(
                        fontSize: 14,
                        height: 1.5,
                        color: AppColors.grey600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.timer_outlined,
                          color: AppColors.grey400,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          drop?.dailyActionDuration ?? '',
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.grey500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: GestureDetector(
                        onTap: () {
                          HapticUtils.success();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Action added to your quest log!'),
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.all(Radius.circular(12)),
                              ),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                AppColors.primary,
                                AppColors.pinkLight,
                              ],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Center(
                            child: Text(
                              'Add to Today\'s Quests',
                              style: TextStyle(
                                fontSize: 15,
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
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: GestureDetector(
                  onTap: () {
                    HapticUtils.medium();
                    context.push('/book/0');
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.primary, AppColors.pinkLight],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.3),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.menu_book_rounded,
                            color: AppColors.white, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Open Interactive Book',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  String _extractTitle(String lesson) {
    final parts = lesson.split(' — ');
    return parts.isNotEmpty ? parts[0] : lesson;
  }
}

class _SectionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String content;

  const _SectionCard({
    required this.icon,
    required this.title,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.grey900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            content,
            style: const TextStyle(
              fontSize: 14,
              height: 1.5,
              color: AppColors.grey600,
            ),
          ),
        ],
      ),
    );
  }
}

class _LessonCard extends StatelessWidget {
  final int number;
  final String title;
  final String description;

  const _LessonCard({
    required this.number,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.grey100),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                '$number',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.grey900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.4,
                    color: AppColors.grey500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
