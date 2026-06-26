import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

/// A signed-in (or guest) user. `id` is what the backend keys everything on.
class AuthUser {
  final String id;
  final String? email;
  final String? name;
  final AuthMethod method;

  const AuthUser({required this.id, this.email, this.name, required this.method});
}

enum AuthMethod { google, apple, email, guest }

/// The single seam between the app and authentication.
///
/// The whole app talks ONLY to this interface, so swapping the mock for real
/// Supabase Auth later is a one-file change ([SupabaseAuthService]) wired in one
/// place ([authServiceProvider]) — no screen or repository needs to change.
abstract class AuthService {
  /// The persisted session, if any (called on app start).
  Future<AuthUser?> currentUser();

  Future<AuthUser> signInWithGoogle();
  Future<AuthUser> signInWithApple();
  Future<AuthUser> signInWithEmail(String email, String password);
  Future<AuthUser> continueAsGuest();
  Future<void> signOut();
}

/// UI-only auth: generates a stable local user id and persists a lightweight
/// session. No network, no real credentials — but it produces a real backend
/// user id (used as `?user=` against the dev backend), so the rest of the app is
/// fully exercised end-to-end.
///
/// To go live with SSO, implement [AuthService] with `supabase_flutter`:
///   - signInWithGoogle/Apple → supabase.auth.signInWithOAuth(...)
///   - signInWithEmail        → supabase.auth.signInWithPassword(...)
///   - id                     → supabase.auth.currentUser!.id
/// then point [authServiceProvider] at it. The API layer already centralises the
/// user credential, so only the auth header needs to change there.
class MockAuthService implements AuthService {
  static const _kId = 'quicks.user.id';
  static const _kEmail = 'quicks.user.email';
  static const _kName = 'quicks.user.name';
  static const _kMethod = 'quicks.user.method';

  Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  @override
  Future<AuthUser?> currentUser() async {
    final p = await _prefs;
    final id = p.getString(_kId);
    if (id == null) return null;
    return AuthUser(
      id: id,
      email: p.getString(_kEmail),
      name: p.getString(_kName),
      method: AuthMethod.values.firstWhere(
        (m) => m.name == p.getString(_kMethod),
        orElse: () => AuthMethod.guest,
      ),
    );
  }

  @override
  Future<AuthUser> signInWithGoogle() =>
      _persist(AuthUser(id: _newId('google'), email: 'you@gmail.com', name: 'Google User', method: AuthMethod.google));

  @override
  Future<AuthUser> signInWithApple() =>
      _persist(AuthUser(id: _newId('apple'), email: 'you@icloud.com', name: 'Apple User', method: AuthMethod.apple));

  @override
  Future<AuthUser> signInWithEmail(String email, String password) =>
      _persist(AuthUser(id: _newId('email'), email: email, name: email.split('@').first, method: AuthMethod.email));

  @override
  Future<AuthUser> continueAsGuest() =>
      _persist(AuthUser(id: _newId('guest'), method: AuthMethod.guest));

  @override
  Future<void> signOut() async {
    final p = await _prefs;
    await p.remove(_kId);
    await p.remove(_kEmail);
    await p.remove(_kName);
    await p.remove(_kMethod);
  }

  Future<AuthUser> _persist(AuthUser user) async {
    // Simulate a brief network round-trip so loading states are exercised.
    await Future.delayed(const Duration(milliseconds: 600));
    final p = await _prefs;
    await p.setString(_kId, user.id);
    if (user.email != null) await p.setString(_kEmail, user.email!);
    if (user.name != null) await p.setString(_kName, user.name!);
    await p.setString(_kMethod, user.method.name);
    return user;
  }

  String _newId(String prefix) {
    final r = Random();
    final rand = List.generate(8, (_) => r.nextInt(16).toRadixString(16)).join();
    return '$prefix-${DateTime.now().millisecondsSinceEpoch.toRadixString(16)}$rand';
  }
}
