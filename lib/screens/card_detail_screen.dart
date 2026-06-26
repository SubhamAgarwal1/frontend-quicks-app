import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme.dart';
import '../models/card.dart';
import '../state/providers.dart';

/// Deep-dive view of a single card: full content, category, the pre-generated
/// Deep Dive long-form, and an "Add to Brain" (save) action.
class CardDetailScreen extends ConsumerStatefulWidget {
  const CardDetailScreen({super.key, required this.cardId});
  final String cardId;

  @override
  ConsumerState<CardDetailScreen> createState() => _CardDetailScreenState();
}

class _CardDetailScreenState extends ConsumerState<CardDetailScreen> {
  bool? _savedOverride;

  Future<void> _toggleSave(QuicksCard card) async {
    final uid = ref.read(userIdProvider);
    if (uid == null) return;
    final api = ref.read(apiProvider);
    final saved = _savedOverride ?? card.isSaved;
    setState(() => _savedOverride = !saved);
    try {
      if (saved) {
        await api.unsave(userId: uid, cardId: card.id);
      } else {
        await api.save(userId: uid, cardId: card.id);
      }
      refreshBrainData(ref);
    } catch (_) {
      if (mounted) setState(() => _savedOverride = saved);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cardAsync = ref.watch(cardProvider(widget.cardId));
    return Scaffold(
      body: cardAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.teal)),
        error: (e, _) => _ErrorBody(onBack: () => Navigator.of(context).pop()),
        data: (card) => _Body(
          card: card,
          saved: _savedOverride ?? card.isSaved,
          onSave: () => _toggleSave(card),
        ),
      ),
    );
  }
}

class _Body extends ConsumerWidget {
  const _Body({required this.card, required this.saved, required this.onSave});
  final QuicksCard card;
  final bool saved;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accent = AppColors.forDomain(card.l1Domain);
    final deepDive = ref.watch(deepDiveProvider(card.id));
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          pinned: true,
          backgroundColor: AppColors.ground,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.textCard),
            onPressed: () => Navigator.of(context).pop(),
          ),
          actions: [
            IconButton(icon: const Icon(Icons.ios_share, color: AppColors.textCard), onPressed: () {}),
          ],
          expandedHeight: card.imageUrl.isEmpty ? 0 : 220,
          flexibleSpace: card.imageUrl.isEmpty
              ? null
              : FlexibleSpaceBar(
                  background: Stack(fit: StackFit.expand, children: [
                    CachedNetworkImage(imageUrl: card.imageUrl, fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => Container(color: AppColors.surface)),
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter, end: Alignment.bottomCenter,
                          colors: [Colors.transparent, AppColors.ground],
                        ),
                      ),
                    ),
                  ]),
                ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(card.l1Domain.toUpperCase(),
                    style: AppText.label(size: 9, color: accent, tracking: 0.14)),
                const SizedBox(height: 12),
                Text(card.hook, style: AppText.heading(size: 26, weight: FontWeight.w600)),
                const SizedBox(height: 16),
                Text(card.insightBody, style: AppText.body(size: 15, color: AppColors.textCard)),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    border: Border.all(color: accent.withValues(alpha: 0.4)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(card.twist,
                      style: AppText.body(size: 14, color: AppColors.textPrimary)
                          .copyWith(fontStyle: FontStyle.italic)),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton.icon(
                    onPressed: onSave,
                    style: FilledButton.styleFrom(
                      backgroundColor: saved ? AppColors.surfaceRaised : AppColors.textPrimary,
                      foregroundColor: saved ? AppColors.gold : AppColors.ground,
                      side: saved ? const BorderSide(color: AppColors.gold) : BorderSide.none,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                    ),
                    icon: Icon(saved ? Icons.bookmark : Icons.add, size: 18),
                    label: Text(saved ? 'In your Brain' : 'Add to Brain',
                        style: AppText.body(size: 14, weight: FontWeight.w600,
                            color: saved ? AppColors.gold : AppColors.ground)),
                  ),
                ),
                if (card.l3Tags.isNotEmpty) ...[
                  const SizedBox(height: 18),
                  Wrap(
                    spacing: 8, runSpacing: 8,
                    children: card.l3Tags
                        .map((t) => Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceRaised,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: AppColors.borderSoft),
                              ),
                              child: Text('#$t', style: AppText.body(size: 11, color: AppColors.textMuted)),
                            ))
                        .toList(),
                  ),
                ],
                const SizedBox(height: 24),
                Text('DEEP DIVE', style: AppText.label(size: 9, color: AppColors.textMuted, tracking: 0.16)),
                const SizedBox(height: 10),
                deepDive.when(
                  loading: () => const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: SizedBox(
                        height: 18, width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.teal)),
                  ),
                  error: (_, __) => Text('Deep Dive unavailable.',
                      style: AppText.body(size: 13, color: AppColors.textMuted)),
                  data: (text) => Text(text, style: AppText.body(size: 15, color: AppColors.textCard).copyWith(height: 1.85)),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ErrorBody extends StatelessWidget {
  const _ErrorBody({required this.onBack});
  final VoidCallback onBack;
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(children: [
        Align(
          alignment: Alignment.centerLeft,
          child: IconButton(icon: const Icon(Icons.arrow_back, color: AppColors.textCard), onPressed: onBack),
        ),
        const Spacer(),
        Center(child: Text('Couldn’t load this card', style: AppText.body(color: AppColors.textDim))),
        const Spacer(),
      ]),
    );
  }
}
