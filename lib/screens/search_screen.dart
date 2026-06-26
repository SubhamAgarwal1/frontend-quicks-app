import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/theme.dart';
import '../models/card.dart';
import '../state/providers.dart';

/// Browse: a search field, domain chips, and a 2-column grid of cards.
/// Filters the loaded feed client-side (the dev backend has no search endpoint yet).
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  String _query = '';
  String? _domain;

  static const _domains = ['Psychology', 'History', 'Science', 'Economics', 'Philosophy', 'Art'];

  @override
  Widget build(BuildContext context) {
    final feed = ref.watch(feedProvider);
    return SafeArea(
      bottom: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 0),
            child: Text('Search', style: AppText.heading(size: 26)),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 12),
            child: TextField(
              onChanged: (v) => setState(() => _query = v.toLowerCase()),
              style: AppText.body(size: 14, color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: 'Search ideas…',
                hintStyle: AppText.body(size: 14, color: AppColors.textMuted),
                prefixIcon: const Icon(Icons.search, color: AppColors.textMuted, size: 20),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(21),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(21),
                  borderSide: const BorderSide(color: AppColors.teal),
                ),
              ),
            ),
          ),
          SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 18),
              children: [
                for (final d in _domains)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _Chip(
                      label: d,
                      active: _domain == d,
                      color: AppColors.forDomain(d),
                      onTap: () => setState(() => _domain = _domain == d ? null : d),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: feed.when(
              loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.teal)),
              error: (e, _) => Center(child: Text('Couldn’t load', style: AppText.body(color: AppColors.textDim))),
              data: (cards) {
                final filtered = cards.where((c) {
                  final matchesDomain = _domain == null || c.l1Domain == _domain;
                  final matchesQuery = _query.isEmpty ||
                      c.hook.toLowerCase().contains(_query) ||
                      c.l3Tags.any((t) => t.toLowerCase().contains(_query));
                  return matchesDomain && matchesQuery;
                }).toList();
                if (filtered.isEmpty) {
                  return Center(child: Text('No matches', style: AppText.body(color: AppColors.textDim)));
                }
                return GridView.builder(
                  padding: const EdgeInsets.fromLTRB(18, 0, 18, 90),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 0.82,
                  ),
                  itemCount: filtered.length,
                  itemBuilder: (context, i) => _TopicCard(card: filtered[i]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.active, required this.color, required this.onTap});
  final String label;
  final bool active;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: active ? color.withValues(alpha: 0.18) : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: active ? color.withValues(alpha: 0.5) : AppColors.border),
        ),
        child: Text(label, style: AppText.body(size: 12, color: active ? color : AppColors.textDim)),
      ),
    );
  }
}

class _TopicCard extends StatelessWidget {
  const _TopicCard({required this.card});
  final QuicksCard card;

  @override
  Widget build(BuildContext context) {
    final accent = AppColors.forDomain(card.l1Domain);
    return GestureDetector(
      onTap: () => context.push('/card/${card.id}'),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surfaceRaised,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borderSoft),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(card.l1Domain.toUpperCase(),
                style: AppText.label(size: 8, color: accent, tracking: 0.14)),
            const SizedBox(height: 8),
            Expanded(
              child: Text(card.hook,
                  maxLines: 5,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.body(size: 13, color: AppColors.textCard)),
            ),
          ],
        ),
      ),
    );
  }
}
