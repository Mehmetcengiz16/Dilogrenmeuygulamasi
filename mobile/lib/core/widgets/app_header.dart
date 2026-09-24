import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../features/auth/data/auth_controller.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'app_logo.dart';
import 'user_avatar.dart';

/// Sekme ekranlarının üst başlığı: logo + seri rozeti + bildirim + profil (h-16, bulanık yüzey).
class AppHeader extends ConsumerWidget implements PreferredSizeWidget {
  const AppHeader({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).value;
    return _BlurBar(
      child: Row(
        children: [
          const AppLogo(),
          const Spacer(),
          StreakPill(streak: user?.currentStreak ?? 0),
          const SizedBox(width: 8),
          _CircleIconButton(
            icon: Symbols.notifications,
            tooltip: 'Bildirimler',
            onTap: () => ScaffoldMessenger.of(context)
                .showSnackBar(const SnackBar(content: Text('Yeni bildirimin yok.'))),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => context.go('/profile'),
            child: UserAvatar(name: user?.name ?? '', url: user?.avatarUrl),
          ),
        ],
      ),
    );
  }
}

/// Yığın ekranların başlığı (quiz): geri + başlık + seçenekler + profil.
class StackHeader extends ConsumerWidget implements PreferredSizeWidget {
  const StackHeader({super.key, required this.title, this.onBack, this.onMore});

  final String title;
  final VoidCallback? onBack;
  final VoidCallback? onMore;

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).value;
    return _BlurBar(
      child: Row(
        children: [
          Transform.translate(
            offset: const Offset(-8, 0),
            child: _CircleIconButton(
              icon: Symbols.arrow_back_ios_new,
              color: AppColors.onSurface,
              tooltip: 'Geri',
              onTap: onBack ?? () => context.pop(),
            ),
          ),
          Expanded(
            child: Text(title, style: AppTextStyles.headlineSm, maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
          if (onMore != null) _CircleIconButton(icon: Symbols.more_horiz, tooltip: 'Seçenekler', onTap: onMore!),
          const SizedBox(width: 8),
          UserAvatar(name: user?.name ?? '', url: user?.avatarUrl),
        ],
      ),
    );
  }
}

class StreakPill extends StatelessWidget {
  const StreakPill({super.key, required this.streak});
  final int streak;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primaryFixed,
        borderRadius: BorderRadius.circular(999),
        boxShadow: [BoxShadow(color: AppColors.violetShadow(0.08), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Symbols.local_fire_department, size: 14, color: AppColors.primary),
          const SizedBox(width: 4),
          Text('$streak', style: AppTextStyles.labelMd.withColor(AppColors.onPrimaryFixed)),
        ],
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({required this.icon, required this.onTap, this.tooltip, this.color});
  final IconData icon;
  final VoidCallback onTap;
  final String? tooltip;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip ?? '',
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(
            width: 44,
            height: 44,
            child: Icon(icon, size: 22, color: color ?? AppColors.onSurfaceVariant),
          ),
        ),
      ),
    );
  }
}

class _BlurBar extends StatelessWidget {
  const _BlurBar({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface.withValues(alpha: 0.8),
            boxShadow: const [BoxShadow(color: Color(0x0A000000), blurRadius: 8, offset: Offset(0, 1))],
          ),
          child: SafeArea(
            bottom: false,
            child: SizedBox(
              height: 64,
              child: Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: child),
            ),
          ),
        ),
      ),
    );
  }
}
