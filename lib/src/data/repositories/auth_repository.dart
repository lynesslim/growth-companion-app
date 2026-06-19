import 'package:supabase_flutter/supabase_flutter.dart' as supa;

class AuthRepository {
  Future<void> login({
    required String email,
    required String password,
  }) async {
    await supa.Supabase.instance.client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signUp({
    required String email,
    required String password,
  }) async {
    final response = await supa.Supabase.instance.client.auth.signUp(
      email: email,
      password: password,
    );
    if (response.session == null) {
      // Email confirmation required — throw so the catch block shows the message
      throw Exception('Check your email for the confirmation link before logging in.');
    }
  }

  Future<void> logout() async {
    await supa.Supabase.instance.client.auth.signOut();
  }
}
