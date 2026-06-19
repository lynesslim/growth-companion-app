import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/repositories/tasks_repository.dart';
import '../domain/models/weekly_goal.dart';
import 'quests_provider.dart';

final currentWeeklyGoalProvider =
    StateNotifierProvider<WeeklyGoalNotifier, AsyncValue<WeeklyGoal?>>((ref) {
  final repo = ref.watch(tasksRepositoryProvider);
  return WeeklyGoalNotifier(repo);
});

class WeeklyGoalNotifier extends StateNotifier<AsyncValue<WeeklyGoal?>> {
  final TasksRepository _repository;

  WeeklyGoalNotifier(this._repository)
      : super(const AsyncValue.data(null)) {
    _init();
  }

  Future<void> _init() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repository.getCurrentWeeklyGoal());
  }

  Future<void> setGoal(WeeklyGoal goal) async {
    state = await AsyncValue.guard(() => _repository.setWeeklyGoal(goal));
  }
}
