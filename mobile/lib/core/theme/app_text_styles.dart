import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Tipografi ölçeği: Plus Jakarta Sans, DESIGN.md'deki boyut / satır yüksekliği / ağırlıklar.
abstract final class AppTextStyles {
  static TextStyle _base(double size, double lineHeight, FontWeight weight) => GoogleFonts.plusJakartaSans(
        fontSize: size,
        height: lineHeight / size,
        fontWeight: weight,
        color: AppColors.onSurface,
      );

  static final displayLg = _base(36, 44, FontWeight.w700);
  static final headlineLg = _base(28, 36, FontWeight.w700).copyWith(letterSpacing: -0.4);
  static final headlineMd = _base(22, 30, FontWeight.w600);
  static final headlineSm = _base(18, 24, FontWeight.w600);
  static final bodyLg = _base(16, 24, FontWeight.w400);
  static final bodyMd = _base(14, 20, FontWeight.w400);
  static final bodySm = _base(12, 16, FontWeight.w400);
  static final labelLg = _base(14, 20, FontWeight.w600);
  static final labelMd = _base(12, 16, FontWeight.w600);
  static final labelSm = _base(10, 12, FontWeight.w700);
}

extension TextStyleX on TextStyle {
  TextStyle get bold => copyWith(fontWeight: FontWeight.w700);
  TextStyle get variant => copyWith(color: AppColors.onSurfaceVariant);
  TextStyle withColor(Color c) => copyWith(color: c);
}
