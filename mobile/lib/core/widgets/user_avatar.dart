import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class UserAvatar extends StatelessWidget {
  const UserAvatar({super.key, required this.name, this.url, this.size = 32});

  final String name;
  final String? url;
  final double size;

  @override
  Widget build(BuildContext context) {
    final initial = name.isEmpty ? '?' : name.characters.first.toUpperCase();
    final fallback = Container(
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        gradient: LinearGradient(colors: [AppColors.secondaryFixed, AppColors.primaryFixedDim]),
      ),
      child: Text(initial, style: AppTextStyles.labelLg.copyWith(fontSize: size * 0.42, color: AppColors.secondary)),
    );

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: AppColors.violetShadow(0.12), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      clipBehavior: Clip.antiAlias,
      child: url == null
          ? fallback
          : Image.network(url!, fit: BoxFit.cover, errorBuilder: (_, _, _) => fallback),
    );
  }
}
