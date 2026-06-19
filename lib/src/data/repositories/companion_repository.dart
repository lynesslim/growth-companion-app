import '../../domain/models/companion.dart';

class CompanionRepository {
  static final List<Companion> _mockCompanions = [
    const Companion(
      id: 'companion_1',
      name: 'Ambition',
      type: 'discipline',
      description: 'For discipline, career, and action',
      assetPath: 'assets/companions/ambition.riv',
    ),
    const Companion(
      id: 'companion_2',
      name: 'Creativity',
      type: 'creativity',
      description: 'For expression, imagination, and originality',
      assetPath: 'assets/companions/creativity.riv',
    ),
    const Companion(
      id: 'companion_3',
      name: 'Wisdom',
      type: 'wisdom',
      description: 'For focus, clarity, and calm',
      assetPath: 'assets/companions/wisdom.riv',
    ),
  ];

  Future<List<Companion>> getAvailableCompanions() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _mockCompanions;
  }

  Future<Companion?> getCompanionById(String id) async {
    await Future.delayed(const Duration(milliseconds: 150));
    try {
      return _mockCompanions.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }
}
