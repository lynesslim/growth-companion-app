import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'src/core/app_theme.dart';
import 'src/core/router.dart';
import 'src/features/onboarding/pre_onboarding_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ponytail: override ErrorWidget.builder to show only the main exception message clearly and print to console
  ErrorWidget.builder = (FlutterErrorDetails details) {
    // Print to developer console so it's permanently readable in Chrome DevTools
    debugPrint('---------------- FLUTTER ERROR DIAGNOSTICS ----------------');
    debugPrint(details.exception.toString());
    debugPrint(details.stack?.toString());
    debugPrint('-----------------------------------------------------------');

    return Material(
      color: const Color(0xFF121212),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(left: 24, right: 24, bottom: 24, top: 280), // Push down below coach card
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF221515),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.redAccent, width: 2),
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.redAccent, size: 28),
                    SizedBox(width: 12),
                    Text(
                      'Application Error Detected',
                      style: TextStyle(color: Colors.redAccent, fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SelectableText(
                  details.exception.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontFamily: 'monospace',
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  '💡 Tip: Check your Chrome DevTools Console (F12 -> Console tab) for the full stack trace.',
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                ),
              ],
            ),
          ),
        ),
      ),
    );

  };



  final prefs = await SharedPreferences.getInstance();
  PreOnboardingState.hasSeen = prefs.getBool('hasSeenPreOnboarding') ?? false;

  await Supabase.initialize(
    url: 'https://picrdsjxtpdufnqofpdt.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InBpY3Jkc2p4dHBkdWZucW9mcGR0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODE3NzgyMTQsImV4cCI6MjA5NzM1NDIxNH0.ozX6oEZYvh2NNcZKWY0M07beRxBVk_7cVvQOhvag4jw',
  );

  runApp(const ProviderScope(child: GrowthCompanionApp()));
}

class CustomScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
      };
}

class GrowthCompanionApp extends ConsumerWidget {
  const GrowthCompanionApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(goRouterProvider);
    return MaterialApp.router(
      scrollBehavior: CustomScrollBehavior(),
      title: 'Growth Companion',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.light,
      routerConfig: router,
      builder: (context, child) {
        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: child,
          ),
        );
      },
    );
  }
}
