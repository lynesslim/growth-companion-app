import 'dart:convert';
import 'lib/src/domain/models/user.dart';

void main() {
  final data = {
    "id": "c797aea3-4ff0-4846-8988-7c4b661f5fc8",
    "name": null,
    "current_xp": 0,
    "level": 1,
    "current_streak": 0,
    "selected_companion_id": null,
    "onboarding_profile": {
      "stage": "Student",
      "struggle": "I procrastinate",
      "dailyTime": "5 min",
      "focusArea": "Confidence",
      "aspiration": "More disciplined",
      "motivation": "Seeing progress"
    },
    "created_at": "2026-06-19 09:06:16.160244+00"
  };
  
  try {
    final user = User.fromJson(data);
    print('SUCCESS: user.onboardingProfile = ${user.onboardingProfile}');
    print('isEmpty = ${user.onboardingProfile.isEmpty}');
  } catch (e, stack) {
    print('ERROR: $e');
    print(stack);
  }
}
