import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/app_colors.dart';
import '../../domain/models/user.dart';
import '../../providers/social_provider.dart';

class FriendProfileScreen extends ConsumerWidget {
  final User profile;

  const FriendProfileScreen({super.key, required this.profile});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final socialState = ref.watch(socialProvider).valueOrNull;

    final existingFriend = socialState?.acceptedFriends.where((f) =>
        f.userId1 == profile.id || f.userId2 == profile.id).firstOrNull;
    final pendingRequest = socialState?.pendingRequests.where((f) =>
        f.userId1 == profile.id).firstOrNull;
    final outgoingRequest = socialState?.outgoingRequests.where((f) =>
        f.userId2 == profile.id).firstOrNull;

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
            await ref.read(socialProvider.notifier).sendFriendRequest(profile.id);
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Friend request sent to ${profile.name}!')),
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
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.grey900),
          onPressed: () => context.pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: [
            const SizedBox(height: 20),
            CircleAvatar(
              radius: 48,
              backgroundColor: AppColors.primaryLight,
              child: Text(
                profile.name[0].toUpperCase(),
                style: const TextStyle(fontSize: 36, color: AppColors.white, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              profile.name,
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.grey900),
            ),
            const SizedBox(height: 8),
            Text(
              'Level ${profile.level} \u2022 ${profile.currentXp} XP',
              style: const TextStyle(fontSize: 16, color: AppColors.grey500),
            ),
            const SizedBox(height: 32),
            actionButton,
          ],
        ),
      ),
    );
  }
}
