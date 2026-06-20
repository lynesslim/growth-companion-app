import 'package:supabase_flutter/supabase_flutter.dart' as supa;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/models/growth_drop.dart';
import 'growth_drop_provider.dart';

final journalProvider = FutureProvider<List<GrowthDrop>>((ref) async {
  final userId = supa.Supabase.instance.client.auth.currentUser?.id ?? '';
  if (userId.isEmpty) return [];
  final data = await supa.Supabase.instance.client
      .from('growth_drops')
      .select()
      .eq('is_saved', true)
      .eq('user_id', userId)
      .order('drop_date', ascending: false);
  return data.map((json) => fromSupabase(json)).toList();
});
