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
