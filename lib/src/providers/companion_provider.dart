import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/repositories/companion_repository.dart';
import '../domain/models/companion.dart';

final companionRepositoryProvider = Provider<CompanionRepository>((ref) {
  return CompanionRepository();
});

final companionsProvider = FutureProvider<List<Companion>>((ref) async {
  final repo = ref.watch(companionRepositoryProvider);
  return repo.getAvailableCompanions();
});

final companionByIdProvider =
    FutureProvider.family<Companion?, String>((ref, id) async {
  final repo = ref.watch(companionRepositoryProvider);
  return repo.getCompanionById(id);
});
