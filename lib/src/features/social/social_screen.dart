import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/app_colors.dart';
import '../../domain/models/friend.dart';
import '../../domain/models/growth_drop.dart';
import '../../domain/models/social_streak.dart';
import '../../providers/journal_provider.dart';
import '../../providers/social_provider.dart';
import '../../providers/user_provider.dart';

class SocialScreen extends ConsumerStatefulWidget {
  const SocialScreen({super.key});

  @override
  ConsumerState<SocialScreen> createState() => _SocialScreenState();
}

class _SocialScreenState extends ConsumerState<SocialScreen> {
  final _searchController = TextEditingController();
  Timer? _debounce;
  String? _openingFriendId;

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
    
    // Use the actual live domain the app is running on
    final inviteLink = '${Uri.base.origin}/#/invite?sender=$userId';
    
    try {
      Share.share('Read with me! I\'m sending you a daily blind-box book drop. Join here: $inviteLink');
    } catch (_) {}
    Clipboard.setData(ClipboardData(text: inviteLink));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Invite link copied to clipboard!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final socialStateAsync = ref.watch(socialProvider);
    final userStateAsync = ref.watch(userProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Friends & Streaks', style: TextStyle(color: AppColors.grey900, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: socialStateAsync.when(
        data: (socialState) {
          final userId = userStateAsync.valueOrNull?.id;

          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              // Search bar
              TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                decoration: InputDecoration(
                  hintText: 'Search by name or email...',
                  prefixIcon: const Icon(Icons.search, color: AppColors.grey400),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            _onSearchChanged('');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: AppColors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                ),
              ),
              // Search results
              if (socialState.isSearching)
                const Padding(
                  padding: EdgeInsets.only(top: 16),
                  child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                ),
              if (socialState.searchResults.isNotEmpty && !socialState.isSearching)
                ...socialState.searchResults.map((u) => _buildSearchResult(u, userId)),
              if (socialState.searchResults.isNotEmpty || socialState.isSearching)
                const SizedBox(height: 24),

              // Pending requests
              if (socialState.pendingRequests.isNotEmpty) ...[
                const Text('Pending Requests', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.primary)),
                const SizedBox(height: 12),
                ...socialState.pendingRequests.map((req) => _buildPendingRequest(req)),
                const SizedBox(height: 32),
              ],

