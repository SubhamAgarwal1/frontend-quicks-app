import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/theme.dart';
import 'signin_sheet.dart';

/// 2–3 paged panels: what Quicks is, how the Brain grows. Dots + next.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pc = PageController();
  int _page = 0;

  static const _panels = [
    (
      'One idea at a time',
      'A vertical feed of sharp, surprising ideas across psychology, history, science and more — built to make you think, not scroll.',
      AppColors.gold,
    ),
    (
      'Save what resonates',
      'Tap to keep a card. Each save, completion and lingering read quietly feeds your Brain.',
      AppColors.teal,
    ),
    (
      'Watch your Brain grow',
      'Your saves form a living constellation — domains light up, and concepts bridge across fields as you learn.',
      AppColors.violet,
    ),
  ];

  @override
  void dispose() {
    _pc.dispose();
    super.dispose();
  }

  void _next() async {
    if (_page < _panels.length - 1) {
      _pc.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    } else {
      final ok = await showSignInSheet(context, ref);
      if (ok && mounted) context.go('/app');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pc,
                onPageChanged: (i) => setState(() => _page = i),
                itemCount: _panels.length,
                itemBuilder: (context, i) {
                  final (title, body, accent) = _panels[i];
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(28, 40, 28, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Center(
                            child: Container(
                              width: 160,
                              height: 160,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(colors: [
                                  accent.withValues(alpha: 0.5),
                                  accent.withValues(alpha: 0.05),
                                ]),
                                boxShadow: [BoxShadow(color: accent.withValues(alpha: 0.4), blurRadius: 40)],
                              ),
                            ),
                          ),
                        ),
                        Text(title, style: AppText.heading(size: 30)),
                        const SizedBox(height: 14),
                        Text(body, style: AppText.body(size: 15, color: AppColors.textDim)),
                        const SizedBox(height: 60),
                      ],
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 0, 28, 28),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      for (var i = 0; i < _panels.length; i++)
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 220),
                          margin: const EdgeInsets.only(right: 6),
                          width: i == _page ? 18 : 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: i == _page ? AppColors.teal : AppColors.border,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                    ],
                  ),
                  GestureDetector(
                    onTap: _next,
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFF3A3B3F)),
                      ),
                      child: const Icon(Icons.arrow_forward, color: AppColors.textCard, size: 18),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
