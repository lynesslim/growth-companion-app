import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import '../../core/app_colors.dart';
import '../../core/app_typography.dart';
import '../../core/animated_widgets.dart';
import '../../domain/models/user.dart';
import '../../providers/social_provider.dart';

class FriendProfileScreen extends ConsumerStatefulWidget {
  final User profile;

  const FriendProfileScreen({super.key, required this.profile});

  @override
  ConsumerState<FriendProfileScreen> createState() => _FriendProfileScreenState();
}

class _FriendProfileScreenState extends ConsumerState<FriendProfileScreen> {
  int _booksRead = 0;
  bool _loadingBooks = true;

  @override
  void initState() {
    super.initState();
    _loadBooksCount();
  }

  Future<void> _loadBooksCount() async {
    try {
      final count = await Supabase.instance.client
          .rpc('count_user_drops', params: {'target_user_id': widget.profile.id});
      if (mounted) {
        setState(() {
          _booksRead = (count as num?)?.toInt() ?? 0;
          _loadingBooks = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingBooks = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final socialState = ref.watch(socialProvider).valueOrNull;

    final existingFriend = socialState?.acceptedFriends.where((f) =>
        f.userId1 == widget.profile.id || f.userId2 == widget.profile.id).firstOrNull;
    final pendingRequest = socialState?.pendingRequests.where((f) =>
        f.userId1 == widget.profile.id).firstOrNull;
    final outgoingRequest = socialState?.outgoingRequests.where((f) =>
        f.userId2 == widget.profile.id).firstOrNull;

    Widget? actionButton;
    if (existingFriend != null) {
      actionButton = OutlinedButton.icon(
        onPressed: () async {
          try {
            await ref.read(socialProvider.notifier).removeFriend(existingFriend.id);
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Friend removed')),
              );
            }
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Could not remove friend: $e')),
              );
            }
          }
        },
        icon: const Icon(Icons.person_remove_rounded, size: 18),
        label: const Text('Unfriend'),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.error,
          side: const BorderSide(color: AppColors.error),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      );
    } else if (pendingRequest != null) {
      actionButton = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ElevatedButton.icon(
            onPressed: () => ref.read(socialProvider.notifier).acceptFriendRequest(pendingRequest.id),
            icon: const Icon(Icons.check, size: 18),
            label: const Text('Accept'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
          const SizedBox(width: 12),
          OutlinedButton.icon(
            onPressed: () => ref.read(socialProvider.notifier).declineFriendRequest(pendingRequest.id),
            icon: const Icon(Icons.close, size: 18),
            label: const Text('Decline'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.grey600,
              side: const BorderSide(color: AppColors.grey300),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ],
      );
    } else if (outgoingRequest != null) {
      actionButton = Chip(
        avatar: const Icon(Icons.hourglass_empty_rounded, size: 16),
        label: const Text('Request Sent'),
        backgroundColor: AppColors.grey100,
      );
    } else {
      actionButton = ElevatedButton.icon(
        onPressed: () async {
          try {
            await ref.read(socialProvider.notifier).sendFriendRequest(widget.profile.id);
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Friend request sent to ${widget.profile.name}!')),
              );
            }
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Could not send request: $e')),
              );
            }
          }
        },
        icon: const Icon(Icons.person_add_rounded, size: 18),
        label: const Text('Add Friend'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.scaffoldGrey,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.grey900),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: [
            const SizedBox(height: 20),
            // Avatar with gradient
            EntranceFadeSlide(
              delayMs: 0,
              child: Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primaryLight, AppColors.pinkLight],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Center(
                  child: Text(
                    widget.profile.name[0].toUpperCase(),
                    style: const TextStyle(fontSize: 40, color: AppColors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            EntranceFadeSlide(
              delayMs: 50,
              child: Text(
                widget.profile.name,
                style: AppTypography.h1Playfair.copyWith(
                  fontSize: 28,
                  color: AppColors.grey900,
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Stats card
            EntranceFadeSlide(
              delayMs: 100,
              child: Container(
                width: double.infinity,
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
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _StatItem(icon: Icons.menu_book_rounded, label: 'Books', value: _loadingBooks ? '-' : '$_booksRead'),
                    _StatItem(icon: Icons.auto_awesome_rounded, label: 'Level', value: '${widget.profile.level}'),
                    _StatItem(icon: Icons.stars_rounded, label: 'XP', value: '${widget.profile.currentXp}'),
                    _StatItem(icon: Icons.local_fire_department_rounded, label: 'Streak', value: '${widget.profile.currentStreak}'),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Friend action button
            actionButton,
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatItem({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 22, color: AppColors.primary),
        const SizedBox(height: 8),
        Text(
          value,
          style: AppTypography.h1Playfair.copyWith(
            fontSize: 20,
            color: AppColors.grey900,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppColors.grey500, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}
