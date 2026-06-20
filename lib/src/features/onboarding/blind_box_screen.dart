import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/app_colors.dart';

class BlindBoxScreen extends ConsumerStatefulWidget {
  final String senderId;
  const BlindBoxScreen({super.key, required this.senderId});

  @override
  ConsumerState<BlindBoxScreen> createState() => _BlindBoxScreenState();
}

class _BlindBoxScreenState extends ConsumerState<BlindBoxScreen> {
  bool _isLoading = false;

  Future<void> _pickBox() async {
    setState(() => _isLoading = true);
    try {
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser!.id;

      // Create friend relationship
      await supabase.from('friends').insert({
        'user_id_1': widget.senderId,
        'user_id_2': userId,
        'status': 'accepted'
      });

      // Trigger social drop from sender to the new user
      await supabase.functions.invoke('generate-social-drop', body: {
        'sender_id': widget.senderId,
        'recipient_id': userId,
      });

      // Clear the sender_id from prefs so we don't trigger this again
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('sender_id');

      if (mounted) {
        context.go('/social');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
        setState(() => _isLoading = false);
      }
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
                'Your friend sent you a mystery book tailored to your goals. Pick a box to reveal it!',
                style: TextStyle(fontSize: 16, color: AppColors.grey600),
                textAlign: TextAlign.center,
              ),
              const Spacer(),
              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(3, (index) => _buildBox(index)),
                ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBox(int index) {
    return GestureDetector(
      onTap: _pickBox,
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: AppColors.primaryLight.withOpacity(0.2),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.primary, width: 2),
        ),
        child: const Icon(Icons.card_giftcard, color: AppColors.primary, size: 40),
      ),
    );
  }
}
