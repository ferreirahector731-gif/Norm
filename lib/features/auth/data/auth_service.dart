import 'dart:io' show Platform;

import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

enum SessionMode { none, guest, authenticated }

class AuthService {
  final bool isCloudEnabled;
  final SupabaseClient? _supabase;
  SessionMode _sessionMode = SessionMode.none;

  static const _keySessionMode = 'session_mode';

  AuthService({this.isCloudEnabled = false})
      : _supabase = isCloudEnabled ? Supabase.instance.client : null;

  SessionMode get sessionMode => _sessionMode;

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

  bool get isAuthenticated => _sessionMode == SessionMode.authenticated;
  bool get isGuest => _sessionMode == SessionMode.guest;
  bool get hasSession => _sessionMode != SessionMode.none;

  Future<void> loadSession() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_keySessionMode) ?? 'none';
    _sessionMode = SessionMode.values.firstWhere(
      (e) => e.name == value,
      orElse: () => SessionMode.none,
    );
  }

  Future<void> setGuestMode() async {
    _sessionMode = SessionMode.guest;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keySessionMode, SessionMode.guest.name);
  }

  Future<void> clearSession() async {
    _sessionMode = SessionMode.none;
    if (isCloudEnabled && _supabase != null) {
      await _supabase!.auth.signOut();
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keySessionMode, SessionMode.none.name);
  }

  Future<String?> signInWithGoogle() async {
    if (!isCloudEnabled || _supabase == null) {
      return 'Modo local: sin conexión a Supabase';
    }
    try {
      // En desktop usamos PKCE sin redirectTo personalizado
      // (Supabase SDK levanta un servidor local para el callback)
      final isDesktop = Platform.isWindows || Platform.isLinux || Platform.isMacOS;
      await _supabase!.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: isDesktop ? null : 'io.supabase.norm://login-callback/',
      );
      _sessionMode = SessionMode.authenticated;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keySessionMode, SessionMode.authenticated.name);
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
    final response = await _supabase!.auth.signInWithPassword(email: email, password: password);
    _sessionMode = SessionMode.authenticated;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keySessionMode, SessionMode.authenticated.name);
    return response;
  }

  Future<AuthResponse> signUpWithEmail(String email, String password) async {
    if (!isCloudEnabled || _supabase == null) {
      throw Exception('Modo local: sin conexión a Supabase');
    }
    final response = await _supabase!.auth.signUp(email: email, password: password);
    _sessionMode = SessionMode.authenticated;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keySessionMode, SessionMode.authenticated.name);
    return response;
  }

  Future<void> signOut() async {
    if (isCloudEnabled && _supabase != null) {
      await _supabase!.auth.signOut();
    }
    _sessionMode = SessionMode.none;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keySessionMode, SessionMode.none.name);
  }
}
