import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_quantity_stepper.dart';
import '../../data/models/po_inbound_model.dart';
import '../../data/models/rak_model.dart';

/// Tile input satu item penerimaan PO: jumlah diterima, nomor batch, tanggal kedaluwarsa, dan rak tujuan.
class InboundItemDraftTile extends StatelessWidget {
  final InboundItemDraft draft;
  final AsyncValue<List<RakModel>> rakListAsync;
  final VoidCallback onPickExpiredDate;
  final VoidCallback onPickRak;
  final ValueChanged<int> onQuantityChanged;
  final ValueChanged<int>? onRusakChanged;
  final ValueChanged<String>? onBatchChanged;
  final VoidCallback? onRetryRak;
  final String? rakUnavailableMessage;
  final int? gudangPenerimaId;
  final String? namaGudangPenerima;

  const InboundItemDraftTile({
    super.key,
    required this.draft,
    required this.rakListAsync,
    required this.onPickExpiredDate,
    required this.onPickRak,
    required this.onQuantityChanged,
    this.onRusakChanged,
    this.onBatchChanged,
    this.onRetryRak,
    this.rakUnavailableMessage,
    this.gudangPenerimaId,
    this.namaGudangPenerima,
  });

  /// Membangun form draft item penerimaan; pilihan rak diambil dari [rakListAsync].
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Header: Icon Box + Nama Barang + Meta Info (Sesuai Desain Acuan)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.tintBlueBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(LucideIcons.package, size: 20, color: AppColors.tintBlue),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      draft.poItem.namaBarang,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${draft.poItem.kodeBarang} • Pesan: ${draft.poItem.jumlahDipesan} ${draft.poItem.satuan} (Sisa: ${draft.poItem.sisaKebutuhan})',
                      style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // 2. Baris Satuan & Stepper Qty (Bersih tanpa teks terlipat di kolom sempit)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Satuan: ${draft.poItem.satuan}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              AppQuantityStepper(
                value: draft.jumlahDiterima,
                min: 0,
                max: draft.poItem.sisaKebutuhan,
                onChanged: onQuantityChanged,
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 2b. Jumlah Rusak: 0 <= rusak <= jumlah diterima (sama dengan validasi backend)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Jumlah Rusak (${draft.poItem.satuan}):',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Stok bersih: ${draft.jumlahDiterima - draft.jumlahRusak} ${draft.poItem.satuan}',
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              AppQuantityStepper(
                key: const ValueKey('jumlah-rusak-stepper'),
                value: draft.jumlahRusak,
                min: 0,
                max: draft.jumlahDiterima,
                onChanged: (v) {
                  final clamped = v.clamp(0, draft.jumlahDiterima);
                  draft.jumlahRusak = clamped;
                  onRusakChanged?.call(clamped);
                },
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: AppColors.border),
          const SizedBox(height: 14),

          // 3. Form Logistik: Nomor Batch Fisik & Tgl Expired (ED)
          Row(
            children: [
              // Nomor Batch Fisik
              Expanded(
                flex: 4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Nomor Batch Fisik *',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      initialValue: draft.nomorBatch,
                      onChanged: (v) {
                        draft.nomorBatch = v.trim();
                        onBatchChanged?.call(v.trim());
                      },
                      decoration: const InputDecoration(
                        hintText: 'misal: B-1234',
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),

              // Tanggal Expired (ED)
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Tgl Expired (ED)',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 6),
                    InkWell(
                      onTap: onPickExpiredDate,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        height: 44,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceSecondary,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: Text(
                                draft.tanggalKedaluwarsa ?? 'Non-Exp',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: draft.tanggalKedaluwarsa != null
                                      ? AppColors.textPrimary
                                      : AppColors.textMuted,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const Icon(LucideIcons.calendar, size: 14, color: AppColors.textSecondary),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 4. Rak Simpan Gudang (Full Width agar nama rak tidak terpotong)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Rak Simpan Gudang *',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 6),
              if (rakUnavailableMessage != null)
                Text(rakUnavailableMessage!, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary))
              else
                rakListAsync.when(
                  skipLoadingOnRefresh: false,
                  data: (raks) {
                    if (raks.isEmpty) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Tidak ada rak aktif di gudang penerima.', style: TextStyle(fontSize: 11)),
                          if (onRetryRak != null)
                            TextButton(onPressed: onRetryRak, child: const Text('Coba lagi rak')),
                        ],
                      );
                    }
                    final index = raks.indexWhere((r) => r.id == draft.lokasiGudangId);
                    final selected = index < 0 ? null : raks[index];
                    var warehouseName = selected?.namaGudang.trim() ?? '';
                    if ((warehouseName.isEmpty || warehouseName == '-') &&
                        selected?.gudangId == gudangPenerimaId) {
                      warehouseName = namaGudangPenerima?.trim() ?? '';
                    }
                    return Semantics(
                      button: true,
                      child: InkWell(
                        key: ValueKey('pilih-rak-${draft.poItem.id}'),
                        onTap: onPickRak,
                        borderRadius: BorderRadius.circular(12),
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      selected == null ? 'Pilih rak simpan' : '${selected.kode} (${selected.nama})',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                    if (selected != null)
                                      Text(
                                        warehouseName.isEmpty || warehouseName == '-'
                                            ? 'Informasi gudang belum tersedia'
                                            : 'Gudang: $warehouseName',
                                        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                      ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(LucideIcons.search, size: 18, color: AppColors.textSecondary),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                  loading: () => const Text('Memuat rak gudang...', style: TextStyle(fontSize: 11)),
                  error: (_, __) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Gagal memuat rak gudang.', style: TextStyle(fontSize: 11, color: AppColors.danger)),
                      if (onRetryRak != null)
                        TextButton(onPressed: onRetryRak, child: const Text('Coba lagi rak')),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
