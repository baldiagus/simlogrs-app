import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/aset_tersedia_model.dart';

/// Tahap 1 form pengalihan aset: lokasi tujuan terkunci dan pilihan aset sumber.
class ModalPengalihanAsetTahap1Card extends StatelessWidget {
  final String lokasiTujuanUser;
  final bool isAsetPreselected;
  final AsetTersediaModel? chosenAset;
  final AsyncValue<List<AsetTersediaModel>> katalogAsync;
  final void Function(List<AsetTersediaModel> asets, int? id) onAsetChanged;

  const ModalPengalihanAsetTahap1Card({
    super.key,
    required this.lokasiTujuanUser,
    required this.isAsetPreselected,
    required this.chosenAset,
    required this.katalogAsync,
    required this.onAsetChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.canvas,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tahap 1: Komoditas & Fasilitas Asal (Sumber)',
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary),
          ),
          const SizedBox(height: 10),

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(LucideIcons.lock, size: 13, color: AppColors.textMuted),
                  SizedBox(width: 5),
                  Text(
                    'Lokasi Tujuan (Terkunci):',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textMuted),
                  ),
                ],
              ),
              const SizedBox(height: 3),
              Text(
                lokasiTujuanUser,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Pilihan Aset Sumber
          if (isAsetPreselected && chosenAset != null) ...[
            _ChosenAsetInfo(
              aset: chosenAset!,
              spacing: 4,
              asalLabel: 'Fasilitas Asal (Sumber): ${chosenAset!.namaPenyedia}',
            ),
          ] else ...[
            katalogAsync.when(
              data: (asets) {
                if (asets.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      'Tidak ada aset fisik tersedia dari fasilitas lain yang siap dialihkan.',
                      style: TextStyle(fontSize: 12, color: AppColors.warning),
                    ),
                  );
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _AsetAsalDropdown(
                      asets: asets,
                      chosenAset: chosenAset,
                      onChanged: (val) => onAsetChanged(asets, val),
                    ),
                    if (chosenAset != null) ...[
                      const SizedBox(height: 10),
                      _ChosenAsetInfo(
                        aset: chosenAset!,
                        spacing: 3,
                        asalLabel:
                            'Fasilitas Asal (Sumber): ${chosenAset!.namaPenyedia} • Kondisi: ${chosenAset!.kondisi}',
                      ),
                    ],
                  ],
                );
              },
              loading: () => const LinearProgressIndicator(),
              error: (_, __) =>
                  const Text('Gagal memuat katalog aset tersedia'),
            ),
          ],
        ],
      ),
    );
  }
}

class _AsetAsalDropdown extends StatelessWidget {
  final List<AsetTersediaModel> asets;
  final AsetTersediaModel? chosenAset;
  final ValueChanged<int?> onChanged;

  const _AsetAsalDropdown({
    required this.asets,
    required this.chosenAset,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<int>(
      key: const Key('dropdown_aset_asal'),
      isExpanded: true,
      initialValue: chosenAset?.id,
      decoration: const InputDecoration(
        labelText: 'Pilih Aset dari Fasilitas Lain (Sumber) *',
        prefixIcon: Icon(LucideIcons.armchair, size: 18),
      ),
      selectedItemBuilder: (context) {
        return asets.map((a) {
          return Text(
            '${a.namaKomoditas} (${a.kodeAset}) - ${a.namaPenyedia}',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            overflow: TextOverflow.ellipsis,
          );
        }).toList();
      },
      items: asets.map((a) {
        return DropdownMenuItem<int>(
          value: a.id,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        a.namaKomoditas,
                        style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: AppColors.tintVioletBg,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        a.tipePenyedia,
                        style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryPurple),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${a.kodeAset} • ${a.namaPenyedia}',
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.textSecondary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }
}

class _ChosenAsetInfo extends StatelessWidget {
  final AsetTersediaModel aset;
  final double spacing;
  final String asalLabel;

  const _ChosenAsetInfo({
    required this.aset,
    required this.spacing,
    required this.asalLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  aset.namaKomoditas,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w700),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.tintVioletBg,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  aset.tipePenyedia,
                  style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryPurple),
                ),
              ),
            ],
          ),
          SizedBox(height: spacing),
          Text(
            'Kode: ${aset.kodeAset} • SN: ${aset.nomorSeri}',
            style:
                const TextStyle(fontSize: 11, color: AppColors.textSecondary),
          ),
          SizedBox(height: spacing),
          Text(
            asalLabel,
            style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary),
          ),
        ],
      ),
    );
  }
}
