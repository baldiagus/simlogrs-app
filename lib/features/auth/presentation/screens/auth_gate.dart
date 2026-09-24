import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../shell/presentation/screens/main_shell_screen.dart';
import '../providers/auth_provider.dart';
import 'login_screen.dart';
import 'splash_screen.dart';

class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    switch (authState.status) {
      case AuthStatus.initial:
      case AuthStatus.loading:
        // Tampilkan SplashScreen selama inisialisasi sesi awal
        if (authState.user == null) {
          return const SplashScreen(
            statusText: 'Memeriksa sesi pengguna...',
          );
        }
        return const Scaffold(
          body: Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryPurple),
            ),
          ),
        );

      case AuthStatus.authenticated:
        return const MainShellScreen();

      case AuthStatus.unauthenticated:
        return const LoginScreen();
    }
  }
}
