import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/app_colors.dart';
import '../../core/app_gradients.dart';
import '../../core/app_typography.dart';
import '../../core/animated_widgets.dart';
import '../../domain/models/friend.dart';
import '../../domain/models/social_streak.dart';
import '../../providers/social_provider.dart';
import '../../providers/user_provider.dart';

final List<Color> _avatarColors = [
  const Color(0xFF9E82F0),
  const Color(0xFFF0A8D2),
  const Color(0xFFE882B8),
  const Color(0xFFE75B1B),
  const Color(0xFF6366F1),
  const Color(0xFF14B8A6),
  const Color(0xFFEC4899),
  const Color(0xFF8B5CF6),
];

Color _avatarColor(String name) => _avatarColors[name.hashCode % _avatarColors.length];

String _initials(String name) {
  final parts = name.trim().split(RegExp(r'\s+'));
  if (parts.length >= 2) return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  if (parts.length == 1 && parts.first.isNotEmpty) return parts.first[0].toUpperCase();
  return '?';
}

Widget _buildAvatar(double size, String name) {
  return Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: _avatarColor(name),
      shape: BoxShape.circle,
    ),
    child: Center(
      child: Text(
        _initials(name),
        style: TextStyle(
          color: Colors.white,
          fontSize: size * 0.38,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
  );
}

Widget _buildGradientAvatarRing(double size, String name, {double borderWidth = 3}) {
  return Container(
    width: size + borderWidth * 2 + 4,
    height: size + borderWidth * 2 + 4,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      gradient: AppGradients.avatarRing,
    ),
    padding: const EdgeInsets.all(3),
    child: Container(
      decoration: const BoxDecoration(
        color: AppColors.white,
        shape: BoxShape.circle,
      ),
      padding: const EdgeInsets.all(2),
      child: _buildAvatar(size, name),
    ),
  );
}

Widget _streakBadge(int count) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.08),
          blurRadius: 4,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('🔥', style: TextStyle(fontSize: 11)),
        const SizedBox(width: 2),
        Text(
          '$count',
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: AppColors.black,
          ),
        ),
      ],
    ),
  );
}

class FriendsScreen extends ConsumerWidget {
  const FriendsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final socialStateAsync = ref.watch(socialProvider);
    final userStateAsync = ref.watch(userProvider);

    return Scaffold(
      backgroundColor: AppColors.scaffoldGrey,
      body: socialStateAsync.when(
        data: (socialState) {
          final userId = userStateAsync.valueOrNull?.id;
          final currentUserName = userStateAsync.valueOrNull?.name ?? 'You';
          return _FriendsBody(
            userId: userId,
            currentUserName: currentUserName,
            socialState: socialState,
          );
        },
        error: (e, _) => Center(child: Text('Error: $e')),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
    );
  }
}

class _FriendsBody extends StatelessWidget {
  final String? userId;
  final String currentUserName;
  final SocialState socialState;

  const _FriendsBody({
    required this.userId,
    required this.currentUserName,
    required this.socialState,
  });

  Friend? get _topStreakFriend {
    if (userId == null || socialState.acceptedFriends.isEmpty) return null;
    Friend? best;
    int bestStreak = -1;
    for (final f in socialState.acceptedFriends) {
      final fid = f.userId1 == userId ? f.userId2 : f.userId1;
      final s = socialState.streaks.firstWhere(
        (s) => (s.userId1 == userId && s.userId2 == fid) || (s.userId1 == fid && s.userId2 == userId),
        orElse: () => SocialStreak(id: '', userId1: userId!, userId2: fid, currentStreak: 0),
      );
      if (s.effectiveStreak > bestStreak) {
        bestStreak = s.effectiveStreak;
        best = f;
      }
    }
    return best;
  }

  int _streakForFriend(Friend f) {
    if (userId == null) return 0;
    final fid = f.userId1 == userId ? f.userId2 : f.userId1;
    final s = socialState.streaks.firstWhere(
      (s) => (s.userId1 == userId && s.userId2 == fid) || (s.userId1 == fid && s.userId2 == userId),
      orElse: () => SocialStreak(id: '', userId1: userId!, userId2: fid, currentStreak: 0),
    );
    return s.effectiveStreak;
  }

