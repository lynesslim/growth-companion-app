import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/repositories/tasks_repository.dart';
import '../domain/models/quest.dart';
import 'user_provider.dart';

final tasksRepositoryProvider = Provider<TasksRepository>((ref) {
  return TasksRepository();
});

final dailyQuestsProvider =
    StateNotifierProvider<DailyQuestsNotifier, AsyncValue<List<Quest>>>(
        (ref) {
  final repo = ref.watch(tasksRepositoryProvider);
  return DailyQuestsNotifier(repo, ref);
});

class DailyQuestsNotifier extends StateNotifier<AsyncValue<List<Quest>>> {
  final TasksRepository _repository;
  final Ref _ref;

  DailyQuestsNotifier(this._repository, this._ref)
      : super(const AsyncValue.loading()) {
    _init();
  }

  Future<void> _init() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repository.getDailyQuests());
  }

  void addQuest(Quest quest) {
    final current = [...state.valueOrNull ?? []];
    state = AsyncValue.data([quest, ...current]);
    _repository.addQuest(quest);
  }

  Future<void> completeQuest(String questId) async {
    state = await AsyncValue.guard(() async {
      final updated = await _repository.completeQuest(questId);
      final current = state.valueOrNull ?? [];
      return current.map((q) => q.id == questId ? updated : q).toList();
    });

    _ref.read(userProvider.notifier).updateXp(10);
  }
}
