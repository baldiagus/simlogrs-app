import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../widgets/qr_sticker_sheet.dart';
import '../widgets/aset_detail_sections.dart';
import '../widgets/aset_riwayat_peminjaman_card.dart';
import '../widgets/aset_histori_pengalihan_card.dart';
import 'histori_pengalihan_aset_screen.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_error_view.dart';
import '../../../../shared/widgets/app_loading_view.dart';
import '../../../../shared/widgets/custom_button.dart';
import '../../../../shared/widgets/status_badge.dart';
import '../widgets/modal_pengembalian_aset_sheet.dart';
import '../widgets/modal_perpanjang_peminjaman_sheet.dart';
import '../widgets/modal_pengalihan_aset_sheet.dart';
import '../../../maintenance/presentation/screens/lapor_cepat_screen.dart';
import '../../../maintenance/presentation/screens/rekam_medis_detail_screen.dart';
import '../../data/models/aset_detail_model.dart';
import '../../data/models/aset_tersedia_model.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/aset_provider.dart';
import 'form_peminjaman_aset_screen.dart';
import 'histori_sirkulasi_aset_screen.dart';

class AsetDetailScreen extends ConsumerStatefulWidget {
  final AsetDetailModel? initialAset;
  final int? asetId;

  const AsetDetailScreen({
    super.key,
    this.initialAset,
    this.asetId,
  }) : assert(initialAset != null || asetId != null, 'Either initialAset or asetId must be provided');

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
      final data = await ref.read(asetRepositoryProvider).getDetailAset(widget.asetId!);
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

    final isOwnedByCurrentUserLocation = isAsetUnitPengguna || isAsetGudangPengguna || isSameLocationName;

    final isGlobalAdmin = user?.isSuperAdmin == true || user?.isAdminLogistik == true;

    final isAsetSedangDipinjamUnitUser = currentAset.isDipinjam &&
        currentAset.peminjamanAktif != null &&
        user?.unit?.nama != null &&
        currentAset.peminjamanAktif!.unitPeminjam == user!.unit!.nama;

    final canLaporRusak = !isTeknisi &&
        (isOwnedByCurrentUserLocation || isAsetSedangDipinjamUnitUser || isGlobalAdmin);

