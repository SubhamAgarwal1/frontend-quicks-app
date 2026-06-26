import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Quicks design tokens, lifted from the wireframe: a dark, premium "knowledge in
/// flashes" aesthetic — Playfair Display headings, Jost body, JetBrains Mono labels,
/// with gold / teal / violet category accents.
class AppColors {
  // Surfaces (deepest → raised)
  static const ground = Color(0xFF0A0B0C);
  static const surface = Color(0xFF0F1011);
  static const surfaceRaised = Color(0xFF141517);
  static const border = Color(0xFF2A2B2E);
  static const borderSoft = Color(0xFF1E1F22);

  // Text
  static const textPrimary = Color(0xFFE8E6E2);
  static const textCard = Color(0xFFCFCDC9);
  static const textDim = Color(0xFF9A9CA0);
  static const textMuted = Color(0xFF76787C);

  // Accents
  static const gold = Color(0xFFC9A44A);
  static const teal = Color(0xFF5BA3A1);
  static const violet = Color(0xFF8B7BD8);
  static const ocean = Color(0xFF3E7FA3);
  static const indigo = Color(0xFF6C6AE0);
  static const rose = Color(0xFFC97A9C);

  /// Glass panel fill that floats over imagery.
  static const glassFill = Color(0x0DFFFFFF); // rgba(255,255,255,.05)

  /// One distinct accent per L1 domain (used for tags, brain nodes, etc.).
  static const Map<String, Color> domain = {
    'Psychology': violet,
    'History': gold,
    'Science': teal,
    'Economics': ocean,
    'Philosophy': indigo,
    'Art': rose,
  };

  static Color forDomain(String? l1) => domain[l1] ?? textDim;
}

class AppText {
  static TextStyle display({double size = 42, Color color = AppColors.textPrimary}) =>
      GoogleFonts.playfairDisplay(fontSize: size, color: color, height: 1.05);

  static TextStyle heading({double size = 24, Color color = AppColors.textPrimary, FontWeight weight = FontWeight.w500}) =>
      GoogleFonts.playfairDisplay(fontSize: size, color: color, fontWeight: weight, height: 1.15);

  static TextStyle body({double size = 14, Color color = AppColors.textCard, FontWeight weight = FontWeight.w400}) =>
      GoogleFonts.jost(fontSize: size, color: color, fontWeight: weight, height: 1.6);

  /// Wide-tracked uppercase mono — the brand's eyebrow / label voice.
  static TextStyle label({double size = 10, Color color = AppColors.textMuted, double tracking = 0.16, FontWeight weight = FontWeight.w500}) =>
      GoogleFonts.jetBrainsMono(
        fontSize: size, color: color, fontWeight: weight,
        letterSpacing: tracking * size, height: 1.2,
      );
}

ThemeData buildTheme() {
  final base = ThemeData.dark(useMaterial3: true);
  return base.copyWith(
    scaffoldBackgroundColor: AppColors.ground,
    colorScheme: base.colorScheme.copyWith(
      surface: AppColors.surface,
      primary: AppColors.teal,
      secondary: AppColors.gold,
      tertiary: AppColors.violet,
    ),
    splashFactory: InkRipple.splashFactory,
    textTheme: GoogleFonts.jostTextTheme(base.textTheme).apply(
      bodyColor: AppColors.textCard,
      displayColor: AppColors.textPrimary,
    ),
  );
}
