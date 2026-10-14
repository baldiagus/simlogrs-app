import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/offline/offline_providers.dart';
import '../../../../core/theme/app_colors.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../shared/widgets/app_action_banner_card.dart';
import '../../../../shared/widgets/app_toast.dart';
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
import '../../../auth/data/models/user_model.dart';
import '../../../pengadaan/presentation/providers/pengadaan_provider.dart';
import '../../../profile/presentation/screens/profile_screen.dart';
import '../../../distribusi/presentation/providers/distribusi_provider.dart';
import '../../../distribusi/presentation/screens/detail_amprah_screen.dart';
import '../../../gudang/presentation/providers/inbound_provider.dart';
import '../../../gudang/presentation/providers/persediaan_providers.dart';
import '../../../gudang/presentation/screens/otorisasi_penyesuaian_screen.dart';
import '../../../aset/presentation/providers/peminjaman_provider.dart';
import '../../../aset/presentation/providers/pengalihan_provider.dart';
import '../../../aset/presentation/screens/pengalihan_hub_screen.dart';
import '../../../maintenance/presentation/screens/detail_tiket_screen.dart';
import '../../../maintenance/presentation/screens/spk_detail_screen.dart';
import '../../../notifikasi/data/models/notifikasi_model.dart';
import '../../../notifikasi/presentation/screens/notifikasi_screen.dart';
import '../../../pengadaan/presentation/screens/riwayat_pr_screen.dart';
import '../../../../core/notifications/notification_payload.dart';
import '../../../../core/notifications/notification_router.dart';
import '../../../../core/notifications/push_notification_service.dart';
/// Kerangka utama aplikasi pasca-login: tab navigasi bawah menurut role, pemantauan sesi idle, dan refresh data saat kembali ke aplikasi.
class MainShellScreen extends ConsumerStatefulWidget {
  const MainShellScreen({super.key});

  /// Membuat state shell utama.
  @override
  ConsumerState<MainShellScreen> createState() => _MainShellScreenState();
}
/// State shell yang mengelola tab aktif, timer inaktivitas, dan observer lifecycle aplikasi.
class _MainShellScreenState extends ConsumerState<MainShellScreen> with WidgetsBindingObserver {
  int _currentIndex = 0;
  Timer? _inactivityTimer;
  StreamSubscription<NotificationPayload?>? _tapSub;
  DateTime? _lastResumeTime;
  static const Duration _idleTimeout = Duration(minutes: 30);
  static const Duration _resumeThrottle = Duration(seconds: 15);

