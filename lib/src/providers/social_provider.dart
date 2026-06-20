import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/models/friend.dart';
import '../domain/models/social_drop.dart';
import '../domain/models/social_streak.dart';
import '../domain/models/user.dart' as app_user;

final socialProvider = AsyncNotifierProvider<SocialNotifier, SocialState>(() {
  return SocialNotifier();
});

class SocialState {
  final List<Friend> acceptedFriends;
  final List<Friend> pendingRequests;
  final List<Friend> outgoingRequests;
  final List<SocialDrop> receivedDrops;
  final List<SocialStreak> streaks;
  final List<app_user.User> searchResults;
  final bool isSearching;
  final Set<String> sentTodayFriendIds;
  final bool isAdmin;

  SocialState({
    required this.acceptedFriends,
    required this.pendingRequests,
    required this.outgoingRequests,
    required this.receivedDrops,
    required this.streaks,
    this.searchResults = const [],
    this.isSearching = false,
    this.sentTodayFriendIds = const {},
    this.isAdmin = false,
  });
}

class SocialNotifier extends AsyncNotifier<SocialState> {
  final _supabase = Supabase.instance.client;

  @override
  Future<SocialState> build() async {
    return _fetchData();
  }

  Future<SocialState> _fetchData() async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      return SocialState(acceptedFriends: [], pendingRequests: [], outgoingRequests: [], receivedDrops: [], streaks: []);
    }

    final uid = user.id;

    // Fetch all friend relationships
    final friendsResponse = await _supabase
        .from('friends')
        .select()
        .or('user_id_1.eq.$uid,user_id_2.eq.$uid');

    final allFriends = (friendsResponse as List);
    final acceptedRows = allFriends.where((f) => f['status'] == 'accepted').toList();
    final pendingRows = allFriends.where((f) => f['status'] == 'pending' && f['user_id_2'] == uid).toList();
    final outgoingRows = allFriends.where((f) => f['status'] == 'pending' && f['user_id_1'] == uid).toList();

    // Fetch profiles for all related users
    final allRelatedIds = <String>{};
    for (final f in allFriends) {
      allRelatedIds.add(f['user_id_1'] == uid ? f['user_id_2'] : f['user_id_1']);
    }

    List<app_user.User> profiles = [];
    if (allRelatedIds.isNotEmpty) {
      final profilesResponse = await _supabase
          .from('profiles')
          .select()
          .inFilter('id', allRelatedIds.toList());
      profiles = (profilesResponse as List)
          .map((e) => app_user.User.fromJson(e))
          .toList();
    }

    app_user.User profileForId(String id) => profiles.firstWhere(
      (p) => p.id == id,
      orElse: () => app_user.User(id: id, name: 'Unknown'),
    );

    final acceptedFriends = acceptedRows.map((f) {
      final friendId = f['user_id_1'] == uid ? f['user_id_2'] : f['user_id_1'];
      return Friend.fromJson(f, profile: profileForId(friendId));
    }).toList();

    final pendingRequests = pendingRows.map((f) {
      final requesterId = f['user_id_1'];
      return Friend.fromJson(f, profile: profileForId(requesterId));
    }).toList();

    final outgoingRequests = outgoingRows.map((f) {
      final targetId = f['user_id_2'];
      return Friend.fromJson(f, profile: profileForId(targetId));
    }).toList();

    // Fetch streaks
    final streaksResponse = await _supabase
        .from('social_streaks')
        .select()
        .or('user_id_1.eq.$uid,user_id_2.eq.$uid');

    final streaks = (streaksResponse as List)
        .map((s) => SocialStreak.fromJson(s))
        .toList();

    // Fetch received drops
    final dropsResponse = await _supabase
        .from('social_drops')
        .select()
        .eq('recipient_id', uid)
        .order('drop_date', ascending: false);

    final dropSenderIds = dropsResponse.map((e) => e['sender_id']).toSet().toList();
    List<app_user.User> allProfiles = List.from(profiles);
    final missingProfiles = dropSenderIds.where((id) => !allProfiles.any((p) => p.id == id)).toList();
    if (missingProfiles.isNotEmpty) {
      final missingResp = await _supabase
          .from('profiles')
          .select()
          .inFilter('id', missingProfiles);
      allProfiles.addAll((missingResp as List).map((e) => app_user.User.fromJson(e)));
    }

    final receivedDrops = (dropsResponse as List).map((d) {
      final senderProfile = allProfiles.firstWhere(
        (p) => p.id == d['sender_id'],
        orElse: () => app_user.User(id: d['sender_id'], name: 'Unknown'),
      );
      return SocialDrop.fromJson(d, senderProfile: senderProfile);
    }).toList();

    // Fetch drops sent by me today
    final today = DateTime.now().toIso8601String().split('T')[0];
    final sentTodayResponse = await _supabase
        .from('social_drops')
        .select('recipient_id')
        .eq('sender_id', uid)
        .eq('drop_date', today);
    
    final sentTodayFriendIds = (sentTodayResponse as List).map((e) => e['recipient_id'].toString()).toSet();

    // Fetch admin status
    final profileData = await _supabase.from('profiles').select('is_admin').eq('id', uid).maybeSingle();
    final isAdmin = profileData?['is_admin'] == true;

    return SocialState(
      acceptedFriends: acceptedFriends,
      pendingRequests: pendingRequests,
      outgoingRequests: outgoingRequests,
      receivedDrops: receivedDrops,
      streaks: streaks,
      sentTodayFriendIds: sentTodayFriendIds,
      isAdmin: isAdmin,
    );
  }

  Future<void> sendDrop(String friendId) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;
    try {
      final today = DateTime.now().toIso8601String().split('T')[0];
      final isAdmin = state.value?.isAdmin ?? false;

      // 1. Client-side check (skip for admins)
      if (!isAdmin) {
        final existingDrop = await _supabase
            .from('social_drops')
            .select('id')
            .eq('sender_id', user.id)
            .eq('recipient_id', friendId)
            .eq('drop_date', today)
            .maybeSingle();

        if (existingDrop != null) {
          throw Exception('You already sent a drop to this friend today!');
        }
      }

      // 2. Insert drop
      try {
        await _supabase.from('social_drops').insert({
          'sender_id': user.id,
          'recipient_id': friendId,
          'drop_date': today,
          'book_data': {},
        });
      } catch (e) {
        // Skip DB constraint for admins; otherwise show friendly error
        if (!isAdmin && (e.toString().contains('23505') || e.toString().contains('unique_daily_drop'))) {
          throw Exception('You already sent a drop to this friend today!');
        }
        rethrow;
      }

      await _updateStreak(friendId, today);

      ref.invalidateSelf();
    } catch (e) {
      print('Error sending drop: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> openBlindBox(String dropId) async {
    try {
      final res = await _supabase.functions.invoke('generate-social-drop', body: {
        'drop_id': dropId,
      });
      await _supabase
          .from('social_drops')
          .update({'is_opened': true})
          .eq('id', dropId);
      ref.invalidateSelf();
      final data = res.data;
      final actualData = data is Map && data['data'] != null ? data['data'] : data;
      return Map<String, dynamic>.from(actualData is Map ? actualData : {});
    } catch (e) {
      print('Error opening blind box: $e');
      rethrow;
    }
  }

  Future<void> sendBookFromJournal(String friendId, Map<String, dynamic> bookData) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;
    try {
      final today = DateTime.now().toIso8601String().split('T')[0];
      final isAdmin = state.value?.isAdmin ?? false;

      if (!isAdmin) {
        final existingDrop = await _supabase
            .from('social_drops')
            .select('id')
            .eq('sender_id', user.id)
            .eq('recipient_id', friendId)
            .eq('drop_date', today)
            .maybeSingle();

        if (existingDrop != null) {
          throw Exception('You already sent a drop to this friend today!');
        }
      }

      await _supabase.from('social_drops').insert({
        'sender_id': user.id,
        'recipient_id': friendId,
        'drop_date': today,
        'book_data': bookData,
      });

      await _updateStreak(friendId, today);

      ref.invalidateSelf();
    } catch (e) {
      print('Error sending book: $e');
      rethrow;
    }
  }

  Future<void> _updateStreak(String friendId, String today) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    var streakData = await _supabase
        .from('social_streaks')
        .select()
        .eq('user_id_1', user.id)
        .eq('user_id_2', friendId)
        .maybeSingle();

    if (streakData == null) {
      streakData = await _supabase
          .from('social_streaks')
          .select()
          .eq('user_id_1', friendId)
          .eq('user_id_2', user.id)
          .maybeSingle();
    }

    if (streakData != null) {
      final isUser1 = streakData['user_id_1'] == user.id;
      final myLastDate = isUser1 ? streakData['last_shared_date_1'] : streakData['last_shared_date_2'];
      final otherDate = isUser1 ? streakData['last_shared_date_2'] : streakData['last_shared_date_1'];

      if (myLastDate == today) {
        return; // already sent today, no double-count
      }

      final updatePayload = <String, dynamic>{};
      if (isUser1) {
        updatePayload['last_shared_date_1'] = today;
        if (otherDate == today) {
          updatePayload['current_streak'] = (streakData['current_streak'] as int? ?? 0) + 1;
        }
      } else {
        updatePayload['last_shared_date_2'] = today;
        if (otherDate == today) {
          updatePayload['current_streak'] = (streakData['current_streak'] as int? ?? 0) + 1;
        }
      }
      await _supabase.from('social_streaks').update(updatePayload).eq('id', streakData['id']);
    } else {
      await _supabase.from('social_streaks').insert({
        'user_id_1': user.id,
        'user_id_2': friendId,
        'last_shared_date_1': today,
        'current_streak': 0,
      });
    }
  }

  Future<void> markDropOpened(String dropId) async {
    try {
      await _supabase
          .from('social_drops')
          .update({'is_opened': true})
          .eq('id', dropId);
      ref.invalidateSelf();
    } catch (e) {
      print('Error marking drop opened: $e');
    }
  }

  Future<void> searchUsers(String query) async {
    final user = _supabase.auth.currentUser;
    if (user == null || query.trim().isEmpty) {
      state = AsyncValue.data(state.value!.copyWith(searchResults: [], isSearching: false));
      return;
    }
    state = AsyncValue.data(state.value!.copyWith(isSearching: true));
    try {
      final res = await _supabase.rpc('search_users', params: {
        'search_query': query,
        'current_user_id': user.id,
      });
      final results = (res as List).map((e) => app_user.User.fromJson(e)).toList();
      state = AsyncValue.data(state.value!.copyWith(searchResults: results, isSearching: false));
    } catch (e) {
      state = AsyncValue.data(state.value!.copyWith(searchResults: [], isSearching: false));
    }
  }

  Future<void> sendFriendRequest(String targetUserId) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;
    try {
      await _supabase.from('friends').insert({
        'user_id_1': user.id,
        'user_id_2': targetUserId,
        'status': 'pending',
      });
      ref.invalidateSelf();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> acceptFriendRequest(String friendRowId) async {
    try {
      await _supabase
          .from('friends')
          .update({'status': 'accepted'})
          .eq('id', friendRowId);
      ref.invalidateSelf();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> declineFriendRequest(String friendRowId) async {
    try {
      await _supabase
          .from('friends')
          .update({'status': 'declined'})
          .eq('id', friendRowId);
      ref.invalidateSelf();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> removeFriend(String friendRowId) async {
    try {
      final row = await _supabase
          .from('friends')
          .select('user_id_1, user_id_2')
          .eq('id', friendRowId)
          .maybeSingle();
      if (row == null) return;

      final uid1 = row['user_id_1'] as String;
      final uid2 = row['user_id_2'] as String;

      await _supabase.from('friends').delete().eq('id', friendRowId);

      // Clean up related streaks (both directions)
      await _supabase
          .from('social_streaks')
          .delete()
          .or('and(user_id_1.eq.$uid1,user_id_2.eq.$uid2),and(user_id_1.eq.$uid2,user_id_2.eq.$uid1)');

      // Clean up related social drops
      final currentUserId = _supabase.auth.currentUser?.id;
      if (currentUserId != null) {
        final otherId = currentUserId == uid1 ? uid2 : uid1;
        await _supabase
            .from('social_drops')
            .delete()
            .or('and(sender_id.eq.$currentUserId,recipient_id.eq.$otherId),and(sender_id.eq.$otherId,recipient_id.eq.$currentUserId)');
      }

      ref.invalidateSelf();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> saveDropToJournal(SocialDrop drop) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;
    final bookData = drop.bookData;
    if (bookData == null) return;
    try {
      await _supabase.from('growth_drops').insert({
        'user_id': user.id,
        'drop_date': DateTime.now().toIso8601String().split('T')[0],
        'focus_area': bookData.focusArea,
        'recommended_books': {
          'bookTitle': bookData.bookTitle,
          'bookAuthor': bookData.bookAuthor,
          'whatItsAbout': bookData.whatItsAbout,
          'lessons': bookData.lessons,
          'summary': bookData.summary,
        },
        'is_read': true,
      });
    } catch (e) {
      rethrow;
    }
  }
}

extension _SocialStateCopy on SocialState {
  SocialState copyWith({
    List<Friend>? acceptedFriends,
    List<Friend>? pendingRequests,
    List<Friend>? outgoingRequests,
    List<SocialDrop>? receivedDrops,
    List<SocialStreak>? streaks,
    List<app_user.User>? searchResults,
    bool? isSearching,
    Set<String>? sentTodayFriendIds,
    bool? isAdmin,
  }) {
    return SocialState(
      acceptedFriends: acceptedFriends ?? this.acceptedFriends,
      pendingRequests: pendingRequests ?? this.pendingRequests,
      outgoingRequests: outgoingRequests ?? this.outgoingRequests,
      receivedDrops: receivedDrops ?? this.receivedDrops,
      streaks: streaks ?? this.streaks,
      searchResults: searchResults ?? this.searchResults,
      isSearching: isSearching ?? this.isSearching,
      sentTodayFriendIds: sentTodayFriendIds ?? this.sentTodayFriendIds,
      isAdmin: isAdmin ?? this.isAdmin,
    );
  }
}
