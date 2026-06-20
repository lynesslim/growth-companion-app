import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart' as supa;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/models/growth_drop.dart';

final growthDropProvider = FutureProvider<GrowthDrop?>((ref) async {
  final userId = supa.Supabase.instance.client.auth.currentUser?.id ?? '';
  if (userId.isEmpty) return null;
  final today = DateTime.now().toIso8601String().split('T')[0];
  final data = await supa.Supabase.instance.client
      .from('growth_drops')
      .select()
      .eq('user_id', userId)
      .eq('drop_date', today)
      .maybeSingle();
  if (data == null) return null;
  return _fromSupabase(data);
});

GrowthDrop _fromSupabase(Map<String, dynamic> json) {
  final books = json['recommended_books'];
  
  // The Edge Function saves it as an array of 1 book object
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

  // Parse GPT JSON keys
  final questsRaw = bookMap['quests'] as List<dynamic>? ?? [];
  final parsedQuests = questsRaw.map((q) {
    if (q is Map) {
      final title = q['title']?.toString() ?? '';
      final desc = q['description']?.toString() ?? '';
      if (desc.isNotEmpty) {
        return desc;
      }
      return title;
    }
    return q.toString();
  }).toList();

  // Parse first chapter
  final fcTitle = bookMap['first_chapter_title'] as String? ?? '';
  final fcDesc = bookMap['first_chapter_description'] as String? ?? '';
  String parsedFirstChapter = '';
  
  if (fcTitle.isNotEmpty && fcDesc.isNotEmpty) {
    parsedFirstChapter = '$fcTitle\n\n$fcDesc';
  } else if (fcTitle.isNotEmpty || fcDesc.isNotEmpty) {
    parsedFirstChapter = fcTitle.isNotEmpty ? fcTitle : fcDesc;
  } else {
    // Fallback to old format
    final firstChapRaw = bookMap['first_chapter'];
    if (firstChapRaw is Map) {
      final t = firstChapRaw['title']?.toString() ?? '';
      final d = firstChapRaw['description']?.toString() ?? '';
      parsedFirstChapter = t.isNotEmpty && d.isNotEmpty ? '$t\n\n$d' : (t.isNotEmpty ? t : d);
    } else if (firstChapRaw is String && firstChapRaw.isNotEmpty) {
      parsedFirstChapter = firstChapRaw;
    } else {
      parsedFirstChapter = 'Read the introduction to discover why this matters for your specific journey.';
    }
  }

  return GrowthDrop(
    id: json['id'] as String,
    date: DateTime.parse(json['drop_date'] as String),
    focusArea: json['focus_area'] as String,
    recommendedBooks: const [], // legacy
    bookTitle: bookMap['title'] as String? ?? 'Your Growth Book',
    bookAuthor: bookMap['author'] as String? ?? 'AI Coach',
    summary: bookMap['summary'] as String? ?? '',
    whyThisBook: '', // deprecated
    whatItsAbout: '', // deprecated
    lessons: (bookMap['lessons'] as List<dynamic>?)?.cast<String>() ?? [],
    firstChapter: parsedFirstChapter,
    dailyAction: '', // deprecated
    dailyActionDuration: '', // deprecated
    quests: parsedQuests,
  );
}
