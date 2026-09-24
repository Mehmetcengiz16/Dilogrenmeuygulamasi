import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../network/api_exception.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

/// Beyaz, yuvarlak köşeli, mor tonlu gölgeli içerik kartı.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.md),
    this.radius = AppRadius.lg,
    this.color = AppColors.surfaceContainerLowest,
    this.shadow,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final Color color;
  final List<BoxShadow>? shadow;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: shadow ?? AppShadows.soft(),
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

/// Küçük hap rozet (label-sm).
class Pill extends StatelessWidget {
  const Pill({
    super.key,
    required this.text,
    this.icon,
    this.background = AppColors.primaryFixed,
    this.foreground = AppColors.onPrimaryFixed,
    this.padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
    this.style,
    this.iconFill = 0,
  });

  final String text;
  final IconData? icon;
  final Color background;
  final Color foreground;
  final EdgeInsetsGeometry padding;
  final TextStyle? style;
  final double iconFill;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(999)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: foreground, fill: iconFill),
            const SizedBox(width: 4),
          ],
          Text(text, style: (style ?? AppTextStyles.labelSm).withColor(foreground)),
        ],
      ),
    );
  }
}

/// Tam genişlik, 56px yüksekliğinde birincil hap buton (quiz "Sonraki Soru").
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.loading = false,
    this.height = 56,
    this.color = AppColors.primaryContainer,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool loading;
  final double height;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !loading;
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 150),
      opacity: enabled ? 1 : 0.55,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          boxShadow: enabled ? AppShadows.button() : null,
        ),
        child: Material(
          color: color,
          borderRadius: BorderRadius.circular(999),
          child: InkWell(
            borderRadius: BorderRadius.circular(999),
            onTap: enabled ? onPressed : null,
            child: Center(
              child: loading
                  ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(label, style: AppTextStyles.headlineSm.withColor(AppColors.onPrimary)),
                        if (icon != null) ...[
                          const SizedBox(width: 8),
                          Icon(icon, size: 22, color: AppColors.onPrimary),
                        ],
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Küçük hap buton (ör. "Pratiğe Başla", "Devam Et").
class SoftButton extends StatelessWidget {
  const SoftButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.background = AppColors.surfaceContainerLow,
    this.foreground = AppColors.secondary,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    this.style,
    this.shadow,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Color background;
  final Color foreground;
  final EdgeInsetsGeometry padding;
  final TextStyle? style;
  final List<BoxShadow>? shadow;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(999), boxShadow: shadow),
      child: Material(
        color: background,
        borderRadius: BorderRadius.circular(999),
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: onPressed,
          child: Padding(
            padding: padding,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(label, style: (style ?? AppTextStyles.labelMd).withColor(foreground)),
                if (icon != null) ...[
                  const SizedBox(width: 6),
                  Icon(icon, size: 16, color: foreground),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Yuvarlak ikon butonu (w-9/w-10), beyaz zemin + hafif gölge.
class RoundIconButton extends StatelessWidget {
  const RoundIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.size = 36,
    this.iconSize = 19,
    this.background = AppColors.surfaceContainerLowest,
    this.foreground = AppColors.onSurfaceVariant,
    this.tooltip,
    this.shadow = AppShadows.sm,
    this.fill = 0,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final double size;
  final double iconSize;
  final Color background;
  final Color foreground;
  final String? tooltip;
  final List<BoxShadow>? shadow;
  final double fill;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip ?? '',
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, boxShadow: shadow),
        child: Material(
          color: background,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onPressed,
            child: Icon(icon, size: iconSize, color: foreground, fill: fill),
          ),
        ),
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader({super.key, required this.title, this.action, this.onAction, this.style});
  final String title;
  final String? action;
  final VoidCallback? onAction;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(title, style: style ?? AppTextStyles.headlineSm)),
        if (action != null)
          GestureDetector(
            onTap: onAction,
            child: Text(action!, style: AppTextStyles.labelSm.withColor(AppColors.primary).copyWith(fontWeight: FontWeight.w600)),
          ),
      ],
    );
  }
}

/// Riverpod AsyncValue için yükleniyor / hata / veri görünümü.
class AsyncBody<T> extends StatelessWidget {
  const AsyncBody({super.key, required this.value, required this.data, required this.onRetry});

  final AsyncValue<T> value;
  final Widget Function(T data) data;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return value.when(
      data: data,
      loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primaryContainer)),
      error: (e, _) => ErrorState(message: e is ApiException ? e.message : 'Bir hata oluştu.', onRetry: onRetry),
    );
  }
}

class ErrorState extends StatelessWidget {
  const ErrorState({super.key, required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: const BoxDecoration(color: AppColors.errorContainer, shape: BoxShape.circle),
              child: const Icon(Symbols.cloud_off, color: AppColors.error),
            ),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center, style: AppTextStyles.bodyMd.variant),
            const SizedBox(height: 16),
            SoftButton(label: 'Tekrar dene', icon: Symbols.refresh, onPressed: onRetry),
          ],
        ),
      ),
    );
  }
}

/// Arka plandaki bulanık dekoratif daire (tasarımlardaki "glow" katmanları).
class GlowBlob extends StatelessWidget {
  const GlowBlob({super.key, required this.size, required this.color});
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: [color, color.withValues(alpha: 0)]),
        ),
      ),
    );
  }
}

void showMessage(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}
