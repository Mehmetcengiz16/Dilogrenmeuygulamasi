import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Ekranın altına sabit, tam genişlikte alt menü.
/// Tasarımdaki görsel dil korunur: aktif sekme dolu mor daire, ortadaki mikrofon (AI sohbet) öne çıkar.
class AppBottomNavBar extends StatelessWidget {
  const AppBottomNavBar({super.key, required this.currentIndex, required this.onTap});

  final int currentIndex;
  final ValueChanged<int> onTap;

  static const height = 68.0;

  static const _items = [
    (Symbols.home, 'Ana Sayfa'),
    (Symbols.auto_awesome, 'Pratik'),
    (Symbols.mic, 'AI Sohbet'),
    (Symbols.translate, 'Çeviri'),
    (Symbols.person, 'Profil'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        boxShadow: [BoxShadow(color: AppColors.violetShadow(0.10), blurRadius: 24, offset: const Offset(0, -4))],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: height,
          child: Row(
            children: [for (var i = 0; i < _items.length; i++) Expanded(child: _item(i))],
          ),
        ),
      ),
    );
  }

  Widget _item(int i) {
    final (icon, label) = _items[i];
    final active = i == currentIndex;
    final isMic = i == 2;

    final Color bg;
    final Color fg;
    List<BoxShadow>? shadow;
    if (active) {
      bg = AppColors.primary;
      fg = AppColors.onPrimary;
      shadow = [BoxShadow(color: AppColors.deepShadow(0.3), blurRadius: 14, offset: const Offset(0, 4))];
    } else if (isMic) {
      bg = AppColors.primaryContainer;
      fg = AppColors.onPrimaryContainer;
      shadow = [BoxShadow(color: AppColors.violetShadow(0.3), blurRadius: 12, offset: const Offset(0, 4))];
    } else {
      bg = Colors.transparent;
      fg = AppColors.onSurfaceVariant;
    }

    return Semantics(
      label: label,
      selected: active,
      button: true,
      child: InkWell(
        onTap: () => onTap(i),
        splashColor: AppColors.primaryFixed.withValues(alpha: 0.5),
        highlightColor: Colors.transparent,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(999),
                boxShadow: shadow,
              ),
              child: Icon(icon, size: isMic ? 24 : 22, color: fg, fill: active ? 1 : 0),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: AppTextStyles.labelSm.withColor(active ? AppColors.primary : AppColors.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
