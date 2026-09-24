import 'package:flutter/widgets.dart';

import 'app_colors.dart';

/// DESIGN.md spacing (1rem = 16) ve köşe yuvarlaklıkları.
abstract final class AppSpacing {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 32.0;
  static const xxl = 40.0;
  static const gutter = 16.0;
  static const gutterSm = 12.0;
  static const margin = 20.0;
}

abstract final class AppRadius {
  static const sm = 8.0;
  static const md = 16.0; // rounded-2xl (tailwind DEFAULT 1rem)
  static const card = 24.0; // rounded-3xl / rounded-[24px]
  static const cardLg = 28.0; // rounded-[28px]
  static const lg = 32.0; // tailwind 'lg' = 2rem
  static const full = 999.0;
}

/// Tasarımlarda tekrar eden gölgeler.
abstract final class AppShadows {
  static List<BoxShadow> soft([double a = 0.06]) =>
      [BoxShadow(color: AppColors.violetShadow(a), blurRadius: 24, offset: const Offset(0, 8))];
  static List<BoxShadow> card([double a = 0.07]) =>
      [BoxShadow(color: AppColors.violetShadow(a), blurRadius: 28, offset: const Offset(0, 12))];
  static List<BoxShadow> strong([double a = 0.28]) =>
      [BoxShadow(color: AppColors.violetShadow(a), blurRadius: 36, offset: const Offset(0, 16))];
  static List<BoxShadow> button([double a = 0.35]) =>
      [BoxShadow(color: AppColors.violetShadow(a), blurRadius: 28, offset: const Offset(0, 12))];
  static const List<BoxShadow> sm = [BoxShadow(color: Color(0x0D000000), blurRadius: 3, offset: Offset(0, 1))];
}
