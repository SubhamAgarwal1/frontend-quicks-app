import 'dart:math';

import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../models/brain.dart';

/// Renders the Brain as a drifting constellation: one node per explored L1 domain
/// (size ∝ engagement, colour = domain), faint links between domains that share a
/// bridge concept, and ghost outlines for unexplored domains. Tap a node to act.
class BrainConstellation extends StatefulWidget {
  const BrainConstellation({super.key, required this.graph, this.onTapDomain});
  final BrainGraph graph;
  final void Function(String domain)? onTapDomain;

  @override
  State<BrainConstellation> createState() => _BrainConstellationState();
}

class _BrainConstellationState extends State<BrainConstellation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _drift;

  @override
  void initState() {
    super.initState();
    _drift = AnimationController(vsync: this, duration: const Duration(seconds: 12))..repeat();
  }

  @override
  void dispose() {
    _drift.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        final nodes = _layout(size);
        return AnimatedBuilder(
          animation: _drift,
          builder: (context, _) {
            return GestureDetector(
              onTapUp: (d) {
                for (final n in nodes) {
                  final p = n.animated(_drift.value, size);
                  if ((d.localPosition - p).distance <= n.radius + 12) {
                    widget.onTapDomain?.call(n.domain);
                    return;
                  }
                }
              },
              child: CustomPaint(
                size: size,
                painter: _ConstellationPainter(
                  nodes: nodes,
                  bridges: widget.graph.bridges,
                  allDomains: widget.graph.allDomains,
                  t: _drift.value,
                ),
              ),
            );
          },
        );
      },
    );
  }

  List<_Node> _layout(Size size) {
    final explored = widget.graph.domains;
    if (explored.isEmpty) return const [];
    final maxScore = explored.map((d) => d.engagementScore).fold<double>(0, max).clamp(0.001, double.infinity);
    final rnd = Random(7); // stable layout
    return [
      for (var i = 0; i < explored.length; i++)
        _Node(
          domain: explored[i].l1Domain,
          color: AppColors.forDomain(explored[i].l1Domain),
          radius: 12 + 22 * (explored[i].engagementScore / maxScore),
          // Spread nodes on a jittered ring.
          base: Offset(
            0.5 + 0.34 * cos(2 * pi * i / explored.length + rnd.nextDouble()),
            0.46 + 0.34 * sin(2 * pi * i / explored.length + rnd.nextDouble()),
          ),
          phase: rnd.nextDouble() * 2 * pi,
        ),
    ];
  }
}

class _Node {
  _Node({required this.domain, required this.color, required this.radius, required this.base, required this.phase});
  final String domain;
  final Color color;
  final double radius;
  final Offset base; // normalised 0..1
  final double phase;

  Offset animated(double t, Size size) {
    const drift = 10.0;
    final dx = drift * cos(2 * pi * t + phase);
    final dy = drift * sin(2 * pi * t + phase * 1.3);
    return Offset(base.dx * size.width + dx, base.dy * size.height + dy);
  }
}

class _ConstellationPainter extends CustomPainter {
  _ConstellationPainter({
    required this.nodes,
    required this.bridges,
    required this.allDomains,
    required this.t,
  });
  final List<_Node> nodes;
  final List<BridgeNode> bridges;
  final List<String> allDomains;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final byDomain = {for (final n in nodes) n.domain: n};

    // Ghost territory: faint dashed circles for unexplored domains.
    final explored = nodes.map((n) => n.domain).toSet();
    final ghosts = allDomains.where((d) => !explored.contains(d)).toList();
    final ghostPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = AppColors.border;
    for (var i = 0; i < ghosts.length; i++) {
      final p = Offset(
        (0.2 + 0.6 * (i / (ghosts.length))) * size.width,
        (0.12 + 0.1 * (i.isEven ? 1 : -1) + 0.5) * size.height,
      );
      canvas.drawCircle(p, 9, ghostPaint);
    }

    // Bridge links between domains that share a concept.
    final linkPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (final b in bridges) {
      final present = b.connectedDomains.where(byDomain.containsKey).toList();
      for (var i = 0; i < present.length; i++) {
        for (var j = i + 1; j < present.length; j++) {
          final a = byDomain[present[i]]!.animated(t, size);
          final c = byDomain[present[j]]!.animated(t, size);
          linkPaint.color = AppColors.textMuted.withValues(alpha: 0.18);
          canvas.drawLine(a, c, linkPaint);
        }
      }
    }

    // Nodes: glow + core.
    for (final n in nodes) {
      final p = n.animated(t, size);
      final glow = Paint()
        ..color = n.color.withValues(alpha: 0.45)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14);
      canvas.drawCircle(p, n.radius * 1.2, glow);
      final core = Paint()
        ..shader = RadialGradient(
          colors: [Color.lerp(n.color, Colors.white, 0.3)!, n.color],
        ).createShader(Rect.fromCircle(center: p, radius: n.radius));
      canvas.drawCircle(p, n.radius, core);
    }
  }

  @override
  bool shouldRepaint(covariant _ConstellationPainter old) => old.t != t;
}
