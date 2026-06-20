import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/app_colors.dart';
import '../../core/animated_widgets.dart';
import '../../providers/growth_drop_provider.dart';
import '../../providers/social_provider.dart';
import '../../providers/user_provider.dart';
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
    final sharedDropId = prefs.getString('shared_drop_id');
    if (senderId == null) return;
    await prefs.remove('sender_id');
    await prefs.remove('shared_drop_id');

    final supabase = Supabase.instance.client;
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;

    // Self-referral guard
    if (senderId == userId) return;

    try {
      // Dedup: check if friendship already exists
      final existing = await supabase
          .from('friends')
          .select()
          .or('and(user_id_1.eq.$senderId,user_id_2.eq.$userId),and(user_id_1.eq.$userId,user_id_2.eq.$senderId)')
          .maybeSingle();
      if (existing == null) {
        await supabase.from('friends').insert({
          'user_id_1': senderId,
          'user_id_2': userId,
          'status': 'accepted',
        });
      }

      // Fetch shared book if drop_id was provided
      Map<String, dynamic> bookData = {};
      String message = "You've received a blind box from your friend!";
      if (sharedDropId != null && sharedDropId.isNotEmpty) {
        final response = await supabase.rpc('get_shared_book', params: {'drop_id': sharedDropId});
        if (response != null) {
          bookData = Map<String, dynamic>.from(response);
          message = "You've received a book from your friend!";
        }
      }

      await supabase.from('social_drops').insert({
        'sender_id': senderId,
        'recipient_id': userId,
        'is_opened': false,
        'drop_date': DateTime.now().toIso8601String().split('T')[0],
        'book_data': bookData,
      });
      ref.invalidate(socialProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }
    } catch (_) {
      // ponytail: duplicates or already processed, silently ignore
    }
  }

  @override
  Widget build(BuildContext context) {
    final dropState = ref.watch(growthDropProvider);
    final socialState = ref.watch(socialProvider);
    final drop = dropState.valueOrNull;

    if (!_modalShown && !dropState.isLoading) {
      if (drop == null) {
        _modalShown = true;
        WidgetsBinding.instance.addPostFrameCallback((_) => _showGenerateModal(context));
      } else if (!drop.isRead) {
        _modalShown = true;
        WidgetsBinding.instance.addPostFrameCallback((_) => _showDropModal(context));
      }
    }

    if (dropState.isLoading || socialState.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.only(left: 20, right: 20, top: 60, bottom: 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          EntranceFadeSlide(delayMs: 0, child: const HomeHeader()),
          const SizedBox(height: 28),
          EntranceFadeSlide(delayMs: 50, child: const GrowthDropCard()),
          const SizedBox(height: 24),
          EntranceFadeSlide(delayMs: 100, child: const SocialDropsCard()),
        ],
      ),
    );
  }

  void _showGenerateModal(BuildContext context) {
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
                child: Icon(Icons.auto_awesome_rounded, color: AppColors.white, size: 32),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              "Ready for today's drop?",
              textAlign: TextAlign.center,
              style: GoogleFonts.playfairDisplay(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: AppColors.grey900,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Your personalized book is waiting to be generated.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, color: AppColors.grey500, height: 1.5),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: GestureDetector(
                onTap: () {
                  Navigator.pop(ctx);
                  _generateFromModal(context);
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
                      'Generate Now',
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

  Future<void> _generateFromModal(BuildContext context) async {
    final user = ref.read(userProvider).valueOrNull;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please complete onboarding first')),
      );
      return;
    }
    
    // Show loading modal
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        contentPadding: const EdgeInsets.all(32),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('\u{1F4E6}', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 24),
            const CircularProgressIndicator(color: AppColors.primary),
            const SizedBox(height: 24),
            Text(
              'Generating...',
              style: GoogleFonts.playfairDisplay(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppColors.grey900,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );

    try {
      final body = <String, dynamic>{
        'user_id': user.id,
        'drop_date': DateTime.now().toIso8601String().split('T')[0],
        'onboarding_profile': user.onboardingProfile,
      };
      await Supabase.instance.client.functions.invoke(
        'generate-growth-drop',
        body: body,
      );
      if (mounted) {
        Navigator.pop(context); // close loading modal
        ref.invalidate(growthDropProvider);
        context.push('/book');
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // close loading modal
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to generate: $e')),
        );
      }
    }
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
