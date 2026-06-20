import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/app_colors.dart';
import '../../../providers/social_provider.dart';

class SocialDropsCard extends ConsumerWidget {
  const SocialDropsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final socialState = ref.watch(socialProvider).valueOrNull;
    if (socialState == null) return const SizedBox.shrink();

    final unopened = socialState.receivedDrops.where((d) => !d.isOpened).toList();
    if (unopened.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.card_giftcard, size: 18, color: AppColors.primary),
            const SizedBox(width: 6),
            const Text(
              'Gifted for you',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.grey900,
              ),
            ),
            const Spacer(),
            GestureDetector(
              onTap: () => context.push('/social'),
              child: const Text(
                'See all',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...unopened.take(2).map((drop) => GestureDetector(
          onTap: () {
            ref.read(socialProvider.notifier).markDropOpened(drop.id);
            context.push('/book', extra: drop.bookData);
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
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
                  color: AppColors.primary.withValues(alpha: 0.2),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.card_giftcard, color: AppColors.white, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'From ${drop.senderProfile?.name ?? "A Friend"}',
                        style: const TextStyle(
                          color: AppColors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Tap to open your blind box',
                        style: TextStyle(
                          color: AppColors.white.withValues(alpha: 0.7),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: AppColors.white, size: 20),
              ],
            ),
          ),
        )),
      ],
    );
  }
}
