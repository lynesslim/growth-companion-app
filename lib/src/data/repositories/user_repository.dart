import 'package:supabase_flutter/supabase_flutter.dart' as supa;
import '../../domain/models/user.dart';

class UserRepository {
  String get _userId => supa.Supabase.instance.client.auth.currentUser?.id ?? '';

  Future<User> getUserProfile() async {
    if (_userId.isEmpty) throw Exception('Not authenticated');
    final data = await supa.Supabase.instance.client
        .from('profiles')
        .select()
        .eq('id', _userId)
        .maybeSingle();
    if (data != null) return User.fromJson(data);
    throw Exception('Profile not found');
  }

  Future<User> updateXp(int xp) async {
    if (_userId.isEmpty) throw Exception('Not authenticated');
    final user = await getUserProfile();
    final newXp = user.currentXp + xp;
    await supa.Supabase.instance.client
        .from('profiles')
        .update({'current_xp': newXp})
        .eq('id', _userId);
    return user.copyWith(currentXp: newXp);
  }

  Future<User> updateOnboardingData(User updatedUser) async {
    if (_userId.isEmpty) throw Exception('Not authenticated');
    await supa.Supabase.instance.client
        .from('profiles')
        .update({
          'name': updatedUser.name,
          'onboarding_profile': updatedUser.onboardingProfile
        })
        .eq('id', _userId);
    return getUserProfile();
  }
}
