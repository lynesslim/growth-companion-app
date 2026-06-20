import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/app_colors.dart';
import '../../providers/user_provider.dart';
import '../../providers/social_provider.dart';
import '../../domain/models/growth_drop.dart';

class StreakCompleteScreen extends ConsumerWidget {
  final GrowthDrop? book;

  const StreakCompleteScreen({super.key, this.book});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider).valueOrNull;
    final streak = user?.currentStreak ?? 0;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFF97316), Color(0xFFF59E0B)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(28),
                ),
                child: const Icon(Icons.local_fire_department_rounded,
                    color: AppColors.white, size: 48),
              ),
              const SizedBox(height: 32),
              Text(
                streak > 0 ? 'Day $streak' : 'Great start!',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 36,
                  fontWeight: FontWeight.w700,
                  color: AppColors.grey900,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                streak > 1
                    ? 'You\'re building an incredible habit.\nSee you tomorrow!'
                    : 'First book down!\nYou\'re on your way to an amazing habit.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  color: AppColors.grey500,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 48),
              if (book != null) ...[
                SizedBox(
                  width: double.infinity,
                  child: GestureDetector(
                    onTap: () => _showFriendPicker(context, ref, book!),
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
              ],
              SizedBox(
                width: double.infinity,
                child: GestureDetector(
                  onTap: () => context.go('/'),
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
    );
  }

  void _inviteViaWhatsApp(BuildContext context, GrowthDrop bookData) {
    Share.share('I just read "${bookData.bookTitle}" by ${bookData.bookAuthor} and it was amazing! Try the app and let\'s share books daily.');
  }

  void _showFriendPicker(BuildContext context, WidgetRef ref, GrowthDrop bookData) {
    final socialState = ref.read(socialProvider).valueOrNull;
    final friends = socialState?.acceptedFriends ?? [];

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
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppColors.primaryLight,
                          child: Text(friend.profile?.name[0].toUpperCase() ?? '?', style: const TextStyle(color: AppColors.white)),
                        ),
                        title: Text(friend.profile?.name ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.w600)),
                        trailing: const Icon(Icons.send_rounded, color: AppColors.primary),
                        onTap: () {
                          Navigator.pop(ctx);
                          ref.read(socialProvider.notifier).sendBookFromJournal(friendId, {
                            'bookTitle': bookData.bookTitle,
                            'bookAuthor': bookData.bookAuthor,
                            'whatItsAbout': bookData.whatItsAbout,
                            'lessons': bookData.lessons,
                            'summary': bookData.summary,
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
                    _inviteViaWhatsApp(context, bookData);
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
