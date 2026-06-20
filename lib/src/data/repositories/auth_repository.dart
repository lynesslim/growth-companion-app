import 'package:supabase_flutter/supabase_flutter.dart' as supa;

class AuthRepository {
  Future<void> login({
    required String email,
    required String password,
  }) async {
    try {
      await supa.Supabase.instance.client.auth.signInWithPassword(
        email: email,
        password: password,
      );
    } on supa.AuthException catch (e) {
      throw _toUserFacing(e);
    }
  }

  Future<void> signUp({
    required String email,
    required String password,
  }) async {
    try {
      final response = await supa.Supabase.instance.client.auth.signUp(
        email: email,
        password: password,
      );
      if (response.session == null) {
        throw Exception('Check your email for the confirmation link before logging in.');
      }
    } on supa.AuthException catch (e) {
      throw _toUserFacing(e);
    }
  }

  Future<void> logout() async {
    await supa.Supabase.instance.client.auth.signOut();
  }

  Exception _toUserFacing(supa.AuthException e) {
    final msg = e.message;
    if (msg == 'Invalid login credentials') {
      return Exception('Invalid email or password.');
    }
    return switch (e.code) {
      'email_exists' || 'user_already_exists' =>
        Exception('An account with this email already exists.'),
      'email_not_confirmed' =>
        Exception('Please confirm your email before logging in.'),
      'over_request_rate_limit' || 'over_email_send_rate_limit' =>
        Exception('Too many attempts. Please try again later.'),
      'weak_password' =>
        Exception('Password is too weak. Choose a stronger one.'),
      'validation_failed' => Exception(msg),
      _ => Exception(msg),
    };
  }
}
