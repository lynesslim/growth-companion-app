import 'package:supabase_flutter/supabase_flutter.dart' as supa;
import '../../domain/models/quest.dart';
import '../../domain/models/weekly_goal.dart';

class TasksRepository {
  String get _userId => supa.Supabase.instance.client.auth.currentUser?.id ?? '';

  Future<List<Quest>> getDailyQuests() async {
    if (_userId.isEmpty) return [];
    final data = await supa.Supabase.instance.client
        .from('quests')
        .select()
        .eq('user_id', _userId)
        .eq('quest_type', 'daily')
        .order('created_at');
    return (data as List).map((json) => _questFromSupabase(json)).toList();
  }

  Future<List<Quest>> getWeeklyQuests() async {
    if (_userId.isEmpty) return [];
    final data = await supa.Supabase.instance.client
        .from('quests')
        .select()
        .eq('user_id', _userId)
        .eq('quest_type', 'weekly')
        .order('created_at');
    return (data as List).map((json) => _questFromSupabase(json)).toList();
  }

  Future<Quest> addQuest(Quest quest) async {
    if (_userId.isEmpty) throw Exception('Not authenticated');
    final data = await supa.Supabase.instance.client
        .from('quests')
        .insert({
          'user_id': _userId,
          'title': quest.title,
          'xp_reward': quest.xpReward,
          'is_completed': quest.isCompleted,
          'quest_type': quest.type,
        })
        .select()
        .single();
    return _questFromSupabase(data);
  }

  Future<Quest> completeQuest(String questId) async {
    final data = await supa.Supabase.instance.client
        .from('quests')
        .update({'is_completed': true})
        .eq('id', questId)
        .select()
        .single();
    return _questFromSupabase(data);
  }

  Future<WeeklyGoal?> getCurrentWeeklyGoal() async {
    if (_userId.isEmpty) return null;
    final data = await supa.Supabase.instance.client
        .from('weekly_goals')
        .select()
        .eq('user_id', _userId)
        .eq('status', 'active')
        .maybeSingle();
    if (data == null) return null;
    return _weeklyGoalFromSupabase(data);
  }

  Future<WeeklyGoal> setWeeklyGoal(WeeklyGoal goal) async {
    final data = await supa.Supabase.instance.client
        .from('weekly_goals')
        .insert({
          'user_id': _userId,
          'focus_area': goal.focusArea,
          'status': goal.status,
          'start_date': goal.startDate.toIso8601String(),
          'end_date': goal.endDate?.toIso8601String(),
        })
        .select()
        .single();
    return _weeklyGoalFromSupabase(data);
  }

  Quest _questFromSupabase(Map<String, dynamic> json) => Quest(
        id: json['id'] as String,
        title: json['title'] as String,
        xpReward: (json['xp_reward'] as num?)?.toInt() ?? 10,
        isCompleted: json['is_completed'] as bool? ?? false,
        type: (json['quest_type'] as String?) ?? 'daily',
        description: json['description'] as String? ?? '',
        xpCategory: json['xp_category'] as String? ?? '+10 XP',
        duration: json['duration'] as String? ?? '15 min',
        completedAt: json['completed_at'] != null
            ? DateTime.parse(json['completed_at'] as String)
            : null,
      );

  WeeklyGoal _weeklyGoalFromSupabase(Map<String, dynamic> json) => WeeklyGoal(
        id: json['id'] as String,
        userId: json['user_id'] as String,
        focusArea: json['focus_area'] as String,
        status: json['status'] as String? ?? 'active',
        startDate: DateTime.parse(json['start_date'] as String),
        endDate: json['end_date'] != null
            ? DateTime.parse(json['end_date'] as String)
            : null,
      );
}
