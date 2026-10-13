import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/empty_state_view.dart';
import '../../../../shared/widgets/status_badge.dart';
import '../../data/models/aset_detail_model.dart';
import '../providers/aset_provider.dart';

/// Halaman histori sirkulasi (peminjaman) sebuah aset.
class HistoriSirkulasiAsetScreen extends ConsumerStatefulWidget {
  final int asetId;
  final String kodeAset;
  final String namaKomoditas;
  final String nomorSeri;
  final List<RiwayatPeminjamanAsetItemModel> initialRiwayat;

  /// Membuat layar histori; riwayat awal opsional untuk tampilan instan sebelum refresh.
  const HistoriSirkulasiAsetScreen({
    super.key,
    required this.asetId,
    required this.kodeAset,
    required this.namaKomoditas,
    required this.nomorSeri,
    this.initialRiwayat = const [],
  });

  /// Membuat state layar histori sirkulasi aset.
  @override
  ConsumerState<HistoriSirkulasiAsetScreen> createState() =>
      _HistoriSirkulasiAsetScreenState();
}

/// State histori sirkulasi: menyimpan riwayat dan memuat ulang dari server.
class _HistoriSirkulasiAsetScreenState
    extends ConsumerState<HistoriSirkulasiAsetScreen> {
  late List<RiwayatPeminjamanAsetItemModel> _riwayat;
  bool _isLoading = false;

  /// Mengisi riwayat awal dari `initialRiwayat`.
  @override
  void initState() {
    super.initState();
    _riwayat = widget.initialRiwayat;
  }

  /// Mengambil ulang riwayat peminjaman terbaru dari server; gagal diabaikan agar data lama tetap tampil.
  Future<void> _fetchLatest() async {
    setState(() => _isLoading = true);
    try {
      final repo = ref.read(asetRepositoryProvider);
      final detail = await repo.getDetailAset(widget.asetId);
      if (mounted) {
        setState(() {
          _riwayat = detail.riwayatPeminjaman;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Membangun halaman histori sirkulasi aset: kartu ringkasan dan daftar riwayat peminjaman.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: Text('Histori Sirkulasi: ${widget.kodeAset}'),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.refreshCw, size: 18),
            tooltip: 'Muat ulang',
            onPressed: _fetchLatest,
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _fetchLatest,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Hero Header Card
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryHeroGradient,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Container(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white24,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                widget.kodeAset,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  fontFamily: 'monospace',
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${_riwayat.length}x Dipinjam',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        widget.namaKomoditas,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Nomor Seri: ${widget.nomorSeri}',
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Section Title
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Expanded(
                      child: Text(
                        'Buku Catatan Sirkulasi Unit',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Linimasa Penggunaan',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                if (_isLoading && _riwayat.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(40),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primaryPurple,
                      ),
                    ),
                  )
                else if (_riwayat.isEmpty)
                  const EmptyStateView(
                    icon: LucideIcons.calendarCheck,
                    title: 'Belum Ada Transaksi Peminjaman',
                    message:
                        'Alat fisik ini belum pernah tercatat dipinjam oleh ruangan manapun.',
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _riwayat.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (ctx, i) {
                      final item = _riwayat[i];
                      final isReturned = item.status == 'SELESAI';

                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Flexible(
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        LucideIcons.repeat,
                                        size: 16,
                                        color: AppColors.primaryPurple,
                                      ),
                                      const SizedBox(width: 8),
                                      Flexible(
                                        child: Text(
                                          item.kodePeminjaman,
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w800,
                                            fontFamily: 'monospace',
                                            color: AppColors.textPrimary,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                StatusBadge(status: item.status),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Peminjam: ${item.unitPeminjam}',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Penanggung Jawab: ${item.peminjam}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const Divider(color: AppColors.border, height: 18),
                            _buildInfoRow(
                              icon: LucideIcons.calendar,
                              label: 'Masa Pinjam',
                              value:
                                  '${item.tanggalPinjam} s/d ${item.tanggalKembaliRencana}',
                            ),
                            if (item.keperluan.isNotEmpty && item.keperluan != '-') ...[
                              const SizedBox(height: 6),
                              _buildInfoRow(
                                icon: LucideIcons.fileText,
                                label: 'Keperluan',
                                value: item.keperluan,
                              ),
                            ],
                            if (isReturned && item.tanggalKembaliAktual != null) ...[
                              const SizedBox(height: 12),
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
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Expanded(
                                          child: Row(
                                            children: [
                                              Icon(
                                                LucideIcons.packageCheck,
                                                size: 15,
                                                color: AppColors.success,
                                              ),
                                              SizedBox(width: 6),
                                              Expanded(
                                                child: Text(
                                                  'Pengembalian Fisik',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w700,
                                                    color: AppColors.textPrimary,
                                                  ),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        if (item.kondisiSaatKembali != null)
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: item.kondisiSaatKembali ==
                                                      'BAIK'
                                                  ? const Color(0xFFECFDF5)
                                                  : const Color(0xFFFEF2F2),
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              item.kondisiSaatKembali!
                                                  .replaceAll('_', ' '),
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w700,
                                                color: item.kondisiSaatKembali ==
                                                        'BAIK'
                                                    ? AppColors.success
                                                    : AppColors.danger,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      'Dikembalikan pada: ${item.tanggalKembaliAktual!}',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                    if (item.pemeriksaKembali != null)
                                      Text(
                                        'Pemeriksa: ${item.pemeriksaKembali}',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    if (item.catatanPengembalian != null &&
                                        item.catatanPengembalian!.isNotEmpty)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 4),
                                        child: Text(
                                          'Catatan: "${item.catatanPengembalian!}"',
                                          style: const TextStyle(
                                            fontSize: 11,
                                            fontStyle: FontStyle.italic,
                                            color: AppColors.textMuted,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Membangun satu baris info (ikon, label, nilai) pada kartu riwayat sirkulasi.
  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 14, color: AppColors.textSecondary),
        const SizedBox(width: 8),
        SizedBox(
          width: 90,
          child: Text(
            label,
            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
          ),
        ),
        const Text(': ',
            style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}
