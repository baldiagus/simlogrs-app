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

class AsetDetailScreen extends ConsumerStatefulWidget {
  final AsetDetailModel? initialAset;
  final int? asetId;

  const AsetDetailScreen({
    super.key,
    this.initialAset,
    this.asetId,
  }) : assert(initialAset != null || asetId != null,
            'Either initialAset or asetId must be provided');

  @override
  ConsumerState<AsetDetailScreen> createState() => _AsetDetailScreenState();
}

class _AsetDetailScreenState extends ConsumerState<AsetDetailScreen> {
  AsetDetailModel? _aset;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    if (widget.initialAset != null) {
      _aset = widget.initialAset;
    } else {
      _fetchAset();
    }
  }

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

  void _showQrStickerModal(AsetDetailModel aset) {
    QrStickerSheet.show(context, aset);
  }

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

  Future<void> _refreshAset(AsetDetailModel aset) async {
    final updated =
        await ref.read(asetActionProvider.notifier).scanAset(aset.kodeAset);
    if (updated != null && mounted) {
      setState(() {
        _aset = updated;
      });
    }
  }

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

  const _AsetDetailAccess({
    required this.isOwnedByCurrentUserLocation,
    required this.isGlobalAdmin,
    required this.isProviderOwner,
    required this.canPinjam,
    required this.canLaporRusak,
  });

  factory _AsetDetailAccess.resolve(
      AsetDetailModel currentAset, UserModel? user) {
    final isTeknisi = user?.isTeknisi ?? false;

    // Cek apakah aset berada di unit/ruangan/gudang pengguna sendiri
    final isAsetUnitPengguna = currentAset.unitId != null &&
        user?.unit?.id != null &&
        currentAset.unitId == user!.unit!.id;

    final isAsetGudangPengguna = currentAset.gudangId != null &&
        user?.gudang?.id != null &&
        currentAset.gudangId == user!.gudang!.id;

    final isSameLocationName = (user?.unit?.nama != null &&
            (currentAset.penanggungJawab == user!.unit!.nama ||
                currentAset.lokasiTercatat.contains(user.unit!.nama))) ||
        (user?.gudang?.nama != null &&
            (currentAset.penanggungJawab == user!.gudang!.nama ||
                currentAset.lokasiTercatat.contains(user.gudang!.nama)));

    final isOwnedByCurrentUserLocation =
        isAsetUnitPengguna || isAsetGudangPengguna || isSameLocationName;

    final isGlobalAdmin =
        user?.isSuperAdmin == true || user?.isAdminLogistik == true;

    final isAsetSedangDipinjamUnitUser = currentAset.isDipinjam &&
        currentAset.peminjamanAktif != null &&
        user?.unit?.nama != null &&
        currentAset.peminjamanAktif!.unitPeminjam == user!.unit!.nama;

    final canLaporRusak = !isTeknisi &&
        (isOwnedByCurrentUserLocation ||
            isAsetSedangDipinjamUnitUser ||
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
