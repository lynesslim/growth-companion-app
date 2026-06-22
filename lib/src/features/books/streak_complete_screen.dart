import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:confetti/confetti.dart';
import '../../core/app_colors.dart';
import '../../core/app_typography.dart';
import '../../providers/user_provider.dart';
import '../../providers/social_provider.dart';
import '../../providers/growth_drop_provider.dart';
import '../../domain/models/growth_drop.dart';

class StreakCompleteScreen extends ConsumerStatefulWidget {
  final GrowthDrop? book;

  const StreakCompleteScreen({super.key, this.book});

  @override
  ConsumerState<StreakCompleteScreen> createState() => _StreakCompleteScreenState();
}

class _StreakCompleteScreenState extends ConsumerState<StreakCompleteScreen> {
  late ConfettiController _confettiController;
  bool _isSaved = false;

  @override
  void initState() {
    super.initState();
    _isSaved = widget.book?.isSaved ?? false;
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
    _confettiController.play();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProvider).valueOrNull;
    final streak = user?.currentStreak ?? 0;
    final isSocialDrop = widget.book?.giftedBy != null;

    return Scaffold(
      body: Stack(
        children: [
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      gradient: isSocialDrop
                          ? const LinearGradient(
                              colors: [AppColors.primary, AppColors.pinkLight],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                          : const LinearGradient(
                              colors: [AppColors.xpInfluence, AppColors.warning],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: Icon(
                      isSocialDrop ? Icons.card_giftcard : Icons.local_fire_department_rounded,
                      color: AppColors.white, size: 48),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    isSocialDrop
                        ? 'Gift Unlocked!'
                        : streak > 0 ? 'Day $streak' : 'Streak Started!',
                    style: AppTypography.h1Playfair.copyWith(
                      fontSize: 36,
                      color: AppColors.grey900,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    isSocialDrop
                        ? 'You\'ve unpacked a blind box from your friend.'
                        : 'You\'re building an incredible habit.\nSee you tomorrow!',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 16,
                      color: AppColors.grey500,
                      height: 1.6,
                    ),
                  ),
              const SizedBox(height: 48),
              if (widget.book != null) ...[
                SizedBox(
                  width: double.infinity,
                  child: GestureDetector(
                    onTap: () => _showFriendPicker(context, ref, widget.book!),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight.withOpacity(0.1),
                        border: Border.all(color: AppColors.primaryLight.withOpacity(0.3)),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.send_rounded, color: AppColors.primary, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Share Book with Friend',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                if (widget.book!.giftedBy != null) const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: GestureDetector(
                    onTap: _isSaved ? null : () => _saveToJournal(context, widget.book!),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: _isSaved ? AppColors.grey200 : AppColors.primary.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _isSaved ? Colors.transparent : AppColors.primary.withOpacity(0.2),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _isSaved ? Icons.bookmark_added_rounded : Icons.bookmark_add_rounded,
                            size: 18,
                            color: _isSaved ? AppColors.grey500 : AppColors.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _isSaved ? 'Saved to Journal' : 'Save to my Journal',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: _isSaved ? AppColors.grey500 : AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              SizedBox(
                width: double.infinity,
                child: GestureDetector(
                  onTap: () async {
                    (await SharedPreferences.getInstance()).setBool('_pendingStreakComplete', true);
                    if (context.mounted) context.go('/');
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
                    ),
                    child: const Center(
                      child: Text(
                        'Return to Home',
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
            ],
          ),
        ),
      ),
      Align(
        alignment: Alignment.topCenter,
        child: ConfettiWidget(
          confettiController: _confettiController,
          blastDirectionality: BlastDirectionality.explosive,
          shouldLoop: false,
          colors: const [
            AppColors.primary,
            AppColors.pinkLight,
            AppColors.xpInfluence,
            AppColors.warning,
            Colors.white,
          ],
          numberOfParticles: 20,
          maxBlastForce: 20,
          minBlastForce: 5,
          gravity: 0.1,
        ),
      ),
    ],
  ),
);
}

  Future<void> _saveToJournal(BuildContext context, GrowthDrop book) async {
    if (book.giftedBy == null) {
      // daily drop — just flip is_saved on the existing row
      await ref.read(growthDropProvider.notifier).saveToJournal();
      if (mounted) {
        setState(() => _isSaved = true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Saved to your journal!')),
        );
      }
      return;
    }
    // social drop — insert a new row
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;
    if (user == null) return;
    try {
      await supabase.from('growth_drops').insert({
        'user_id': user.id,
        'drop_date': DateTime.now().toIso8601String().split('T')[0],
        'focus_area': book.focusArea,
        'recommended_books': {
          'bookTitle': book.bookTitle,
          'bookAuthor': book.bookAuthor,
          'whatItsAbout': book.whatItsAbout,
          'lessons': book.lessons,
          'summary': book.summary,
          if (book.coverUrl != null) 'coverUrl': book.coverUrl,
        },
        'is_read': true,
        'is_saved': true,
      });
      if (mounted) {
        setState(() => _isSaved = true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Saved to your journal!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not save: $e')),
        );
      }
    }
  }

  void _inviteViaWhatsApp(BuildContext context, WidgetRef ref, GrowthDrop bookData) {
    final userId = ref.read(userProvider).valueOrNull?.id;
    final inviteLink = userId != null ? ' Join me here: ${Uri.base.origin}/#/invite?sender=$userId&drop_id=${bookData.id}' : '';
    final shareText = 'Look what I\'m learning on Growth Companion: $inviteLink';
    
    try {
      Share.share(shareText);
    } catch (_) {}
    
    Clipboard.setData(ClipboardData(text: shareText));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Share link copied to clipboard!')),
    );
  }

  void _showFriendPicker(BuildContext context, WidgetRef ref, GrowthDrop bookData) {
    final socialState = ref.read(socialProvider).valueOrNull;
    final friends = socialState?.acceptedFriends ?? [];
    final sentToday = socialState?.sentTodayFriendIds ?? const {};

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        maxChildSize: 0.85,
        minChildSize: 0.3,
        expand: false,
        builder: (_, scrollController) => Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.grey300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text('Send to a Friend', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.grey900)),
              const SizedBox(height: 16),
              if (friends.isEmpty)
                const Expanded(
                  child: Center(child: Text('Add friends in the Social tab to send books!', style: TextStyle(color: AppColors.grey500))),
                )
              else
                Expanded(
                  child: ListView.separated(
                    controller: scrollController,
                    itemCount: friends.length,
                    separatorBuilder: (_, _) => const Divider(),
                    itemBuilder: (_, i) {
                      final friend = friends[i];
                      final friendId = friend.userId1 == ref.read(userProvider).valueOrNull?.id ? friend.userId2 : friend.userId1;
                      final alreadySent = sentToday.contains(friendId);
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: alreadySent ? AppColors.grey200 : AppColors.primaryLight,
                          child: Text(friend.profile?.name[0].toUpperCase() ?? '?', style: TextStyle(color: alreadySent ? AppColors.grey400 : AppColors.white)),
                        ),
                        title: Text(friend.profile?.name ?? 'Unknown', style: TextStyle(fontWeight: FontWeight.w600, color: alreadySent ? AppColors.grey400 : null)),
                        trailing: Icon(alreadySent ? Icons.check_rounded : Icons.send_rounded, color: alreadySent ? AppColors.grey400 : AppColors.primary),
                        enabled: !alreadySent,
                        onTap: alreadySent ? null : () {
                          Navigator.pop(ctx);
                          ref.read(socialProvider.notifier).sendBookFromJournal(friendId, {
                            'bookTitle': bookData.bookTitle,
                            'bookAuthor': bookData.bookAuthor,
                            'whatItsAbout': bookData.whatItsAbout,
                            'lessons': bookData.lessons,
                            'summary': bookData.summary,
                            if (bookData.coverUrl != null) 'coverUrl': bookData.coverUrl,
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Book sent!')),
                          );
                        },
                      );
                    },
                  ),
                ),
              if (friends.isNotEmpty) const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _inviteViaWhatsApp(context, ref, bookData);
                  },
                  icon: const Icon(Icons.chat_rounded, size: 18),
                  label: const Text('Invite via WhatsApp'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primaryLight),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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
