import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Tasarımdaki LinguaAI logosu: mor gradyan kare içinde "A" konuşma balonu ve yeşil nokta.
class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.size = 32, this.showName = true});

  final double size;
  final bool showName;

  @override
  Widget build(BuildContext context) {
    final mark = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF8072F6), AppColors.primaryContainer, AppColors.primary],
        ),
        boxShadow: [BoxShadow(color: AppColors.violetShadow(0.3), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(Symbols.chat_bubble, fill: 1, size: size * 0.62, color: Colors.white),
          Padding(
            padding: EdgeInsets.only(bottom: size * 0.08),
            child: Text('A', style: AppTextStyles.labelMd.copyWith(
              fontSize: size * 0.3, height: 1, color: AppColors.primary, fontWeight: FontWeight.w800)),
          ),
          Positioned(
            top: size * 0.14,
            right: size * 0.14,
            child: Container(
              width: size * 0.18,
              height: size * 0.18,
              decoration: const BoxDecoration(color: AppColors.tertiaryFixedDim, shape: BoxShape.circle),
            ),
          ),
        ],
      ),
    );
    if (!showName) return mark;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        mark,
        const SizedBox(width: 8),
        Text('LinguaAI', style: AppTextStyles.headlineSm.withColor(AppColors.primary).copyWith(letterSpacing: -0.3)),
      ],
    );
  }
}
