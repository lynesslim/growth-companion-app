import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';

import '../../core/app_colors.dart';
import '../../core/app_typography.dart';
import '../../domain/models/growth_drop.dart';
import '../../providers/social_provider.dart';

class SocialUtils {
  static Future<void> openDrop(BuildContext context, WidgetRef ref, dynamic drop) async {
    if (drop.bookData != null) {
      ref.read(socialProvider.notifier).markDropOpened(drop.id);
      if (context.mounted) context.push('/book', extra: drop.bookData);
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        contentPadding: const EdgeInsets.all(32),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Lottie.asset('assets/images/wrapped-gift.json', width: 120, height: 120, repeat: true),
            const SizedBox(height: 24),
            const CircularProgressIndicator(color: AppColors.primary),
            const SizedBox(height: 24),
            Text(
              'Unpacking drop from ${drop.senderProfile?.name ?? 'a friend'}...',
              style: AppTypography.h1Playfair.copyWith(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppColors.grey900,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Generating a personalized book drop just for you.',
              style: TextStyle(color: AppColors.grey600, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );

    try {
      final bookData = await ref.read(socialProvider.notifier).openBlindBox(drop.id);
      if (!context.mounted) return;

      Navigator.of(context, rootNavigator: true).pop(); // Close modal

      final lessonsData = bookData['lessons'];
      final List<String> parsedLessons = lessonsData is List
          ? lessonsData.map((e) => e.toString()).toList()
          : (lessonsData != null ? [lessonsData.toString()] : []);

      final insightsData = bookData['actionableInsights'];
      final List<String>? parsedInsights = insightsData is List
          ? insightsData.map((e) => e.toString()).toList()
          : null;

      final newDrop = GrowthDrop.fromJson({
        'id': drop.id,
        'date': drop.dropDate.toIso8601String(),
        'focusArea': 'Social Drop',
        'bookTitle': bookData['bookTitle'] ?? '',
        'bookAuthor': bookData['bookAuthor'] ?? '',
        'whatItsAbout': bookData['whatItsAbout'] ?? '',
        'lessons': parsedLessons,
        'summary': bookData['summary'] ?? '',
        'coverUrl': bookData['coverUrl'] as String?,
        'isRead': true,
        'giftedBy': drop.senderProfile?.name,
        'caseStudy': bookData['caseStudy'],
        'actionableInsights': parsedInsights,
      });

      context.push('/book', extra: newDrop);
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop(); // Close modal
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to unpack drop: $e')),
        );
      }
    }
  }
}
