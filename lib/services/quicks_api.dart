import 'package:dio/dio.dart';

import '../core/config.dart';
import '../models/brain.dart';
import '../models/card.dart';
import '../models/profile.dart';

/// Thin, typed wrapper over the Quicks REST API.
///
/// The user credential is centralised here: the dev backend identifies the user
/// via a `?user=` query param, so [_q] injects it on every call. When real SSO
/// lands, replace that single helper with an `Authorization: Bearer <jwt>` header
/// — no call site changes.
class QuicksApi {
  QuicksApi([Dio? dio])
      : _dio = dio ??
            Dio(BaseOptions(
              baseUrl: AppConfig.apiBaseUrl,
              connectTimeout: AppConfig.connectTimeout,
              receiveTimeout: AppConfig.receiveTimeout,
              headers: {'Accept': 'application/json'},
            ));

  final Dio _dio;

  Map<String, dynamic> _q(String? userId, [Map<String, dynamic>? extra]) => {
        if (userId != null) 'user': userId,
        ...?extra,
      };

  // ── Feed ───────────────────────────────────────────────────────────────────

  Future<List<QuicksCard>> getFeed({String? userId, int limit = 10}) async {
    final r = await _dio.get('/api/v1/feed', queryParameters: _q(userId, {'limit': limit}));
    return (r.data['cards'] as List).map((e) => QuicksCard.fromJson(e)).toList();
  }

  Future<double> engage({
    required String userId,
    required String cardId,
    required String signalType, // save | completion | dwell
    int? dwellSeconds,
  }) async {
    final r = await _dio.post(
      '/api/v1/feed/engage',
      queryParameters: _q(userId),
      data: {
        'card_id': cardId,
        'signal_type': signalType,
        if (dwellSeconds != null) 'dwell_seconds': dwellSeconds,
      },
    );
    return (r.data['brain_weight'] as num?)?.toDouble() ?? 0;
  }

  Future<void> markServed({required String userId, required List<String> cardIds}) async {
    if (cardIds.isEmpty) return;
    await _dio.post('/api/v1/feed/served', queryParameters: _q(userId), data: {'card_ids': cardIds});
  }

  // ── Saves ──────────────────────────────────────────────────────────────────

  Future<List<QuicksCard>> getSaved({required String userId, int limit = 50}) async {
    final r = await _dio.get('/api/v1/saves', queryParameters: _q(userId, {'limit': limit}));
    return (r.data['cards'] as List).map((e) => QuicksCard.fromJson(e)).toList();
  }

  Future<void> unsave({required String userId, required String cardId}) async {
    await _dio.delete('/api/v1/saves/$cardId', queryParameters: _q(userId));
  }

  /// Convenience: a save is recorded as an engagement signal of type "save".
  Future<void> save({required String userId, required String cardId}) =>
      engage(userId: userId, cardId: cardId, signalType: 'save');

  // ── Brain ──────────────────────────────────────────────────────────────────

  Future<BrainGraph> getBrain({required String userId}) async {
    final r = await _dio.get('/api/v1/brain', queryParameters: _q(userId));
    return BrainGraph.fromJson(r.data);
  }

  Future<BrainShare> getBrainShare({required String userId}) async {
    final r = await _dio.get('/api/v1/brain/share', queryParameters: _q(userId));
    return BrainShare.fromJson(r.data);
  }

  /// Returns the generated bio, or null if the 20-save / 3-domain threshold isn't met.
  Future<String?> generateBio({required String userId}) async {
    try {
      final r = await _dio.post('/api/v1/brain/generate-bio', queryParameters: _q(userId));
      return r.data['generated_bio'] as String?;
    } on DioException catch (e) {
      if (e.response?.statusCode == 400) return null; // threshold not met
      rethrow;
    }
  }

  // ── Card detail ─────────────────────────────────────────────────────────────

  Future<QuicksCard> getCard({required String cardId, String? userId}) async {
    final r = await _dio.get('/api/v1/cards/$cardId', queryParameters: _q(userId));
    return QuicksCard.fromJson(r.data);
  }

  Future<String> getDeepDive({required String cardId}) async {
    final r = await _dio.get('/api/v1/cards/$cardId/deep-dive');
    return r.data['deep_dive'] as String? ?? '';
  }

  // ── Profile ─────────────────────────────────────────────────────────────────

  Future<Profile> getProfile({required String userId}) async {
    final r = await _dio.get('/api/v1/profile', queryParameters: _q(userId));
    return Profile.fromJson(r.data);
  }

  Future<Profile> updateProfile({
    required String userId,
    String? username,
    String? userBio,
    String? avatarUrl,
  }) async {
    final r = await _dio.put('/api/v1/profile', queryParameters: _q(userId), data: {
      if (username != null) 'username': username,
      if (userBio != null) 'user_bio': userBio,
      if (avatarUrl != null) 'avatar_url': avatarUrl,
    });
    return Profile.fromJson(r.data);
  }
}
