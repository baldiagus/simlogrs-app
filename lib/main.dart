import 'package:flutter/foundation.dart';
import 'features/auth/presentation/screens/auth_gate.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'shared/widgets/custom_button.dart';
import 'shared/widgets/empty_state_view.dart';
import 'shared/widgets/status_badge.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (!kIsWeb) {
    try {
      await dotenv.load(fileName: '.env');
    } catch (_) {
      // Abaikan jika .env belum dimuat pada initial runtime
    }
  }

  runApp(
    const ProviderScope(
      child: SimlogApp(),
    ),
  );
}

class SimlogApp extends StatelessWidget {
  const SimlogApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SIMLOG RS',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const AuthGate(),
    );
  }
}

class CoreFoundationSmokeScreen extends StatelessWidget {
  const CoreFoundationSmokeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SIMLOG RS Foundation'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Gradient Showcase
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryHeroGradient,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Core Foundation Aktif',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Design Tokens, Dio Client, Secure Storage & Shared UI siap digunakan.',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Status Badges Showcase
              const Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  StatusBadge(status: 'DISETUJUI'),
                  StatusBadge(status: 'PENDING'),
                  StatusBadge(status: 'DITOLAK'),
                  StatusBadge(status: 'DALAM_MAINTENANCE'),
                  StatusBadge(status: 'TERSEDIA'),
                ],
              ),
              const SizedBox(height: 24),

              // Button Showcase
              CustomButton(
                text: 'Tombol Aksi Utama',
                onPressed: () {},
              ),
              const SizedBox(height: 12),
              CustomButton(
                text: 'Tombol Outlined',
                isOutlined: true,
                onPressed: () {},
              ),
              const SizedBox(height: 24),

              // Empty State Showcase
              const EmptyStateView(
                title: 'Data Masih Kosong',
                message: 'Tidak ada data antrean dummy. Semua data akan diambil real-time dari API v1.',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
