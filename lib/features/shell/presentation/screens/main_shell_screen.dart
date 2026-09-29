import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../shared/widgets/floating_bottom_nav_bar.dart';
import '../../../approval/presentation/providers/approval_provider.dart';
import '../../../approval/presentation/screens/approval_center_screen.dart';
import '../../../aset/presentation/screens/qr_scanner_screen.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../dashboard/presentation/providers/dashboard_provider.dart';
import '../../../dashboard/presentation/screens/home_screen.dart';
import '../../../maintenance/presentation/providers/ipsrs_providers.dart';
import '../../../maintenance/presentation/providers/maintenance_provider.dart';
import '../../../maintenance/presentation/providers/tiket_maintenance_provider.dart';
import '../../../maintenance/presentation/screens/ipsrs_hub_screen.dart';
import '../../../maintenance/presentation/screens/spk_list_screen.dart';
import '../../../pengadaan/presentation/providers/pengadaan_provider.dart';
import '../../../profile/presentation/screens/profile_screen.dart';

class MainShellScreen extends ConsumerStatefulWidget {
  const MainShellScreen({super.key});

  @override
  ConsumerState<MainShellScreen> createState() => _MainShellScreenState();
}
class _MainShellScreenState extends ConsumerState<MainShellScreen> with WidgetsBindingObserver {
  int _currentIndex = 0;
  Timer? _inactivityTimer;
  DateTime? _lastResumeTime;
  static const Duration _idleTimeout = Duration(minutes: 30);
  static const Duration _resumeThrottle = Duration(seconds: 15);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _resetInactivityTimer();
  }

  void _resetInactivityTimer() {
    _inactivityTimer?.cancel();
    _inactivityTimer = Timer(_idleTimeout, () {
      if (mounted) {
        ref.read(authStateProvider.notifier).handleSessionTimeout();
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      final now = DateTime.now();
      if (_lastResumeTime == null || now.difference(_lastResumeTime!) > _resumeThrottle) {
        _lastResumeTime = now;
        _refreshActiveTabData();
      }
    }
  }

  void _refreshActiveTabData() {
    if (!mounted) return;
    final authState = ref.read(authStateProvider);
    if (!authState.isAuthenticated || authState.user == null) return;

    switch (_currentIndex) {
      case 0:
        ref.invalidate(dashboardSummaryProvider);
        break;
      case 1:
        ref.invalidate(approvalPendingProvider);
        final user = authState.user;
        if (user?.isPengadaan == true ||
            user?.isAdminLogistik == true ||
            user?.isManajemen == true ||
            user?.isAuditor == true ||
            user?.hasRole('super_admin') == true) {
          ref.invalidate(poListProvider);
        }
        break;
      case 2:
        ref.invalidate(jadwalPreventifListProvider);
        ref.invalidate(rekamMedisKatalogProvider);
        ref.invalidate(spkListProvider);
        ref.invalidate(daftarTiketUnitProvider);
        break;
      case 3:
        break;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _inactivityTimer?.cancel();
    super.dispose();
  }

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

    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => _resetInactivityTimer(),
      onPointerMove: (_) => _resetInactivityTimer(),
      child: Scaffold(
        backgroundColor: AppColors.canvas,
      body: IndexedStack(
        index: _currentIndex,
        children: [
          // 0: Beranda
          HomeScreen(
            onNavigateTab: (index) {
              setState(() => _currentIndex = index);
              _refreshActiveTabData();
            },
          ),

          // 1: Approval Center untuk umum / Tugas SPK untuk Teknisi
          isTeknisi
              ? SpkListScreen(
                  isEmbedded: false,
                  leading: IconButton(
                    icon: const Icon(LucideIcons.arrowLeft),
                    tooltip: 'Kembali ke Beranda',
                    onPressed: () => setState(() => _currentIndex = 0),
                  ),
                  allowedStatuses: const ['DITUGASKAN'],
                  customTitle: 'Surat Perintah Kerja (SPK)',
                )
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
          _refreshActiveTabData();
        },
        onScanPressed: _onScanPressed,
      ),
    ),
  );
}
}
