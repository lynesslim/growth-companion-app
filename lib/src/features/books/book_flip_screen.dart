import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/app_colors.dart';
import '../../core/app_typography.dart';
import '../../core/animated_widgets.dart';
import '../../domain/models/growth_drop.dart';
import '../../providers/growth_drop_provider.dart';
import '../../providers/user_provider.dart';
import '../../utils/haptic_utils.dart';

class BookFlipScreen extends ConsumerStatefulWidget {
  final GrowthDrop? book;
  const BookFlipScreen({super.key, this.book});

  @override
  ConsumerState<BookFlipScreen> createState() => _BookFlipScreenState();
}

class _BookFlipScreenState extends ConsumerState<BookFlipScreen> {
  int _currentPage = 0;
  bool _isAnimating = false;
  final _pageController = PageController();

  List<String> _getPageNames(GrowthDrop book) {
    final names = <String>['Cover', 'Why This Book', 'Lesson 1', 'Lesson 2', 'Lesson 3'];
    if (book.caseStudy != null) names.add('Case Study');
    if (book.actionableInsights != null) names.add('Insights');
    names.add('Summary');
    return names;
  }

  void _nextPage(GrowthDrop book) {
    HapticUtils.light();
    if (_isAnimating) return;
    final pageNames = _getPageNames(book);
    if (_currentPage >= pageNames.length - 1) {
      if (book.giftedBy == null) {
        ref.read(userProvider.notifier).updateStreak();
      }
      ref.read(growthDropProvider.notifier).markAsRead(book);
      context.push('/streak', extra: book);
      return;
    }
    _isAnimating = true;
    _pageController.nextPage(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }

  void _previousPage() {
    if (_isAnimating || _currentPage <= 0) return;
    HapticUtils.light();
    _isAnimating = true;
    _pageController.previousPage(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.book != null) return _buildBookUI(widget.book!);

    final dropAsync = ref.watch(growthDropProvider);

    return dropAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        body: Center(child: Text('Something went wrong: $e')),
      ),
      data: (drop) {
        if (drop == null) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('No growth drop for today.'),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () => context.push('/weekly-focus'),
                    child: const Text('Set your weekly focus'),
                  ),
                ],
              ),
            ),
          );
        }
        return _buildBookUI(drop);
      },
    );
  }

  Widget _buildBookUI(GrowthDrop book) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 24, 0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    color: AppColors.grey600,
                    onPressed: () => context.pop(),
                  ),
                  const Spacer(),
                  ...List.generate(_getPageNames(book).length, (i) {
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: i == _currentPage ? 20 : 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: i <= _currentPage
                            ? AppColors.primary
                            : AppColors.grey300,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    );
                  }),
                  const SizedBox(width: 8),
                  Text(
                    '${_currentPage + 1}/${_getPageNames(book).length}',
                    style: const TextStyle(
                      color: AppColors.grey400,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            if (book.giftedBy != null) ...[
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.card_giftcard, size: 16, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Text(
                      'Gifted by ${book.giftedBy}',
                      style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  onPageChanged: (page) {
                    setState(() {
                      _currentPage = page;
                      _isAnimating = false;
                    });
                  },
                  children: [
                    for (var i = 0; i < _getPageNames(book).length; i++)
                      _buildPageContent(i, book),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Row(
                children: [
                  if (_currentPage > 0)
                    PressScale(
                      onTap: _previousPage,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.grey100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.arrow_back_rounded,
                                size: 18, color: AppColors.grey600),
                            SizedBox(width: 4),
                            Text(
                              'Back',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: AppColors.grey600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  const Spacer(),
                  PressScale(
                    onTap: () => _nextPage(book),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.primary, AppColors.pinkLight],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _currentPage == _getPageNames(book).length - 1
                                ? 'Finish'
                                : _currentPage == 0
                                    ? 'Open Book'
                                    : 'Next Page',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppColors.white,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Icon(
                            _currentPage == _getPageNames(book).length - 1
                                ? Icons.check_rounded
                                : _currentPage == 0
                                    ? Icons.menu_book_rounded
                                    : Icons.arrow_forward_rounded,
                            color: AppColors.white,
                            size: 18,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPageContent(int index, GrowthDrop book) {
    final pageNames = _getPageNames(book);
    switch (pageNames[index]) {
      case 'Cover':
        return _CoverPage(book: book);
      case 'Why This Book':
        return _WhatItsAboutPage(book: book);
      case 'Lesson 1':
        return _LessonPage(lessonNumber: 1, lesson: book.lessons.isNotEmpty ? book.lessons[0] : '');
      case 'Lesson 2':
        return _LessonPage(lessonNumber: 2, lesson: book.lessons.length > 1 ? book.lessons[1] : '');
      case 'Lesson 3':
        return _LessonPage(lessonNumber: 3, lesson: book.lessons.length > 2 ? book.lessons[2] : '');
      case 'Case Study':
        return _CaseStudyPage(book: book);
      case 'Insights':
        return _ActionableInsightsPage(book: book);
      case 'Summary':
        return _FinalSummaryPage(book: book);
      default:
        return const SizedBox();
    }
  }

}

class _CaseStudyPage extends StatelessWidget {
  final GrowthDrop book;

  const _CaseStudyPage({required this.book});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.psychology_rounded,
              color: AppColors.primary,
              size: 22,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Case Study',
            style: AppTypography.h1Playfair.copyWith(
              fontSize: 22,
              color: AppColors.grey900,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Scrollbar(
              thumbVisibility: true,
              child: SingleChildScrollView(
                child: Text(
                  _cleanAiText(book.caseStudy ?? ''),
                  style: const TextStyle(
                    fontSize: 15,
                    height: 1.7,
                    color: AppColors.grey600,
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

String _cleanAiText(String text) {
  var lines = text.split('\n');
  for (var i = 0; i < lines.length; i++) {
    lines[i] = lines[i].replaceAll(RegExp(r'^\[?Paragraph \d+:\s*'), '');
    lines[i] = lines[i].replaceAll(RegExp(r'^Insight \d+:\s*'), '');
    if (lines[i].endsWith(']')) {
      lines[i] = lines[i].substring(0, lines[i].length - 1);
    }
  }
  return lines.join('\n');
}

class _ActionableInsightsPage extends StatefulWidget {
  final GrowthDrop book;

  const _ActionableInsightsPage({required this.book});

  @override
  State<_ActionableInsightsPage> createState() => _ActionableInsightsPageState();
}

class _ActionableInsightsPageState extends State<_ActionableInsightsPage> {
  final List<bool> _checked = [];
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _loadStates();
  }

  void _loadStates() async {
    final prefs = await SharedPreferences.getInstance();
    final insights = widget.book.actionableInsights ?? [];
    setState(() {
      _checked.clear();
      for (var i = 0; i < insights.length; i++) {
        final key = 'drop_${widget.book.id}_insight_$i';
        _checked.add(prefs.getBool(key) ?? false);
      }
      _loaded = true;
    });
  }

  void _toggle(int index) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'drop_${widget.book.id}_insight_$index';

    setState(() {
      _checked[index] = !_checked[index];
    });
    await prefs.setBool(key, _checked[index]);
  }

  @override
  Widget build(BuildContext context) {
    final insights = widget.book.actionableInsights ?? [];
    if (!_loaded) {
      return const Center(child: CircularProgressIndicator());
    }
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.bolt_rounded,
              color: AppColors.warning,
              size: 22,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Thing To Do',
            style: AppTypography.h1Playfair.copyWith(
              fontSize: 22,
              color: AppColors.grey900,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.separated(
              itemCount: insights.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) => GestureDetector(
                onTap: () => _toggle(index),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.warning.withValues(alpha: 0.15),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: _checked[index]
                              ? AppColors.warning
                              : Colors.transparent,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.warning,
                            width: 2,
                          ),
                        ),
                        child: _checked[index]
                            ? const Icon(
                                Icons.check_rounded,
                                color: AppColors.white,
                                size: 18,
                              )
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _cleanAiText(insights[index]),
                          style: TextStyle(
                            fontSize: 15,
                            height: 1.5,
                            color: _checked[index]
                                ? AppColors.grey400
                                : AppColors.grey700,
                            decoration: _checked[index]
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        ),
                      ),
                    ],
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

class _CoverPage extends StatelessWidget {
  final GrowthDrop book;

  const _CoverPage({required this.book});

  @override
  Widget build(BuildContext context) {
    String? cleanSvg;
    if (book.coverUrl != null && book.coverUrl!.trim().isNotEmpty) {
      cleanSvg = book.coverUrl!.trim();
      if (cleanSvg.startsWith('```')) {
        cleanSvg = cleanSvg.replaceFirst(RegExp(r'^```[a-zA-Z]*\n?'), '');
        cleanSvg = cleanSvg.replaceFirst(RegExp(r'\n?```$'), '');
      }
    }

    Widget backgroundWidget;
    if (cleanSvg != null && cleanSvg.startsWith('http')) {
      backgroundWidget = cleanSvg.endsWith('.svg') 
          ? SvgPicture.network(cleanSvg, fit: BoxFit.cover)
          : Image.network(cleanSvg, fit: BoxFit.cover);
    } else if (cleanSvg != null && cleanSvg.contains('<svg')) {
      try {
        backgroundWidget = SvgPicture.string(
          cleanSvg,
          width: double.infinity,
          height: double.infinity,
          fit: BoxFit.cover,
        );
      } catch (e) {
        backgroundWidget = Container(
          color: Colors.red.shade100,
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: Text("SVG PARSE ERROR: $e\n\nRAW STRING:\n$cleanSvg"),
          ),
        );
      }
    } else {
      backgroundWidget = Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.primary, AppColors.pinkLight],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      );
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 32,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Background
            backgroundWidget,
            // Text Overlay
            Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: AppColors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.menu_book_rounded,
                        color: AppColors.white, size: 28),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    book.focusArea,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.white.withValues(alpha: 0.8),
                      fontWeight: FontWeight.w500,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    book.bookTitle,
                    style: AppTypography.h1Playfair.copyWith(
                      fontSize: 34,
                      color: AppColors.white,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    book.bookAuthor,
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.white.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WhatItsAboutPage extends StatelessWidget {
  final GrowthDrop book;

  const _WhatItsAboutPage({required this.book});

  @override
  Widget build(BuildContext context) {
    final points = book.whatItsAbout
        .split('\n')
        .where((l) => l.trim().isNotEmpty)
        .toList();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.menu_book_rounded,
              color: AppColors.primary,
              size: 22,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'What this book is about',
            style: AppTypography.h1Playfair.copyWith(
              fontSize: 22,
              color: AppColors.grey900,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Scrollbar(
              thumbVisibility: true,
              child: ListView.separated(
                itemCount: points.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) => Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 6),
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        points[index],
                        style: const TextStyle(
                          fontSize: 15,
                          height: 1.7,
                          color: AppColors.grey600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LessonPage extends StatelessWidget {
  final int lessonNumber;
  final String lesson;

  const _LessonPage({
    required this.lessonNumber,
    required this.lesson,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, 4),
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
              gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.pinkLight],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                '$lessonNumber',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Lesson $lessonNumber',
            style: AppTypography.h1Playfair.copyWith(
              fontSize: 20,
              color: AppColors.grey900,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Scrollbar(
              thumbVisibility: true,
              child: SingleChildScrollView(
                child: Text(
                  lesson,
                  style: const TextStyle(
                    fontSize: 15,
                    height: 1.7,
                    color: AppColors.grey600,
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

class _FinalSummaryPage extends StatelessWidget {
  final GrowthDrop book;

  const _FinalSummaryPage({required this.book});

  @override
  Widget build(BuildContext context) {
    final points = book.summary
        .split('\n')
        .where((l) => l.trim().isNotEmpty)
        .toList();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.summarize_rounded,
              color: AppColors.primary,
              size: 22,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Key Takeaways',
            style: AppTypography.h1Playfair.copyWith(
              fontSize: 22,
              color: AppColors.grey900,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Scrollbar(
              thumbVisibility: true,
              child: ListView.separated(
                itemCount: points.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) => Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 6),
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        points[index],
                        style: const TextStyle(
                          fontSize: 15,
                          height: 1.7,
                          color: AppColors.grey600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary.withValues(alpha: 0.05),
                    AppColors.pinkLight.withValues(alpha: 0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.1),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.primary, AppColors.pinkLight],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.local_fire_department_rounded,
                      color: AppColors.white,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Amazing work!',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.grey900,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'You finished this drop. Swipe up to continue your streak.',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.grey500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
