import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../widgets/qr_sticker_sheet.dart';
import '../widgets/aset_detail_sections.dart';
import '../widgets/aset_detail_actions.dart';
import '../widgets/aset_detail_hero_card.dart';
import '../widgets/aset_detail_riwayat_section.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_error_view.dart';
import '../../../../shared/widgets/app_loading_view.dart';
import '../widgets/modal_pengembalian_aset_sheet.dart';
import '../widgets/modal_perpanjang_peminjaman_sheet.dart';
import '../../../maintenance/presentation/screens/rekam_medis_detail_screen.dart';
import '../../data/models/aset_detail_model.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/aset_provider.dart';

/// Halaman profil aset fisik beserta riwayat dan aksi sirkulasi.
class AsetDetailScreen extends ConsumerStatefulWidget {
  final AsetDetailModel? initialAset;
  final int? asetId;

  /// Membuat layar detail; wajib menerima `initialAset` atau `asetId`.
  const AsetDetailScreen({
    super.key,
    this.initialAset,
    this.asetId,
  }) : assert(initialAset != null || asetId != null,
            'Either initialAset or asetId must be provided');

  /// Membuat state layar detail aset.
  @override
  ConsumerState<AsetDetailScreen> createState() => _AsetDetailScreenState();
}

/// State untuk [AsetDetailScreen]: memuat data aset dan membuka modal aksi.
class _AsetDetailScreenState extends ConsumerState<AsetDetailScreen> {
  AsetDetailModel? _aset;
  bool _isLoading = false;
  String? _errorMessage;

  /// Mengisi data awal dari `initialAset` atau mengambilnya dari server.
  @override
  void initState() {
    super.initState();
    if (widget.initialAset != null) {
      _aset = widget.initialAset;
    } else {
      _fetchAset();
    }
  }