              // Friends list
              if (socialState.acceptedFriends.isNotEmpty || socialState.outgoingRequests.isNotEmpty) ...[
                const Text('Your Friends', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.primary)),
                const SizedBox(height: 12),
                ...[...socialState.acceptedFriends, ...socialState.outgoingRequests].map((friend) {
                  final friendId = friend.userId1 == userId ? friend.userId2 : friend.userId1;
                  final streak = socialState.streaks.firstWhere(
                    (s) => (s.userId1 == userId && s.userId2 == friendId) || (s.userId1 == friendId && s.userId2 == userId),
                    orElse: () => SocialStreak(id: '', userId1: userId ?? '', userId2: friendId, currentStreak: 0),
                  );
                  final unopenedCount = socialState.receivedDrops
                      .where((d) => d.senderId == friendId && !d.isOpened)
                      .length;
                  return _buildFriendCard(friend, streak, userId, friend.status == 'pending', unopenedCount);
                }),
                const SizedBox(height: 24),
              ],

              // Empty state when no friends and no drops
              if (socialState.acceptedFriends.isEmpty && socialState.outgoingRequests.isEmpty && socialState.pendingRequests.isEmpty && socialState.searchResults.isEmpty)
                _buildEmptyState(userId),

              // Invite button
              if (socialState.acceptedFriends.isNotEmpty || socialState.outgoingRequests.isNotEmpty)
                Center(
                  child: ElevatedButton.icon(
                    onPressed: () => _shareInvite(userId),
                    icon: const Icon(Icons.person_add),
                    label: const Text('Invite More Friends'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                  ),
                ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Widget _buildSearchResult(dynamic user, String? currentUserId) {
    final isSelf = user.id == currentUserId;
    return Card(
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
        subtitle: Text('Level ${user.level} \u2022 ${user.currentXp} XP'),
        trailing: isSelf
            ? const Chip(label: Text('You', style: TextStyle(fontSize: 12)))
            : TextButton(
                onPressed: () async {
                  try {
                    await ref.read(socialProvider.notifier).sendFriendRequest(user.id);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Friend request sent to ${user.name}!')),
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
                child: const Text('Add Friend', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
              ),
        onTap: () => context.push('/friend-profile', extra: user),
      ),
    );
  }

  Widget _buildPendingRequest(Friend req) {
    return Card(
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
              onPressed: () => ref.read(socialProvider.notifier).acceptFriendRequest(req.id),
            ),
            IconButton(
              icon: const Icon(Icons.cancel, color: Colors.red),
              onPressed: () => ref.read(socialProvider.notifier).declineFriendRequest(req.id),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openDrop(dynamic drop) async {
    if (drop.isOpened) {
      if (drop.bookData != null) context.push('/book', extra: drop.bookData);
      return;
    }
    if (drop.bookData != null) {
      ref.read(socialProvider.notifier).markDropOpened(drop.id);
      context.push('/book', extra: drop.bookData);
      return;
    }
    
    setState(() => _openingFriendId = drop.senderId);
    
    // Show unpacking modal
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
            Text(
              'Unpacking your blind box...',
              style: GoogleFonts.playfairDisplay(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppColors.grey900,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Generating a personalized book drop just for you.',
              style: TextStyle(color: AppColors.grey600, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
    
    try {
      final bookData = await ref.read(socialProvider.notifier).openBlindBox(drop.id);
      if (!mounted) return;
      
      // Construct the object first so if it throws, we haven't popped yet
      final lessonsData = bookData['lessons'];
      final List<String> parsedLessons = lessonsData is List
          ? lessonsData.map((e) => e.toString()).toList()
          : (lessonsData != null ? [lessonsData.toString()] : []);

      final newDrop = GrowthDrop.fromJson({
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
      });

      setState(() => _openingFriendId = null);
      Navigator.of(context, rootNavigator: true).pop(); // Close modal
      context.push('/book', extra: newDrop);
      
    } catch (e) {
      if (mounted) {
        setState(() => _openingFriendId = null);
        Navigator.of(context, rootNavigator: true).pop(); // Close modal
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to generate: $e')),
        );
      }
    }
  }

  Widget _buildFriendCard(dynamic friend, dynamic streak, String? currentUserId, bool isPending, int unopenedCount) {
    final profile = friend.profile;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 1,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Stack(
          children: [
            CircleAvatar(
              backgroundColor: isPending ? AppColors.grey300 : AppColors.primaryLight,
              child: Text(friend.profile?.name[0].toUpperCase() ?? '?', style: const TextStyle(color: AppColors.white)),
            ),
            if (unopenedCount > 0)
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '$unopenedCount',
                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
          ],
        ),
        title: Text(friend.profile?.name ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: isPending
            ? const Text('Pending acceptance...', style: TextStyle(color: AppColors.grey500, fontStyle: FontStyle.italic))
            : Row(
                children: [
                  const Text('\u{1F525} ', style: TextStyle(fontSize: 14)),
                  Text('${streak.currentStreak} day streak', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
                ],
              ),
        trailing: IconButton(
          icon: const Icon(Icons.send, color: AppColors.primary),
          onPressed: () {
            _showSendDialog(context, ref, friend);
          },
        ),
        onTap: profile != null
            ? () {
                if (_openingFriendId == profile.id) return; // Prevent multiple taps
                
                if (unopenedCount > 0) {
                  final drop = (ref.read(socialProvider).valueOrNull?.receivedDrops ?? [])
                      .where((d) => d.senderId == profile.id && !d.isOpened)
                      .firstOrNull;
                  if (drop != null) _openDrop(drop);
                } else {
                  context.push('/friend-profile', extra: profile);
                }
              }
            : null,
      ),
    );
  }

  Widget _buildEmptyState(String? userId) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          const Icon(Icons.group_add, size: 80, color: AppColors.primaryLight),
          const SizedBox(height: 24),
          const Text(
            'No friends yet!',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.grey900),
          ),
          const SizedBox(height: 16),
          const Text(
            'Search for friends above or invite them to start sending daily Blind Box book drops!',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: AppColors.grey600),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () => _shareInvite(userId),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: const Text('Invite a Friend', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  void _showSendDialog(BuildContext context, WidgetRef ref, dynamic friend) {
    final friendId = friend.profile?.id;
    final friendName = friend.profile?.name;
    if (friendId == null) return;

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
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.card_giftcard, color: AppColors.primary),
                ),
                title: const Text('Send Blind Box (AI)'),
                subtitle: const Text('AI generates a book based on their goals'),
                onTap: () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Generating and sending...')));
                  ref.read(socialProvider.notifier).sendDrop(friendId);
                },
              ),
              const Divider(),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.menu_book_rounded, color: AppColors.primary),
                ),
                title: const Text('Send from Journal'),
                subtitle: const Text('Choose a book you\'ve read'),
                onTap: () {
                  Navigator.pop(ctx);
                  _showJournalPicker(context, ref, friendId);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  void _showJournalPicker(BuildContext context, WidgetRef ref, String friendId) {
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
                                  color: AppColors.primaryLight.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.menu_book_rounded, color: AppColors.primary, size: 20),
                              ),
                              title: Text(drop.bookTitle, style: const TextStyle(fontWeight: FontWeight.w600)),
                              subtitle: Text(drop.bookAuthor, style: const TextStyle(color: AppColors.grey500)),
                              onTap: () {
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
}
