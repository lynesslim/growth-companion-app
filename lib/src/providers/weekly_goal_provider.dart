import 'package:supabase_flutter/supabase_flutter.dart' as supa;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/models/weekly_goal.dart';

final currentWeeklyGoalProvider =
    StateNotifierProvider<WeeklyGoalNotifier, AsyncValue<WeeklyGoal?>>((ref) {
  return WeeklyGoalNotifier();
});

class WeeklyGoalNotifier extends StateNotifier<AsyncValue<WeeklyGoal?>> {
  WeeklyGoalNotifier() : super(const AsyncValue.data(null)) {
    _init();
  }

  String get _userId => supa.Supabase.instance.client.auth.currentUser?.id ?? '';

  Future<void> _init() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final data = await supa.Supabase.instance.client
          .from('weekly_goals')
          .select()
          .eq('user_id', _userId)
          .eq('status', 'active')
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();
      if (data == null) return null;
      return WeeklyGoal(
        id: data['id'] as String,
        userId: data['user_id'] as String,
        focusArea: data['focus_area'] as String,
        intent: data['intent'] as String? ?? '',
        struggle: data['struggle'] as String? ?? '',
        status: data['status'] as String? ?? 'active',
        startDate: DateTime.parse(data['start_date'] as String),
        endDate: data['end_date'] != null
            ? DateTime.parse(data['end_date'] as String)
            : null,
      );
    });
  }

  Future<void> setGoal(WeeklyGoal goal) async {
    state = await AsyncValue.guard(() async {
      final data = await supa.Supabase.instance.client
          .from('weekly_goals')
          .insert({
            'user_id': _userId,
            'focus_area': goal.focusArea,
            'intent': goal.intent,
            'struggle': goal.struggle,
            'status': goal.status,
            'start_date': goal.startDate.toIso8601String(),
            'end_date': goal.endDate?.toIso8601String(),
          })
          .select()
          .single();
      return WeeklyGoal(
        id: data['id'] as String,
        userId: data['user_id'] as String,
        focusArea: data['focus_area'] as String,
        intent: data['intent'] as String? ?? '',
        struggle: data['struggle'] as String? ?? '',
        status: data['status'] as String? ?? 'active',
        startDate: DateTime.parse(data['start_date'] as String),
        endDate: data['end_date'] != null
            ? DateTime.parse(data['end_date'] as String)
            : null,
      );
    });
  }
}
