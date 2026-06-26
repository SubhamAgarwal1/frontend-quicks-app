import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/theme.dart';
import '../models/card.dart';
import '../state/providers.dart';
import '../widgets/glass_panel.dart';

/// The home feed: full-screen cards, swipe vertically. Each card layers a glass
/// hook / body / twist over its image. Dwell + completion are reported to the
/// Brain as you move through the feed; the bookmark records a save.
class FeedScreen extends ConsumerStatefulWidget {
  const FeedScreen({super.key});

  @override
  ConsumerState<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends ConsumerState<FeedScreen> {
  final _pc = PageController();
  int _current = 0;
  DateTime _enteredAt = DateTime.now();
  // Per-card optimistic save state; falls back to the card's server value.
  final _saveState = <String, bool>{};

  @override
  void dispose() {
    _pc.dispose();
    super.dispose();
  }

  void _onPageChanged(List<QuicksCard> cards, int next) {
    _reportEngagement(cards, _current);
    setState(() => _current = next);
    _enteredAt = DateTime.now();
  }

  void _reportEngagement(List<QuicksCard> cards, int index) {
    if (index < 0 || index >= cards.length) return;
    final uid = ref.read(userIdProvider);
    if (uid == null) return;
    final elapsed = DateTime.now().difference(_enteredAt).inSeconds;
    if (elapsed < 2) return; // ignore accidental flicks
    final api = ref.read(apiProvider);
    final card = cards[index];
    api.engage(userId: uid, cardId: card.id, signalType: 'completion');
    if (elapsed >= 10) {
      api.engage(userId: uid, cardId: card.id, signalType: 'dwell', dwellSeconds: elapsed);
    }
    refreshBrainData(ref);
  }

  bool _isSaved(QuicksCard card) => _saveState[card.id] ?? card.isSaved;

  Future<void> _toggleSave(QuicksCard card) async {
    final uid = ref.read(userIdProvider);
    if (uid == null) return;
    final api = ref.read(apiProvider);
    final wasSaved = _isSaved(card);
    setState(() => _saveState[card.id] = !wasSaved);
    try {
      if (wasSaved) {
        await api.unsave(userId: uid, cardId: card.id);
      } else {
        await api.save(userId: uid, cardId: card.id);
      }
      refreshBrainData(ref);
    } catch (_) {
      if (mounted) setState(() => _saveState[card.id] = wasSaved);
    }
  }

  @override
  Widget build(BuildContext context) {
    final feed = ref.watch(feedProvider);
    return feed.when(
      loading: () => const _FeedLoading(),
      error: (e, _) => _FeedError(onRetry: () => ref.invalidate(feedProvider)),
      data: (cards) {
        if (cards.isEmpty) {
          return const Center(child: Text('No cards yet.', style: TextStyle(color: AppColors.textDim)));
        }
        return PageView.builder(
          controller: _pc,
          scrollDirection: Axis.vertical,
          itemCount: cards.length,
          onPageChanged: (i) => _onPageChanged(cards, i),
          itemBuilder: (context, i) {
            final card = cards[i];
            return _FeedCard(
              card: card,
              saved: _isSaved(card),
              onSave: () => _toggleSave(card),
              onDeepDive: () => context.push('/card/${card.id}'),
            );
          },
        );
      },
    );
  }
}

class _FeedCard extends StatelessWidget {
  const _FeedCard({required this.card, required this.saved, required this.onSave, required this.onDeepDive});
  final QuicksCard card;
  final bool saved;
  final VoidCallback onSave;
  final VoidCallback onDeepDive;

  @override
  Widget build(BuildContext context) {
    final accent = AppColors.forDomain(card.l1Domain);
    return Stack(
      fit: StackFit.expand,
      children: [
        // Full-bleed image canvas.
        if (card.imageUrl.isNotEmpty)
          CachedNetworkImage(
            imageUrl: card.imageUrl,
            fit: BoxFit.cover,
            placeholder: (_, __) => Container(color: AppColors.surface),
            errorWidget: (_, __, ___) => Container(color: AppColors.surface),
          )
        else
          Container(color: AppColors.surface),
        // Scrim for legibility.
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0x33000000), Color(0xCC000000)],
              stops: [0.2, 1.0],
            ),
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 92),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DomainChip(card.l1Domain, subdomain: card.l2Subdomain),
                const Spacer(),
                // Hook
                GlassPanel(
                  fill: const Color(0x40000000),
                  child: Text(card.hook,
                      style: AppText.heading(size: 24, weight: FontWeight.w600)),
                ),
                const SizedBox(height: 10),
                // Body
                GlassPanel(
                  fill: const Color(0x33000000),
                  child: Text(card.insightBody, style: AppText.body(size: 14, color: AppColors.textCard)),
                ),
                const SizedBox(height: 10),
                // Twist — warm-tinted glass pill, italic.
                GlassPanel(
                  fill: accent.withValues(alpha: 0.12),
                  borderColor: accent.withValues(alpha: 0.35),
                  child: Text(card.twist,
                      style: AppText.body(size: 13, color: AppColors.textPrimary)
                          .copyWith(fontStyle: FontStyle.italic)),
                ),
                const SizedBox(height: 14),
                _ActionRow(saved: saved, onSave: onSave, onDeepDive: onDeepDive),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({required this.saved, required this.onSave, required this.onDeepDive});
  final bool saved;
  final VoidCallback onSave;
  final VoidCallback onDeepDive;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _CircleAction(
          icon: saved ? Icons.bookmark : Icons.bookmark_border,
          color: saved ? AppColors.gold : AppColors.textCard,
          onTap: onSave,
        ),
        const SizedBox(width: 12),
        _CircleAction(icon: Icons.menu_book_outlined, color: AppColors.textCard, onTap: onDeepDive),
        const Spacer(),
        _CircleAction(icon: Icons.ios_share, color: AppColors.textCard, onTap: () {}),
      ],
    );
  }
}

class _CircleAction extends StatelessWidget {
  const _CircleAction({required this.icon, required this.color, required this.onTap});
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.06),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(11),
          child: Icon(icon, size: 20, color: color),
        ),
      ),
    );
  }
}

class _FeedLoading extends StatelessWidget {
  const _FeedLoading();
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(strokeWidth: 2, color: AppColors.teal),
          const SizedBox(height: 16),
          Text('Waking the feed…', style: AppText.label(size: 10, color: AppColors.textMuted)),
          const SizedBox(height: 4),
          Text('(free server may cold-start ~30s)',
              style: AppText.body(size: 11, color: AppColors.textMuted)),
        ],
      ),
    );
  }
}

class _FeedError extends StatelessWidget {
  const _FeedError({required this.onRetry});
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Couldn’t load the feed', style: AppText.body(size: 15, color: AppColors.textDim)),
          const SizedBox(height: 12),
          OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}
