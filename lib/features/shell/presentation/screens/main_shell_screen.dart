import '../../../maintenance/presentation/screens/ipsrs_hub_screen.dart';
import '../../../aset/presentation/screens/qr_scanner_screen.dart';
import '../../../approval/presentation/screens/approval_center_screen.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
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
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const QrScannerScreen()),
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

          // 2: IPSRS Fieldwork
          const IpsrsHubScreen(),

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
