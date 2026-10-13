import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/empty_state_view.dart';
import '../../../../shared/widgets/status_badge.dart';
import '../../data/models/aset_detail_model.dart';
import '../providers/aset_provider.dart';

/// Halaman histori mutasi/pengalihan sebuah aset antar ruangan atau fasilitas.
class HistoriPengalihanAsetScreen extends ConsumerStatefulWidget {
  final int asetId;
  final String kodeAset;
  final String namaKomoditas;
  final String nomorSeri;
  final List<RiwayatPengalihanAsetItemModel> initialRiwayat;

  /// Membuat layar histori; riwayat awal opsional untuk tampilan instan sebelum refresh.
  const HistoriPengalihanAsetScreen({
    super.key,
    required this.asetId,
    required this.kodeAset,
    required this.namaKomoditas,
    required this.nomorSeri,
    this.initialRiwayat = const [],
  });

  /// Membuat state layar histori pengalihan aset.
  @override
  ConsumerState<HistoriPengalihanAsetScreen> createState() =>
      _HistoriPengalihanAsetScreenState();
}

/// State histori pengalihan: menyimpan riwayat dan memuat ulang dari server.
class _HistoriPengalihanAsetScreenState
    extends ConsumerState<HistoriPengalihanAsetScreen> {
  late List<RiwayatPengalihanAsetItemModel> _riwayat;
  bool _isLoading = false;

  /// Mengisi riwayat awal dari `initialRiwayat`.
  @override
  void initState() {
    super.initState();
    _riwayat = widget.initialRiwayat;
  }

  /// Mengambil ulang riwayat pengalihan terbaru dari server; gagal diabaikan agar data lama tetap tampil.
  Future<void> _fetchLatest() async {
    setState(() => _isLoading = true);
    try {
      final repo = ref.read(asetRepositoryProvider);
      final detail = await repo.getDetailAset(widget.asetId);
      if (mounted) {
        setState(() {
          _riwayat = detail.riwayatPengalihan;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Membangun halaman histori mutasi aset: daftar pengalihan atau tampilan kosong.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: Text('Histori Mutasi: ${widget.kodeAset}'),
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
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white24,
                                borderRadius: BorderRadius.circular(8),
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
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(LucideIcons.arrowRightLeft, size: 12, color: AppColors.primaryPurple),
                                const SizedBox(width: 4),
                                Text(
                                  '${_riwayat.length}x Mutasi',
                                  style: const TextStyle(
                                    color: AppColors.primaryPurple,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        widget.namaKomoditas,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Nomor Seri Fisik: ${widget.nomorSeri}',
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Section Title
                const Row(
                  children: [
                    Icon(LucideIcons.gitCommit, size: 18, color: AppColors.primaryPurple),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Jejak Kronologis Perpindahan Fisik',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                if (_isLoading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 32),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (_riwayat.isEmpty)
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.45,
                    child: const EmptyStateView(
                      icon: LucideIcons.arrowRightLeft,
                      title: 'Belum Ada Riwayat Mutasi',
                      message: 'Aset ini belum pernah dialihkan ke ruangan atau fasilitas lain sejak registrasi perolehan.',
                    ),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _riwayat.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final item = _riwayat[index];
                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: AppColors.border),
                          boxShadow: const [
                            BoxShadow(
                              color: Color.fromRGBO(15, 23, 42, 0.03),
                              blurRadius: 8,
                              offset: Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header Row
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Flexible(
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: AppColors.tintVioletBg,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: const Icon(
                                          LucideIcons.fileCheck2,
                                          size: 14,
                                          color: AppColors.primaryPurple,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Flexible(
                                        child: Text(
                                          item.kodePengalihan,
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w800,
                                            fontFamily: 'monospace',
                                            color: AppColors.primaryPurple,
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
                            const Divider(height: 20, color: AppColors.border),

                            // Route Display Card
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.canvas,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      const Icon(LucideIcons.circleDot, size: 14, color: AppColors.textSecondary),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Text('Fasilitas Asal (Sumber):',
                                                style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
                                            Text(
                                              item.asalNama,
                                              style: const TextStyle(
                                                  fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 4),
                                    child: Row(
                                      children: [
                                        SizedBox(width: 6),
                                        Icon(LucideIcons.arrowDown, size: 14, color: AppColors.primaryPurple),
                                      ],
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      const Icon(LucideIcons.mapPin, size: 14, color: AppColors.primaryPurple),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Text('Fasilitas Tujuan (Penerima):',
                                                style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
                                            Text(
                                              item.tujuanNama,
                                              style: const TextStyle(
                                                  fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primaryPurple),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Detail Meta Info
                            _buildMetaRow(
                              LucideIcons.calendarCheck,
                              'Tanggal Serah Terima',
                              item.tanggalSerahTerima,
                            ),
                            const SizedBox(height: 6),
                            _buildMetaRow(
                              LucideIcons.userCheck,
                              'Penerima Fisik',
                              item.penerima,
                            ),
                            const SizedBox(height: 6),
                            _buildMetaRow(
                              LucideIcons.shieldCheck,
                              'Kondisi Saat Diterima',
                              item.kondisiSaatDiterima,
                              valueColor: item.kondisiSaatDiterima == 'BAIK'
                                  ? AppColors.success
                                  : AppColors.warning,
                            ),
                            const SizedBox(height: 6),
                            _buildMetaRow(
                              LucideIcons.helpCircle,
                              'Dasar Pengalihan',
                              item.alasan,
                            ),
                            if (item.catatan != null && item.catatan!.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              _buildMetaRow(
                                LucideIcons.messageSquare,
                                'Catatan BAST',
                                item.catatan!,
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Membangun satu baris metadata (ikon, label, nilai) pada kartu riwayat mutasi.
  Widget _buildMetaRow(IconData icon, String label, String value, {Color? valueColor}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(icon, size: 13, color: AppColors.textMuted),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text.rich(
            TextSpan(
              text: '$label: ',
              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
              children: [
                TextSpan(
                  text: value,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: valueColor ?? AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
