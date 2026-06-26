import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/brain.dart';
import '../models/card.dart';
import '../models/profile.dart';
import '../services/auth_service.dart';
import '../services/quicks_api.dart';

// ── Singletons ────────────────────────────────────────────────────────────────

/// Swap MockAuthService → SupabaseAuthService here to go live with SSO.
final authServiceProvider = Provider<AuthService>((ref) => MockAuthService());

final apiProvider = Provider<QuicksApi>((ref) => QuicksApi());

// ── Auth ──────────────────────────────────────────────────────────────────────

class AuthController extends StateNotifier<AsyncValue<AuthUser?>> {
  AuthController(this._auth) : super(const AsyncValue.loading()) {
    _restore();
  }
  final AuthService _auth;

  Future<void> _restore() async {
    state = AsyncValue.data(await _auth.currentUser());
  }

  Future<void> google() => _run(_auth.signInWithGoogle);
  Future<void> apple() => _run(_auth.signInWithApple);
  Future<void> email(String e, String p) => _run(() => _auth.signInWithEmail(e, p));
  Future<void> guest() => _run(_auth.continueAsGuest);

  Future<void> signOut() async {
    await _auth.signOut();
    state = const AsyncValue.data(null);
  }

  Future<void> _run(Future<AuthUser> Function() fn) async {
    state = const AsyncValue.loading();
    try {
      state = AsyncValue.data(await fn());
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final authProvider =
    StateNotifierProvider<AuthController, AsyncValue<AuthUser?>>(
        (ref) => AuthController(ref.watch(authServiceProvider)));

/// The current user's id (null when signed out / still loading).
final userIdProvider = Provider<String?>((ref) => ref.watch(authProvider).value?.id);

// ── Data ──────────────────────────────────────────────────────────────────────

final feedProvider = FutureProvider<List<QuicksCard>>((ref) async {
  final api = ref.watch(apiProvider);
  return api.getFeed(userId: ref.watch(userIdProvider), limit: 12);
});

final brainProvider = FutureProvider<BrainGraph>((ref) async {
  final uid = ref.watch(userIdProvider);
  if (uid == null) {
    return const BrainGraph(
      domains: [],
      allDomains: [],
      bridges: [],
      stats: BrainStats(
          totalSaved: 0, totalCompleted: 0, totalServed: 0, domainsExplored: 0, bridgeConnections: 0),
      bioThresholdReached: false,
    );
  }
  return ref.watch(apiProvider).getBrain(userId: uid);
});

final savedProvider = FutureProvider<List<QuicksCard>>((ref) async {
  final uid = ref.watch(userIdProvider);
  if (uid == null) return const [];
  return ref.watch(apiProvider).getSaved(userId: uid);
});

final profileProvider = FutureProvider<Profile?>((ref) async {
  final uid = ref.watch(userIdProvider);
  if (uid == null) return null;
  return ref.watch(apiProvider).getProfile(userId: uid);
});

/// Card detail (family by card id).
final cardProvider = FutureProvider.family<QuicksCard, String>((ref, id) async {
  return ref.watch(apiProvider).getCard(cardId: id, userId: ref.watch(userIdProvider));
});

/// Pre-generated Deep Dive long-form for a card (family by card id).
final deepDiveProvider = FutureProvider.family<String, String>((ref, id) async {
  return ref.watch(apiProvider).getDeepDive(cardId: id);
});

/// Invalidate everything that changes when the user engages with a card.
void refreshBrainData(WidgetRef ref) {
  ref.invalidate(brainProvider);
  ref.invalidate(savedProvider);
  ref.invalidate(profileProvider);
}
