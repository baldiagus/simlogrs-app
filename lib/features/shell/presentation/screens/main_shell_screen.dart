import '../../../approval/presentation/screens/approval_center_screen.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/empty_state_view.dart';
import '../../../../shared/widgets/floating_bottom_nav_bar.dart';
import '../../../dashboard/presentation/screens/home_screen.dart';
import '../../../profile/presentation/screens/profile_screen.dart';

class MainShellScreen extends StatefulWidget {
  const MainShellScreen({super.key});

  @override
  State<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends State<MainShellScreen> {
  int _currentIndex = 0;

  void _onScanPressed() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                gradient: AppColors.primaryHeroGradient,
                shape: BoxShape.circle,
              ),
              child: const Icon(LucideIcons.qrCode, color: Colors.white, size: 32),
            ),
            const SizedBox(height: 16),
            const Text(
              'Scanner Mobile SIMLOG',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Pindai QR Aset untuk sirkulasi & cek fisik atau scan barcode rak gudang.',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Modul QR Scanner Aset aktif pada Fase 6.')),
                      );
                    },
                    icon: const Icon(LucideIcons.scanLine, size: 18),
                    label: const Text('Scan QR Aset'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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

          // 1: Approval Center
          const ApprovalCenterScreen(),

          // 2: IPSRS Fieldwork (Placeholder hingga Fase 7)
          Scaffold(
            appBar: AppBar(title: const Text('IPSRS Fieldwork')),
            body: const EmptyStateView(
              icon: LucideIcons.wrench,
              title: 'Pemeliharaan Sarana',
              message: 'Daftar SPK teknisi dan lembar kerja pengerjaan akan dibangun pada Fase 7.',
            ),
          ),

          // 3: Profil
          const ProfileScreen(),
        ],
      ),
      bottomNavigationBar: FloatingBottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() => _currentIndex = index);
        },
        onScanPressed: _onScanPressed,
      ),
    );
  }
}
