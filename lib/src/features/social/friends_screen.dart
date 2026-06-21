import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
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
        const Text('🔥', style: TextStyle(fontSize: 11, fontFamily: 'Apple Color Emoji')),
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

  void _shareInvite(String? userId) {
    if (userId == null) return;
    HapticFeedback.lightImpact();
    final inviteLink = '${Uri.base.origin}/#/invite?sender=$userId';
    
    final journalState = ref.read(journalProvider).valueOrNull;
    String shareText;
    
    if (journalState != null && journalState.isNotEmpty) {
      final latestBook = journalState.first;
      shareText = 'I just read "${latestBook.bookTitle}" by ${latestBook.bookAuthor} and it was amazing! Try the app and let\'s share books daily. Join me here: $inviteLink';
    } else {
      shareText = 'I\'ve been using this amazing app to build my reading habit and share books daily. Try it out and let\'s start a reading streak together! Join me here: $inviteLink';
    }
    
    try {
      Share.share(shareText);
    } catch (_) {}
    
    Clipboard.setData(ClipboardData(text: shareText));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Invite link copied to clipboard!')),
    );
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

  void _showSendDialog(Friend friend) {
    final friendId = friend.userId1 == ref.read(userProvider).valueOrNull?.id ? friend.userId2 : friend.userId1;
    final friendName = friend.profile?.name ?? 'Friend';

    final socialState = ref.read(socialProvider).valueOrNull;
    final isAdmin = socialState?.isAdmin ?? false;
    final alreadySent = (socialState?.sentTodayFriendIds.contains(friendId) ?? false) && !isAdmin;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
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
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Generating and sending...')));
                  try {
                    await ref.read(socialProvider.notifier).sendDrop(friendId);
                  } catch (e) {
                    if (mounted) {
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
                  _showJournalPicker(friendId);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  void _showJournalPicker(String friendId) {
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
            onSendDrop: _showSendDialog,
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
      if (s.currentStreak > bestStreak) {
        bestStreak = s.currentStreak;
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
    return s.currentStreak;
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
    return s.currentStreak;
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
                _buildGradientAvatarRing(52, name),
                if (streak > 0)
                  Positioned(
                    bottom: -6,
                    left: -10,
                    right: -10,
                    child: Center(child: _streakBadge(streak)),
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
                            child: _buildAvatar(36, currentUserName),
                          ),
                          Positioned(
                            left: 20,
                            top: 0,
                            child: _buildGradientAvatarRing(40, friendName, borderWidth: 2.5),
                          ),
                          if (streakCount > 0)
                            Positioned(
                              right: 8,
                              bottom: -4,
                              child: Transform.scale(
                                scale: 0.8,
                                child: _streakBadge(streakCount),
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
    return s.currentStreak;
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
