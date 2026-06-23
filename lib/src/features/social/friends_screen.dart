import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/app_colors.dart';
import '../../core/app_gradients.dart';
import '../../core/app_typography.dart';
import '../../core/animated_widgets.dart';
import '../../domain/models/friend.dart';
import '../../domain/models/social_streak.dart';
import '../../providers/social_provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/journal_provider.dart';
import '../../domain/models/growth_drop.dart';
import '../../shared/widgets/avatar_ring.dart';
import 'widgets/send_drop_dialog.dart';

class FriendsScreen extends ConsumerStatefulWidget {
  const FriendsScreen({super.key});

  @override
  ConsumerState<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends ConsumerState<FriendsScreen> {
  final _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      ref.read(socialProvider.notifier).searchUsers(query);
    });
  }

  Future<void> _shareInvite(String? userId) async {
    if (userId == null) return;
    HapticFeedback.lightImpact();
    
    // Fetch last read book directly from DB for the share text
    String bookTitle = "a great book";
    String? bookAuthor;
    try {
      final response = await Supabase.instance.client
          .from('growth_drops')
          .select('recommended_books')
          .eq('user_id', userId)
          .eq('is_read', true)
          .order('drop_date', ascending: false)
          .limit(1)
          .maybeSingle();
          
      if (response != null && response['recommended_books'] != null) {
        final recs = response['recommended_books'];
        final rec = recs is List ? recs.first : recs;
        bookTitle = rec['bookTitle'] ?? rec['title'] ?? bookTitle;
        bookAuthor = rec['bookAuthor'] ?? rec['author'];
      }
    } catch (_) {}

    final inviteLink = '${Uri.base.origin}/#/invite?sender=$userId';
    final authorText = bookAuthor != null ? ' by $bookAuthor' : '';
    
    final shareText = 'I just read "$bookTitle"$authorText and it was amazing! Try the app and let\'s share books daily. Join me here: $inviteLink\n\nRead more books & stay consistent with friends today!';
    
    try {
      Share.share(shareText);
    } catch (_) {}
    
    Clipboard.setData(ClipboardData(text: shareText));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invite link copied to clipboard!')),
      );
    }
  }

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
            const Text('📦', style: TextStyle(fontSize: 48, fontFamily: 'Apple Color Emoji')),
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
          'coverUrl': bookData['coverUrl'] as String?,
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

  Widget _buildSearchResult(dynamic user, String? currentUserId) {
    final isSelf = user.id == currentUserId;
    final socialState = ref.read(socialProvider).valueOrNull;
    
    final isAlreadyFriend = socialState?.acceptedFriends.any((f) => f.userId1 == user.id || f.userId2 == user.id) ?? false;
    final hasSentRequest = socialState?.outgoingRequests.any((f) => f.userId2 == user.id) ?? false;
    final hasReceivedRequest = socialState?.pendingRequests.any((f) => f.userId1 == user.id) ?? false;

    Widget trailingWidget;
    if (isSelf) {
      trailingWidget = const Chip(label: Text('You', style: TextStyle(fontSize: 12)));
    } else if (isAlreadyFriend) {
      trailingWidget = const Chip(label: Text('Friend', style: TextStyle(fontSize: 12)));
    } else if (hasSentRequest) {
      trailingWidget = const Chip(label: Text('Pending', style: TextStyle(fontSize: 12)));
    } else if (hasReceivedRequest) {
      trailingWidget = const Chip(label: Text('Requested You', style: TextStyle(fontSize: 12)));
    } else {
      trailingWidget = TextButton(
        onPressed: () async {
          try {
            await ref.read(socialProvider.notifier).sendFriendRequest(user.id);
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Friend request sent to ${user.name}!')),
              );
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Could not send request: $e')),
              );
            }
          }
        },
        child: const Text('Add Friend', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
      );
    }

    return CardPress(
      onTap: () {
        HapticFeedback.lightImpact();
        context.push('/friend-profile', extra: user);
      },
      child: Card(
        margin: const EdgeInsets.only(top: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 1,
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          leading: CircleAvatar(
            backgroundColor: AppColors.primaryLight,
            child: Text(user.name[0].toUpperCase() ?? '?', style: const TextStyle(color: AppColors.white)),
          ),
          title: Text(user.name ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text('Level ${user.level} • ${user.currentXp} XP'),
          trailing: trailingWidget,
        ),
      ),
    );
  }

  Widget _buildPendingRequest(Friend req) {
    return CardPress(
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 1,
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: CircleAvatar(
            backgroundColor: AppColors.primaryLight,
            child: Text(req.profile?.name[0].toUpperCase() ?? '?', style: const TextStyle(color: AppColors.white)),
          ),
          title: Text('${req.profile?.name ?? "Unknown"} wants to be friends!', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.check_circle, color: Colors.green),
                onPressed: () {
                  HapticFeedback.lightImpact();
                  ref.read(socialProvider.notifier).acceptFriendRequest(req.id);
                },
              ),
              IconButton(
                icon: const Icon(Icons.cancel, color: Colors.red),
                onPressed: () {
                  HapticFeedback.lightImpact();
                  ref.read(socialProvider.notifier).declineFriendRequest(req.id);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    final socialStateAsync = ref.watch(socialProvider);
    final userStateAsync = ref.watch(userProvider);
    // Watch journalProvider so it loads data proactively
    ref.watch(journalProvider);

    return Scaffold(
      backgroundColor: AppColors.scaffoldGrey,
      body: socialStateAsync.when(
        data: (socialState) {
          final userId = userStateAsync.valueOrNull?.id;
          final currentUserName = userStateAsync.valueOrNull?.name ?? 'You';

          final searchResultWidgets = socialState.isSearching
              ? [const Padding(
                  padding: EdgeInsets.only(top: 16),
                  child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                )]
              : socialState.searchResults.isNotEmpty
                  ? socialState.searchResults.map((u) => _buildSearchResult(u, userId)).toList()
                  : <Widget>[];

          final pendingRequestWidgets = socialState.pendingRequests.isNotEmpty
              ? [
                  EntranceFadeSlide(
                    delayMs: 150,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 24),
                      child: Text('Pending Requests', style: AppTypography.h2Inter.copyWith(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.primary)),
                    ),
                  ),
                  ...socialState.pendingRequests.map((req) => _buildPendingRequest(req)),
                  const SizedBox(height: 16),
                ]
              : <Widget>[];

          return _FriendsBody(
            userId: userId,
            currentUserName: currentUserName,
            socialState: socialState,
            searchController: _searchController,
            onSearchChanged: _onSearchChanged,
            onShareInvite: () => _shareInvite(userId),
            onSendDrop: (f) => showSendDropDialog(context, ref, f),
            onOpenDrop: _openDrop,
            searchResultWidgets: searchResultWidgets,
            pendingRequestWidgets: pendingRequestWidgets,
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
  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onShareInvite;
  final void Function(Friend) onSendDrop;
  final void Function(dynamic drop) onOpenDrop;
  final List<Widget> searchResultWidgets;
  final List<Widget> pendingRequestWidgets;

  const _FriendsBody({
    required this.userId,
    required this.currentUserName,
    required this.socialState,
    required this.searchController,
    required this.onSearchChanged,
    required this.onShareInvite,
    required this.onSendDrop,
    required this.onOpenDrop,
    required this.searchResultWidgets,
    required this.pendingRequestWidgets,
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
                        Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(text: 'Grow better, together. ', style: AppTypography.bodyInter.copyWith(fontSize: 14, color: AppColors.midGrey)),
                              const TextSpan(text: '💜', style: TextStyle(fontSize: 14, fontFamily: 'Apple Color Emoji')),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  EntranceFadeSlide(
                    delayMs: 100,
                    child: PressScale(
                      onTap: onShareInvite,
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
                child: TextField(
                  controller: searchController,
                  onChanged: onSearchChanged,
                  decoration: InputDecoration(
                    hintText: 'Search by name or email...',
                    hintStyle: const TextStyle(color: AppColors.grey400, fontSize: 15),
                    prefixIcon: const Icon(Icons.search, color: AppColors.grey400, size: 22),
                    suffixIcon: searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              searchController.clear();
                              onSearchChanged('');
                            },
                          )
                        : null,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(50), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                  ),
                ),
              ),
            ),
            if (searchResultWidgets.isNotEmpty || pendingRequestWidgets.isNotEmpty)
              const SizedBox(height: 16),
            ...searchResultWidgets,
            if (searchResultWidgets.isNotEmpty && pendingRequestWidgets.isNotEmpty)
              const SizedBox(height: 24),
            ...pendingRequestWidgets,
            const SizedBox(height: 32),
            EntranceFadeSlide(
              delayMs: 200,
              child: _ClosestStreaksSection(
                userId: userId,
                socialState: socialState,
                onFriendTap: (f) {
                  if (f.profile != null) {
                    HapticFeedback.lightImpact();
                    context.push('/friend-profile', extra: f.profile);
                  }
                },
                onOpenDrop: onOpenDrop,
              ),
            ),
            const SizedBox(height: 24),
            if (topFriend != null)
              EntranceFadeSlide(
                delayMs: 300,
                child: _HighlightCard(
                  currentUserName: currentUserName,
                  friend: topFriend,
                  streakCount: topStreak,
                  onSendDrop: () => onSendDrop(topFriend),
                ),
              ),
            if (topFriend != null) const SizedBox(height: 24),
            EntranceFadeSlide(
              delayMs: 400,
              child: _AllFriendsSection(
                userId: userId,
                socialState: socialState,
                onFriendTap: (f) {
                  if (f.profile != null) {
                    HapticFeedback.lightImpact();
                    context.push('/friend-profile', extra: f.profile);
                  }
                },
                onSendDrop: onSendDrop,
                onOpenDrop: onOpenDrop,
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
  final SocialState socialState;
  final void Function(Friend friend) onFriendTap;
  final void Function(dynamic drop)? onOpenDrop;

  const _ClosestStreaksSection({
    required this.userId,
    required this.socialState,
    required this.onFriendTap,
    this.onOpenDrop,
  });

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
    final sorted = List<Friend>.from(socialState.acceptedFriends)
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
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 100,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: sorted.length,
            separatorBuilder: (_, _) => const SizedBox(width: 16),
            itemBuilder: (context, index) {
              final f = sorted[index];
              final friendName = f.profile?.name ?? 'Friend';
              final streak = _streakForFriend(f);
              final fid = userId != null
                  ? (f.userId1 == userId ? f.userId2 : f.userId1)
                  : '';
              final unopenedDrops = socialState.receivedDrops.where((d) => d.senderId == fid && !d.isOpened).toList();
              return _StreakAvatarItem(
                name: friendName, 
                streak: streak,
                onTap: () {
                  if (unopenedDrops.isNotEmpty && onOpenDrop != null) {
                    onOpenDrop!(unopenedDrops.first);
                  } else {
                    onFriendTap(f);
                  }
                },
                unopenedCount: unopenedDrops.length,
              );
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
  final VoidCallback? onTap;
  final int unopenedCount;

  const _StreakAvatarItem({required this.name, required this.streak, this.onTap, this.unopenedCount = 0});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 72,
        child: Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                AvatarRing(size: 52, name: name),
                if (streak > 0)
                  Positioned(
                    bottom: -6,
                    left: -10,
                    right: -10,
                    child: Center(child: StreakBadge(count: streak)),
                  ),
                if (unopenedCount > 0)
                  Positioned(
                    right: -2,
                    top: -2,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                      child: Text(
                        '$unopenedCount',
                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
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
      ),
    );
  }
}


class _HighlightCard extends StatelessWidget {
  final String currentUserName;
  final Friend friend;
  final int streakCount;
  final VoidCallback onSendDrop;

  const _HighlightCard({
    required this.currentUserName,
    required this.friend,
    required this.streakCount,
    required this.onSendDrop,
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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 72,
                      height: 50,
                      child: Stack(
                        children: [
                          Positioned(
                            left: 0,
                            top: 4,
                            child: AvatarCircle(size: 36, name: currentUserName),
                          ),
                          Positioned(
                            left: 20,
                            top: 0,
                            child: AvatarRing(size: 40, name: friendName, borderWidth: 2.5),
                          ),
                          if (streakCount > 0)
                            Positioned(
                              right: 8,
                              bottom: -4,
                              child: Transform.scale(
                                scale: 0.8,
                                child: StreakBadge(count: streakCount),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'You and ${friendName.split(' ').first} are on a',
                            style: AppTypography.bodyInter.copyWith(fontSize: 12, color: AppColors.black),
                          ),
                          RichText(
                            text: TextSpan(
                              style: AppTypography.h2Inter.copyWith(fontSize: 18, fontWeight: FontWeight.bold),
                              children: [
                                TextSpan(
                                  text: '$streakCount-day',
                                  style: TextStyle(
                                    foreground: Paint()..shader = AppGradients.friendsHeaderText.createShader(const Rect.fromLTWH(0, 0, 100, 20)),
                                  ),
                                ),
                                TextSpan(
                                  children: [
                                    const TextSpan(text: ' streak ', style: TextStyle(color: AppColors.black)),
                                    const TextSpan(text: '🔥', style: TextStyle(color: AppColors.black, fontFamily: 'Apple Color Emoji')),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: AppGradients.ctaButton,
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(22),
                        onTap: () {
                          HapticFeedback.lightImpact();
                          onSendDrop();
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Center(
                            child: Text(
                              "Send Today",
                              style: AppTypography.bodyInter.copyWith(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.white),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Container(
            width: 100,
            height: 120,
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/3d_friends_illustration.webp'),
                fit: BoxFit.contain,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AllFriendsSection extends StatelessWidget {
  final String? userId;
  final SocialState socialState;
  final void Function(Friend friend) onFriendTap;
  final void Function(Friend friend) onSendDrop;
  final void Function(dynamic drop)? onOpenDrop;

  const _AllFriendsSection({
    required this.userId,
    required this.socialState,
    required this.onFriendTap,
    required this.onSendDrop,
    this.onOpenDrop,
  });

  int _streakForFriend(Friend f) {
    if (userId == null) return 0;
    final fid = f.userId1 == userId ? f.userId2 : f.userId1;
    final s = socialState.streaks.firstWhere(
      (s) => (s.userId1 == userId && s.userId2 == fid) || (s.userId1 == fid && s.userId2 == userId),
      orElse: () => SocialStreak(id: '', userId1: userId!, userId2: fid, currentStreak: 0),
    );
    return s.effectiveStreak;
  }

  DateTime? _lastInteractionForFriend(Friend f) {
    if (userId == null) return null;
    final fid = f.userId1 == userId ? f.userId2 : f.userId1;
    final s = socialState.streaks.firstWhere(
      (s) => (s.userId1 == userId && s.userId2 == fid) || (s.userId1 == fid && s.userId2 == userId),
      orElse: () => SocialStreak(id: '', userId1: userId!, userId2: fid, currentStreak: 0),
    );
    final d1 = s.lastSharedDate1;
    final d2 = s.lastSharedDate2;
    if (d1 == null) return d2;
    if (d2 == null) return d1;
    return d1.isAfter(d2) ? d1 : d2;
  }

  @override
  Widget build(BuildContext context) {
    final sorted = List<Friend>.from(socialState.acceptedFriends)
      ..sort((a, b) {
        final dA = _lastInteractionForFriend(a);
        final dB = _lastInteractionForFriend(b);
        if (dA == null && dB == null) return 0;
        if (dA == null) return 1; // nulls go to the bottom
        if (dB == null) return -1;
        return dB.compareTo(dA); // most recent first
      });

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
                final fid = userId != null
                    ? (f.userId1 == userId ? f.userId2 : f.userId1)
                    : '';
                final alreadySent = socialState.sentTodayFriendIds.contains(fid);
                final unopenedDrops = socialState.receivedDrops.where((d) => d.senderId == fid && !d.isOpened).toList();
                return _FriendTile(
                  name: friendName,
                  streak: streak,
                  hasStreak: streak > 0,
                  onTap: () {
                    if (unopenedDrops.isNotEmpty && onOpenDrop != null) {
                      onOpenDrop!(unopenedDrops.first);
                    } else {
                      onFriendTap(f);
                    }
                  },
                  onSendDrop: () => onSendDrop(f),
                  alreadySent: alreadySent,
                  unopenedCount: unopenedDrops.length,
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
  final VoidCallback? onTap;
  final VoidCallback? onSendDrop;
  final bool alreadySent;
  final int unopenedCount;

  const _FriendTile({
    required this.name,
    required this.streak,
    required this.hasStreak,
    this.onTap,
    this.onSendDrop,
    this.alreadySent = false,
    this.unopenedCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                AvatarCircle(size: 48, name: name),
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
                        child: const Text('🔥', style: TextStyle(fontSize: 12, fontFamily: 'Apple Color Emoji')),
                      ),
                    ),
                  ),
                if (unopenedCount > 0)
                  Positioned(
                    right: -2,
                    top: -2,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                      child: Text(
                        '$unopenedCount',
                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
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
                  style: AppTypography.bodyInter.copyWith(fontSize: 13, color: AppColors.grey500),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              if (onSendDrop != null) onSendDrop!();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: hasStreak ? AppColors.paleOrange : AppColors.paleLavender,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (hasStreak) ...[
                    const Text('🔥', style: TextStyle(fontSize: 14, fontFamily: 'Apple Color Emoji')),
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
          ),
        ],
      ),
    ),
  );
}
}
