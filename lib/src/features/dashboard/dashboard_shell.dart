import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/app_colors.dart';
import '../../utils/haptic_utils.dart';

class DashboardShell extends StatefulWidget {
  final StatefulNavigationShell navigationShell;

  const DashboardShell({super.key, required this.navigationShell});

  @override
  State<DashboardShell> createState() => _DashboardShellState();
}

class _DashboardShellState extends State<DashboardShell> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widget.navigationShell,
      extendBody: true,
      bottomNavigationBar: _FloatingBottomNav(
        currentIndex: widget.navigationShell.currentIndex,
        onTap: (index) {
          HapticUtils.light();
          widget.navigationShell.goBranch(
            index,
            initialLocation: index == widget.navigationShell.currentIndex,
          );
        },
      ),
    );
  }
}

class _FloatingBottomNav extends StatelessWidget {
  final int currentIndex;
  final void Function(int) onTap;

  const _FloatingBottomNav({
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final items = [
      (icon: Icons.home_rounded, label: 'Home'),
      (icon: Icons.people_rounded, label: 'Social'),
      (icon: Icons.auto_stories_rounded, label: 'Journal'),
      (icon: Icons.person_rounded, label: 'Profile'),
    ];

    return Container(
      margin: const EdgeInsets.only(left: 21, right: 21, bottom: 21),
      height: 72,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(36),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.1),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(36),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            color: AppColors.secondarySurface.withValues(alpha: 0.50),
            child: Row(
              children: List.generate(items.length, (i) {
                final isSelected = currentIndex == i;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => onTap(i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 260),
                      curve: Curves.easeOutCubic,
                      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.white.withValues(alpha: 0.90)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(28),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 6),
                          Icon(
                            items[i].icon,
                            color: isSelected
                                ? const Color(0xFFF06A19)
                                : AppColors.textSecondary,
                            size: 24,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            items[i].label,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                              color: isSelected
                                  ? const Color(0xFFF06A19)
                                  : AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Container(
                            width: 4,
                            height: 4,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFFF06A19)
                                  : Colors.transparent,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}
