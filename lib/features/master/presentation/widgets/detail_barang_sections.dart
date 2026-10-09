import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/app_formatters.dart';
import '../../../../shared/widgets/empty_state_view.dart';
import '../../../../shared/widgets/status_badge.dart';
import '../../../aset/presentation/screens/aset_detail_screen.dart';
import '../../data/models/master_barang_item_model.dart';

class DetailBarangParamCard extends StatelessWidget {
  final MasterBarangItemModel b;

  const DetailBarangParamCard({super.key, required this.b});

  Widget _buildRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 4,
          child: Text(
            label,
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 5,
          child: Text(
            value,
            style: const TextStyle(
                fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
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
              Expanded(
                child: Text(
                  'Parameter Logistik & Pengadaan',
                  style: TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildRow('Merek Pabrikan', b.merek.isEmpty || b.merek == '-' ? '-' : b.merek),
          const Divider(color: AppColors.border, height: 16),
          _buildRow(
              'Pemasok Rekanan',
              b.pemasok.isEmpty || b.pemasok == '-'
                  ? 'Belum ditentukan'
                  : b.pemasok),
          const Divider(color: AppColors.border, height: 16),
          _buildRow(
              'Harga Beli Terakhir',
              b.hargaBeliTerakhir > 0
                  ? AppFormatters.rupiah(b.hargaBeliTerakhir)
                  : 'Belum ada riwayat'),
          const Divider(color: AppColors.border, height: 16),
          _buildRow(
              'Titik Pesan Ulang (ROP)',
              b.titikPesan > 0
                  ? '${b.titikPesan} ${b.simbolSatuan}'
                  : '- (Tanpa Batas)'),
          const Divider(color: AppColors.border, height: 16),
          _buildRow(
              'Batas Stok Min / Max',
              (b.stokMinimum <= 0 && b.stokMaksimum <= 0)
                  ? '- (Tanpa Batas)'
                  : '${b.stokMinimum > 0 ? b.stokMinimum : "-"} / ${b.stokMaksimum > 0 ? b.stokMaksimum : "-"} ${b.simbolSatuan}'),
          if (b.spesifikasi != null && b.spesifikasi!.isNotEmpty) ...[
            const Divider(color: AppColors.border, height: 16),
            _buildRow('Spesifikasi Fisik', b.spesifikasi!),
          ],
        ],
      ),
    );
  }
}

class DetailBarangAsetList extends StatelessWidget {
  final List<DaftarAsetFisikItem> daftarAset;

  const DetailBarangAsetList({super.key, required this.daftarAset});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(LucideIcons.boxes, size: 18, color: AppColors.primaryPurple),
                const SizedBox(width: 8),
                Text(
                  'Unit Register Fisik (${daftarAset.length})',
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                ),
              ],
            ),
            Text(
              'Ketuk untuk profil unit',
              style: TextStyle(
                  fontSize: 11, color: AppColors.textSecondary.withValues(alpha: 0.8)),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (daftarAset.isEmpty)
          const EmptyStateView(
            icon: LucideIcons.box,
            title: 'Belum Ada Register Unit Fisik',
            message: 'Komoditas aset ini belum memiliki unit fisik bernomor seri terdaftar.',
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: daftarAset.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (ctx, idx) {
              final a = daftarAset[idx];
              return InkWell(
                onTap: () {
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
                          color: AppColors.tintVioletBg,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(LucideIcons.qrCode,
                            color: AppColors.tintViolet, size: 22),
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
                                StatusBadge(status: a.kondisi),
                              ],
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'SN: ${a.nomorSeri} • ${a.lokasi}',
                              style: const TextStyle(
                                  fontSize: 11, color: AppColors.textSecondary),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}

class DetailBarangBatchList extends StatelessWidget {
  final List<DaftarBatchItem> daftarBatch;
  final String simbolSatuan;

  const DetailBarangBatchList({
    super.key,
    required this.daftarBatch,
    required this.simbolSatuan,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(LucideIcons.layers, size: 18, color: AppColors.primaryPurple),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Persediaan Stok Batch di Gudang',
                style: TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (daftarBatch.isEmpty)
          const EmptyStateView(
            icon: LucideIcons.packageOpen,
            title: 'Stok Gudang Kosong',
            message: 'Tidak ada batch stok aktif yang tersimpan di rak gudang saat ini.',
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: daftarBatch.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (ctx, idx) {
              final batch = daftarBatch[idx];
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
                            style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary),
                          ),
                          Text(
                            '${batch.gudang} (Rak: ${batch.rak}) • Exp: ${batch.tanggalKedaluwarsa ?? "-"}',
                            style: const TextStyle(
                                fontSize: 11, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${batch.jumlah} $simbolSatuan',
                          style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primaryPurple),
                        ),
                        Text(
                          AppFormatters.rupiah(batch.hargaSatuan),
                          style: const TextStyle(
                              fontSize: 10, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }
}

class DetailBarangRuanganList extends StatelessWidget {
  final List<DaftarRuanganItem> daftarRuangan;
  final String simbolSatuan;

  const DetailBarangRuanganList({
    super.key,
    required this.daftarRuangan,
    required this.simbolSatuan,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(LucideIcons.building2, size: 18, color: AppColors.primaryPurple),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Sebaran Saldo di Ruangan Unit',
                style: TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (daftarRuangan.isEmpty)
          const EmptyStateView(
            icon: LucideIcons.building,
            title: 'Belum Ada Stok di Ruangan',
            message: 'Barang ini belum didistribusikan ke unit ruangan manapun.',
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: daftarRuangan.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (ctx, idx) {
              final r = daftarRuangan[idx];
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
                    Expanded(
                      child: Row(
                        children: [
                          const Icon(LucideIcons.mapPin,
                              size: 14, color: AppColors.textSecondary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              r.unit,
                              style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${r.jumlah} $simbolSatuan',
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary),
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }
}
