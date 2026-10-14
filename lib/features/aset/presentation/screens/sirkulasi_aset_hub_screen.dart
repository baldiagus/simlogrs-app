import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../widgets/modal_pengembalian_aset_sheet.dart';
import '../widgets/modal_otorisasi_peminjaman_sheet.dart';
import '../widgets/modal_perpanjang_peminjaman_sheet.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../dashboard/presentation/providers/dashboard_provider.dart';
import '../../data/models/peminjaman_aset_model.dart';
import '../../../master/presentation/providers/register_aset_provider.dart';
import '../providers/peminjaman_provider.dart';
import '../widgets/sirkulasi_hub_common_widgets.dart';
import '../widgets/sirkulasi_hub_otorisasi_tab.dart';
import '../widgets/sirkulasi_hub_peminjaman_tab.dart';
import '../widgets/sirkulasi_hub_siap_kembali_tab.dart';
import 'form_peminjaman_aset_screen.dart';
import 'qr_scanner_screen.dart';

/// Halaman hub sirkulasi aset RS (peminjaman, otorisasi, dan pengembalian).
class SirkulasiAsetHubScreen extends ConsumerStatefulWidget {
  /// Membuat layar hub sirkulasi aset.
  const SirkulasiAsetHubScreen({super.key});

  /// Membuat state layar hub sirkulasi aset.
  @override
  ConsumerState<SirkulasiAsetHubScreen> createState() =>
      _SirkulasiAsetHubScreenState();
}

