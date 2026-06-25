import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum TutorialStep {
  none,
  step1SocialTab,
  step2AcceptRequest,
  step3SendDrop,
  step4SendBlindBox,
  step5StreakExplanation,
}

final socialTabKey = GlobalKey();
final socialTabTutorialKey = GlobalKey();
final acceptRequestKey = GlobalKey();
final sendDropButtonKey = GlobalKey();
final sendBlindBoxKey = GlobalKey();
final cloooStreakKey = GlobalKey();


class TutorialNotifier extends StateNotifier<TutorialStep> {
  TutorialNotifier() : super(TutorialStep.none);

  void startTutorial() {
    state = TutorialStep.step1SocialTab;
  }

  void setStep(TutorialStep step) {
    state = step;
  }

  void nextStep() {
    if (state == TutorialStep.step1SocialTab) {
      state = TutorialStep.step2AcceptRequest;
    } else if (state == TutorialStep.step2AcceptRequest) {
      state = TutorialStep.step3SendDrop;
    } else if (state == TutorialStep.step3SendDrop) {
      state = TutorialStep.step4SendBlindBox;
    } else if (state == TutorialStep.step4SendBlindBox) {
      state = TutorialStep.step5StreakExplanation;
    }
  }

  void completeTutorial() {
    state = TutorialStep.none;
  }
}

final tutorialStepProvider =
    StateNotifierProvider<TutorialNotifier, TutorialStep>((ref) {
  return TutorialNotifier();
});
