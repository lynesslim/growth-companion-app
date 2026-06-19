import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/app_colors.dart';
import '../../domain/models/quest.dart';
import '../../providers/quests_provider.dart';
import '../../utils/haptic_utils.dart';
import 'book_data.dart';

class ActionPlansScreen extends ConsumerWidget {
  const ActionPlansScreen({super.key, required this.bookIndex});

  final int bookIndex;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final book = books[bookIndex.clamp(0, books.length - 1)];
    return Scaffold(
      body: _ActionPlansBody(bookIndex: bookIndex, book: book, ref: ref),
    );
  }
}

class _ActionPlansBody extends StatefulWidget {
  final int bookIndex;
  final BookData book;
  final WidgetRef ref;

  const _ActionPlansBody({
    required this.bookIndex,
    required this.book,
    required this.ref,
  });

  @override
  State<_ActionPlansBody> createState() => _ActionPlansBodyState();
}

class _ActionPlansBodyState extends State<_ActionPlansBody> {
  final Set<int> _selected = {};

  String _shortTitle(String lesson) {
    final idx = lesson.indexOf(' — ');
    if (idx != -1) return lesson.substring(0, idx).trim();
    return lesson;
  }

  void _toggle(int index) {
    HapticUtils.light();
    setState(() {
      if (_selected.contains(index)) {
        _selected.remove(index);
      } else {
        _selected.add(index);
      }
    });
  }

  void _continue() {
    HapticUtils.success();
    for (final i in _selected) {
      final title = _shortTitle(widget.book.lessons[i]);
      final quest = Quest(
        id: 'action_${widget.bookIndex}_$i',
        title: title,
        type: 'daily',
        description: widget.book.lessons[i],
        xpCategory: '+10 XP',
        duration: '15 min',
        xpReward: 10,
      );
      widget.ref.read(dailyQuestsProvider.notifier).addQuest(quest);
    }
    if (mounted) context.push('/congrats');
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [widget.book.gradientBegin, widget.book.gradientEnd],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () => context.pop(),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.arrow_back_rounded,
                        color: AppColors.white, size: 20),
                  ),
                ),
                const SizedBox(height: 24),
                Icon(widget.book.icon, color: AppColors.white, size: 32),
                const SizedBox(height: 16),
                Text(
                  widget.book.title,
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: AppColors.white,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.book.author,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Choose action plans to add to your daily quests.',
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.white,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
              itemCount: widget.book.lessons.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final lesson = widget.book.lessons[index];
                final isSelected = _selected.contains(index);
                final shortTitle = _shortTitle(lesson);

                return GestureDetector(
                  onTap: () => _toggle(index),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary.withValues(alpha: 0.08)
                          : AppColors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.grey200,
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 24,
                          height: 24,
                          margin: const EdgeInsets.only(top: 2),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isSelected
                                ? AppColors.primary
                                : Colors.transparent,
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.grey400,
                              width: 2,
                            ),
                          ),
                          child: isSelected
                              ? const Icon(Icons.check,
                                  color: AppColors.white, size: 14)
                              : null,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                shortTitle,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: isSelected
                                      ? AppColors.primary
                                      : AppColors.grey900,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                lesson,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.grey500,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
            child: SizedBox(
              width: double.infinity,
              child: GestureDetector(
                onTap: _continue,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primary, AppColors.pinkLight],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      _selected.isNotEmpty
                          ? 'Add to Quests & Continue'
                          : 'Continue',
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
    );
  }
}