  @override
  Widget build(BuildContext context) {
    final topFriend = _topStreakFriend;
    final topStreak = topFriend != null ? _streakForFriend(topFriend) : 0;

    return Stack(
      children: [
        Positioned(
          top: -80,
          right: -40,
          child: Container(
            width: 280,
            height: 280,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  const Color(0xFFFFE8F0).withValues(alpha: 0.6),
                  const Color(0xFFE8D5FF).withValues(alpha: 0.3),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        ListView(
          padding: const EdgeInsets.only(left: 24, right: 24, top: 60, bottom: 100),
          children: [
            EntranceFadeSlide(
              delayMs: 0,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        RichText(
                          text: TextSpan(
                            style: AppTypography.h1Playfair.copyWith(fontSize: 34, fontWeight: FontWeight.w700),
                            children: [
                              TextSpan(
                                text: 'Friends ',
                                style: const TextStyle(color: AppColors.black),
                              ),
                              TextSpan(
                                text: '& Streaks',
                                style: TextStyle(
                                  foreground: Paint()..shader = AppGradients.friendsHeaderText.createShader(const Rect.fromLTWH(0, 0, 200, 40)),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Grow better, together. 💜',
                          style: AppTypography.bodyInter.copyWith(fontSize: 14, color: AppColors.midGrey),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  EntranceFadeSlide(
                    delayMs: 100,
                    child: PressScale(
                      onTap: () => context.push('/invite'),
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          gradient: AppGradients.addFriendButton,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF8A4FFF).withValues(alpha: 0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.person_add, color: AppColors.white, size: 22),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            EntranceFadeSlide(
              delayMs: 100,
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(50),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const TextField(
                  decoration: InputDecoration(
                    hintText: 'Search by name or email...',
                    hintStyle: TextStyle(color: AppColors.grey400, fontSize: 15),
                    prefixIcon: Icon(Icons.search, color: AppColors.grey400, size: 22),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
            EntranceFadeSlide(
              delayMs: 200,
              child: _ClosestStreaksSection(
                userId: userId,
                friends: socialState.acceptedFriends,
                streaks: socialState.streaks,
              ),
            ),
            const SizedBox(height: 32),
            if (topFriend != null)
              EntranceFadeSlide(
                delayMs: 300,
                child: _HighlightCard(
                  currentUserName: currentUserName,
                  friend: topFriend,
                  streakCount: topStreak,
                ),
              ),
            if (topFriend != null) const SizedBox(height: 32),
            EntranceFadeSlide(
              delayMs: 400,
              child: _AllFriendsSection(
                userId: userId,
                friends: socialState.acceptedFriends,
                streaks: socialState.streaks,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ClosestStreaksSection extends StatelessWidget {
  final String? userId;
  final List<Friend> friends;
  final List<SocialStreak> streaks;

  const _ClosestStreaksSection({
    required this.userId,
    required this.friends,
    required this.streaks,
  });

  int _streakForFriend(Friend f) {
    if (userId == null) return 0;
    final fid = f.userId1 == userId ? f.userId2 : f.userId1;
    final s = streaks.firstWhere(
      (s) => (s.userId1 == userId && s.userId2 == fid) || (s.userId1 == fid && s.userId2 == userId),
      orElse: () => SocialStreak(id: '', userId1: userId!, userId2: fid, currentStreak: 0),
    );
    return s.effectiveStreak;
  }

  @override
  Widget build(BuildContext context) {
    final sorted = List<Friend>.from(friends)
      ..sort((a, b) => _streakForFriend(b).compareTo(_streakForFriend(a)));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Your closest streaks',
              style: AppTypography.h2Inter.copyWith(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.black),
            ),
            GestureDetector(
              onTap: () {},
              child: Text(
                'View all >',
                style: AppTypography.bodyInter.copyWith(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.purplePrimary),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 100,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: sorted.length + 1,
            separatorBuilder: (_, _) => const SizedBox(width: 16),
            itemBuilder: (context, index) {
              if (index == sorted.length) return _ViewAllItem();
              final f = sorted[index];
              final friendName = f.profile?.name ?? 'Friend';
              final streak = _streakForFriend(f);
              return _StreakAvatarItem(name: friendName, streak: streak);
            },
          ),
        ),
      ],
    );
  }
}

class _StreakAvatarItem extends StatelessWidget {
  final String name;
  final int streak;

  const _StreakAvatarItem({required this.name, required this.streak});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 72,
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              _buildGradientAvatarRing(52, name),
              if (streak > 0)
                Positioned(
                  bottom: -6,
                  left: 0,
                  right: 0,
                  child: Center(child: _streakBadge(streak)),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            name.split(' ').first,
            style: AppTypography.bodyInter.copyWith(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.black),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _ViewAllItem extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 72,
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(
              color: AppColors.paleLavender,
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Icon(Icons.people_rounded, color: AppColors.purplePrimary, size: 28),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'View all',
            style: AppTypography.bodyInter.copyWith(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.black),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _HighlightCard extends StatelessWidget {
  final String currentUserName;
  final Friend friend;
  final int streakCount;

  const _HighlightCard({
    required this.currentUserName,
    required this.friend,
    required this.streakCount,
  });

  @override
  Widget build(BuildContext context) {
    final friendName = friend.profile?.name ?? 'Friend';

    return Container(
      decoration: BoxDecoration(
        gradient: AppGradients.highlightCardBg,
        borderRadius: BorderRadius.circular(24),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SizedBox(
                width: 80,
                height: 56,
                child: Stack(
                  children: [
                    Positioned(
                      left: 0,
                      top: 4,
                      child: _buildAvatar(40, currentUserName),
                    ),
                    Positioned(
                      left: 24,
                      top: 0,
                      child: _buildGradientAvatarRing(44, friendName, borderWidth: 2.5),
                    ),
                    if (streakCount > 0)
                      Positioned(
                        right: 8,
                        bottom: 0,
                        child: _streakBadge(streakCount),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'You and ${friendName.split(' ').first} are on a',
                      style: AppTypography.bodyInter.copyWith(fontSize: 14, color: AppColors.black),
                    ),
                    RichText(
                      text: TextSpan(
                        style: AppTypography.h2Inter.copyWith(fontSize: 22, fontWeight: FontWeight.bold),
                        children: [
                          TextSpan(
                            text: '$streakCount-day',
                            style: TextStyle(
                              foreground: Paint()..shader = AppGradients.friendsHeaderText.createShader(const Rect.fromLTWH(0, 0, 150, 30)),
                            ),
                          ),
                          TextSpan(
                            text: ' streak 🔥',
                            style: const TextStyle(color: AppColors.black),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      'Keep inspiring each other.',
                      style: AppTypography.bodyInter.copyWith(fontSize: 13, color: AppColors.midGrey),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 100,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    image: const DecorationImage(
                      image: AssetImage('assets/images/3d_friends_illustration.webp'),
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: AppGradients.ctaButton,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(24),
                        onTap: () {},
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Expanded(
                                child: Text(
                                  "Send today's Growth Drop",
                                  style: AppTypography.bodyInter.copyWith(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.white),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const Icon(Icons.chevron_right, color: AppColors.white, size: 20),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AllFriendsSection extends StatelessWidget {
  final String? userId;
  final List<Friend> friends;
  final List<SocialStreak> streaks;

  const _AllFriendsSection({
    required this.userId,
    required this.friends,
    required this.streaks,
  });

  int _streakForFriend(Friend f) {
    if (userId == null) return 0;
    final fid = f.userId1 == userId ? f.userId2 : f.userId1;
    final s = streaks.firstWhere(
      (s) => (s.userId1 == userId && s.userId2 == fid) || (s.userId1 == fid && s.userId2 == userId),
      orElse: () => SocialStreak(id: '', userId1: userId!, userId2: fid, currentStreak: 0),
    );
    return s.effectiveStreak;
  }

  @override
  Widget build(BuildContext context) {
    final sorted = List<Friend>.from(friends)
      ..sort((a, b) => _streakForFriend(b).compareTo(_streakForFriend(a)));

    if (sorted.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'All friends',
            style: AppTypography.h2Inter.copyWith(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.black),
          ),
          const SizedBox(height: 24),
          Center(
            child: Column(
              children: [
                const Icon(Icons.people_outline, size: 48, color: AppColors.grey300),
                const SizedBox(height: 12),
                Text(
                  'No friends yet — invite someone to start your streak!',
                  style: AppTypography.bodyInter.copyWith(fontSize: 14, color: AppColors.midGrey),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'All friends',
              style: AppTypography.h2Inter.copyWith(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.black),
            ),
            Text(
              'Sort: Streak (High to Low) v',
              style: AppTypography.bodyInter.copyWith(fontSize: 13, color: AppColors.midGrey),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: Container(
            decoration: const BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: sorted.length,
              separatorBuilder: (_, _) => const Divider(height: 1, color: AppColors.grey100),
              itemBuilder: (context, index) {
                final f = sorted[index];
                final friendName = f.profile?.name ?? 'Friend';
                final streak = _streakForFriend(f);
                return _FriendTile(
                  name: friendName,
                  streak: streak,
                  hasStreak: streak > 0,
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _FriendTile extends StatelessWidget {
  final String name;
  final int streak;
  final bool hasStreak;

  const _FriendTile({
    required this.name,
    required this.streak,
    required this.hasStreak,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              _buildAvatar(48, name),
              if (hasStreak)
                Positioned(
                  bottom: -2,
                  right: -2,
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: const BoxDecoration(
                      color: AppColors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Text('🔥', style: TextStyle(fontSize: 12)),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: AppTypography.bodyInter.copyWith(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.black),
                ),
                const SizedBox(height: 2),
                Text(
                  hasStreak ? '$streak-day streak' : 'No streak yet',
                  style: AppTypography.bodyInter.copyWith(fontSize: 13, color: AppColors.purplePrimary),
                ),
                Text(
                  hasStreak ? 'Active today' : 'Send a drop to start!',
                  style: AppTypography.bodyInter.copyWith(fontSize: 13, color: AppColors.midGrey),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: hasStreak ? AppColors.paleOrange : AppColors.paleLavender,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (hasStreak) ...[
                  const Text('🔥', style: TextStyle(fontSize: 14)),
                  const SizedBox(width: 4),
                  Text(
                    '$streak',
                    style: AppTypography.bodyInter.copyWith(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.black),
                  ),
                ] else ...[
                  Text(
                    'Send drop',
                    style: AppTypography.bodyInter.copyWith(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.purplePrimary),
                  ),
                ],
                const SizedBox(width: 2),
                const Icon(Icons.chevron_right, size: 16, color: AppColors.grey400),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
