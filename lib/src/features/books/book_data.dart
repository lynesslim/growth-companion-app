import 'package:flutter/material.dart';
import '../../core/app_colors.dart';

class BookData {
  final String title;
  final String author;
  final String tagline;
  final Color gradientBegin;
  final Color gradientEnd;
  final IconData icon;
  final String summary;
  final List<String> lessons;
  final String firstChapter;

  const BookData({
    required this.title,
    required this.author,
    required this.tagline,
    required this.gradientBegin,
    required this.gradientEnd,
    required this.icon,
    required this.summary,
    required this.lessons,
    required this.firstChapter,
  });
}

const books = <BookData>[
  BookData(
    title: 'Deep Work',
    author: 'Cal Newport',
    tagline: 'Master focused work',
    gradientBegin: AppColors.primary,
    gradientEnd: AppColors.primaryDark,
    icon: Icons.timer_outlined,
    summary:
      'A guide to cultivating deep focus in a world of distractions. '
      'This book shows you how to train your attention, create meaningful work rituals, '
      'and protect your cognitive resources from shallow demands.',
    lessons: [
      'Your attention is your competitive advantage — those who can focus deeply '
          'will thrive in the modern economy.',
      'Shallow work (email, meetings, quick tasks) creates the illusion of productivity '
          'but rarely produces meaningful results.',
      'Environment shapes focus — design your workspace and schedule to minimize '
          'friction and protect deep work blocks.',
    ],
    firstChapter:
      'Chapter 3 — this chapter gives you the clearest practical framework for '
      'creating deep work rituals and is the fastest starting point for building focus.',
  ),
  BookData(
    title: 'Atomic Habits',
    author: 'James Clear',
    tagline: 'Build small changes',
    gradientBegin: const Color(0xFFEC4899),
    gradientEnd: const Color(0xFFBE185D),
    icon: Icons.loop_rounded,
    summary:
      'A practical framework for building good habits and breaking bad ones '
      'through tiny, incremental changes that compound into remarkable results over time.',
    lessons: [
      'Small changes (1% improvements) compound into extraordinary results — '
          'focus on systems, not goals.',
      'Make good habits obvious and attractive; make bad habits invisible and '
          'unsatisfactory to reshape your behaviour.',
      'Identity-based habits stick — instead of "I want to run", become '
          '"I am a runner" and let your identity drive your actions.',
    ],
    firstChapter:
      'Chapter 1 — start here to understand the surprising power of tiny habits '
      'and why small changes can lead to remarkable results.',
  ),
  BookData(
    title: 'The Creative Act',
    author: 'Rick Rubin',
    tagline: 'Unlock your creativity',
    gradientBegin: const Color(0xFF14B8A6),
    gradientEnd: const Color(0xFF0F766E),
    icon: Icons.auto_awesome_rounded,
    summary:
      'A masterclass in creativity from one of the most legendary music producers. '
      'This book reveals how to access your innate creative potential by tuning into '
      'the world around you and trusting your unique perspective.',
    lessons: [
      'Creativity is not a rare gift — it is a natural state that everyone can access '
          'by removing the blocks that hold them back.',
      'Notice more — the best ideas come from paying close attention to the world '
          'without judgement or expectation.',
      'Let go of outcomes — create for the sake of creating, and the best work '
          'will emerge naturally when you stop forcing it.',
    ],
    firstChapter:
      'Chapter 2 — Rubin explains how to tune into your surroundings and find '
      'inspiration in everyday moments, a perfect starting point for any creator.',
  ),
];
