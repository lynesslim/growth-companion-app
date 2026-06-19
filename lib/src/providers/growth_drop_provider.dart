import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart' as supa;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/models/growth_drop.dart';

final growthDropProvider = FutureProvider<GrowthDrop?>((ref) async {
  final userId = supa.Supabase.instance.client.auth.currentUser?.id ?? '';
  if (userId.isEmpty) return null;
  final data = await supa.Supabase.instance.client
      .from('growth_drops')
      .select()
      .eq('user_id', userId)
      .order('drop_date', ascending: false)
      .limit(1)
      .maybeSingle();
  if (data == null) return null;
  return _fromSupabase(data);
});

GrowthDrop _fromSupabase(Map<String, dynamic> json) {
  final books = json['recommended_books'];
  final bookMap = books is String ? jsonDecode(books) : books as Map<String, dynamic>? ?? {};
  return GrowthDrop(
    id: json['id'] as String,
    date: DateTime.parse(json['drop_date'] as String),
    focusArea: json['focus_area'] as String,
    recommendedBooks: (bookMap['recommendedBooks'] as List<dynamic>?)?.cast<String>() ?? [],
    bookTitle: bookMap['bookTitle'] as String? ?? '',
    bookAuthor: bookMap['bookAuthor'] as String? ?? '',
    summary: bookMap['summary'] as String? ?? '',
    whyThisBook: bookMap['whyThisBook'] as String? ?? '',
    whatItsAbout: bookMap['whatItsAbout'] as String? ?? '',
    lessons: (bookMap['lessons'] as List<dynamic>?)?.cast<String>() ?? [],
    firstChapter: bookMap['firstChapter'] as String? ?? '',
    dailyAction: bookMap['dailyAction'] as String? ?? '',
    dailyActionDuration: bookMap['dailyActionDuration'] as String? ?? '',
  );
}
