import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/models/growth_drop.dart';

final growthDropProvider = Provider<GrowthDrop>((ref) {
  return GrowthDrop(
    id: 'drop_1',
    date: DateTime(2026, 6, 4),
    focusArea: 'Deep Work',
    recommendedBooks: ['Deep Work', 'Atomic Habits', 'The Creative Act'],
    bookTitle: 'Deep Work',
    bookAuthor: 'Cal Newport',
    summary:
        'A guide to cultivating deep focus in a world of distractions. '
        'This book shows you how to train your attention, create meaningful work rituals, '
        'and protect your cognitive resources from shallow demands.',
    whyThisBook:
        'You said you want to become more focused and consistent. '
        'This book explains why deep, distraction-free work is becoming rare, '
        'and why people who can protect their attention have an advantage.',
    whatItsAbout:
        'This book is about training your ability to focus in a distracted world. '
        'The key idea is not just time management — it\'s learning how to protect '
        'your attention and create conditions where serious work becomes easier.',
    lessons: [
      'Your attention is your competitive advantage — those who can focus deeply '
          'will thrive in the modern economy.',
      'Shallow work (email, meetings, quick tasks) creates the illusion of productivity '
          'but rarely produces meaningful results.',
      'Environment shapes focus — design your workspace and schedule to minimize '
          'friction and protect deep work blocks.',
    ],
    firstChapter:
        'Start with Chapter 3 — it gives you the clearest practical framework '
        'for creating deep work rituals. Since your main struggle is distraction, '
        'this chapter gives you the fastest starting point.',
    dailyAction:
        'Block 30 minutes today for one important task. '
        'Put your phone away, close unnecessary tabs, '
        'and work on only that task.',
    dailyActionDuration: '30 min',
  );
});
