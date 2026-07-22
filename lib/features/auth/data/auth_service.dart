import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  final bool isCloudEnabled;
  final SupabaseClient? _supabase;

  AuthService({this.isCloudEnabled = false})
      : _supabase = isCloudEnabled ? Supabase.instance.client : null;

  Stream<User?> get authStateStream {
    if (!isCloudEnabled || _supabase == null) {
      return Stream.value(null);
    }
    return _supabase!.auth.onAuthStateChange.map(
      (data) => data.session?.user,
    );
  }

  User? get currentUser {
    if (!isCloudEnabled || _supabase == null) return null;
    return _supabase!.auth.currentUser;
  }

  Future<String?> signInWithGoogle() async {
    if (!isCloudEnabled || _supabase == null) {
      return 'Modo local: sin conexión a Supabase';
    }
    try {
      await _supabase!.auth.signInWithOAuth(
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
    if (!isCloudEnabled || _supabase == null) {
      throw Exception('Modo local: sin conexión a Supabase');
    }
    return _supabase!.auth.signInWithPassword(email: email, password: password);
  }

  Future<AuthResponse> signUpWithEmail(String email, String password) async {
    if (!isCloudEnabled || _supabase == null) {
      throw Exception('Modo local: sin conexión a Supabase');
    }
    return _supabase!.auth.signUp(email: email, password: password);
  }

  Future<void> signOut() async {
    if (!isCloudEnabled || _supabase == null) return;
    await _supabase!.auth.signOut();
  }
}
