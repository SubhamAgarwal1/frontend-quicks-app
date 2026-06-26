import 'package:flutter/material.dart';

import '../core/theme.dart';

/// Persistent 5-tab bar: Home · Search · Brain · Saved · Profile.
/// The active tab glows in its accent (violet, per the wireframe).
class AppBottomNav extends StatelessWidget {
  const AppBottomNav({super.key, required this.index, required this.onTap});
  final int index;
  final ValueChanged<int> onTap;

  static const _items = <(_NavGlyph, String)>[
    (_NavGlyph.home, 'Home'),
    (_NavGlyph.search, 'Search'),
    (_NavGlyph.brain, 'Brain'),
    (_NavGlyph.saved, 'Saved'),
    (_NavGlyph.profile, 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: AppColors.surfaceRaised,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            for (var i = 0; i < _items.length; i++)
              _NavButton(
                glyph: _items[i].$1,
                active: i == index,
                onTap: () => onTap(i),
              ),
          ],
        ),
      ),
    );
  }
}

enum _NavGlyph { home, search, brain, saved, profile }

IconData _icon(_NavGlyph g, bool active) => switch (g) {
      _NavGlyph.home => active ? Icons.auto_stories : Icons.auto_stories_outlined,
      _NavGlyph.search => Icons.search,
      _NavGlyph.brain => active ? Icons.bubble_chart : Icons.bubble_chart_outlined,
      _NavGlyph.saved => active ? Icons.bookmark : Icons.bookmark_border,
      _NavGlyph.profile => active ? Icons.person : Icons.person_outline,
    };

class _NavButton extends StatelessWidget {
  const _NavButton({required this.glyph, required this.active, required this.onTap});
  final _NavGlyph glyph;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = active ? AppColors.violet : AppColors.textMuted;
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
          decoration: BoxDecoration(
            color: active ? AppColors.violet.withValues(alpha: 0.16) : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Center(child: Icon(_icon(glyph, active), size: 18, color: color)),
        ),
      ),
    );
  }
}
