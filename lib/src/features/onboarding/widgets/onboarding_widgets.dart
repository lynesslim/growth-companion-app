import 'package:flutter/material.dart';
import '../../../core/app_colors.dart';

class OnboardingLayout extends StatelessWidget {
  final Widget child;
  final Widget? bottom;
  final double progress;

  const OnboardingLayout({
    super.key,
    required this.child,
    this.bottom,
    this.progress = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            if (progress > 0)
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 4,
                    backgroundColor: AppColors.grey200,
                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                  ),
                ),
              ),
            Expanded(child: child),
            ?bottom,
          ],
        ),
      ),
    );
  }
}

class SelectionCard extends StatelessWidget {
  final String label;
  final bool selected;
  final bool multi;
  final VoidCallback onTap;

  const SelectionCard({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.multi = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary.withValues(alpha: 0.1) : AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.grey200,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: multi ? BoxShape.rectangle : BoxShape.circle,
                borderRadius: multi ? BorderRadius.circular(4) : null,
                color: selected ? AppColors.primary : Colors.transparent,
                border: Border.all(
                  color: selected ? AppColors.primary : AppColors.grey400,
                  width: 2,
                ),
              ),
              child: selected
                  ? const Icon(Icons.check, color: AppColors.white, size: 14)
                  : null,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  color: selected ? AppColors.primary : AppColors.grey800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TopicPill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const TopicPill({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.grey200,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: selected ? AppColors.white : AppColors.grey700,
          ),
        ),
      ),
    );
  }
}

class QuoteCard extends StatelessWidget {
  final String quote;
  final bool? answer;
  final ValueChanged<bool> onAnswer;

  const QuoteCard({
    super.key,
    required this.quote,
    required this.answer,
    required this.onAnswer,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.pinkLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Icon(Icons.format_quote_rounded,
              color: AppColors.white.withValues(alpha: 0.4), size: 40),
          const SizedBox(height: 12),
          Text(
            quote,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 18,
              height: 1.5,
              color: AppColors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: () => onAnswer(false),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                  decoration: BoxDecoration(
                    color: answer == false
                        ? AppColors.white
                        : AppColors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    Icons.close_rounded,
                    color: answer == false ? AppColors.error : AppColors.white,
                    size: 28,
                  ),
                ),
              ),
              const SizedBox(width: 20),
              GestureDetector(
                onTap: () => onAnswer(true),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                  decoration: BoxDecoration(
                    color: answer == true
                        ? AppColors.white
                        : AppColors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    Icons.check_rounded,
                    color: answer == true ? AppColors.success : AppColors.white,
                    size: 28,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
