import 'package:dramacircle/src/core/providers.dart';
import 'package:dramacircle/src/core/theme/app_theme.dart';
import 'package:dramacircle/src/features/auth/providers/auth_controller.dart';
import 'package:dramacircle/src/features/shell/presentation/main_shell_screen.dart';
import 'package:dramacircle/src/features/splash/presentation/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class KissAsianApp extends ConsumerWidget {
  const KissAsianApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(sharedPreferencesProvider);
    final auth = ref.watch(authControllerProvider);

    Widget home;
    if (prefs.isLoading || auth.isLoading) {
      home = const SplashScreen();
    } else {
      home = const MainShellScreen();
    }

    return MaterialApp(
      title: 'KissAsian',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark(),
      home: home,
    );
  }
}
