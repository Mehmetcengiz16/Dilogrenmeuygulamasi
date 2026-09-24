import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_logo.dart';
import '../../../core/widgets/common.dart';
import '../data/auth_controller.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;

  static const _slides = [
    (Symbols.smart_toy, 'Yapay zekâ ile\nkonuşarak öğren', 'Lina AI ile gerçek senaryolarda sesli ve yazılı pratik yap.', AppColors.primaryFixed, AppColors.primary),
    (Symbols.local_fire_department, 'Günde 10 dakika,\nkalıcı ilerleme', 'Kısa dersler, günlük hedef ve seri ile alışkanlık kazan.', AppColors.tertiaryFixed, AppColors.tertiary),
    (Symbols.translate, 'Anlık çeviri ve\nkelime haznesi', 'Kalıpları kaydet, telaffuzu dinle, kelimelerini tekrar et.', AppColors.secondaryFixed, AppColors.secondary),
  ];

  Future<void> _finish(String route) async {
    await markOnboardingSeen();
    ref.invalidate(onboardingSeenProvider);
    if (mounted) context.go(route);
  }

  @override
  Widget build(BuildContext context) {
    final last = _page == _slides.length - 1;
    return Scaffold(
      body: Stack(
        children: [
          const Positioned(top: -80, left: -60, child: GlowBlob(size: 280, color: Color(0x406C5CE7))),
          const Positioned(bottom: -60, right: -80, child: GlowBlob(size: 300, color: Color(0x40A19AFD))),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.margin),
              child: Column(
                children: [
                  SizedBox(
                    height: 64,
                    child: Row(
                      children: [
                        const AppLogo(),
                        const Spacer(),
                        TextButton(
                          onPressed: () => _finish('/login'),
                          child: Text('Giriş yap', style: AppTextStyles.labelLg.withColor(AppColors.primary)),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: PageView.builder(
                      controller: _controller,
                      itemCount: _slides.length,
                      onPageChanged: (i) => setState(() => _page = i),
                      itemBuilder: (_, i) {
                        final (icon, title, text, bg, fg) = _slides[i];
                        return Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 180,
                              height: 180,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [bg, AppColors.surfaceContainerLowest],
                                ),
                                boxShadow: AppShadows.strong(0.14),
                              ),
                              child: Icon(icon, size: 84, color: fg, fill: 1),
                            ),
                            const SizedBox(height: AppSpacing.xl),
                            Text(title, textAlign: TextAlign.center, style: AppTextStyles.headlineLg),
                            const SizedBox(height: AppSpacing.sm),
                            Text(text, textAlign: TextAlign.center, style: AppTextStyles.bodyLg.variant),
                          ],
                        );
                      },
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (var i = 0; i < _slides.length; i++)
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          width: i == _page ? 24 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: i == _page ? AppColors.primaryContainer : AppColors.primaryFixed,
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  PrimaryButton(
                    label: last ? 'Hemen Başla' : 'Devam',
                    icon: Symbols.arrow_forward,
                    onPressed: () => last
                        ? _finish('/register')
                        : _controller.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeOut),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
