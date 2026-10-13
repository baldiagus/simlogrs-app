import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_shadows.dart';

class SplashScreen extends StatefulWidget {
  final Widget? nextScreen;
  final String statusText;
  final Duration? duration;

  const SplashScreen({
    super.key,
    this.nextScreen,
    this.statusText = 'Memeriksa sesi pengguna...',
    this.duration,
  });

  /// Membuat state splash yang mengelola animasi fade dan scale logo.
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _scaleAnimation;

  /// Menyiapkan animasi masuk logo dan, jika ada `nextScreen`, berpindah ke layar itu setelah jeda.
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    );

    _scaleAnimation = Tween<double>(begin: 0.88, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutBack,
      ),
    );

    _controller.forward();

    if (widget.nextScreen != null) {
      Future.delayed(widget.duration ?? const Duration(milliseconds: 1800), () {
        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            transitionDuration: const Duration(milliseconds: 500),
            pageBuilder: (_, animation, __) => FadeTransition(
              opacity: animation,
              child: widget.nextScreen!,
            ),
          ),
        );
      });
    }
  }

  /// Melepas AnimationController agar tidak bocor setelah splash dilepas.
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Membangun tampilan splash: logo, nama aplikasi, indikator loading, teks status, dan versi.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        child: Stack(
          children: [
            // Center Brand Showcase
            Center(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Glowing Brand Emblem
                      Container(
                        width: 88,
                        height: 88,
                        decoration: const BoxDecoration(
                          gradient: AppColors.primaryHeroGradient,
                          borderRadius: BorderRadius.all(Radius.circular(26)),
                          boxShadow: AppShadows.heroCard,
                        ),
                        child: const Icon(
                          LucideIcons.packageCheck,
                          color: Colors.white,
                          size: 44,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // App Name
                      const Text(
                        'SIMLOG RS',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 6),

                      // Tagline / Subtitle
                      const Text(
                        'Logistik Rumah Sakit Non-Medis v2',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Bottom Status & Version Indicator
            Positioned(
              left: 0,
              right: 0,
              bottom: 28,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.primaryPurple,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    widget.statusText,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'v2.0.0 • Mobile Client',
                    style: TextStyle(
                      fontSize: 11,
                      color: Color(0xFFCBD5E1),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
