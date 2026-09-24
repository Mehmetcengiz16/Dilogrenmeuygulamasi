import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_logo.dart';
import '../../../core/widgets/common.dart';
import '../data/auth_controller.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;
  ApiException? _error;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ref.read(authControllerProvider.notifier).login(_email.text.trim(), _password.text);
    } on ApiException catch (e) {
      setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _AuthScaffold(
      title: 'Tekrar hoş geldin!',
      subtitle: 'Kaldığın yerden devam etmek için giriş yap.',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: AppSpacing.md,
          children: [
            _Field(
              controller: _email,
              label: 'E-posta',
              icon: Symbols.mail,
              keyboard: TextInputType.emailAddress,
              error: _error?.fieldError('email'),
              validator: (v) => v != null && v.contains('@') ? null : 'Geçerli bir e-posta gir',
            ),
            _Field(
              controller: _password,
              label: 'Şifre',
              icon: Symbols.lock,
              obscure: true,
              error: _error?.fieldError('password'),
              validator: (v) => (v ?? '').isEmpty ? 'Şifreni gir' : null,
              onSubmitted: (_) => _submit(),
            ),
            if (_error != null && _error!.errors.isEmpty) _ErrorBanner(_error!.message),
            const SizedBox(height: AppSpacing.sm),
            PrimaryButton(label: 'Giriş Yap', icon: Symbols.arrow_forward, loading: _loading, onPressed: _submit),
            _SwitchLink(text: 'Hesabın yok mu?', action: 'Kayıt ol', onTap: () => context.go('/register')),
          ],
        ),
      ),
    );
  }
}

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  int _goal = 15;
  bool _loading = false;
  ApiException? _error;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ref.read(authControllerProvider.notifier).register(
            name: _name.text.trim(),
            email: _email.text.trim(),
            password: _password.text,
            dailyGoalMinutes: _goal,
          );
    } on ApiException catch (e) {
      setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _AuthScaffold(
      title: 'Hesap oluştur',
      subtitle: 'Yapay zekâ destekli dil yolculuğuna başla.',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: AppSpacing.md,
          children: [
            _Field(
              controller: _name,
              label: 'Adın',
              icon: Symbols.person,
              error: _error?.fieldError('name'),
              validator: (v) => (v ?? '').trim().isEmpty ? 'Adını gir' : null,
            ),
            _Field(
              controller: _email,
              label: 'E-posta',
              icon: Symbols.mail,
              keyboard: TextInputType.emailAddress,
              error: _error?.fieldError('email'),
              validator: (v) => v != null && v.contains('@') ? null : 'Geçerli bir e-posta gir',
            ),
            _Field(
              controller: _password,
              label: 'Şifre (en az 8 karakter)',
              icon: Symbols.lock,
              obscure: true,
              error: _error?.fieldError('password'),
              validator: (v) => (v ?? '').length < 8 ? 'Şifre en az 8 karakter olmalı' : null,
            ),
            Text('Günlük hedefin', style: AppTextStyles.labelLg),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final m in const [5, 10, 15, 20, 30])
                  ChoiceChip(
                    label: Text('$m dk'),
                    selected: _goal == m,
                    onSelected: (_) => setState(() => _goal = m),
                    showCheckmark: false,
                    labelStyle: AppTextStyles.labelMd.withColor(_goal == m ? Colors.white : AppColors.onSurface),
                    selectedColor: AppColors.primaryContainer,
                    backgroundColor: AppColors.surfaceContainerLow,
                    side: BorderSide.none,
                    shape: const StadiumBorder(),
                  ),
              ],
            ),
            if (_error != null && _error!.errors.isEmpty) _ErrorBanner(_error!.message),
            const SizedBox(height: AppSpacing.sm),
            PrimaryButton(label: 'Kayıt Ol', icon: Symbols.arrow_forward, loading: _loading, onPressed: _submit),
            _SwitchLink(text: 'Zaten hesabın var mı?', action: 'Giriş yap', onTap: () => context.go('/login')),
          ],
        ),
      ),
    );
  }
}

class _AuthScaffold extends StatelessWidget {
  const _AuthScaffold({required this.title, required this.subtitle, required this.child});
  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const Positioned(top: -90, right: -70, child: GlowBlob(size: 300, color: Color(0x406C5CE7))),
          const Positioned(bottom: -80, left: -90, child: GlowBlob(size: 300, color: Color(0x33A19AFD))),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.margin),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const AppLogo(size: 40),
                      const SizedBox(height: AppSpacing.xl),
                      Text(title, style: AppTextStyles.headlineLg),
                      const SizedBox(height: AppSpacing.xs),
                      Text(subtitle, style: AppTextStyles.bodyMd.variant),
                      const SizedBox(height: AppSpacing.lg),
                      AppCard(radius: AppRadius.cardLg, padding: const EdgeInsets.all(AppSpacing.lg), child: child),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.label,
    required this.icon,
    this.obscure = false,
    this.keyboard,
    this.validator,
    this.error,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool obscure;
  final TextInputType? keyboard;
  final String? Function(String?)? validator;
  final String? error;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboard,
      validator: validator,
      onFieldSubmitted: onSubmitted,
      style: AppTextStyles.bodyLg,
      decoration: InputDecoration(
        hintText: label,
        errorText: error,
        fillColor: AppColors.surfaceContainerLow,
        prefixIcon: Icon(icon, size: 20, color: AppColors.onSurfaceVariant),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner(this.message);
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppColors.errorContainer, borderRadius: BorderRadius.circular(AppRadius.md)),
      child: Row(
        children: [
          const Icon(Symbols.error, size: 18, color: AppColors.error),
          const SizedBox(width: 8),
          Expanded(child: Text(message, style: AppTextStyles.bodySm.withColor(AppColors.onErrorContainer))),
        ],
      ),
    );
  }
}

class _SwitchLink extends StatelessWidget {
  const _SwitchLink({required this.text, required this.action, required this.onTap});
  final String text;
  final String action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(text, style: AppTextStyles.bodyMd.variant),
        TextButton(onPressed: onTap, child: Text(action, style: AppTextStyles.labelLg.withColor(AppColors.primary))),
      ],
    );
  }
}
