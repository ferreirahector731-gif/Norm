import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Stream<User?> get authStateStream => _supabase.auth.onAuthStateChange.map(
    (data) => data.session?.user,
  );

  User? get currentUser => _supabase.auth.currentUser;

  Future<String?> signInWithGoogle() async {
    try {
      await _supabase.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: 'io.supabase.norm://login-callback/',
      );
      return null;
    } catch (e, stackTrace) {
      debugPrint('Error Supabase: $e\n$stackTrace');
      return e.toString();
    }
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
