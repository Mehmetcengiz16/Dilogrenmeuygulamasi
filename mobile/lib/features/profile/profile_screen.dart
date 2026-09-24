import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../core/network/api_client.dart';
import '../../core/network/api_exception.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/icon_map.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/shell_scaffold.dart';
import '../../core/widgets/user_avatar.dart';
import '../auth/data/auth_controller.dart';
import '../home/data/home_data.dart';

final statsProvider = FutureProvider.autoDispose<Map<String, dynamic>>(
  (ref) => ref.watch(apiClientProvider).get<Map<String, dynamic>>('/stats'),
);

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).value;
    final stats = ref.watch(statsProvider);
    if (user == null) return const SizedBox.shrink();

    return ListView(
      padding: ShellScaffold.contentPadding(context, vertical: AppSpacing.md),
      children: [
        // Profil başlığı
        Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: AppColors.primaryContainer,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            boxShadow: AppShadows.strong(),
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              const Positioned(top: -60, right: -50, child: GlowBlob(size: 180, color: Color(0x55E4DFFF))),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: const BoxDecoration(color: Colors.white24, shape: BoxShape.circle),
                    child: UserAvatar(name: user.name, url: user.avatarUrl, size: 64),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(user.name, style: AppTextStyles.headlineMd.bold.withColor(Colors.white)),
                        Text(user.email, style: AppTextStyles.bodySm.withColor(Colors.white70)),
                        const SizedBox(height: 8),
                        if (user.activeCourseTitle != null)
                          Pill(
                            text: '${user.activeCourseTitle} · ${user.activeCourseLevel}',
                            background: Colors.white.withValues(alpha: 0.2),
                            foreground: Colors.white,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        stats.when(
          loading: () => const Padding(padding: EdgeInsets.all(32), child: Center(child: CircularProgressIndicator())),
          error: (e, _) => ErrorState(message: e.toString(), onRetry: () => ref.invalidate(statsProvider)),
          data: (s) => _Stats(stats: s),
        ),
        const SizedBox(height: AppSpacing.md),
        Text('Ayarlar', style: AppTextStyles.headlineSm),
        const SizedBox(height: AppSpacing.sm),
        AppCard(
          padding: const EdgeInsets.symmetric(vertical: 4),
          radius: AppRadius.card,
          child: Column(
            children: [
              _SettingTile(
                icon: Symbols.flag,
                title: 'Günlük hedef',
                value: '${user.dailyGoalMinutes} dk',
                onTap: () => _pickGoal(context, ref, user.dailyGoalMinutes),
              ),
              _SettingTile(
                icon: Symbols.edit,
                title: 'Adını değiştir',
                value: user.name,
                onTap: () => _editName(context, ref, user.name),
              ),
              _SettingTile(icon: Symbols.style, title: 'Kelime defteri', onTap: () => context.push('/vocabulary')),
              _SettingTile(icon: Symbols.school, title: 'Kurs değiştir', onTap: () => context.go('/practice')),
              _SettingTile(
                icon: Symbols.logout,
                title: 'Çıkış yap',
                onTap: () => ref.read(authControllerProvider.notifier).logout(),
              ),
              _SettingTile(
                icon: Symbols.delete,
                title: 'Hesabı sil',
                danger: true,
                onTap: () => _confirmDelete(context, ref),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _pickGoal(BuildContext context, WidgetRef ref, int current) async {
    final picked = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.cardLg))),
      builder: (c) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Text('Günlük hedef', style: AppTextStyles.headlineSm),
            for (final m in const [5, 10, 15, 20, 30])
              ListTile(
                title: Text('$m dakika'),
                trailing: m == current ? const Icon(Symbols.check_circle, fill: 1, color: AppColors.primary) : null,
                onTap: () => Navigator.pop(c, m),
              ),
          ],
        ),
      ),
    );
    if (picked == null) return;
    try {
      await ref.read(authControllerProvider.notifier).updateProfile(dailyGoalMinutes: picked);
      ref.invalidate(homeProvider);
    } on ApiException catch (e) {
      if (context.mounted) showMessage(context, e.message);
    }
  }

  Future<void> _editName(BuildContext context, WidgetRef ref, String current) async {
    final c = TextEditingController(text: current);
    final name = await showDialog<String>(
      context: context,
      builder: (d) => AlertDialog(
        backgroundColor: AppColors.surfaceContainerLowest,
        title: const Text('Adın'),
        content: TextField(controller: c, autofocus: true, decoration: const InputDecoration(fillColor: AppColors.surfaceContainerLow)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(d), child: const Text('Vazgeç')),
          TextButton(onPressed: () => Navigator.pop(d, c.text.trim()), child: const Text('Kaydet')),
        ],
      ),
    );
    if (name == null || name.isEmpty) return;
    try {
      await ref.read(authControllerProvider.notifier).updateProfile(name: name);
    } on ApiException catch (e) {
      if (context.mounted) showMessage(context, e.message);
    }
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (d) => AlertDialog(
        backgroundColor: AppColors.surfaceContainerLowest,
        title: const Text('Hesabı sil'),
        content: const Text('Tüm ilerlemen kalıcı olarak silinecek. Emin misin?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(d, false), child: const Text('Vazgeç')),
          TextButton(
            onPressed: () => Navigator.pop(d, true),
            child: const Text('Sil', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (ok == true) await ref.read(authControllerProvider.notifier).deleteAccount();
  }
}

class _Stats extends StatelessWidget {
  const _Stats({required this.stats});
  final Map<String, dynamic> stats;

  @override
  Widget build(BuildContext context) {
    final history = (stats['xp_history'] as List).cast<Map<String, dynamic>>();
    final maxXp = history.fold<int>(1, (m, d) => (d['xp'] as int) > m ? d['xp'] as int : m);
    final badges = (stats['badges'] as List).cast<Map<String, dynamic>>();
    const days = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpacing.md,
      children: [
        Row(
          spacing: AppSpacing.sm,
          children: [
            _StatTile(icon: Symbols.bolt, value: '${stats['total_xp']}', label: 'Toplam XP', color: AppColors.primary, bg: AppColors.primaryFixed),
            _StatTile(icon: Symbols.local_fire_department, value: '${stats['current_streak']}', label: 'Gün seri', color: AppColors.secondary, bg: AppColors.secondaryFixed),
            _StatTile(icon: Symbols.menu_book, value: '${stats['learned_words']}', label: 'Kelime', color: AppColors.tertiary, bg: AppColors.tertiaryFixed),
          ],
        ),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text('Son 7 gün', style: AppTextStyles.headlineSm),
                  const Spacer(),
                  Text('${stats['completed_lessons']} ders tamamlandı', style: AppTextStyles.labelSm.variant),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              SizedBox(
                height: 110,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final d in history)
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text('${d['xp']}', style: AppTextStyles.labelSm.variant),
                            const SizedBox(height: 4),
                            // Çubuk kalan alanı XP oranında doldurur; sabit yükseklik taşmaya yol açıyordu.
                            Expanded(
                              child: Align(
                                alignment: Alignment.bottomCenter,
                                child: FractionallySizedBox(
                                  heightFactor: 0.1 + 0.9 * ((d['xp'] as int) / maxXp),
                                  child: Container(
                                    margin: const EdgeInsets.symmetric(horizontal: 6),
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryContainer,
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(days[DateTime.parse(d['date'] as String).weekday - 1], style: AppTextStyles.labelSm.variant),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Text('Rozetler', style: AppTextStyles.headlineSm),
        LayoutBuilder(
          builder: (context, c) => Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final b in badges)
              Opacity(
                opacity: b['earned'] == true ? 1 : 0.45,
                child: Container(
                  // Satırda eşit genişlikte 3 rozet.
                  width: (c.maxWidth - 2 * AppSpacing.sm) / 3,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(AppRadius.card),
                    boxShadow: AppShadows.soft(),
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: b['earned'] == true ? AppColors.tertiaryFixed : AppColors.surfaceContainer,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(iconFromName(b['icon'] as String?), fill: 1,
                            color: b['earned'] == true ? AppColors.tertiary : AppColors.outline),
                      ),
                      const SizedBox(height: 6),
                      Text(b['name'] as String, textAlign: TextAlign.center, style: AppTextStyles.labelMd),
                      Text(b['description'] as String? ?? '', textAlign: TextAlign.center, style: AppTextStyles.labelSm.variant, maxLines: 2),
                    ],
                  ),
                ),
              ),
          ],
        ),
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.icon, required this.value, required this.label, required this.color, required this.bg});
  final IconData icon;
  final String value;
  final String label;
  final Color color;
  final Color bg;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: AppCard(
        radius: AppRadius.card,
        child: Column(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
              child: Icon(icon, size: 20, color: color, fill: 1),
            ),
            const SizedBox(height: 6),
            Text(value, style: AppTextStyles.headlineMd.bold),
            Text(label, style: AppTextStyles.bodySm.variant),
          ],
        ),
      ),
    );
  }
}

class _SettingTile extends StatelessWidget {
  const _SettingTile({required this.icon, required this.title, this.value, required this.onTap, this.danger = false});
  final IconData icon;
  final String title;
  final String? value;
  final VoidCallback onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final color = danger ? AppColors.error : AppColors.onSurface;
    return ListTile(
      onTap: onTap,
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(color: danger ? AppColors.errorContainer : AppColors.surfaceContainerLow, shape: BoxShape.circle),
        child: Icon(icon, size: 18, color: danger ? AppColors.error : AppColors.primary),
      ),
      title: Text(title, style: AppTextStyles.labelLg.withColor(color)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (value != null)
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 120),
              child: Text(value!, style: AppTextStyles.bodySm.variant, maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
          const Icon(Symbols.chevron_right, color: AppColors.outline),
        ],
      ),
    );
  }
}
