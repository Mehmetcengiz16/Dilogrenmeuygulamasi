import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_spacing.dart';
import 'app_header.dart';
import 'app_bottom_nav_bar.dart';

/// Sekme ekranlarının iskeleti: bulanık üst başlık + sabit, tam genişlikte alt menü.
/// İçerik başlığın altından kayar; alt menünün üstünde biter.
class ShellScaffold extends StatelessWidget {
  const ShellScaffold({super.key, required this.shell});

  final StatefulNavigationShell shell;

  static double topInset(BuildContext context) => MediaQuery.paddingOf(context).top + 64;

  /// Başlık payını (h-16) hesaba katan içerik boşluğu.
  static EdgeInsets contentPadding(BuildContext context, {double vertical = 0}) => EdgeInsets.fromLTRB(
        AppSpacing.margin,
        topInset(context) + vertical,
        AppSpacing.margin,
        AppSpacing.lg,
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: const AppHeader(),
      body: shell,
      bottomNavigationBar: AppBottomNavBar(
        currentIndex: shell.currentIndex,
        onTap: (i) => shell.goBranch(i, initialLocation: i == shell.currentIndex),
      ),
    );
  }
}
