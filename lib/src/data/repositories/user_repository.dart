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
        
    if (data != null) {
      final booksCountResponse = await supa.Supabase.instance.client
          .from('growth_drops')
          .select('id')
          .eq('user_id', _userId)
          .eq('is_read', true);
          
      data['books_read'] = (booksCountResponse as List).length;
      final user = User.fromJson(data);
      
      // If the streak is dead (more than 1 calendar day ago), report it as 0 to the UI.
      if (user.lastDropDate != null) {
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final last = DateTime(user.lastDropDate!.year, user.lastDropDate!.month, user.lastDropDate!.day);
        
        if (today.difference(last).inDays > 1) {
          return user.copyWith(currentStreak: 0);
        }
      }
      return user;
    }
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

  Future<User> updateStreak(int currentStreak, String lastActiveDate) async {
    if (_userId.isEmpty) throw Exception('Not authenticated');
    await supa.Supabase.instance.client
        .from('profiles')
        .update({
          'current_streak': currentStreak,
          'last_active_date': lastActiveDate,
        })
        .eq('id', _userId);
    return getUserProfile();
  }
}
