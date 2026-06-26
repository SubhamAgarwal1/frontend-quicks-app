import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/theme.dart';
import '../models/profile.dart';
import '../state/providers.dart';

/// Identity: avatar, name, the gold knowledge-bio, and a 3-column grid of saves.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);
    final saved = ref.watch(savedProvider);
    final brain = ref.watch(brainProvider);

    return SafeArea(
      bottom: false,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Profile', style: AppText.heading(size: 26)),
                  IconButton(
                    icon: const Icon(Icons.logout, color: AppColors.textMuted, size: 20),
                    onPressed: () async {
                      await ref.read(authProvider.notifier).signOut();
                      if (context.mounted) context.go('/');
                    },
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(child: _Header(profile: profile.value)),
          SliverToBoxAdapter(
            child: brain.maybeWhen(
              data: (g) => _BioBlock(
                profile: profile.value,
                bioReady: g.bioThresholdReached,
                onGenerate: () => _generateBio(context, ref),
              ),
              orElse: () => const SizedBox.shrink(),
            ),
          ),
          saved.when(
            loading: () => const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(40),
                child: Center(child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.teal)),
              ),
            ),
            error: (e, _) => SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Center(child: Text('Couldn’t load saves', style: AppText.body(color: AppColors.textDim))),
              ),
            ),
            data: (cards) {
              if (cards.isEmpty) {
                return SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(40),
                    child: Center(child: Text('Your saved cards appear here.',
                        style: AppText.body(color: AppColors.textMuted))),
                  ),
                );
              }
              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 90),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3, mainAxisSpacing: 6, crossAxisSpacing: 6, childAspectRatio: 1,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, i) {
                      final card = cards[i];
                      return GestureDetector(
                        onTap: () => context.push('/card/${card.id}'),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: card.imageUrl.isEmpty
                              ? Container(color: AppColors.forDomain(card.l1Domain).withValues(alpha: 0.18))
                              : CachedNetworkImage(
                                  imageUrl: card.imageUrl, fit: BoxFit.cover,
                                  errorWidget: (_, __, ___) =>
                                      Container(color: AppColors.surfaceRaised)),
                        ),
                      );
                    },
                    childCount: cards.length,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _generateBio(BuildContext context, WidgetRef ref) async {
    final uid = ref.read(userIdProvider);
    if (uid == null) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Generating your knowledge identity…')),
    );
    final bio = await ref.read(apiProvider).generateBio(userId: uid);
    ref.invalidate(profileProvider);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(bio == null ? 'Save 20+ cards across 3+ domains first.' : 'Bio updated.')),
      );
    }
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.profile});
  final Profile? profile;

  @override
  Widget build(BuildContext context) {
    final name = profile?.username ?? 'You';
    final initials = name.isNotEmpty ? name[0].toUpperCase() : 'Q';
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
      child: Row(
        children: [
          Container(
            width: 56, height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.border),
              image: profile?.avatarUrl != null
                  ? DecorationImage(image: CachedNetworkImageProvider(profile!.avatarUrl!), fit: BoxFit.cover)
                  : null,
            ),
            alignment: Alignment.center,
            child: profile?.avatarUrl == null
                ? Text(initials, style: AppText.heading(size: 18, color: AppColors.textCard))
                : null,
          ),
          const SizedBox(width: 14),
          Text(name, style: AppText.heading(size: 20)),
        ],
      ),
    );
  }
}

class _BioBlock extends StatelessWidget {
  const _BioBlock({required this.profile, required this.bioReady, required this.onGenerate});
  final Profile? profile;
  final bool bioReady;
  final VoidCallback onGenerate;

  @override
  Widget build(BuildContext context) {
    final bio = profile?.displayBio;
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 0),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.gold.withValues(alpha: 0.35)),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (bio != null && bio.isNotEmpty)
              Text(bio,
                  style: AppText.body(size: 14, color: AppColors.gold).copyWith(fontStyle: FontStyle.italic))
            else
              Text(
                bioReady
                    ? 'Generate your knowledge identity from what you’ve saved.'
                    : 'Save 20+ cards across 3+ domains to unlock your knowledge identity.',
                style: AppText.body(size: 13, color: AppColors.textDim),
              ),
            if (bioReady) ...[
              const SizedBox(height: 10),
              GestureDetector(
                onTap: onGenerate,
                child: Text(bio == null ? 'GENERATE BIO' : 'REGENERATE',
                    style: AppText.label(size: 9, color: AppColors.gold, tracking: 0.14)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
