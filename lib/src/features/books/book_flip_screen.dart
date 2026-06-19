import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/app_colors.dart';
import '../../utils/haptic_utils.dart';
import 'book_data.dart';

class BookFlipScreen extends StatefulWidget {
  const BookFlipScreen({super.key, required this.bookIndex});

  final int bookIndex;

  @override
  State<BookFlipScreen> createState() => _BookFlipScreenState();
}

class _BookFlipScreenState extends State<BookFlipScreen> {
  int _currentPage = 0;
  bool _isAnimating = false;
  final _pageController = PageController();

  static const _pageNames = [
    'Cover',
    'Overview',
    'Lesson 1',
    'Lesson 2',
    'Lesson 3',
    'First Chapter',
  ];

  BookData get _book => books[widget.bookIndex];

  void _nextPage() {
    HapticUtils.light();
    if (_isAnimating) return;
    if (_currentPage >= _pageNames.length - 1) {
      context.push('/action-plans?bookIndex=${widget.bookIndex}');
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
    final book = _book;
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
                  ...List.generate(_pageNames.length, (i) {
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
                    '${_currentPage + 1}/${_pageNames.length}',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.grey500,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
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
                    for (var i = 0; i < _pageNames.length; i++)
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
                    GestureDetector(
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
                  GestureDetector(
                    onTap: _nextPage,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            book.gradientBegin,
                            book.gradientEnd,
                          ],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: book.gradientBegin.withValues(alpha: 0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _currentPage == _pageNames.length - 1
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
                            _currentPage == _pageNames.length - 1
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

  Widget _buildPageContent(int index, BookData book) {
    switch (index) {
      case 0:
        return _CoverPage(book: book);
      case 1:
        return _SummaryPage(book: book);
      case 2:
      case 3:
      case 4:
        return _LessonPage(
          lessonNumber: index - 1,
          lesson: book.lessons[index - 2],
          gradientBegin: book.gradientBegin,
          gradientEnd: book.gradientEnd,
        );
      case 5:
        return _FirstChapterPage(book: book);
      default:
        return const SizedBox();
    }
  }
}

class _CoverPage extends StatelessWidget {
  final BookData book;

  const _CoverPage({required this.book});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [book.gradientBegin, book.gradientEnd],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: book.gradientBegin.withValues(alpha: 0.3),
            blurRadius: 32,
            offset: const Offset(0, 8),
          ),
        ],
      ),
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
            child: Icon(book.icon, color: AppColors.white, size: 28),
          ),
          const SizedBox(height: 32),
          Text(
            book.tagline,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.white.withValues(alpha: 0.8),
              fontWeight: FontWeight.w500,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            book.title,
            style: GoogleFonts.playfairDisplay(
              fontSize: 34,
              fontWeight: FontWeight.w700,
              color: AppColors.white,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            book.author,
            style: TextStyle(
              fontSize: 16,
              color: AppColors.white.withValues(alpha: 0.7),
            ),
          ),
          const Spacer(),
          Text(
            'Why this book this week',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.white.withValues(alpha: 0.7),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            book.summary.length > 120
                ? '${book.summary.substring(0, 120)}...'
                : book.summary,
            style: TextStyle(
              fontSize: 14,
              height: 1.4,
              color: AppColors.white.withValues(alpha: 0.85),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryPage extends StatelessWidget {
  final BookData book;

  const _SummaryPage({required this.book});

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
              Icons.menu_book_rounded,
              color: AppColors.primary,
              size: 22,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'What this book is about',
            style: GoogleFonts.playfairDisplay(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.grey900,
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: SingleChildScrollView(
              child: Text(
                book.summary,
                style: const TextStyle(
                  fontSize: 15,
                  height: 1.7,
                  color: AppColors.grey600,
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
  final Color gradientBegin;
  final Color gradientEnd;

  const _LessonPage({
    required this.lessonNumber,
    required this.lesson,
    required this.gradientBegin,
    required this.gradientEnd,
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
              gradient: LinearGradient(
                colors: [gradientBegin, gradientEnd],
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
            style: GoogleFonts.playfairDisplay(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.grey900,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
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
        ],
      ),
    );
  }
}

class _FirstChapterPage extends StatelessWidget {
  final BookData book;

  const _FirstChapterPage({required this.book});

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
              Icons.bookmark_rounded,
              color: AppColors.primary,
              size: 22,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Chapter to read first',
            style: GoogleFonts.playfairDisplay(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.grey900,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: SingleChildScrollView(
              child: Text(
                book.firstChapter,
                style: const TextStyle(
                  fontSize: 15,
                  height: 1.7,
                  color: AppColors.grey600,
                ),
              ),
            ),
          ),
          const Spacer(),
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
                      gradient: LinearGradient(
                        colors: [book.gradientBegin, book.gradientEnd],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.rocket_launch_rounded,
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
                          'Ready for more?',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.grey900,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Complete all 3 books to unlock your weekly growth plan.',
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


