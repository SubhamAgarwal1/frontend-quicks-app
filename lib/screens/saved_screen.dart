import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/theme.dart';
import '../state/providers.dart';

/// The saved-cards grid (the "Discover/Saved" tab). Tight image-only mosaic.
class SavedScreen extends ConsumerWidget {
  const SavedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final saved = ref.watch(savedProvider);
    return SafeArea(
      bottom: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 14),
            child: Text('Saved', style: AppText.heading(size: 26)),
          ),
          Expanded(
            child: saved.when(
              loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.teal)),
              error: (e, _) => Center(child: Text('Couldn’t load', style: AppText.body(color: AppColors.textDim))),
              data: (cards) {
                if (cards.isEmpty) {
                  return Center(
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.bookmark_border, size: 52, color: AppColors.border),
                      const SizedBox(height: 14),
                      Text('Nothing saved yet', style: AppText.body(size: 14, color: AppColors.textDim)),
                      const SizedBox(height: 4),
                      Text('Tap the bookmark on a card to keep it.',
                          style: AppText.body(size: 12, color: AppColors.textMuted)),
                    ]),
                  );
                }
                return RefreshIndicator(
                  color: AppColors.teal,
                  backgroundColor: AppColors.surfaceRaised,
                  onRefresh: () async => ref.invalidate(savedProvider),
                  child: GridView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 90),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3, mainAxisSpacing: 3, crossAxisSpacing: 3, childAspectRatio: 1,
                    ),
                    itemCount: cards.length,
                    itemBuilder: (context, i) {
                      final card = cards[i];
                      return GestureDetector(
                        onTap: () => context.push('/card/${card.id}'),
                        child: Container(
                          color: AppColors.surfaceRaised,
                          child: card.imageUrl.isEmpty
                              ? _Fallback(card.l1Domain)
                              : CachedNetworkImage(
                                  imageUrl: card.imageUrl,
                                  fit: BoxFit.cover,
                                  placeholder: (_, __) => Container(color: AppColors.surface),
                                  errorWidget: (_, __, ___) => _Fallback(card.l1Domain),
                                ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _Fallback extends StatelessWidget {
  const _Fallback(this.domain);
  final String domain;
  @override
  Widget build(BuildContext context) {
    final color = AppColors.forDomain(domain);
    return Container(
      color: color.withValues(alpha: 0.18),
      alignment: Alignment.center,
      child: Text(domain.isNotEmpty ? domain[0] : '?', style: AppText.heading(size: 20, color: color)),
    );
  }
}
