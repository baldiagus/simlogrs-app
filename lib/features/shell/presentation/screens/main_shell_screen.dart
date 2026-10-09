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
import '../../../gudang/presentation/screens/inbound_po_list_screen.dart';
import '../../../distribusi/presentation/screens/picking_distribusi_screen.dart';
import '../../../distribusi/presentation/screens/amprah_hub_screen.dart';
import '../../../aset/presentation/screens/sirkulasi_aset_hub_screen.dart';
import '../../../anggaran/presentation/screens/pagu_realisasi_screen.dart';
import '../../../audit/presentation/screens/audit_spi_hub_screen.dart';
import '../../../auth/data/models/user_model.dart';
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

  _ShellNavConfig _resolveNavConfig(UserModel? user) {
    final homeScreen = HomeScreen(
      onNavigateTab: (index) {
        setState(() => _currentIndex = index);
        _refreshActiveTabData();
      },
    );
    const profileScreen = ProfileScreen();

    // 1. Teknik & IPSRS (Teknisi / Kepala Teknisi)
    if (user?.isTeknisi == true || user?.isKepalaTeknisi == true) {
      final isKepalaTeknisi = user?.isKepalaTeknisi == true;
      return _ShellNavConfig(
        screens: [
          homeScreen,
          SpkListScreen(
            isEmbedded: false,
            leading: IconButton(
              icon: const Icon(LucideIcons.arrowLeft),
              tooltip: 'Kembali ke Beranda',
              onPressed: () => setState(() => _currentIndex = 0),
            ),
            allowedStatuses: isKepalaTeknisi ? null : const ['DITUGASKAN'],
            customTitle: isKepalaTeknisi ? 'Monitoring SPK IPSRS' : 'Surat Perintah Kerja (SPK)',
          ),
          const IpsrsHubScreen(),
          profileScreen,
        ],
        navItems: [
          const BottomNavItem(icon: LucideIcons.home, label: 'Beranda'),
          BottomNavItem(
            icon: LucideIcons.clipboardCheck,
            label: isKepalaTeknisi ? 'Semua SPK' : 'Tugas SPK',
          ),
          const BottomNavItem(icon: LucideIcons.wrench, label: 'IPSRS'),
          const BottomNavItem(icon: LucideIcons.user, label: 'Profil'),
        ],
      );
    }

    // 2. Gudang & Logistik Sentral (Kepala Gudang, Petugas Gudang, Admin Logistik)
    if (user?.isGudangUser == true) {
      return _ShellNavConfig(
        screens: [
          homeScreen,
          const InboundPoListScreen(),
          const PickingDistribusiScreen(),
          profileScreen,
        ],
        navItems: [
          const BottomNavItem(icon: LucideIcons.home, label: 'Beranda'),
          const BottomNavItem(icon: LucideIcons.packageCheck, label: 'Inbound PO'),
          const BottomNavItem(icon: LucideIcons.truck, label: 'Picking'),
          const BottomNavItem(icon: LucideIcons.user, label: 'Profil'),
        ],
      );
    }

    // 3. Eksekutif & Pengawas (Manajemen, Auditor SPI, Pengadaan, Super Admin)
    if (user?.isManajemen == true ||
        user?.isAuditor == true ||
        user?.isPengadaan == true ||
        user?.isSuperAdmin == true) {
      final isAuditor = user?.isAuditor == true;
      return _ShellNavConfig(
        screens: [
          homeScreen,
          const ApprovalCenterScreen(),
          isAuditor ? const AuditSpiHubScreen() : const PaguRealisasiScreen(),
          profileScreen,
        ],
        navItems: [
          const BottomNavItem(icon: LucideIcons.home, label: 'Beranda'),
          const BottomNavItem(icon: LucideIcons.checkSquare, label: 'Approval'),
          BottomNavItem(
            icon: isAuditor ? LucideIcons.shieldAlert : LucideIcons.banknote,
            label: isAuditor ? 'Audit SPI' : 'Pagu RS',
          ),
          const BottomNavItem(icon: LucideIcons.user, label: 'Profil'),
        ],
      );
    }

    // 4. Ruangan Pelayanan: Kepala Unit (Karu) vs Petugas Unit
    if (user?.isKaru == true) {
      return _ShellNavConfig(
        screens: [
          homeScreen,
          const ApprovalCenterScreen(),
          const AmprahHubScreen(),
          profileScreen,
        ],
        navItems: [
          const BottomNavItem(icon: LucideIcons.home, label: 'Beranda'),
          const BottomNavItem(icon: LucideIcons.checkSquare, label: 'Approval'),
          const BottomNavItem(icon: LucideIcons.fileSpreadsheet, label: 'Amprah'),
          const BottomNavItem(icon: LucideIcons.user, label: 'Profil'),
        ],
      );
    }

    // Default: Petugas Unit / Staf Ruangan
    return _ShellNavConfig(
      screens: [
        homeScreen,
        const AmprahHubScreen(),
        const SirkulasiAsetHubScreen(),
        profileScreen,
      ],
      navItems: [
        const BottomNavItem(icon: LucideIcons.home, label: 'Beranda'),
        const BottomNavItem(icon: LucideIcons.fileSpreadsheet, label: 'Amprah'),
        const BottomNavItem(icon: LucideIcons.repeat, label: 'Sirkulasi'),
        const BottomNavItem(icon: LucideIcons.user, label: 'Profil'),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).user;
    final navConfig = _resolveNavConfig(user);
    final activeIndex = _currentIndex.clamp(0, navConfig.screens.length - 1);

    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => _resetInactivityTimer(),
      onPointerMove: (_) => _resetInactivityTimer(),
      child: Scaffold(
        backgroundColor: AppColors.canvas,
        body: IndexedStack(
          index: activeIndex,
          children: navConfig.screens,
        ),
        bottomNavigationBar: FloatingBottomNavBar(
          currentIndex: activeIndex,
          items: navConfig.navItems,
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

class _ShellNavConfig {
  final List<Widget> screens;
  final List<BottomNavItem> navItems;

  const _ShellNavConfig({
    required this.screens,
    required this.navItems,
  });
}
