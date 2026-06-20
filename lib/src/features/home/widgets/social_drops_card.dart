import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/app_colors.dart';
import '../../../domain/models/growth_drop.dart';
import '../../../providers/social_provider.dart';

class SocialDropsCard extends ConsumerStatefulWidget {
  const SocialDropsCard({super.key});

  @override
  ConsumerState<SocialDropsCard> createState() => _SocialDropsCardState();
}

class _SocialDropsCardState extends ConsumerState<SocialDropsCard> {
  String? _openingDropId;

  Future<void> _openDrop(dynamic drop) async {
    if (drop.bookData != null) {
      ref.read(socialProvider.notifier).markDropOpened(drop.id);
      if (context.mounted) context.push('/book', extra: drop.bookData);
      return;
    }
    setState(() => _openingDropId = drop.id);
    try {
      final bookData = await ref.read(socialProvider.notifier).openBlindBox(drop.id);
      if (mounted) {
        setState(() => _openingDropId = null);
        context.push('/book', extra: GrowthDrop.fromJson({
          'id': drop.id,
          'date': drop.dropDate.toIso8601String(),
          'focusArea': 'Social Drop',
          'bookTitle': bookData['bookTitle'] ?? '',
          'bookAuthor': bookData['bookAuthor'] ?? '',
          'whatItsAbout': bookData['whatItsAbout'] ?? '',
          'lessons': bookData['lessons'] ?? [],
          'summary': bookData['summary'] ?? '',
          'isRead': true,
          'giftedBy': drop.senderProfile?.name,
        }));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _openingDropId = null);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
        ...unopened.take(2).map((drop) {
          final isOpening = _openingDropId == drop.id;
          return GestureDetector(
            onTap: () => _openDrop(drop),
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
                  isOpening
                      ? const SizedBox(
                          width: 42, height: 42,
                          child: Center(child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.white)))
                      : Container(
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
                          isOpening ? 'Generating...' : 'Tap to open your blind box',
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
          );
        }),
      ],
    );
  }
}
