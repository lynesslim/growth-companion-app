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

    final drops = socialState.receivedDrops.where((d) => !d.isOpened).toList();
    if (drops.isEmpty) return const SizedBox.shrink();

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
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: drops.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.75,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemBuilder: (_, i) => _buildGridItem(drops[i]),
        ),
      ],
    );
  }

  Widget _buildGridItem(dynamic drop) {
    final isOpening = _openingDropId == drop.id;

    if (drop.bookData != null) {
      // Book cover style
      return GestureDetector(
        onTap: () => _openDrop(drop),
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
                color: AppColors.primary.withValues(alpha: 0.2),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Spacer(),
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: AppColors.white.withValues(alpha: 0.3),
                    child: Text(
                      drop.senderProfile?.name[0].toUpperCase() ?? '?',
                      style: const TextStyle(color: AppColors.white, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Text(
                drop.bookData.bookTitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                drop.bookData.bookAuthor,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppColors.white.withValues(alpha: 0.7),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Blind box style
    return GestureDetector(
      onTap: () => _openDrop(drop),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.primaryLight.withValues(alpha: 0.3)),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isOpening)
              const CircularProgressIndicator(strokeWidth: 2)
            else
              const Text('\u{1F4E6}', style: TextStyle(fontSize: 40)),
            const SizedBox(height: 12),
            Text(
              'From ${drop.senderProfile?.name ?? "A Friend"}',
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.grey700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