  /// Mendaftarkan observer lifecycle dan memulai timer inaktivitas.
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _resetInactivityTimer();
    _sinkronkanAntrean();
    _pasangListenerNotifikasi();
  }

  /// Mengirim antrean mutasi offline ke server; memberi tahu pengguna bila ada yang ditolak server.
  Future<void> _sinkronkanAntrean() async {
    try {
      final gagal = await ref.read(offlineQueueCountProvider.notifier).flush();
      if (mounted && gagal.isNotEmpty) {
        AppToast.warning(context, '${gagal.length} data offline ditolak server dan dibuang.');
      }
    } catch (_) {
      // Sinkron gagal tak boleh mengganggu shell; akan dicoba lagi saat resume.
    }
  }

  /// Mengulang hitungan timeout idle; bila habis tanpa interaksi, sesi diakhiri lewat handleSessionTimeout demi keamanan.
  void _resetInactivityTimer() {
    _inactivityTimer?.cancel();
    _inactivityTimer = Timer(_idleTimeout, () {
      if (mounted) {
        ref.read(authStateProvider.notifier).handleSessionTimeout();
      }
    });
  }

  /// Saat aplikasi kembali aktif, data tab aktif di-refresh dengan throttle agar tidak memicu request berlebihan.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _sinkronkanAntrean();
      final now = DateTime.now();
      if (_lastResumeTime == null || now.difference(_lastResumeTime!) > _resumeThrottle) {
        _lastResumeTime = now;
        _refreshActiveTabData();
      }
    }
  }

  /// Meng-invalidate provider data milik tab aktif supaya data terbaru dimuat; dilewati bila belum login.
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
        if (authState.user?.isGudangUser == true) ref.invalidate(approvalPendingProvider);
        ref.invalidate(jadwalPreventifListProvider);
        ref.invalidate(rekamMedisKatalogProvider);
        ref.invalidate(spkListProvider);
        ref.invalidate(daftarTiketUnitProvider);
        break;
      case 3:
        break;
    }
  }

  /// Melepas observer lifecycle, langganan notifikasi, dan timer inaktivitas.
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _inactivityTimer?.cancel();
    _tapSub?.cancel();
    PushNotificationService.instance.onForegroundMessage = null;
    super.dispose();
  }

  /// Memasang listener ketuk notifikasi dan callback foreground, lalu mengonsumsi payload yang sudah terbit sebelum shell siap.
  void _pasangListenerNotifikasi() {
    final service = PushNotificationService.instance;
    _tapSub = service.onNotificationTappedStream.listen((_) => _konsumsiPayloadTertunda());
    service.onForegroundMessage = _segarkanDataUntuk;
    WidgetsBinding.instance.addPostFrameCallback((_) => _konsumsiPayloadTertunda());
  }

  /// Mengambil payload tersimpan sekali pakai (lalu mengosongkannya) dan membukanya bila shell masih terpasang.
  void _konsumsiPayloadTertunda() {
    if (!mounted) return;
    final payload = PushNotificationService.instance.onNotificationTapped.consume();
    if (payload != null) _bukaTujuan(payload);
  }

  /// Meng-invalidate provider global dan provider daftar yang relevan dengan tipe [payload] setelah pesan foreground masuk.
  void _segarkanDataUntuk(NotificationPayload payload) {
    if (!mounted) return;
    ref.invalidate(approvalPendingProvider);
    ref.invalidate(dashboardSummaryProvider);
    switch (resolveTarget(payload)) {
      case NotificationTarget.approvalPr:
      case NotificationTarget.riwayatPr:
        ref.invalidate(daftarPrProvider);
        ref.invalidate(poListProvider);
        break;
      case NotificationTarget.inboundPo:
        ref.invalidate(daftarPoInboundProvider);
        ref.invalidate(poListProvider);
        break;
      case NotificationTarget.approvalAmprah:
      case NotificationTarget.detailAmprah:
        ref.invalidate(daftarAmprahProvider);
        break;
      case NotificationTarget.antreanPicking:
        ref.invalidate(antreanPickingProvider);
        ref.invalidate(daftarAmprahProvider);
        break;
      case NotificationTarget.sppbInbound:
        ref.invalidate(sppbInboundProvider);
        ref.invalidate(daftarAmprahProvider);
        break;
      case NotificationTarget.hubIpsrs:
      case NotificationTarget.detailTiket:
        ref.invalidate(daftarTiketUnitProvider);
        break;
      case NotificationTarget.detailSpk:
        ref.invalidate(spkListProvider);
        ref.invalidate(daftarTiketUnitProvider);
        break;
      case NotificationTarget.otorisasiSirkulasi:
      case NotificationTarget.peminjamanSaya:
        ref.invalidate(daftarApprovalPeminjamanProvider);
        ref.invalidate(daftarPeminjamanSayaProvider);
        ref.invalidate(daftarPeminjamanAktifDipinjamProvider);
        ref.invalidate(daftarPeminjamanAktifDipinjamkanProvider);
        break;
      case NotificationTarget.hubPengalihan:
        ref.invalidate(daftarPengalihanProvider);
        ref.invalidate(countOtorisasiPengalihanProvider);
        break;
      case NotificationTarget.otorisasiPenyesuaian:
        ref.invalidate(otorisasiPenyesuaianListProvider);
        break;
      case NotificationTarget.inbox:
      case NotificationTarget.tidakDikenal:
        break;
    }
  }

  /// Membuka layar tujuan notifikasi lewat MaterialPageRoute; tipe tidak dikenal membuka inbox, ID tak valid jatuh ke layar daftar.
  void _bukaTujuan(NotificationPayload payload) {
    if (!mounted) return;
    final user = ref.read(authStateProvider).user;
    final target = resolveTarget(payload);
    if (user?.isGudangUser == true) {
      final tab = resolveGudangTabIndex(target, punyaTabApproval: _punyaTabApprovalGudang(user));
      if (tab != null) {
        Navigator.of(context).popUntil((r) => r.isFirst);
        setState(() => _currentIndex = tab);
        _refreshActiveTabData();
        return;
      }
    }
    final id = int.tryParse(payload.referensiId ?? '');
    final Widget layar;
    switch (target) {
      case NotificationTarget.approvalPr:
      case NotificationTarget.approvalAmprah:
        layar = const ApprovalCenterScreen();
        break;
      case NotificationTarget.antreanPicking:
        layar = const PickingDistribusiScreen();
        break;
      case NotificationTarget.inboundPo:
        layar = const InboundPoListScreen();
        break;
      case NotificationTarget.riwayatPr:
        layar = const RiwayatPrScreen();
        break;
      case NotificationTarget.detailAmprah:
        layar = id == null
            ? const AmprahHubScreen()
            : DetailAmprahScreen(amprahId: id, kodeAmprah: '#$id');
        break;
      case NotificationTarget.sppbInbound:
        layar = const AmprahHubScreen();
        break;
      case NotificationTarget.hubIpsrs:
        layar = const IpsrsHubScreen();
        break;
      case NotificationTarget.detailSpk:
        layar = id == null
            ? const SpkListScreen()
            : SpkDetailScreen(spkId: id, kodeSpk: '#$id');
        break;
      case NotificationTarget.detailTiket:
        layar = id == null
            ? const IpsrsHubScreen()
            : DetailTiketScreen(tiketId: id, kodeTiket: '#$id');
        break;
      case NotificationTarget.otorisasiSirkulasi:
      case NotificationTarget.peminjamanSaya:
        layar = const SirkulasiAsetHubScreen();
        break;
      case NotificationTarget.hubPengalihan:
        layar = const PengalihanHubScreen();
        break;
      case NotificationTarget.otorisasiPenyesuaian:
        layar = const OtorisasiPenyesuaianScreen();
        break;
      case NotificationTarget.inbox:
      case NotificationTarget.tidakDikenal:
        layar = NotifikasiScreen(onBuka: _bukaDariInbox);
        break;
    }
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => layar));
  }

  /// Membuka tujuan dokumen dari item inbox; item bertipe umum/asing diabaikan karena sudah berada di inbox.
  void _bukaDariInbox(NotifikasiModel item) {
    final payload = NotificationPayload(
      tipe: item.tipe,
      referensiId: item.referensiId,
      judul: item.judul,
      pesan: item.pesan,
      timestamp: item.dibuatPada,
    );
    final target = resolveTarget(payload);
    if (target == NotificationTarget.inbox || target == NotificationTarget.tidakDikenal) return;
    _bukaTujuan(payload);
  }

  /// Membuka layar pemindai QR aset dari tombol scan di tengah nav bar.
  void _onScanPressed() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const QrScannerScreen()),
    );
  }

  /// True bila user gudang berhak memutuskan amprah (Meja 2): kepala gudang atau admin logistik; petugas gudang tidak.
  bool _punyaTabApprovalGudang(UserModel? user) =>
      user?.isKepalaGudang == true || user?.isAdminLogistik == true;

  /// Menyusun daftar layar dan item nav bawah sesuai role pengguna (teknisi, gudang, eksekutif, karu, atau petugas unit).
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
      final punyaTabApproval = _punyaTabApprovalGudang(user);
      return _ShellNavConfig(
        screens: [
          homeScreen,
          const InboundPoListScreen(),
          if (punyaTabApproval) const ApprovalCenterScreen(),
          const PickingDistribusiScreen(),
          profileScreen,
        ],
        navItems: [
          const BottomNavItem(icon: LucideIcons.home, label: 'Beranda'),
          const BottomNavItem(icon: LucideIcons.packageCheck, label: 'Inbound PO'),
          if (punyaTabApproval) const BottomNavItem(icon: LucideIcons.checkSquare, label: 'Approval'),
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

  /// Membangun shell dengan IndexedStack layar tab, nav bar melayang, dan Listener sentuhan untuk mereset timer idle.
  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).user;
    final antrean = ref.watch(offlineQueueCountProvider);
    final navConfig = _resolveNavConfig(user);
    final activeIndex = _currentIndex.clamp(0, navConfig.screens.length - 1);

    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => _resetInactivityTimer(),
      onPointerMove: (_) => _resetInactivityTimer(),
      child: Scaffold(
        backgroundColor: AppColors.canvas,
        body: Column(
          children: [
            if (antrean > 0)
              SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: AppActionBannerCard(
                    title: '$antrean laporan menunggu dikirim',
                    subtitle: 'Akan dikirim otomatis saat tersambung internet. Ketuk untuk coba sekarang.',
                    icon: LucideIcons.cloudOff,
                    iconColor: AppColors.warning,
                    onTap: _sinkronkanAntrean,
                  ),
                ),
              ),
            Expanded(
              child: IndexedStack(
                index: activeIndex,
                children: navConfig.screens,
              ),
            ),
          ],
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

/// Konfigurasi tab shell: pasangan daftar layar dan item navigasi yang urutannya sejajar.
class _ShellNavConfig {
  final List<Widget> screens;
  final List<BottomNavItem> navItems;

  const _ShellNavConfig({
    required this.screens,
    required this.navItems,
  });
}