/// State hub sirkulasi: mengelola tab, hak otorisasi, dan aksi modal peminjaman.
class _SirkulasiAsetHubScreenState extends ConsumerState<SirkulasiAsetHubScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _canApprove = false;
  String _subPerspektifSiapKembali =
      'dipinjam'; // 'dipinjam' (peminjam) atau 'dipinjamkan' (penyedia)

  /// Menentukan hak otorisasi awal dan membuat [TabController] sesuai jumlah tab.
  @override
  void initState() {
    super.initState();
    _canApprove = _hitungCanApprove(ref.read(authStateProvider).user);
    _tabController = TabController(length: _canApprove ? 3 : 2, vsync: this);
  }

  /// Membuang [TabController] saat state dilepas agar tidak bocor memori.
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// Izin user untuk mengakses tab Otorisasi peminjaman.
  bool _hitungCanApprove(UserModel? user) {
    return (user?.can('update_layanan_unit::approval::peminjaman') ?? false) ||
        (user?.can('layanan_unit::approval::peminjaman') ?? false) ||
        (user?.hasRole('kepala_unit') ?? false) ||
        (user?.hasRole('kepala_gudang') ?? false) ||
        (user?.hasRole('kepala_teknisi') ?? false) ||
        (user?.hasRole('admin_logistik') ?? false) ||
        (user?.hasRole('super_admin') ?? false);
  }

  /// Membuka form peminjaman baru dan menyegarkan daftar bila peminjaman berhasil dibuat.
  Future<void> _bukaFormPeminjaman(BuildContext context) async {
    final created = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const FormPeminjamanAsetScreen()),
    );
    if (created == true && context.mounted) {
      ref.invalidate(daftarPeminjamanSayaProvider);
      ref.invalidate(daftarApprovalPeminjamanProvider);
      ref.invalidate(dashboardSummaryProvider);
    }
  }

  /// Membuka modal pengembalian untuk item pertama peminjaman lalu menyegarkan daftar terkait.
  void _showReturnModal(BuildContext context, PeminjamanAsetModel item) {
    if (item.items.isEmpty) return;
    final firstItem = item.items.first;
    ModalPengembalianAsetSheet.show(
      context,
      peminjamanId: item.id,
      detailId: firstItem.id,
      asetId: firstItem.asetId,
      kodeDokumen: item.kode,
      namaBarang: firstItem.namaKomoditas,
      onSuccess: () {
        ref.invalidate(daftarPeminjamanSayaProvider);
        ref.invalidate(daftarPeminjamanAktifDipinjamProvider);
        ref.invalidate(daftarPeminjamanAktifDipinjamkanProvider);
        ref.invalidate(registerAsetListProvider);
        ref.invalidate(dashboardSummaryProvider);
      },
    );
  }

  /// Membuka modal otorisasi (setuju/tolak) peminjaman lalu menyegarkan daftar terkait.
  void _showOtorisasiModal(
      BuildContext context, ApprovalPeminjamanModel item, String aksi) {
    ModalOtorisasiPeminjamanSheet.show(
      context,
      item: item,
      aksi: aksi,
      onSuccess: () {
        ref.invalidate(daftarApprovalPeminjamanProvider);
        ref.invalidate(daftarPeminjamanSayaProvider);
        ref.invalidate(daftarPeminjamanAktifDipinjamProvider);
        ref.invalidate(daftarPeminjamanAktifDipinjamkanProvider);
        ref.invalidate(registerAsetListProvider);
        ref.invalidate(dashboardSummaryProvider);
      },
    );
  }

  /// Membuka modal perpanjangan peminjaman lalu menyegarkan daftar terkait.
  void _showPerpanjangModal(BuildContext context, PeminjamanAsetModel item) {
    ModalPerpanjangPeminjamanSheet.show(
      context,
      peminjamanId: item.id,
      kodeDokumen: item.kode,
      tanggalKembaliSaatIni: item.tanggalKembaliRencana,
      onSuccess: () {
        ref.invalidate(daftarPeminjamanSayaProvider);
        ref.invalidate(daftarPeminjamanAktifDipinjamProvider);
        ref.invalidate(daftarPeminjamanAktifDipinjamkanProvider);
        ref.invalidate(dashboardSummaryProvider);
      },
    );
  }

  /// Membangun hub sirkulasi aset: tab pinjaman saya, otorisasi (jika berhak),
  /// dan siap kembali, plus tombol pinjam aset baru.
  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).user;
    final canApproveNow = _hitungCanApprove(user);
    if (canApproveNow != _canApprove) {
      _canApprove = canApproveNow;
      _tabController.dispose();
      _tabController = TabController(length: _canApprove ? 3 : 2, vsync: this);
    }

    final peminjamanSayaAsync = ref.watch(daftarPeminjamanSayaProvider);
    final approvalPeminjamanAsync = _canApprove
        ? ref.watch(daftarApprovalPeminjamanProvider)
        : const AsyncValue.data(<ApprovalPeminjamanModel>[]);
    final peminjamanAktifDipinjamAsync =
        ref.watch(daftarPeminjamanAktifDipinjamProvider);
    final peminjamanAktifDipinjamkanAsync =
        ref.watch(daftarPeminjamanAktifDipinjamkanProvider);
    final totalSiapKembali =
        (peminjamanAktifDipinjamAsync.valueOrNull?.length ?? 0) +
            (peminjamanAktifDipinjamkanAsync.valueOrNull?.length ?? 0);
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: const Text('Sirkulasi Aset RS'),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.qrCode, size: 20),
            tooltip: 'Buka Kamera Scanner',
            onPressed: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const QrScannerScreen()));
            },
          ),
          IconButton(
            icon: const Icon(LucideIcons.refreshCw, size: 18),
            tooltip: 'Segarkan Data',
            onPressed: () {
              ref.invalidate(daftarPeminjamanSayaProvider);
              ref.invalidate(daftarApprovalPeminjamanProvider);
              ref.invalidate(daftarPeminjamanAktifDipinjamProvider);
              ref.invalidate(daftarPeminjamanAktifDipinjamkanProvider);
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          indicatorColor: AppColors.primaryPurple,
          indicatorWeight: 3,
          labelColor: AppColors.primaryPurple,
          unselectedLabelColor: AppColors.textSecondary,
          labelStyle:
              const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
          tabs: [
            Tab(
              child: Text(
                (user?.isKepalaGudang == true ||
                        user?.isAdminLogistik == true ||
                        (user?.gudang != null &&
                            user?.isManajemen != true &&
                            user?.isAuditor != true))
                    ? 'Peminjaman Gudang'
                    : 'Pinjaman Saya',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (_canApprove)
              SirkulasiHubBadgeTab(
                label: 'Otorisasi',
                count: approvalPeminjamanAsync.valueOrNull?.length ?? 0,
              ),
            SirkulasiHubBadgeTab(
                label: 'Siap Kembali', count: totalSiapKembali),
          ],
        ),
      ),
      floatingActionButton: (user?.unit != null)
          ? FloatingActionButton.extended(
              heroTag: null,
              onPressed: () => _bukaFormPeminjaman(context),
              backgroundColor: AppColors.primaryPurple,
              foregroundColor: Colors.white,
              icon: const Icon(LucideIcons.plus, size: 18),
              label: const Text('Pinjam Aset Baru',
                  style: TextStyle(fontWeight: FontWeight.w700)),
            )
          : null,
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: Peminjaman Saya
          SirkulasiHubPeminjamanTab(
            peminjamanAsync: peminjamanSayaAsync,
            onAjukan: () => _bukaFormPeminjaman(context),
            onExtend: _showPerpanjangModal,
          ),

          // Tab 2: Otorisasi Masuk (Karu & Kagud)
          if (_canApprove)
            SirkulasiHubOtorisasiTab(
              approvalAsync: approvalPeminjamanAsync,
              onOtorisasi: _showOtorisasiModal,
            ),

          // Tab 3: Siap Pengembalian (Perspektif: Dipinjam vs Dipinjamkan)
          SirkulasiHubSiapKembaliTab(
            dipinjamAsync: peminjamanAktifDipinjamAsync,
            dipinjamkanAsync: peminjamanAktifDipinjamkanAsync,
            subPerspektif: _subPerspektifSiapKembali,
            onSubPerspektifChanged: (value) =>
                setState(() => _subPerspektifSiapKembali = value),
            onExtend: _showPerpanjangModal,
            onReturn: _showReturnModal,
          ),
        ],
      ),
    );
  }
}
