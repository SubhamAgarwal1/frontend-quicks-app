import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/theme.dart';
import 'screens/card_detail_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/shell_screen.dart';
import 'screens/splash_screen.dart';

void main() {
  runApp(const ProviderScope(child: QuicksApp()));
}

final _router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (_, __) => const SplashScreen()),
    GoRoute(path: '/onboarding', builder: (_, __) => const OnboardingScreen()),
    GoRoute(path: '/app', builder: (_, __) => const ShellScreen()),
    GoRoute(
      path: '/card/:id',
      builder: (_, state) => CardDetailScreen(cardId: state.pathParameters['id']!),
    ),
  ],
);

class QuicksApp extends StatelessWidget {
  const QuicksApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Quicks',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      routerConfig: _router,
    );
  }
}