    final canPinjam = !isTeknisi &&
        user?.unit != null &&
        !isOwnedByCurrentUserLocation &&
        currentAset.isTersedia &&
        !currentAset.isRusak &&
        !currentAset.isSedangDalamProsesPinjam;
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
            onPressed: () async {
              final updated = await ref.read(asetActionProvider.notifier).scanAset(currentAset.kodeAset);
              if (updated != null && mounted) {
                setState(() {
                  _aset = updated;
                });
              }
            },
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
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryHeroGradient,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white24,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              currentAset.kodeAset,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                fontFamily: 'monospace',
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        StatusBadge(status: currentAset.status),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      currentAset.namaKomoditas,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${currentAset.kategori} • Nomor Seri: ${currentAset.nomorSeri}',
                      style: const TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                    const SizedBox(height: 14),
                    // Quick Action: Lihat Stiker QR Button
                    InkWell(
                      onTap: () => _showQrStickerModal(currentAset),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(LucideIcons.qrCode, color: Colors.white, size: 16),
                            SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                'Lihat Stiker QR Inventaris',
                                style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 2. Overdue Alert Banner if active
              if (currentAset.peminjamanAktif != null && currentAset.peminjamanAktif!.isOverdue) ...[
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(LucideIcons.alertTriangle, size: 22, color: AppColors.danger),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Peminjaman Melebihi Batas Waktu!',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.danger,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Rencana kembali: ${currentAset.peminjamanAktif!.tanggalKembaliRencana ?? '-'}. Mohon segera lakukan pengembalian fisik.',
                              style: const TextStyle(fontSize: 11, color: AppColors.danger),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              AsetDetailLokasiCard(aset: currentAset),
              const SizedBox(height: 16),
              AsetDetailSpesifikasiCard(aset: currentAset),
              const SizedBox(height: 16),
              AsetDetailIpsrsCard(
                aset: currentAset,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => RekamMedisDetailScreen(
                        asetId: currentAset.id,
                        initialNama: currentAset.namaKomoditas,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),

              // 6. Active Loan Details if DIPINJAM
              if (currentAset.peminjamanAktif != null) ...[
                AsetDetailActiveLoanCard(loan: currentAset.peminjamanAktif!),
                const SizedBox(height: 16),
              ],

              // 7. Riwayat Sirkulasi Peminjaman Unit
              AsetRiwayatPeminjamanCard(
                riwayat: currentAset.riwayatPeminjaman,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => HistoriSirkulasiAsetScreen(
                        asetId: currentAset.id,
                        kodeAset: currentAset.kodeAset,
                        namaKomoditas: currentAset.namaKomoditas,
                        nomorSeri: currentAset.nomorSeri,
                        initialRiwayat: currentAset.riwayatPeminjaman,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),

              // 8. Riwayat Pengalihan & Mutasi Fisik
              AsetHistoriPengalihanCard(
                riwayat: currentAset.riwayatPengalihan,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => HistoriPengalihanAsetScreen(
                        asetId: currentAset.id,
                        kodeAset: currentAset.kodeAset,
                        namaKomoditas: currentAset.namaKomoditas,
                        nomorSeri: currentAset.nomorSeri,
                        initialRiwayat: currentAset.riwayatPengalihan,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              if (currentAset.isDipinjam && currentAset.peminjamanAktif != null) ...[
                Builder(
                  builder: (context) {
                    final isProviderOwner = isGlobalAdmin || isOwnedByCurrentUserLocation || user == null;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              flex: isProviderOwner ? 2 : 1,
                              child: OutlinedButton.icon(
                                onPressed: () => _showPerpanjangModal(currentAset),
                                icon: const Icon(LucideIcons.calendarPlus, size: 16, color: AppColors.primaryPurple),
                                label: const Text(
                                  'Perpanjang',
                                  style: TextStyle(color: AppColors.primaryPurple, fontSize: 13, fontWeight: FontWeight.w700),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: AppColors.primaryPurple, width: 1.5),
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                ),
                              ),
                            ),
                            if (isProviderOwner) ...[
                              const SizedBox(width: 10),
                              Expanded(
                                flex: 3,
                                child: CustomButton(
                                  text: 'Kembalikan Fisik',
                                  icon: const Icon(LucideIcons.packageCheck, size: 18, color: Colors.white),
                                  isLoading: actionState.isLoading,
                                  onPressed: _showPengembalianModal,
                                ),
                              ),
                            ],
                          ],
                        ),
                        if (!isProviderOwner) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: AppColors.canvas,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Row(
                              children: [
                                const Icon(LucideIcons.info, size: 16, color: AppColors.textSecondary),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Peminjam menyerahkan fisik aset ke unit ${currentAset.namaPenyedia} untuk proses inspeksi pengembalian resmi.',
                                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    );
                  },
                ),
                const SizedBox(height: 10),
              ] else if (canPinjam) ...[
                CustomButton(
                  text: 'Ajukan Peminjaman Aset',
                  icon: const Icon(LucideIcons.repeat, size: 18, color: Colors.white),
                  onPressed: () {
                    // Buat AsetTersediaModel dari currentAset untuk prefill form peminjaman
                    final asetTersedia = AsetTersediaModel(
                      id: currentAset.id,
                      kodeAset: currentAset.kodeAset,
                      nomorSeri: currentAset.nomorSeri,
                      namaKomoditas: currentAset.namaKomoditas,
                      spesifikasi: currentAset.spesifikasi,
                      kategori: currentAset.kategori,
                      satuan: 'Unit',
                      merek: currentAset.merek,
                      kondisi: currentAset.kondisi,
                      tipePenyedia: currentAset.tipePenyedia ?? (currentAset.gudangId != null ? 'GUDANG' : (currentAset.lokasiTercatat.contains('Rak:') ? 'GUDANG' : 'RUANGAN')),
                      penyediaId: currentAset.penyediaId ?? (currentAset.gudangId ?? currentAset.unitId),
                      namaPenyedia: currentAset.namaPenyedia ?? currentAset.penanggungJawab,
                      lokasiLengkap: currentAset.lokasiTercatat,
                    );
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => FormPeminjamanAsetScreen(preselectedAset: asetTersedia),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 10),
              ] else if (!isOwnedByCurrentUserLocation && currentAset.isSedangDalamProsesPinjam && !currentAset.isDipinjam) ...[
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.tintOrangeBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.tintOrange.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(LucideIcons.clockAlert, size: 20, color: AppColors.tintOrange),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Sedang Dalam Proses Peminjaman',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.tintOrange,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              currentAset.antreanPeminjaman != null
                                  ? 'Aset ini sedang diajukan peminjaman oleh ${currentAset.antreanPeminjaman!['unit_peminjam']} (${currentAset.antreanPeminjaman!['kode_pinjam']}) dengan status ${currentAset.antreanPeminjaman!['status']}.'
                                  : 'Aset ini sedang dalam antrean proses peminjaman unit lain dan belum dapat dipinjam.',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                                height: 1.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Tombol Lapor Kerusakan ke IPSRS (Hanya untuk non-teknisi / pemohon ruangan)
              // Tombol Pengalihan / Mutasi Aset (Meminta aset dari fasilitas lain masuk ke unit kerja Anda)
              if ((!isOwnedByCurrentUserLocation || isGlobalAdmin) && currentAset.isTersedia && !currentAset.isDipinjam) ...[
                OutlinedButton.icon(
                  onPressed: () {
                    final asetTersedia = AsetTersediaModel(
                      id: currentAset.id,
                      kodeAset: currentAset.kodeAset,
                      nomorSeri: currentAset.nomorSeri,
                      namaKomoditas: currentAset.namaKomoditas,
                      spesifikasi: currentAset.spesifikasi,
                      kategori: currentAset.kategori,
                      satuan: 'Unit',
                      merek: currentAset.merek,
                      kondisi: currentAset.kondisi,
                      tipePenyedia: currentAset.tipePenyedia ?? (currentAset.gudangId != null ? 'GUDANG' : 'RUANGAN'),
                      penyediaId: currentAset.penyediaId ?? (currentAset.gudangId ?? currentAset.unitId ?? 0),
                      namaPenyedia: currentAset.namaPenyedia ?? currentAset.penanggungJawab,
                      lokasiLengkap: currentAset.lokasiTercatat,
                    );
                    ModalPengalihanAsetSheet.show(context, aset: asetTersedia);
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: const BorderSide(color: AppColors.primaryPurple),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  icon: const Icon(LucideIcons.arrowRightLeft, size: 18, color: AppColors.primaryPurple),
                  label: const Text(
                    'Pengalihan / Mutasi Aset',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primaryPurple),
                  ),
                ),
                const SizedBox(height: 10),
              ],

              if (canLaporRusak) ...[
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => LaporCepatScreen(initialKodeAset: currentAset.kodeAset),
                      ),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: const BorderSide(color: AppColors.danger),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  icon: const Icon(LucideIcons.wrench, size: 18, color: AppColors.danger),
                  label: const Text(
                    'Lapor Kerusakan Alat (IPSRS)',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.danger),
                  ),
                ),
                const SizedBox(height: 30),
              ] else
                const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

}
