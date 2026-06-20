import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/app_colors.dart';
import '../../../providers/quests_provider.dart';

class QuestLogCard extends ConsumerWidget {
  const QuestLogCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final questsAsync = ref.watch(dailyQuestsProvider);
    final quests = questsAsync.valueOrNull ?? [];
    final completed = quests.where((q) => q.isCompleted).length;
    final total = quests.length;
    final progress = total > 0 ? completed / total : 0.0;

    return GestureDetector(
      onTap: () => context.push('/quest/1'),
      child: Container(
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
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.terrain_rounded,
                      color: AppColors.primary,
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
                        'Quest Log',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.grey900,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$completed of $total quests completed',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                          color: AppColors.grey500,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.grey400,
                  size: 24,
                ),
              ],
            ),
            if (total > 0) ...[
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 6,
                  backgroundColor: AppColors.grey100,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  '${(progress * 100).toInt()}% complete',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.grey500,
                  ),
                ),
              ),
            ] else
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Read your daily book drop to discover and add new micro-actions.',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: AppColors.grey500,
                    height: 1.4,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
