import 'package:flutter/material.dart';

/// Fluent AI Studio renk token'ları (ekrantasarimları/fluent_ai_studio/DESIGN.md).
abstract final class AppColors {
  static const primary = Color(0xFF5341CD);
  static const onPrimary = Color(0xFFFFFFFF);
  static const primaryContainer = Color(0xFF6C5CE7);
  static const onPrimaryContainer = Color(0xFFFAF6FF);
  static const primaryFixed = Color(0xFFE4DFFF);
  static const primaryFixedDim = Color(0xFFC6BFFF);
  static const onPrimaryFixed = Color(0xFF160066);

  static const secondary = Color(0xFF5952AF);
  static const secondaryContainer = Color(0xFFA19AFD);
  static const onSecondaryContainer = Color(0xFF352C8A);
  static const secondaryFixed = Color(0xFFE3DFFF);
  static const onSecondaryFixed = Color(0xFF140067);

  static const tertiary = Color(0xFF00664F);
  static const tertiaryContainer = Color(0xFF008166);
  static const onTertiaryContainer = Color(0xFFDEFFF1);
  static const tertiaryFixed = Color(0xFF63FBCF);
  static const tertiaryFixedDim = Color(0xFF3FDEB4);
  static const onTertiaryFixed = Color(0xFF002118);

  static const error = Color(0xFFBA1A1A);
  static const errorContainer = Color(0xFFFFDAD6);
  static const onErrorContainer = Color(0xFF93000A);

  static const background = Color(0xFFF4FAFD);
  static const surface = Color(0xFFF4FAFD);
  static const surfaceContainerLowest = Color(0xFFFFFFFF);
  static const surfaceContainerLow = Color(0xFFEEF5F7);
  static const surfaceContainer = Color(0xFFE8EFF1);
  static const surfaceContainerHigh = Color(0xFFE2E9EC);
  static const surfaceContainerHighest = Color(0xFFDDE4E6);
  static const onSurface = Color(0xFF161D1F);
  static const onSurfaceVariant = Color(0xFF474554);
  static const outline = Color(0xFF787586);
  static const outlineVariant = Color(0xFFC8C4D7);
  static const inverseSurface = Color(0xFF2B3234);

  /// Tasarımlardaki mor tonlu yumuşak gölge rengi: rgba(108,92,231,a)
  static Color violetShadow(double alpha) => const Color(0xFF6C5CE7).withValues(alpha: alpha);
  static Color deepShadow(double alpha) => const Color(0xFF5341CD).withValues(alpha: alpha);
}
