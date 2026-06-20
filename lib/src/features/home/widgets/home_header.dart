import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/app_colors.dart';
import '../../../core/app_gradients.dart';
import '../../../core/animated_widgets.dart';
import '../../../providers/user_provider.dart';
import '../../../providers/growth_drop_provider.dart';

class HomeHeader extends ConsumerWidget {
  const HomeHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userProvider);
    final streak = userAsync.valueOrNull?.currentStreak ?? 0;
    final name = userAsync.valueOrNull?.name ?? 'Explorer';
    final xp = userAsync.valueOrNull?.currentXp ?? 0;
    final level = userAsync.valueOrNull?.level ?? 1;

    final booksCountAsync = ref.watch(readBooksCountProvider);
    final booksCount = booksCountAsync.valueOrNull ?? 0;

    final hour = DateTime.now().hour;
    final greeting = hour < 12 ? 'Good morning' : hour < 17 ? 'Good afternoon' : 'Good evening';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        EntranceFadeSlide(
          delayMs: 0,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: EntranceFadeSlide(
                  delayMs: 0,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$greeting, $name 👋',
                        style: const TextStyle(fontSize: 15, color: Color(0xFF6E6A67)),
                      ),
                      const SizedBox(height: 4),
                      EntranceFadeSlide(
                        delayMs: 45,
                        child: Text(
                          'Your growth',
                          style: GoogleFonts.inter(
                            fontSize: 40,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -1.2,
                            height: 1.0,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      EntranceFadeSlide(
                        delayMs: 90,
                        child: ShaderMask(
                          shaderCallback: (bounds) => AppGradients.headerNameGradient.createShader(bounds),
                          child: Text(
                            'starts today.',
                            style: GoogleFonts.playfairDisplay(
                              fontSize: 42,
                              fontWeight: FontWeight.w500,
                              fontStyle: FontStyle.italic,
                              height: 1.0,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              EntranceFadeSlide(
                delayMs: 0,
                child: Column(
                  children: [
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: const BoxDecoration(
                            gradient: AppGradients.headerPremiumGradient,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                          child: Text(
                            name[0].toUpperCase(),
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              color: const Color(0xFF39C96B),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2.5),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _StreakPill(days: streak),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        EntranceFadeSlide(
          delayMs: 135,
          child: _StatsRow(streak: streak, xp: xp, level: level, booksCount: booksCount),
        ),
      ],
    );
  }
}

class _StreakPill extends StatelessWidget {
  final int days;
  const _StreakPill({required this.days});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        '🔥 $days days',
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.orangeAccent,
        ),
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  final int streak;
  final int xp;
  final int level;
  final int booksCount;

  const _StatsRow({
    required this.streak,
    required this.xp,
    required this.level,
    required this.booksCount,
  });

  @override
  Widget build(BuildContext context) {
    final stats = [
      _StatData(icon: Icons.menu_book_rounded, value: '$booksCount', label: 'Books Read', iconColor: const Color(0xFF7C5CFF), bgColor: const Color(0xFFEEE8FF)),
      _StatData(icon: Icons.emoji_events_rounded, value: '$level', label: 'Level', iconColor: const Color(0xFFF6B91C), bgColor: const Color(0xFFFFF5D8)),
      _StatData(icon: Icons.local_fire_department_rounded, value: '$streak', label: 'Streak Days', iconColor: const Color(0xFFEC4F8C), bgColor: const Color(0xFFFFE7F1)),
      _StatData(icon: Icons.trending_up_rounded, value: '$xp', label: 'Growth Score', iconColor: const Color(0xFF48B96A), bgColor: const Color(0xFFE9F8ED)),
    ];

    return Row(
      children: List.generate(stats.length, (i) {
        final s = stats[i];
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(left: i == 0 ? 0 : 6, right: i == stats.length - 1 ? 0 : 6),
            child: Container(
              height: 145,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.72),
                borderRadius: BorderRadius.circular(26),
                border: Border.all(color: Colors.white, width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                  BoxShadow(
                    color: Colors.white.withValues(alpha: 0.6),
                    blurRadius: 8,
                    spreadRadius: -2,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: s.bgColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Icon(s.icon, size: 16, color: s.iconColor),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    s.value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    s.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textQuaternary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }
}

class _StatData {
  final IconData icon;
  final String value;
  final String label;
  final Color iconColor;
  final Color bgColor;
  const _StatData({
    required this.icon,
    required this.value,
    required this.label,
    required this.iconColor,
    required this.bgColor,
  });
}
