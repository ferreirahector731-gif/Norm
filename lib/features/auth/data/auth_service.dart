import 'package:supabase_flutter/supabase_flutter.dart' show SupabaseClient, User, AuthResponse;
import 'package:flutter/foundation.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Stream<User?> get authStateStream => _supabase.auth.onAuthStateChange.map(
    (data) => data.session?.user,
  );

  User? get currentUser => _supabase.auth.currentUser;

  Future<void> signInWithGoogle() async {
    await _supabase.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: kIsWeb ? null : 'io.supabase.flutter://callback',
    );
  }

  Future<AuthResponse> signInWithEmail(String email, String password) async {
    return _supabase.auth.signInWithPassword(email: email, password: password);
  }

  Future<AuthResponse> signUpWithEmail(String email, String password) async {
    return _supabase.auth.signUp(email: email, password: password);
  }

  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }
}
