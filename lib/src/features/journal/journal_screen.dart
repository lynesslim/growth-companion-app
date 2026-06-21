import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/app_colors.dart';
import '../../core/app_typography.dart';
import '../../core/animated_widgets.dart';
import '../../providers/journal_provider.dart';
import '../../domain/models/growth_drop.dart';

class JournalScreen extends ConsumerWidget {
  const JournalScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dropsAsync = ref.watch(journalProvider);

    return Scaffold(
      backgroundColor: AppColors.scaffoldGrey,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            EntranceFadeSlide(
              delayMs: 0,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                child: Text(
                  'Your Library',
                  style: AppTypography.h1Playfair.copyWith(
                    fontSize: 28,
                    color: AppColors.grey900,
                  ),
                ),
              ),
            ),
            Expanded(
              child: dropsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Something went wrong: $e')),
                data: (drops) {
                  if (drops.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Icon(
                              Icons.auto_stories_rounded,
                              color: AppColors.primary,
                              size: 36,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'Your Library',
                            style: AppTypography.h1Playfair.copyWith(
                              fontSize: 24,
                              fontWeight: FontWeight.w600,
                              color: AppColors.grey900,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Your daily growth drops will appear here.',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.grey500,
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    child: GridView.builder(
                      itemCount: drops.length,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.7,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                      ),
                      itemBuilder: (context, index) =>
                          _BookCoverCard(drop: drops[index]),
                    ),
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

class _BookCoverCard extends StatelessWidget {
  final GrowthDrop drop;

  const _BookCoverCard({required this.drop});

  @override
  Widget build(BuildContext context) {
    return CardPress(
      onTap: () => context.push('/book', extra: drop),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.primary, AppColors.pinkLight],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.25),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.menu_book_rounded,
                  color: AppColors.white, size: 20),
            ),
            const Spacer(),
            Text(
              drop.focusArea,
              style: TextStyle(
                fontSize: 11,
                color: AppColors.white.withValues(alpha: 0.8),
                fontWeight: FontWeight.w500,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              drop.bookTitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.h1Playfair.copyWith(
                fontSize: 16,
                color: AppColors.white,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              drop.bookAuthor,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                color: AppColors.white.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              drop.date.toIso8601String().split('T')[0],
              style: TextStyle(
                fontSize: 10,
                color: AppColors.white.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
