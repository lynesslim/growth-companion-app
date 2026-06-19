import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart' as supa;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/repositories/auth_repository.dart';
import '../domain/models/user.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

class AuthStateNotifier extends StateNotifier<AsyncValue<User?>> {
  supa.SupabaseClient get _supabase => supa.Supabase.instance.client;
  StreamSubscription? _authSub;

  AuthStateNotifier() : super(const AsyncLoading()) {
    _init();
  }

  void _init() {
    final session = _supabase.auth.currentSession;
    _emit(session?.user);
    _authSub = _supabase.auth.onAuthStateChange.listen((event) {
      _emit(event.session?.user);
    });
  }

  void _emit(supa.User? authUser) {
    if (authUser != null) {
      state = AsyncValue.data(User(
        id: authUser.id,
        name: authUser.email?.split('@').first ?? 'Explorer',
      ));
    } else {
      state = const AsyncValue.data(null);
    }
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }
}

final authStateProvider =
    StateNotifierProvider<AuthStateNotifier, AsyncValue<User?>>((ref) {
  return AuthStateNotifier();
});
