import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme.dart';
import '../models/brain.dart';
import '../state/providers.dart';
import '../widgets/brain_constellation.dart';

/// Your knowledge as a constellation. Domains glow by engagement; bridge concepts
/// link them. Tap a node to inspect its subdomains.
class BrainScreen extends ConsumerWidget {
  const BrainScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final brain = ref.watch(brainProvider);
    return SafeArea(
      bottom: false,
      child: brain.when(
        loading: () => const Center(
            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.teal)),
        error: (e, _) => Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text('Couldn’t load your Brain', style: AppText.body(color: AppColors.textDim)),
            const SizedBox(height: 12),
            OutlinedButton(onPressed: () => ref.invalidate(brainProvider), child: const Text('Retry')),
          ]),
        ),
        data: (graph) => _BrainView(graph: graph),
      ),
    );
  }
}

class _BrainView extends ConsumerWidget {
  const _BrainView({required this.graph});
  final BrainGraph graph;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final topDomains = graph.domains.take(2).map((d) => d.l1Domain).join(', ');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Brain', style: AppText.heading(size: 26)),
              IconButton(
                onPressed: () => ref.invalidate(brainProvider),
                icon: const Icon(Icons.refresh, color: AppColors.textMuted, size: 20),
              ),
            ],
          ),
        ),
        if (!graph.isEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 4, 18, 0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.gold.withValues(alpha: 0.4)),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                '${graph.stats.totalSaved} SAVED · ${graph.stats.bridgeConnections} BRIDGES'
                '${topDomains.isNotEmpty ? ' · ${topDomains.toUpperCase()}' : ''}',
                style: AppText.label(size: 9, color: AppColors.gold, tracking: 0.12),
              ),
            ),
          ),
        Expanded(
          child: graph.isEmpty
              ? const _EmptyBrain()
              : BrainConstellation(
                  graph: graph,
                  onTapDomain: (d) => _showDomain(context, graph, d),
                ),
        ),
      ],
    );
  }

  void _showDomain(BuildContext context, BrainGraph graph, String domain) {
    final node = graph.domains.firstWhere((d) => d.l1Domain == domain);
    final color = AppColors.forDomain(domain);
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceRaised,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
              const SizedBox(width: 10),
              Text(domain, style: AppText.heading(size: 22)),
              const Spacer(),
              Text('${node.cardCount} cards', style: AppText.body(size: 13, color: AppColors.textMuted)),
            ]),
            const SizedBox(height: 16),
            ...node.subdomains.map((s) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(children: [
                    Expanded(child: Text(s.l2Subdomain, style: AppText.body(size: 14, color: AppColors.textCard))),
                    Text('${s.subCardCount}', style: AppText.label(size: 10, color: AppColors.textMuted)),
                  ]),
                )),
          ],
        ),
      ),
    );
  }
}

class _EmptyBrain extends StatelessWidget {
  const _EmptyBrain();
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.bubble_chart_outlined, size: 56, color: AppColors.border),
          const SizedBox(height: 16),
          Text('Save cards to build your Brain',
              style: AppText.body(size: 14, color: AppColors.textDim)),
        ],
      ),
    );
  }
}
