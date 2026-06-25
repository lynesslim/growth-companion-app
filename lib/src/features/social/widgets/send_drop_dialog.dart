import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/app_colors.dart';
import '../../../domain/models/friend.dart';
import '../../../providers/social_provider.dart';
import '../../../providers/user_provider.dart';
import '../../../providers/journal_provider.dart';

// ponytail: shared utility for sending drops/books — tutorial step4 is in dashboard_shell
void showSendDropDialog(BuildContext context, WidgetRef ref, Friend friend) {
  final friendId = friend.userId1 == ref.read(userProvider).valueOrNull?.id ? friend.userId2 : friend.userId1;
  final friendName = friend.profile?.name ?? 'Friend';

  showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) => Consumer(
      builder: (_, consumerRef, __) {
        final socialState = consumerRef.watch(socialProvider).valueOrNull;
        final isAdmin = socialState?.isAdmin ?? false;
        final alreadySent = (socialState?.sentTodayFriendIds.contains(friendId) ?? false) && !isAdmin;

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.grey300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                Text('Send to $friendName', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.grey900)),
                const SizedBox(height: 24),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.card_giftcard, color: alreadySent ? AppColors.grey400 : AppColors.primary),
                  ),
                  title: Text('Send Blind Box (AI)', style: TextStyle(color: alreadySent ? AppColors.grey400 : null)),
                  subtitle: Text(
                    alreadySent ? 'Already sent today' : 'AI generates a book based on their goals',
                    style: TextStyle(color: alreadySent ? AppColors.grey400 : AppColors.grey600),
                  ),
                  enabled: !alreadySent,
                  onTap: alreadySent ? null : () async {
                    Navigator.pop(ctx);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Generating and sending...')));
                    }
                    try {
                      await consumerRef.read(socialProvider.notifier).sendDrop(friendId);
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text(e.toString().replaceAll('Exception: ', '')),
                          backgroundColor: AppColors.error,
                        ));
                      }
                    }
                  },
                ),
                const Divider(),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.menu_book_rounded, color: alreadySent ? AppColors.grey400 : AppColors.primary),
                  ),
                  title: Text('Send from Journal', style: TextStyle(color: alreadySent ? AppColors.grey400 : null)),
                  subtitle: Text(
                    alreadySent ? 'Already sent today' : "Choose a book you've read",
                    style: TextStyle(color: alreadySent ? AppColors.grey400 : AppColors.grey600),
                  ),
                  enabled: !alreadySent,
                  onTap: alreadySent ? null : () {
                    Navigator.pop(ctx);
                    _showJournalPicker(context, consumerRef, friendId);
                  },
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    ),
  );
}

void _showJournalPicker(BuildContext context, WidgetRef ref, String friendId) {
  final socialState = ref.read(socialProvider).valueOrNull;
  final isAdmin = socialState?.isAdmin ?? false;
  final alreadySent = (socialState?.sentTodayFriendIds.contains(friendId) ?? false) && !isAdmin;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) => DraggableScrollableSheet(
      initialChildSize: 0.6,
      maxChildSize: 0.85,
      minChildSize: 0.3,
      expand: false,
      builder: (_, scrollController) => Padding(
        padding: const EdgeInsets.all(24),
        child: Consumer(
          builder: (context, ref, child) {
            final journalState = ref.watch(journalProvider);
            
            return Column(
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
                const Text('Choose a Book to Send', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.grey900)),
                const SizedBox(height: 16),
                Expanded(
                  child: journalState.when(
                    data: (journalDrops) {
                      if (journalDrops.isEmpty) {
                        return const Center(child: Text('No books in your journal yet.', style: TextStyle(color: AppColors.grey500)));
                      }
                      return ListView.separated(
                        controller: scrollController,
                        itemCount: journalDrops.length,
                        separatorBuilder: (_, _) => const Divider(),
                        itemBuilder: (_, i) {
                          final drop = journalDrops[i];
                          return ListTile(
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: alreadySent
                                    ? AppColors.grey200
                                    : AppColors.primaryLight.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(Icons.menu_book_rounded,
                                  color: alreadySent ? AppColors.grey400 : AppColors.primary, size: 20),
                            ),
                            title: Text(drop.bookTitle,
                                style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: alreadySent ? AppColors.grey400 : null)),
                            subtitle: Text(drop.bookAuthor,
                                style: TextStyle(
                                    color: alreadySent ? AppColors.grey400 : AppColors.grey500)),
                            enabled: !alreadySent,
                            onTap: alreadySent ? null : () {
                              Navigator.pop(ctx);
                              ref.read(socialProvider.notifier).sendBookFromJournal(friendId, {
                                'bookTitle': drop.bookTitle,
                                'bookAuthor': drop.bookAuthor,
                                'whatItsAbout': drop.whatItsAbout,
                                'lessons': drop.lessons,
                                'summary': drop.summary,
                                if (drop.coverUrl != null) 'coverUrl': drop.coverUrl,
                              });
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Book sent!')),
                              );
                            },
                          );
                        },
                      );
                    },
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (err, stack) => const Center(child: Text('Error loading journal')),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    ),
  );
}


