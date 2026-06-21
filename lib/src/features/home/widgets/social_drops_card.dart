import 'dart:math' show pi;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/app_colors.dart';
import '../../../core/app_gradients.dart';
import '../../../core/app_typography.dart';
import '../../../core/animated_widgets.dart';
import '../../../domain/models/growth_drop.dart';
import '../../../providers/social_provider.dart';

class SocialDropsCard extends ConsumerStatefulWidget {
  const SocialDropsCard({super.key});

  @override
  ConsumerState<SocialDropsCard> createState() => _SocialDropsCardState();
}

class _SocialDropsCardState extends ConsumerState<SocialDropsCard> {
  Future<void> _openDrop(dynamic drop) async {
    if (drop.bookData != null) {
      ref.read(socialProvider.notifier).markDropOpened(drop.id);
      if (context.mounted) context.push('/book', extra: drop.bookData);
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        contentPadding: const EdgeInsets.all(32),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('\u{1F4E6}', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 24),
            const CircularProgressIndicator(color: AppColors.primary),
            const SizedBox(height: 24),
            Text('Unpacking drop from ${drop.senderProfile?.name ?? 'a friend'}...',
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
          ],
        ),
      ),
    );

    try {
      final bookData = await ref.read(socialProvider.notifier).openBlindBox(drop.id);
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();

        final parsedLessons = (bookData['lessons'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];

        context.push('/book', extra: GrowthDrop.fromJson({
          'id': drop.id,
          'date': drop.dropDate.toIso8601String(),
          'focusArea': 'Social Drop',
          'bookTitle': bookData['bookTitle'] ?? '',
          'bookAuthor': bookData['bookAuthor'] ?? '',
          'whatItsAbout': bookData['whatItsAbout'] ?? '',
          'lessons': parsedLessons,
          'summary': bookData['summary'] ?? '',
          'isRead': true,
          'giftedBy': drop.senderProfile?.name,
        }));
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
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
        EntranceFadeSlide(
          delayMs: 500,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'From your friends',
                style: AppTypography.h2Inter.copyWith(color: AppColors.textPrimary),
              ),
              GestureDetector(
                onTap: () => context.push('/social'),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(18),
                  ),
                    child: Text(
                      'See all \u203A',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        EntranceFadeSlide(
          delayMs: 600,
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: drops.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 1.25,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemBuilder: (_, i) => _FriendGiftCard(
              drop: drops[i],
              colorIndex: i % 4,
              onTap: () => _openDrop(drops[i]),
            ),
          ),
        ),
      ],
    );
  }
}

class _FriendGiftCard extends StatefulWidget {
  final dynamic drop;
  final int colorIndex;
  final VoidCallback onTap;

  const _FriendGiftCard({
    required this.drop,
    required this.colorIndex,
    required this.onTap,
  });

  @override
  State<_FriendGiftCard> createState() => _FriendGiftCardState();
}

class _FriendGiftCardState extends State<_FriendGiftCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scaleAnim;
  late Animation<double> _rotateAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 120));
    _scaleAnim = Tween(begin: 1.0, end: 0.98).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );
    _rotateAnim = Tween(begin: 0.0, end: -3 * (pi / 180)).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails _) => _ctrl.forward();
  void _onTapUp(TapUpDetails _) => _ctrl.reverse();
  void _onTapCancel() => _ctrl.reverse();

  @override
  Widget build(BuildContext context) {
    final gradients = [
      AppGradients.socialDropPurple,
      AppGradients.socialDropYellow,
      AppGradients.socialDropPeach,
      AppGradients.socialDropLavender,
    ];

    final colors = gradients[widget.colorIndex];
    final isPurple = widget.colorIndex == 0 || widget.colorIndex == 3;
    final giftAsset = isPurple ? 'assets/images/purple_gift.webp' : 'assets/images/yellow_gift.webp';

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, child) => Transform.scale(
          scale: _scaleAnim.value,
          child: child,
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: colors,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 11,
                          backgroundColor: Colors.white.withValues(alpha: 0.4),
                          child: Text(
                            widget.drop.senderProfile?.name?[0].toUpperCase() ?? '?',
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'A gift from ${widget.drop.senderProfile?.name ?? "Friend"}',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Padding(
                      padding: const EdgeInsets.only(right: 42),
                      child: SizedBox(
                        height: 48,
                        child: Align(
                          alignment: Alignment.bottomLeft,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                widget.drop.bookData?.bookTitle ?? 'A Blind Box',
                                style: GoogleFonts.inter(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                  height: 1.15,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (widget.drop.bookData?.bookAuthor != null) ...[
                                const SizedBox(height: 2),
                                Text(
                                  'by ${widget.drop.bookData.bookAuthor}',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: AppColors.textTertiary,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        'New drop',
                        style: AppTypography.captionInter.copyWith(fontSize: 9, color: AppColors.textPrimary),
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                bottom: 8,
                right: 8,
                child: AnimatedBuilder(
                  animation: _ctrl,
                  builder: (_, child) => Transform.rotate(
                    angle: _rotateAnim.value,
                    child: child,
                  ),
                  child: Image.asset(
                    giftAsset,
                    width: 56,
                    height: 56,
                    fit: BoxFit.contain,
                    color: Colors.white,
                    colorBlendMode: BlendMode.multiply,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
