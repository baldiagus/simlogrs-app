import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../widgets/qr_sticker_sheet.dart';
import '../widgets/aset_detail_sections.dart';
import '../widgets/aset_riwayat_peminjaman_card.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_error_view.dart';
import '../../../../shared/widgets/app_loading_view.dart';
import '../../../../shared/widgets/custom_button.dart';
import '../../../../shared/widgets/status_badge.dart';
import '../widgets/modal_pengembalian_aset_sheet.dart';
import '../widgets/modal_perpanjang_peminjaman_sheet.dart';
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

              // 7. Contextual Action Buttons
              if (currentAset.isDipinjam && currentAset.peminjamanAktif != null) ...[
                Row(
                  children: [
                    Expanded(
                      flex: 2,
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
                ),
                const SizedBox(height: 10),
              ] else if (!isTeknisi && currentAset.isTersedia && !currentAset.isRusak) ...[
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
                      tipePenyedia: currentAset.lokasiTercatat.contains('Rak:') ? 'GUDANG' : 'RUANGAN',
                      namaPenyedia: currentAset.penanggungJawab,
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
              ],

              // Tombol Lapor Kerusakan ke IPSRS (Hanya untuk non-teknisi / pemohon ruangan)
              if (!isTeknisi) ...[
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
