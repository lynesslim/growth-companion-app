import 'package:supabase_flutter/supabase_flutter.dart' as supa;
import '../../domain/models/companion.dart';

class CompanionRepository {
  Future<List<Companion>> getAvailableCompanions() async {
    final data = await supa.Supabase.instance.client
        .from('companions')
        .select()
        .order('created_at');
    return (data as List).map((json) => Companion(
      id: json['id'] as String,
      name: json['name'] as String,
      type: json['type'] as String,
      description: json['description'] as String? ?? '',
      assetPath: json['asset_path'] as String? ?? '',
    )).toList();
  }

  Future<Companion?> getCompanionById(String id) async {
    final data = await supa.Supabase.instance.client
        .from('companions')
        .select()
        .eq('id', id)
        .maybeSingle();
    if (data == null) return null;
    return Companion(
      id: data['id'] as String,
      name: data['name'] as String,
      type: data['type'] as String,
      description: data['description'] as String? ?? '',
      assetPath: data['asset_path'] as String? ?? '',
    );
  }
}
