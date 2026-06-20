import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/app_colors.dart';

class InviteLandingScreen extends StatelessWidget {
  final String senderId;
  const InviteLandingScreen({super.key, required this.senderId});

  Future<void> _pickBox(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    if (senderId.isNotEmpty) {
      await prefs.setString('sender_id', senderId);
    }
    if (!context.mounted) return;
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      context.go('/');
    } else {
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 64),
              const Text(
                'A Gift Awaits',
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.grey900),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const Text(
                'Your friend sent you a mystery book tailored to your goals. Tap to open!',
                style: TextStyle(fontSize: 16, color: AppColors.grey600),
                textAlign: TextAlign.center,
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => _pickBox(context),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(3, (index) => Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.primary, width: 2),
                    ),
                    child: const Icon(Icons.card_giftcard, color: AppColors.primary, size: 40),
                  )),
                ),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
