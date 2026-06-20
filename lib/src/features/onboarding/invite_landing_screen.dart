import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:confetti/confetti.dart';
import '../../core/app_colors.dart';

class InviteLandingScreen extends StatefulWidget {
  final String senderId;
  final String? dropId;
  const InviteLandingScreen({super.key, required this.senderId, this.dropId});

  @override
  State<InviteLandingScreen> createState() => _InviteLandingScreenState();
}

class _InviteLandingScreenState extends State<InviteLandingScreen> {
  late ConfettiController _confettiController;
  bool _unpacking = false;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  Future<void> _unpack() async {
    final prefs = await SharedPreferences.getInstance();
    if (widget.senderId.isNotEmpty) {
      await prefs.setString('sender_id', widget.senderId);
    }
    if (widget.dropId != null && widget.dropId!.isNotEmpty) {
      await prefs.setString('shared_drop_id', widget.dropId!);
    }
    setState(() => _unpacking = true);
    _confettiController.play();
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
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
      body: Stack(
        children: [
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(32),
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
                    'Your friend sent you a mystery book tailored to your goals.',
                    style: TextStyle(fontSize: 16, color: AppColors.grey600),
                    textAlign: TextAlign.center,
                  ),
                  const Spacer(),
                  Center(
                    child: GestureDetector(
                      onTap: _unpacking ? null : _unpack,
                      child: AnimatedScale(
                        scale: _unpacking ? 1.1 : 1.0,
                        duration: const Duration(milliseconds: 400),
                        child: const Text('\u{1F4E6}', style: TextStyle(fontSize: 80)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: GestureDetector(
                      onTap: _unpacking ? null : _unpack,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppColors.primary, AppColors.pinkLight],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: _unpacking
                            ? const Center(child: SizedBox(
                                width: 20, height: 20,
                                child: CircularProgressIndicator(color: AppColors.white, strokeWidth: 2),
                              ))
                            : const Center(
                                child: Text(
                                  'Unpack the blindbox',
                                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: AppColors.white),
                                ),
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 48),
                ],
              ),
            ),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              colors: const [
                AppColors.primary,
                AppColors.pinkLight,
                AppColors.xpInfluence,
                AppColors.warning,
                Colors.white,
              ],
              numberOfParticles: 20,
              maxBlastForce: 20,
              minBlastForce: 5,
              gravity: 0.1,
            ),
          ),
        ],
      ),
    );
  }
}
