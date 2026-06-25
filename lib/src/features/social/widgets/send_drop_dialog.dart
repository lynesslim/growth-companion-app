import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lottie/lottie.dart';
import 'package:confetti/confetti.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/app_colors.dart';
import '../../../domain/models/friend.dart';
import '../../../providers/social_provider.dart';
import '../../../providers/user_provider.dart';
import '../../../providers/journal_provider.dart';

class StreakCelebrationDialog extends StatefulWidget {
  final int streakCount;
  final String friendName;

  const StreakCelebrationDialog({
    super.key,
    required this.streakCount,
    required this.friendName,
  });

  @override
  State<StreakCelebrationDialog> createState() => _StreakCelebrationDialogState();
}

class _StreakCelebrationDialogState extends State<StreakCelebrationDialog> {
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
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
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      elevation: 16,
      backgroundColor: Colors.transparent,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          // The main card
          Container(
            width: 320,
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 10),
                // Lottie fire animation
                SizedBox(
                  width: 150,
                  height: 150,
                  child: Lottie.asset(
                    'assets/images/fire.json',
                    repeat: true,
                  ),
                ),
                const SizedBox(height: 16),
                // Cute title with flame
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [Color(0xFFF06A19), Color(0xFFF14545)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ).createShader(bounds),
                  child: Text(
                    'Streak Continued! 🔥',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Streak count banner
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF2EC),
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Text(
                    '${widget.streakCount}-Day Streak',
                    style: GoogleFonts.inter(
                      color: const Color(0xFFF06A19),
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'You and ${widget.friendName} shared a book today and kept the flame alive! 📚✨',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    color: AppColors.grey600,
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),
                // Cute button
                SizedBox(
                  width: double.infinity,
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFF06A19), Color(0xFFF14545)],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFF06A19).withOpacity(0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Text(
                          'Keep it up! 💪',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Confetti widget shooting outwards
          Positioned(
            top: -30,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              colors: const [
                Color(0xFFF06A19),
                Color(0xFFF14545),
                Color(0xFFFFB300),
                Colors.blue,
                Colors.pink,
              ],
              numberOfParticles: 30,
              maxBlastForce: 15,
              minBlastForce: 5,
              gravity: 0.15,
            ),
          ),
        ],
      ),
    );
  }
}

void showStreakCelebration(BuildContext context, int streakCount, String friendName) {
  showDialog(
    context: context,
    barrierDismissible: true,
    builder: (context) => StreakCelebrationDialog(
      streakCount: streakCount,
      friendName: friendName,
    ),
  );
}

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
                      final newStreak = await consumerRef.read(socialProvider.notifier).sendDrop(friendId);
                      if (newStreak != null && context.mounted) {
                        showStreakCelebration(context, newStreak, friendName);
                      }
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
                    _showJournalPicker(context, consumerRef, friendId, friendName);
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

void _showJournalPicker(BuildContext context, WidgetRef ref, String friendId, String friendName) {
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
                                    : AppColors.primaryLight.withOpacity(0.2),
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
                            onTap: alreadySent ? null : () async {
                              Navigator.pop(ctx);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Sending book...')),
                                );
                              }
                              try {
                                final newStreak = await ref.read(socialProvider.notifier).sendBookFromJournal(friendId, {
                                  'bookTitle': drop.bookTitle,
                                  'bookAuthor': drop.bookAuthor,
                                  'whatItsAbout': drop.whatItsAbout,
                                  'lessons': drop.lessons,
                                  'summary': drop.summary,
                                  if (drop.coverUrl != null) 'coverUrl': drop.coverUrl,
                                });
                                if (newStreak != null && context.mounted) {
                                  showStreakCelebration(context, newStreak, friendName);
                                } else {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Book sent!')),
                                    );
                                  }
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                    content: Text(e.toString()),
                                    backgroundColor: AppColors.error,
                                  ));
                                }
                              }
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
