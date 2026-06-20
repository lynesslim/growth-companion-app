import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/repositories/user_repository.dart';
import '../domain/models/user.dart';
import 'auth_provider.dart';

final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepository();
});

final userProvider =
    StateNotifierProvider<UserStateNotifier, AsyncValue<User>>((ref) {
  final repo = ref.watch(userRepositoryProvider);
  final notifier = UserStateNotifier(repo);

  ref.listen(authStateProvider, (_, next) {
    if (next.valueOrNull != null) {
      notifier.refresh();
    }
  });

  return notifier;
});

class UserStateNotifier extends StateNotifier<AsyncValue<User>> {
  final UserRepository _repository;

  UserStateNotifier(this._repository)
      : super(const AsyncValue.loading()) {
    _init();
  }

  Future<void> _init() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repository.getUserProfile());
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repository.getUserProfile());
  }

  Future<void> updateStreak() async {
    state = await AsyncValue.guard(() async {
      final user = await _repository.getUserProfile();
      final today = DateTime.now();
      final todayDate = DateTime(today.year, today.month, today.day);
      final lastActive = user.lastDropDate;
      final lastActiveDate = lastActive != null
          ? DateTime(lastActive.year, lastActive.month, lastActive.day)
          : null;

      if (lastActiveDate == todayDate) {
        return user.copyWith(currentStreak: user.currentStreak);
      }

      final diff = lastActiveDate != null
          ? todayDate.difference(lastActiveDate).inDays
          : 999;

      final newStreak = diff == 1 ? user.currentStreak + 1 : 1;
      return _repository.updateStreak(newStreak,
          todayDate.toIso8601String().split('T')[0]);
    });
  }

  Future<void> updateXp(int xp) async {
    state = await AsyncValue.guard(() => _repository.updateXp(xp));
  }

  Future<void> saveOnboardingData(User updatedUser) async {
    state = await AsyncValue.guard(() => _repository.updateOnboardingData(updatedUser));
  }
}
