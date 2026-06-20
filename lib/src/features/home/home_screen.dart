import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/app_colors.dart';
import '../../providers/growth_drop_provider.dart';
import '../../providers/social_provider.dart';
import 'widgets/home_header.dart';
import 'widgets/growth_drop_card.dart';
import 'widgets/social_drops_card.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _modalShown = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _processInvite());
  }

  Future<void> _processInvite() async {
    final prefs = await SharedPreferences.getInstance();
    final senderId = prefs.getString('sender_id');
    if (senderId == null) return;
    await prefs.remove('sender_id');

    final supabase = Supabase.instance.client;
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;

    try {
      await supabase.from('friends').insert({
        'user_id_1': senderId,
        'user_id_2': userId,
        'status': 'accepted',
      });
      await supabase.from('social_drops').insert({
        'sender_id': senderId,
        'recipient_id': userId,
        'is_opened': false,
        'drop_date': DateTime.now().toIso8601String().split('T')[0],
        'book_data': {},
      });
      ref.invalidate(socialProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("You've received a blind box from your friend!")),
        );
      }
    } catch (_) {
      // ponytail: duplicates or already processed, silently ignore
    }
  }

  @override
  Widget build(BuildContext context) {
    final drop = ref.watch(growthDropProvider).valueOrNull;

    if (!_modalShown && drop != null && !drop.isRead) {
      _modalShown = true;
      // Use addPostFrameCallback to show modal after build
      WidgetsBinding.instance.addPostFrameCallback((_) => _showDropModal(context));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.only(left: 20, right: 20, top: 60, bottom: 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const HomeHeader(),
          const SizedBox(height: 28),
          const GrowthDropCard(),
          const SizedBox(height: 24),
          const SocialDropsCard(),
        ],
      ),
    );
  }

  void _showDropModal(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        backgroundColor: AppColors.white,
        contentPadding: const EdgeInsets.all(28),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.pinkLight],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Center(
                child: Icon(Icons.menu_book_rounded, color: AppColors.white, size: 32),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Your daily book is ready!',
              textAlign: TextAlign.center,
              style: GoogleFonts.playfairDisplay(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: AppColors.grey900,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'You have a new growth drop waiting.\nOpen it now to continue your streak.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, color: AppColors.grey500, height: 1.5),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: GestureDetector(
                onTap: () {
                  Navigator.pop(ctx);
                  context.push('/book');
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primary, AppColors.pinkLight],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Center(
                    child: Text(
                      'Open Now',
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
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text(
                'Later',
                style: TextStyle(color: AppColors.grey500, fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
