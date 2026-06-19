import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/app_colors.dart';
import '../../utils/haptic_utils.dart';
import '../../providers/user_provider.dart';
import '../../providers/companion_provider.dart';

class CompanionSelectionScreen extends ConsumerStatefulWidget {
  const CompanionSelectionScreen({super.key});

  @override
  ConsumerState<CompanionSelectionScreen> createState() =>
      _CompanionSelectionScreenState();
}

class _CompanionSelectionScreenState
    extends ConsumerState<CompanionSelectionScreen> {
  String? _selectedId;

  @override
  void initState() {
    super.initState();
    ref.read(companionRepositoryProvider);
  }

  @override
  Widget build(BuildContext context) {
    final companionsAsync = ref.watch(companionsProvider);
    final companions = companionsAsync.valueOrNull ?? [];

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              Text(
                'Choose Your\nCompanion',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                  height: 1.1,
                  color: AppColors.grey900,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'This creature will grow with you on your journey.',
                style: TextStyle(
                  fontSize: 15,
                  color: AppColors.grey500,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 40),
              Expanded(
                child: companionsAsync.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ListView.separated(
                        itemCount: companions.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 16),
                        itemBuilder: (context, index) {
                          final c = companions[index];
                          final isSelected = _selectedId == c.id;
                          final color = _companionColor(c.type);
                          return GestureDetector(
                            onTap: () {
                              HapticUtils.medium();
                              setState(() => _selectedId = c.id);
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeOut,
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: AppColors.white,
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(
                                  color: isSelected ? color : Colors.transparent,
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: isSelected
                                        ? color.withValues(alpha: 0.15)
                                        : AppColors.primary.withValues(alpha: 0.04),
                                    blurRadius: 20,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 64,
                                    height: 64,
                                    decoration: BoxDecoration(
                                      color: color.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Icon(
                                      _companionIcon(c.type),
                                      color: color,
                                      size: 30,
                                    ),
                                  ),
                                  const SizedBox(width: 20),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          c.name,
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w600,
                                            color: isSelected
                                                ? color
                                                : AppColors.grey900,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          c.description,
                                          style: const TextStyle(
                                            fontSize: 13,
                                            color: AppColors.grey500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    width: 28,
                                    height: 28,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: isSelected
                                          ? color
                                          : Colors.transparent,
                                      border: Border.all(
                                        color: isSelected
                                            ? color
                                            : AppColors.grey300,
                                        width: 2,
                                      ),
                                    ),
                                    child: isSelected
                                        ? const Icon(
                                            Icons.check,
                                            color: AppColors.white,
                                            size: 16,
                                          )
                                        : null,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 32),
                child: SizedBox(
                  width: double.infinity,
                  child: GestureDetector(
                    onTap: _selectedId != null
                        ? () {
                            HapticUtils.success();
                            ref
                                .read(userProvider.notifier)
                                .selectCompanion(_selectedId!);
                            context.go('/profile-created');
                          }
                        : null,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      decoration: BoxDecoration(
                        gradient: _selectedId != null
                            ? const LinearGradient(
                                colors: [
                                  AppColors.primary,
                                  AppColors.pinkLight,
                                ],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              )
                            : null,
                        color: _selectedId != null ? null : AppColors.grey200,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Center(
                        child: Text(
                          'Start Your Journey',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _companionColor(String type) {
    switch (type) {
      case 'discipline':
        return const Color(0xFF6366F1);
      case 'creativity':
        return const Color(0xFFEC4899);
      case 'wisdom':
        return const Color(0xFF14B8A6);
      default:
        return AppColors.primary;
    }
  }

  IconData _companionIcon(String type) {
    switch (type) {
      case 'discipline':
        return Icons.rocket_launch_rounded;
      case 'creativity':
        return Icons.auto_awesome_rounded;
      case 'wisdom':
        return Icons.psychology_rounded;
      default:
        return Icons.auto_awesome_rounded;
    }
  }
}
