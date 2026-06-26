import 'dart:ui';

import 'package:flutter/material.dart';

import '../core/theme.dart';

/// A frosted glass panel — the card-text treatment from the design: a blurred,
/// low-opacity fill with a faint border that floats over imagery.
class GlassPanel extends StatelessWidget {
  const GlassPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.radius = 14,
    this.blur = 18,
    this.fill = AppColors.glassFill,
    this.borderColor = AppColors.borderSoft,
  });

  final Widget child;
  final EdgeInsets padding;
  final double radius;
  final double blur;
  final Color fill;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: fill,
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: borderColor),
          ),
          child: child,
        ),
      ),
    );
  }
}

/// A small wide-tracked category label, tinted to its L1 domain.
class DomainChip extends StatelessWidget {
  const DomainChip(this.domain, {super.key, this.subdomain});
  final String domain;
  final String? subdomain;

  @override
  Widget build(BuildContext context) {
    final color = AppColors.forDomain(domain);
    final text = subdomain == null ? domain : '$domain · $subdomain';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(text.toUpperCase(),
          style: AppText.label(size: 9, color: color, tracking: 0.12, weight: FontWeight.w600)),
    );
  }
}
