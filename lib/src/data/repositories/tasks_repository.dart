import '../../domain/models/quest.dart';
import '../../domain/models/weekly_goal.dart';

class TasksRepository {
  final List<Quest> _dailyQuests = [
    const Quest(
      id: 'quest_1',
      title: 'Protect 30 minutes of focus',
      xpReward: 10,
      isCompleted: false,
      type: 'daily',
      description: 'Inspired by: Deep Work',
      xpCategory: '+10 Focus XP',
      duration: '30 min',
    ),
    const Quest(
      id: 'quest_2',
      title: 'Write down 5 rough ideas',
      xpReward: 8,
      isCompleted: false,
      type: 'daily',
      description: 'Inspired by: The Creative Act',
      xpCategory: '+8 Creativity XP',
      duration: '15 min',
    ),
    const Quest(
      id: 'quest_3',
      title: 'Review one expense',
      xpReward: 10,
      isCompleted: false,
      type: 'daily',
      description: 'Inspired by: I Will Teach You To Be Rich',
      xpCategory: '+10 Wealth XP',
      duration: '10 min',
    ),
  ];

  final List<Quest> _weeklyQuests = [
    const Quest(
      id: 'quest_4',
      title: 'Read your first lesson',
      xpReward: 15,
      isCompleted: true,
      type: 'weekly',
      description: 'Completed yesterday',
      xpCategory: '+15 XP',
      duration: '',
    ),
    const Quest(
      id: 'quest_5',
      title: 'Complete all 3 book overviews',
      xpReward: 25,
      isCompleted: false,
      type: 'weekly',
      description: 'Inspired by: Weekly Focus',
      xpCategory: '+25 Wisdom XP',
      duration: '20 min',
    ),
  ];

  Future<List<Quest>> getDailyQuests() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _dailyQuests;
  }

  Future<List<Quest>> getWeeklyQuests() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _weeklyQuests;
  }

  Future<Quest> completeQuest(String questId) async {
    await Future.delayed(const Duration(milliseconds: 200));

    final dailyIndex = _dailyQuests.indexWhere((q) => q.id == questId);
    if (dailyIndex != -1) {
      _dailyQuests[dailyIndex] = _dailyQuests[dailyIndex].copyWith(
        isCompleted: true,
        completedAt: DateTime.now(),
      );
      return _dailyQuests[dailyIndex];
    }

    final weeklyIndex = _weeklyQuests.indexWhere((q) => q.id == questId);
    if (weeklyIndex != -1) {
      _weeklyQuests[weeklyIndex] = _weeklyQuests[weeklyIndex].copyWith(
        isCompleted: true,
        completedAt: DateTime.now(),
      );
      return _weeklyQuests[weeklyIndex];
    }

    throw Exception('Quest not found: $questId');
  }

  WeeklyGoal? _currentWeeklyGoal;

  Future<WeeklyGoal?> getCurrentWeeklyGoal(String userId) async {
    await Future.delayed(const Duration(milliseconds: 150));
    return _currentWeeklyGoal;
  }

  Future<WeeklyGoal> setWeeklyGoal(WeeklyGoal goal) async {
    await Future.delayed(const Duration(milliseconds: 200));
    _currentWeeklyGoal = goal;
    return goal;
  }
}
