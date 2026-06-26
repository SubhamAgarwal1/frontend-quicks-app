import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/theme.dart';
import '../state/providers.dart';
import 'signin_sheet.dart';

/// Entry screen: wordmark over a soft accent glow, with two paths.
/// If a session is already restored, it routes straight into the app.
class SplashScreen extends ConsumerWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);

    // Already signed in → go to the app once this frame settles.
    ref.listen(authProvider, (_, next) {
      if (next.value != null && context.mounted) context.go('/app');
    });
    if (auth.value != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) context.go('/app');
      });
    }

    final ready = !auth.isLoading;

    return Scaffold(
      body: Stack(
        children: [
          // Accent glow behind the mark.
          Align(
            alignment: const Alignment(0, -0.45),
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  AppColors.teal.withValues(alpha: 0.14),
                  Colors.transparent,
                ]),
              ),
            ),
          ),
          Column(
            children: [
              const Spacer(),
              Column(
                children: [
                  Text('Quicks', style: AppText.display(size: 48))
                      .animate()
                      .fadeIn(duration: 700.ms)
                      .scale(begin: const Offset(0.96, 0.96)),
                  const SizedBox(height: 10),
                  Text('KNOWLEDGE, IN FLASHES',
                      style: AppText.label(size: 10, color: AppColors.textMuted, tracking: 0.34)),
                ],
              ),
              const Spacer(),
              if (ready && auth.value == null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(28, 0, 28, 36),
                  child: Column(
                    children: [
                      _PrimaryButton(
                        label: 'NEW TO QUICKS',
                        onTap: () => context.push('/onboarding'),
                      ),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: () async {
                          final ok = await showSignInSheet(context, ref);
                          if (ok && context.mounted) context.go('/app');
                        },
                        child: Text('I have an account',
                            style: AppText.body(size: 13, color: AppColors.textDim)),
                      ),
                    ],
                  ),
                )
              else
                const Padding(
                  padding: EdgeInsets.only(bottom: 60),
                  child: SizedBox(
                    width: 22, height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.teal),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Color(0xFF3A3B3F)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        ),
        child: Text(label, style: AppText.label(size: 11, color: AppColors.textCard, tracking: 0.16)),
      ),
    );
  }
}
