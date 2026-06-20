import 'package:flutter/material.dart';

class MotionDurations {
  MotionDurations._();
  static const Duration press = Duration(milliseconds: 90);
  static const Duration fast = Duration(milliseconds: 220);
  static const Duration medium = Duration(milliseconds: 300);
  static const Duration long = Duration(milliseconds: 360);
  static const Duration crossfade = Duration(milliseconds: 200);
}

class MotionOffsets {
  MotionOffsets._();
  static const double entranceSlide = 12.0;
  static const double pressScale = 0.98;
  static const double cardPressScale = 0.985;
  static const double tabSlideFraction = 0.04;
}

class MotionSprings {
  MotionSprings._();
  static const SpringDescription defaultSpring = SpringDescription(
    mass: 1.0,
    stiffness: 300.0,
    damping: 25.0,
  );
  static const SpringDescription gentleSpring = SpringDescription(
    mass: 1.0,
    stiffness: 200.0,
    damping: 30.0,
  );
}

class MotionStagger {
  MotionStagger._();
  static const int maxItems = 5;
  static const Duration interval = Duration(milliseconds: 50);
}

class MotionAccessibility {
  MotionAccessibility._();
  static bool isReducedMotion(BuildContext context) {
    return MediaQuery.of(context).disableAnimations;
  }
}
