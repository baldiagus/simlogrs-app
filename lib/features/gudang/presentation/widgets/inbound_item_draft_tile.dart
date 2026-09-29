import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/po_inbound_model.dart';
import '../../data/models/rak_model.dart';

class InboundItemDraftTile extends StatelessWidget {
  final InboundItemDraft draft;
  final AsyncValue<List<RakModel>> rakListAsync;
  final VoidCallback onPickExpiredDate;
  final ValueChanged<int?> onRakChanged;

  const InboundItemDraftTile({
    super.key,
    required this.draft,
    required this.rakListAsync,
    required this.onPickExpiredDate,
    required this.onRakChanged,
  });

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
          // Barang Name & Order Info
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
          const Divider(height: 1, color: AppColors.border),
          const SizedBox(height: 12),

          // Qty & Batch Inputs Row
          Row(
            children: [
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Qty Diterima',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    TextFormField(
                      initialValue: '${draft.jumlahDiterima}',
                      keyboardType: TextInputType.number,
                      onChanged: (v) => draft.jumlahDiterima = int.tryParse(v) ?? 0,
                      decoration: InputDecoration(
                        suffixText: draft.poItem.satuan,
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Nomor Batch Fisik',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    TextFormField(
                      initialValue: draft.nomorBatch,
                      onChanged: (v) => draft.nomorBatch = v.trim(),
                      decoration: const InputDecoration(
                        hintText: 'misal: B-1234',
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Shelf Location Picker & Expired Date Row
          Row(
            children: [
              // Shelf / Rak Dropdown
              Expanded(
                flex: 4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Rak Simpan Gudang *',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    rakListAsync.when(
                      data: (raks) {
                        if (draft.lokasiGudangId == null && raks.isNotEmpty) {
                          draft.lokasiGudangId = raks.first.id;
                        }
                        return DropdownButtonFormField<int>(
                          initialValue: draft.lokasiGudangId,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            contentPadding:
                                EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                          ),
                          items: raks.map((r) {
                            return DropdownMenuItem<int>(
                              value: r.id,
                              child: Text(
                                '${r.kode} (${r.nama})',
                                style: const TextStyle(fontSize: 12),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList(),
                          onChanged: onRakChanged,
                        );
                      },
                      loading: () => const SizedBox(
                        height: 40,
                        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                      ),
                      error: (_, __) => const Text('Gagal memuat rak',
                          style: TextStyle(fontSize: 11, color: AppColors.danger)),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),

              // Expired Date Picker Button
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Tgl Expired (ED)',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
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
                            const Icon(LucideIcons.calendar,
                                size: 14, color: AppColors.textSecondary),
                          ],
                        ),
                      ),
                    ),
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
