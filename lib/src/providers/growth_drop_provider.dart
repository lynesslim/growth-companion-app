import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart' as supa;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/models/growth_drop.dart';

class GrowthDropNotifier extends AsyncNotifier<GrowthDrop?> {
  @override
  Future<GrowthDrop?> build() async => _fetch();

  Future<GrowthDrop?> _fetch() async {
    final userId = supa.Supabase.instance.client.auth.currentUser?.id ?? '';
    if (userId.isEmpty) return null;
    final today = DateTime.now().toIso8601String().split('T')[0];
    final response = await supa.Supabase.instance.client
        .from('growth_drops')
        .select()
        .eq('user_id', userId)
        .eq('drop_date', today)
        .order('created_at', ascending: false)
        .limit(1);

    if (response.isEmpty) return null;
    return fromSupabase(response.first);
  }

  Future<void> markAsRead(GrowthDrop currentDrop) async {
    if (currentDrop.isRead) return;
    
    await supa.Supabase.instance.client
        .from('growth_drops')
        .update({'is_read': true})
        .eq('id', currentDrop.id);
        
    final drop = state.valueOrNull;
    if (drop != null && drop.id == currentDrop.id) {
      state = AsyncValue.data(drop.copyWith(isRead: true));
    } else {
      // If state was null (e.g. from race condition), populate it
      state = AsyncValue.data(currentDrop.copyWith(isRead: true));
    }
  }

  Future<void> saveToJournal(GrowthDrop currentDrop) async {
    if (currentDrop.isSaved) return;
    
    await supa.Supabase.instance.client
        .from('growth_drops')
        .update({'is_saved': true})
        .eq('id', currentDrop.id);
        
    final drop = state.valueOrNull;
    if (drop != null && drop.id == currentDrop.id) {
      state = AsyncValue.data(drop.copyWith(isSaved: true));
    } else {
      state = AsyncValue.data(currentDrop.copyWith(isSaved: true));
    }
  }
}

final growthDropProvider =
    AsyncNotifierProvider<GrowthDropNotifier, GrowthDrop?>(() {
  return GrowthDropNotifier();
});

GrowthDrop fromSupabase(Map<String, dynamic> json) {
  final books = json['recommended_books'];

  Map<String, dynamic> bookMap = {};
  if (books is List && books.isNotEmpty) {
    bookMap = books.first as Map<String, dynamic>;
  } else if (books is String) {
    final decoded = jsonDecode(books);
    if (decoded is List && decoded.isNotEmpty) {
      bookMap = decoded.first as Map<String, dynamic>;
    } else if (decoded is Map<String, dynamic>) {
      bookMap = decoded;
    }
  } else if (books is Map<String, dynamic>) {
    bookMap = books;
  }

  String parseList(String key1, [String? key2]) {
    final raw = bookMap[key1] ?? (key2 != null ? bookMap[key2] : null);
    if (raw is List) {
      return raw.map((e) => e.toString()).join('\n');
    }
    // ponytail: handle literal \n from backend strings
    if (raw is String) return raw.replaceAll('\\n', '\n');
    return raw?.toString() ?? '';
  }

  return GrowthDrop(
    id: json['id'] as String,
    date: DateTime.parse(json['drop_date'] as String),
    focusArea: json['focus_area'] as String,
    bookTitle: bookMap['bookTitle'] as String? ?? bookMap['title'] as String? ?? 'Your Growth Book',
    bookAuthor: bookMap['bookAuthor'] as String? ?? bookMap['author'] as String? ?? 'AI Coach',
    whatItsAbout: parseList('whatItsAbout', 'what_its_about'),
    lessons: bookMap['lessons'] is List
        ? (bookMap['lessons'] as List).map((e) => e.toString()).toList()
        : [],
    summary: parseList('summary'),
    coverUrl: bookMap['coverUrl'] as String?,
    isRead: json['is_read'] as bool? ?? false,
    isSaved: json['is_saved'] as bool? ?? false,
  );
}

final readBooksCountProvider = FutureProvider<int>((ref) async {
  final userId = supa.Supabase.instance.client.auth.currentUser?.id ?? '';
  if (userId.isEmpty) return 0;
  final response = await supa.Supabase.instance.client
      .from('growth_drops')
      .select('id')
      .eq('user_id', userId)
      .eq('is_read', true);
  return (response as List).length;
});