  /// Mengambil detail aset dari server berdasarkan `asetId` lalu memperbarui
  /// state loading/error.
  Future<void> _fetchAset() async {
    if (widget.asetId == null) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final data =
          await ref.read(asetRepositoryProvider).getDetailAset(widget.asetId!);
      if (mounted) {
        setState(() {
          _aset = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  /// Menampilkan sheet stiker QR code aset untuk dicetak/dibagikan.
  void _showQrStickerModal(AsetDetailModel aset) {
    QrStickerSheet.show(context, aset);
  }

  /// Menampilkan modal perpanjangan untuk peminjaman aktif aset.
  void _showPerpanjangModal(AsetDetailModel aset) {
    final pinjamInfo = aset.peminjamanAktif;
    if (pinjamInfo == null) return;
    ModalPerpanjangPeminjamanSheet.show(
      context,
      peminjamanId: pinjamInfo.peminjamanId,
      kodeDokumen: pinjamInfo.kodePinjam,
      tanggalKembaliSaatIni: pinjamInfo.tanggalKembaliRencana,
      onSuccess: _fetchAset,
    );
  }

  /// Menampilkan modal pengembalian aset untuk peminjaman yang sedang aktif.
  void _showPengembalianModal() {
    if (_aset == null) return;
    final currentAset = _aset!;
    final peminjamanId = currentAset.peminjamanAktif?.peminjamanId;
    if (peminjamanId == null) return;
    ModalPengembalianAsetSheet.show(
      context,
      peminjamanId: peminjamanId,
      detailId: currentAset.peminjamanAktif?.peminjamanDetailId ?? peminjamanId,
      asetId: currentAset.id,
      kodeDokumen: currentAset.kodeAset,
      namaBarang: currentAset.namaKomoditas,
      onSuccess: _fetchAset,
    );
  }

  /// Memuat ulang data aset lewat pemindaian kode aset agar tampilan terbaru.
  Future<void> _refreshAset(AsetDetailModel aset) async {
    final updated =
        await ref.read(asetActionProvider.notifier).scanAset(aset.kodeAset);
    if (updated != null && mounted) {
      setState(() {
        _aset = updated;
      });
    }
  }

  /// Membuka layar rekam medis (riwayat perbaikan/maintenance) milik aset.
  void _openRekamMedis(AsetDetailModel aset) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RekamMedisDetailScreen(
          asetId: aset.id,
          initialNama: aset.namaKomoditas,
        ),
      ),
    );
  }

  /// Membangun halaman detail aset: state loading/error, lalu seluruh kartu
  /// informasi dan tombol aksi sesuai hak akses pengguna.
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.canvas,
        appBar: AppBar(title: const Text('Profil Aset Fisik')),
        body: const AppLoadingView(),
      );
    }

    if (_errorMessage != null || _aset == null) {
      return Scaffold(
        backgroundColor: AppColors.canvas,
        appBar: AppBar(title: const Text('Profil Aset Fisik')),
        body: AppErrorView(
          error: _errorMessage ?? 'Data aset tidak ditemukan',
          onRetry: _fetchAset,
        ),
      );
    }

    final currentAset = _aset!;
    final actionState = ref.watch(asetActionProvider);
    final user = ref.watch(authStateProvider).user;
    final access = _AsetDetailAccess.resolve(currentAset, user);

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: const Text('Profil Aset Fisik'),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.qrCode, size: 20),
            tooltip: 'Stiker QR Code',
            onPressed: () => _showQrStickerModal(currentAset),
          ),
          IconButton(
            icon: const Icon(LucideIcons.refreshCw, size: 18),
            tooltip: 'Muat ulang',
            onPressed: () => _refreshAset(currentAset),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Hero Asset Card
              AsetDetailHeroCard(
                aset: currentAset,
                onShowQr: () => _showQrStickerModal(currentAset),
              ),
              const SizedBox(height: 16),

              // 2. Overdue Alert Banner if active
              if (currentAset.peminjamanAktif != null &&
                  currentAset.peminjamanAktif!.isOverdue) ...[
                AsetDetailOverdueBanner(loan: currentAset.peminjamanAktif!),
                const SizedBox(height: 16),
              ],

              AsetDetailLokasiCard(aset: currentAset),
              const SizedBox(height: 16),
              AsetDetailSpesifikasiCard(aset: currentAset),
              const SizedBox(height: 16),
              AsetDetailIpsrsCard(
                aset: currentAset,
                onTap: () => _openRekamMedis(currentAset),
              ),
              const SizedBox(height: 16),

              // 6. Active Loan Details if DIPINJAM
              if (currentAset.peminjamanAktif != null) ...[
                AsetDetailActiveLoanCard(loan: currentAset.peminjamanAktif!),
                const SizedBox(height: 16),
              ],

              // 7-8. Riwayat Sirkulasi Peminjaman & Pengalihan
              AsetDetailRiwayatSection(aset: currentAset),
              const SizedBox(height: 16),

              AsetDetailActionSection(
                aset: currentAset,
                isOwnedByCurrentUserLocation:
                    access.isOwnedByCurrentUserLocation,
                isGlobalAdmin: access.isGlobalAdmin,
                isProviderOwner: access.isProviderOwner,
                canPinjam: access.canPinjam,
                canLaporRusak: access.canLaporRusak,
                canPerpanjang: user?.canPerpanjangPeminjaman ?? false,
                isActionLoading: actionState.isLoading,
                onPerpanjang: () => _showPerpanjangModal(currentAset),
                onPengembalian: _showPengembalianModal,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Hak akses pengguna terhadap aset yang sedang ditampilkan.
class _AsetDetailAccess {
  final bool isOwnedByCurrentUserLocation;
  final bool isGlobalAdmin;
  final bool isProviderOwner;
  final bool canPinjam;
  final bool canLaporRusak;

  /// Membuat objek hak akses dengan nilai yang sudah ditentukan.
  const _AsetDetailAccess({
    required this.isOwnedByCurrentUserLocation,
    required this.isGlobalAdmin,
    required this.isProviderOwner,
    required this.canPinjam,
    required this.canLaporRusak,
  });

  /// Menghitung hak akses pengguna (pinjam, lapor rusak, pemilik) terhadap
  /// aset berdasarkan lokasi, peran, dan status aset.
  factory _AsetDetailAccess.resolve(
      AsetDetailModel currentAset, UserModel? user) {
    final isTeknisi = user?.isTeknisi ?? false;

    // Cek apakah aset berada di unit/ruangan/gudang pengguna sendiri (strict check)
    final isAsetUnitPengguna = user?.unit != null &&
        currentAset.unitId != null &&
        currentAset.unitId == user!.unit!.id;

    final isAsetGudangPengguna = user?.gudang != null &&
        currentAset.gudangId != null &&
        currentAset.gudangId == user!.gudang!.id;

    final isExactPenanggungJawab = (user?.unit?.nama != null &&
            currentAset.penanggungJawab == user!.unit!.nama) ||
        (user?.gudang?.nama != null &&
            currentAset.penanggungJawab == user!.gudang!.nama);

    final isOwnedByCurrentUserLocation =
        isAsetUnitPengguna || isAsetGudangPengguna || isExactPenanggungJawab;

    final isGlobalAdmin =
        user?.isSuperAdmin == true || user?.isAdminLogistik == true;

    final isBorrowerOrOwnerWhenBorrowed = currentAset.isDipinjam &&
        ((user?.unit?.id != null && currentAset.unitId == user!.unit!.id) ||
            (user?.unit?.nama != null &&
                currentAset.peminjamanAktif?.unitPeminjam == user!.unit!.nama));

    final canLaporRusak = !isTeknisi &&
        (isOwnedByCurrentUserLocation ||
            isBorrowerOrOwnerWhenBorrowed ||
            isGlobalAdmin);
    final canPinjam = !isTeknisi &&
        user?.unit != null &&
        !isOwnedByCurrentUserLocation &&
        currentAset.isTersedia &&
        !currentAset.isRusak &&
        !currentAset.isSedangDalamProsesPinjam;

    return _AsetDetailAccess(
      isOwnedByCurrentUserLocation: isOwnedByCurrentUserLocation,
      isGlobalAdmin: isGlobalAdmin,
      isProviderOwner:
          isGlobalAdmin || isOwnedByCurrentUserLocation || user == null,
      canPinjam: canPinjam,
      canLaporRusak: canLaporRusak,
    );
  }
}
