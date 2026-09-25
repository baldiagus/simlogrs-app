import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/floating_bottom_nav_bar.dart';
import '../../../approval/presentation/screens/approval_center_screen.dart';
import '../../../aset/presentation/screens/qr_scanner_screen.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../dashboard/presentation/screens/home_screen.dart';
import '../../../maintenance/presentation/screens/ipsrs_hub_screen.dart';
import '../../../maintenance/presentation/screens/spk_list_screen.dart';
import '../../../profile/presentation/screens/profile_screen.dart';

class MainShellScreen extends ConsumerStatefulWidget {
  const MainShellScreen({super.key});

  @override
  ConsumerState<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends ConsumerState<MainShellScreen> {
  int _currentIndex = 0;

  void _onScanPressed() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const QrScannerScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).user;
    final isTeknisi = user?.isTeknisi ?? false;

    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: IndexedStack(
        index: _currentIndex,
        children: [
          // 0: Beranda
          HomeScreen(
            onNavigateTab: (index) {
              setState(() => _currentIndex = index);
            },
            onScanPressed: _onScanPressed,
          ),

          // 1: Approval Center untuk umum / Tugas SPK untuk Teknisi
          isTeknisi
              ? const SpkListScreen(isEmbedded: true)
              : const ApprovalCenterScreen(),

          // 2: IPSRS Fieldwork
          const IpsrsHubScreen(),

          // 3: Profil
          const ProfileScreen(),
        ],
      ),
      bottomNavigationBar: FloatingBottomNavBar(
        currentIndex: _currentIndex,
        isTeknisi: isTeknisi,
        onTap: (index) {
          setState(() => _currentIndex = index);
        },
        onScanPressed: _onScanPressed,
      ),
    );
  }
}
