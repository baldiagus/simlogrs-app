import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/empty_state_view.dart';
import '../../../../shared/widgets/status_badge.dart';
import '../../../aset/presentation/screens/aset_detail_screen.dart';
import '../providers/master_barang_provider.dart';

class DetailBarangScreen extends ConsumerWidget {
  final int barangId;
  final String? initialNama;

  const DetailBarangScreen({
    super.key,
    required this.barangId,
    this.initialNama,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(detailBarangProvider(barangId));
    final rupiah = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: Text(initialNama ?? 'Profil Komoditas'),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.refreshCw, size: 18),
            onPressed: () => ref.refresh(detailBarangProvider(barangId)),
          ),
        ],
      ),
      body: detailAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(LucideIcons.circleAlert, size: 48, color: AppColors.danger),
                const SizedBox(height: 12),
                Text(
                  err.toString(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => ref.refresh(detailBarangProvider(barangId)),
                  icon: const Icon(LucideIcons.refreshCw, size: 16),
                  label: const Text('Coba Lagi'),
                ),
              ],
            ),
          ),
        ),
        data: (detail) {
          final b = detail.master;
          final isAset = b.tipe == 'ASET';

          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Hero Card Komoditas
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
                                b.kode,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  fontFamily: 'monospace',
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.18),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                b.tipeLabel,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Text(
                          b.nama,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${b.kategori} • Satuan: ${b.satuan} (${b.simbolSatuan})',
                          style: const TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Estimasi: ${rupiah.format(b.hargaEstimasi)} / ${b.simbolSatuan}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Parameter Logistik & Pengadaan
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
                            Icon(LucideIcons.slidersHorizontal, size: 16, color: AppColors.primaryPurple),
                            SizedBox(width: 8),
                            Text(
                              'Parameter Logistik & Pengadaan',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildRow('Merek Pabrikan', b.merek),
                        const Divider(color: AppColors.border, height: 16),
                        _buildRow('Pemasok Rekanan', b.pemasok),
                        const Divider(color: AppColors.border, height: 16),
                        _buildRow('Harga Beli Terakhir', rupiah.format(b.hargaBeliTerakhir)),
                        const Divider(color: AppColors.border, height: 16),
                        _buildRow('Titik Pesan Ulang (ROP)', '${b.titikPesan} ${b.simbolSatuan}'),
                        const Divider(color: AppColors.border, height: 16),
                        _buildRow('Batas Stok Min / Max', '${b.stokMinimum} / ${b.stokMaksimum} ${b.simbolSatuan}'),
                        if (b.spesifikasi != null && b.spesifikasi!.isNotEmpty) ...[
                          const Divider(color: AppColors.border, height: 16),
                          _buildRow('Spesifikasi Fisik', b.spesifikasi!),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // SEKSI FISIK KOMODITAS: JIKA ASET -> DAFTAR UNIT REGISTER FISIK
                  if (isAset) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(LucideIcons.boxes, size: 18, color: AppColors.primaryPurple),
                            const SizedBox(width: 8),
                            Text(
                              'Unit Register Fisik (${detail.daftarAset.length})',
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                            ),
                          ],
                        ),
                        Text(
                          'Ketuk untuk profil unit',
                          style: TextStyle(fontSize: 11, color: AppColors.textSecondary.withValues(alpha: 0.8)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    if (detail.daftarAset.isEmpty)
                      const EmptyStateView(
                        icon: LucideIcons.box,
                        title: 'Belum Ada Register Unit Fisik',
                        message: 'Komoditas aset ini belum memiliki unit fisik bernomor seri terdaftar.',
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: detail.daftarAset.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (ctx, idx) {
                          final a = detail.daftarAset[idx];
                          return InkWell(
                            onTap: () {
                              // Navigasi langsung ke profil fisik aset AST-...
                              Navigator.push(
                                ctx,
                                MaterialPageRoute(
                                  builder: (_) => AsetDetailScreen(asetId: a.id),
                                ),
                              );
                            },
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryPurple.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(LucideIcons.qrCode, color: AppColors.primaryPurple, size: 22),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              a.kodeAset,
                                              style: const TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w800,
                                                color: AppColors.textPrimary,
                                                fontFamily: 'monospace',
                                              ),
                                            ),
                                            StatusBadge(status: a.status),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'No. Seri: ${a.nomorSeri} • Kondisi: ${a.kondisi}',
                                          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                        ),
                                        const SizedBox(height: 2),
                                        Row(
                                          children: [
                                            const Icon(LucideIcons.mapPin, size: 12, color: AppColors.textSecondary),
                                            const SizedBox(width: 4),
                                            Expanded(
                                              child: Text(
                                                a.lokasi,
                                                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(LucideIcons.chevronRight, size: 18, color: AppColors.textSecondary),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                  ] else ...[
                    // JIKA BUKAN ASET: RINCIAN BATCH GUDANG & SALDO RUANGAN
                    const Row(
                      children: [
                        Icon(LucideIcons.layers, size: 18, color: AppColors.primaryPurple),
                        SizedBox(width: 8),
                        Text(
                          'Persediaan Stok Batch di Gudang',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    if (detail.daftarBatch.isEmpty)
                      const EmptyStateView(
                        icon: LucideIcons.packageOpen,
                        title: 'Stok Gudang Kosong',
                        message: 'Tidak ada batch stok aktif yang tersimpan di rak gudang saat ini.',
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: detail.daftarBatch.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (ctx, idx) {
                          final batch = detail.daftarBatch[idx];
                          return Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppColors.tintBlueBg,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(LucideIcons.barcode, size: 20, color: AppColors.tintBlue),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Batch: ${batch.nomorBatch}',
                                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                                      ),
                                      Text(
                                        '${batch.gudang} (Rak: ${batch.rak}) • Exp: ${batch.tanggalKedaluwarsa ?? '-'}',
                                        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      '${batch.jumlah} ${b.simbolSatuan}',
                                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.primaryPurple),
                                    ),
                                    Text(
                                      rupiah.format(batch.hargaSatuan),
                                      style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    const SizedBox(height: 20),

                    // Saldo Stok di Ruangan
                    const Row(
                      children: [
                        Icon(LucideIcons.building2, size: 18, color: AppColors.primaryPurple),
                        SizedBox(width: 8),
                        Text(
                          'Sebaran Saldo di Ruangan Unit',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    if (detail.daftarRuangan.isEmpty)
                      const EmptyStateView(
                        icon: LucideIcons.building,
                        title: 'Belum Ada Stok di Ruangan',
                        message: 'Barang ini belum didistribusikan ke unit ruangan manapun.',
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: detail.daftarRuangan.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (ctx, idx) {
                          final r = detail.daftarRuangan[idx];
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const Icon(LucideIcons.mapPin, size: 14, color: AppColors.textSecondary),
                                    const SizedBox(width: 8),
                                    Text(
                                      r.unit,
                                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                                    ),
                                  ],
                                ),
                                Text(
                                  '${r.jumlah} ${b.simbolSatuan}',
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                  ],
                  const SizedBox(height: 30),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
        const SizedBox(width: 16),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
          ),
        ),
      ],
    );
  }
}
