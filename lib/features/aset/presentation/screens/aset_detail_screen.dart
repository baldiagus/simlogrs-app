import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/custom_button.dart';
import '../../../../shared/widgets/status_badge.dart';
import '../../../maintenance/presentation/screens/lapor_cepat_screen.dart';
import '../../../maintenance/presentation/screens/rekam_medis_detail_screen.dart';
import '../../data/models/aset_detail_model.dart';
import '../../data/models/aset_tersedia_model.dart';
import '../providers/aset_provider.dart';
import 'form_peminjaman_aset_screen.dart';

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
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Stiker QR Code Inventaris',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 4),
            const Text(
              'Gunakan QR ini untuk pemindaian fisik dan verifikasi di lapangan.',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            // Physical Sticker Box
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border, width: 2),
                boxShadow: const [
                  BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4)),
                ],
              ),
              child: Column(
                children: [
                  QrImageView(
                    data: aset.kodeAset,
                    version: QrVersions.auto,
                    size: 180,
                    backgroundColor: Colors.white,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    aset.kodeAset,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF0F172A),
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    aset.namaKomoditas,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF334155)),
                    textAlign: TextAlign.center,
                  ),
                  if (aset.nomorSeri != '-') ...[
                    const SizedBox(height: 2),
                    Text(
                      'SN: ${aset.nomorSeri}',
                      style: const TextStyle(fontSize: 11, fontFamily: 'monospace', color: Color(0xFF64748B)),
                    ),
                  ],
                  const SizedBox(height: 12),
                  const Divider(color: Color(0xFFE2E8F0), height: 1),
                  const SizedBox(height: 8),
                  const Text(
                    'SIMLOG RS • REGISTER INVENTARIS',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF64748B),
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            CustomButton(
              text: 'Tutup Stiker',
              onPressed: () => Navigator.pop(ctx),
            ),
          ],
        ),
      ),
    );
  }

  void _showPengembalianModal() {
    if (_aset == null) return;
    final currentAset = _aset!;
    String kondisiKembali = 'BAIK';
    final catatanController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Container(
          padding: EdgeInsets.fromLTRB(
            20,
            20,
            20,
            MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.tintOrangeBg,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(LucideIcons.packageCheck, size: 22, color: AppColors.tintOrange),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Inspeksi Fisik Pengembalian',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          '${currentAset.kodeAset} • ${currentAset.namaKomoditas}',
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Kondisi fisik selector
              const Text(
                'Kondisi Fisik Saat Kembali:',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildKondisiChip('BAIK', 'Baik', kondisiKembali, (v) {
                    setModalState(() => kondisiKembali = v);
                  }),
                  const SizedBox(width: 8),
                  _buildKondisiChip('RUSAK_RINGAN', 'Rusak Ringan', kondisiKembali, (v) {
                    setModalState(() => kondisiKembali = v);
                  }),
                  const SizedBox(width: 8),
                  _buildKondisiChip('RUSAK_BERAT', 'Rusak Berat', kondisiKembali, (v) {
                    setModalState(() => kondisiKembali = v);
                  }),
                ],
              ),
              const SizedBox(height: 16),

              // Catatan
              const Text(
                'Catatan Hasil Pemeriksaan:',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: catatanController,
                maxLines: 2,
                decoration: const InputDecoration(
                  hintText: 'Kelengkapan aksesoris, kebersihan, atau keluhan fisik...',
                ),
              ),
              const SizedBox(height: 20),

              CustomButton(
                text: 'Konfirmasi Pengembalian Selesai',
                icon: const Icon(LucideIcons.checkCheck, size: 18, color: Colors.white),
                onPressed: () async {
                  final messenger = ScaffoldMessenger.of(context);
                  Navigator.pop(ctx);
                  final peminjamanId = currentAset.peminjamanAktif?.peminjamanId;
                  if (peminjamanId == null) return;

                  final notifier = ref.read(asetActionProvider.notifier);
                  final ok = await notifier.konfirmasiPengembalian(
                    peminjamanId: peminjamanId,
                    inspeksi: [
                      {
                        'permintaan_peminjaman_detail_id': peminjamanId,
                        'aset_id': currentAset.id,
                        'kondisi_saat_kembali': kondisiKembali,
                        'catatan': catatanController.text.trim(),
                      }
                    ],
                    catatan: catatanController.text.trim(),
                  );

                  if (!mounted) return;
                  final state = ref.read(asetActionProvider);
                  if (ok) {
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text(state.successMessage ?? 'Pengembalian aset berhasil diproses.'),
                        backgroundColor: AppColors.success,
                      ),
                    );
                    _fetchAset();
                  } else {
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text(state.errorMessage ?? 'Gagal memproses pengembalian.'),
                        backgroundColor: AppColors.danger,
                      ),
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKondisiChip(
    String val,
    String label,
    String currentVal,
    ValueChanged<String> onSelect,
  ) {
    final isSelected = currentVal == val;
    Color color = AppColors.success;
    if (val == 'RUSAK_RINGAN') color = AppColors.warning;
    if (val == 'RUSAK_BERAT') color = AppColors.danger;

    return Expanded(
      child: InkWell(
        onTap: () => onSelect(val),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? color.withValues(alpha: 0.12) : AppColors.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? color : AppColors.border,
              width: isSelected ? 1.5 : 1.0,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
              color: isSelected ? color : AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
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
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null || _aset == null) {
      return Scaffold(
        backgroundColor: AppColors.canvas,
        appBar: AppBar(title: const Text('Profil Aset Fisik')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(LucideIcons.circleAlert, size: 48, color: AppColors.danger),
                const SizedBox(height: 12),
                Text(
                  _errorMessage ?? 'Data aset tidak ditemukan',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _fetchAset,
                  icon: const Icon(LucideIcons.refreshCw, size: 16),
                  label: const Text('Coba Lagi'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final currentAset = _aset!;
    final actionState = ref.watch(asetActionProvider);
    final rupiah = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

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
                        Container(
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
                          ),
                        ),
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
                            Text(
                              'Lihat Stiker QR Inventaris',
                              style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
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

              // 3. Asset Location & Condition Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    _buildInfoRow(
                      icon: LucideIcons.mapPin,
                      label: 'Lokasi Tercatat Saat Ini',
                      value: currentAset.lokasiTercatat,
                    ),
                    const Divider(color: AppColors.border, height: 20),
                    _buildInfoRow(
                      icon: LucideIcons.userCheck,
                      label: 'Penanggung Jawab / Peminjam',
                      value: currentAset.penanggungJawab,
                    ),
                    const Divider(color: AppColors.border, height: 20),
                    _buildInfoRow(
                      icon: LucideIcons.activity,
                      label: 'Kondisi Fisik',
                      value: currentAset.kondisi.replaceAll('_', ' '),
                      badge: StatusBadge(status: currentAset.kondisi),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 4. Spesifikasi & Informasi Finansial Pengadaan
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(LucideIcons.fileSpreadsheet, size: 16, color: AppColors.primaryPurple),
                        SizedBox(width: 8),
                        Text(
                          'Spesifikasi & Nilai Perolehan',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildInfoRow(
                      icon: LucideIcons.tag,
                      label: 'Merek Pabrikan',
                      value: currentAset.merek,
                    ),
                    const Divider(color: AppColors.border, height: 16),
                    _buildInfoRow(
                      icon: LucideIcons.banknote,
                      label: 'Nilai Perolehan Awal',
                      value: currentAset.nilaiPerolehan > 0 ? rupiah.format(currentAset.nilaiPerolehan) : '-',
                    ),
                    const Divider(color: AppColors.border, height: 16),
                    _buildInfoRow(
                      icon: LucideIcons.calendarCheck2,
                      label: 'Tanggal Perolehan RS',
                      value: currentAset.tanggalPerolehan,
                    ),
                    if (currentAset.spesifikasi != '-') ...[
                      const Divider(color: AppColors.border, height: 16),
                      _buildInfoRow(
                        icon: LucideIcons.cpu,
                        label: 'Spesifikasi / Kapasitas',
                        value: currentAset.spesifikasi,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 5. Rekam Jejak Pemeliharaan (IPSRS Track Record)
              InkWell(
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
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Row(
                            children: [
                              Icon(LucideIcons.wrench, size: 16, color: AppColors.primaryPurple),
                              SizedBox(width: 8),
                              Text(
                                'Histori Pemeliharaan (IPSRS)',
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: currentAset.totalRiwayatServis > 0 ? AppColors.tintOrangeBg : AppColors.surfaceSecondary,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '${currentAset.totalRiwayatServis}x Servis',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: currentAset.totalRiwayatServis > 0 ? AppColors.tintOrange : AppColors.textSecondary,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Icon(LucideIcons.chevronRight, size: 16, color: AppColors.primaryPurple),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (currentAset.servisTerakhir != null) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.canvas,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    currentAset.servisTerakhir!.kode,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                      fontFamily: 'monospace',
                                      color: AppColors.primaryPurple,
                                    ),
                                  ),
                                  StatusBadge(status: currentAset.servisTerakhir!.status),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                currentAset.servisTerakhir!.deskripsi,
                                style: const TextStyle(fontSize: 12, color: AppColors.textPrimary),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Tgl: ${currentAset.servisTerakhir!.tanggalPengajuan}',
                                    style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                                  ),
                                  const Row(
                                    children: [
                                      Text(
                                        'Buka Rekam Medis & Preventif',
                                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.primaryPurple),
                                      ),
                                      SizedBox(width: 2),
                                      Icon(LucideIcons.arrowRight, size: 12, color: AppColors.primaryPurple),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ] else ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.canvas,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Belum ada tiket servis. Buka rekam medis & preventif.',
                                style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                              ),
                              Icon(LucideIcons.arrowRight, size: 14, color: AppColors.primaryPurple),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 6. Active Loan Details if DIPINJAM
              if (currentAset.peminjamanAktif != null) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(LucideIcons.repeat, size: 16, color: AppColors.primaryPurple),
                          SizedBox(width: 8),
                          Text(
                            'Transaksi Peminjaman Aktif',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildInfoRow(
                        icon: LucideIcons.fileText,
                        label: 'Kode Peminjaman',
                        value: currentAset.peminjamanAktif!.kodePinjam,
                      ),
                      const Divider(color: AppColors.border, height: 16),
                      _buildInfoRow(
                        icon: LucideIcons.building,
                        label: 'Unit Peminjam',
                        value: currentAset.peminjamanAktif!.unitPeminjam,
                      ),
                      const Divider(color: AppColors.border, height: 16),
                      _buildInfoRow(
                        icon: LucideIcons.calendar,
                        label: 'Batas Rencana Kembali',
                        value: currentAset.peminjamanAktif!.tanggalKembaliRencana ?? '-',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // 7. Contextual Action Buttons
              if (currentAset.isDipinjam && currentAset.peminjamanAktif != null) ...[
                CustomButton(
                  text: 'Kembalikan & Cek Fisik',
                  icon: const Icon(LucideIcons.packageCheck, size: 18, color: Colors.white),
                  isLoading: actionState.isLoading,
                  onPressed: _showPengembalianModal,
                ),
                const SizedBox(height: 10),
              ] else if (currentAset.isTersedia && !currentAset.isRusak) ...[
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

              // Tombol Selalu Ada: Lapor Kerusakan ke IPSRS
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    Widget? badge,
  }) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.canvas,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: AppColors.primaryPurple),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
              ),
            ],
          ),
        ),
        if (badge != null) badge,
      ],
    );
  }
}
