import 'package:flutter/material.dart';

class AppGradients {
  AppGradients._();

  static const growthDropCardBg = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFE8D6), Color(0xFFFFF1EB), Color(0xFFFDE8F1), Color(0xFFF3E5F5)],
  );

  static const headerNameGradient = LinearGradient(
    colors: [Color(0xFFF36A21), Color(0xFFE6819E), Color(0xFFB64FD2)],
  );

  static const headerPremiumGradient = RadialGradient(
    colors: [Color(0xFFFFF0B8), Color(0xFFFFD6C4), Color(0xFFF7B6D4)],
  );

  static const cardBgGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF2E2623), Color(0xFF1E1816)],
  );

  static const socialDropPurple = [Color(0xFFEEE6FF), Color(0xFFCBB7FF)];
  static const socialDropYellow = [Color(0xFFFFF6D1), Color(0xFFFFE59E)];
  static const socialDropPeach = [Color(0xFFFFEDE6), Color(0xFFFFD1C2)];
  static const socialDropLavender = [Color(0xFFE8EAF6), Color(0xFFC5CAE9)];
}
