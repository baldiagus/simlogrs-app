import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/aset_tersedia_model.dart';

/// Tahap 1 form pengalihan aset: lokasi tujuan terkunci dan pilihan 2-step aset sumber (komoditas & fasilitas).
class ModalPengalihanAsetTahap1Card extends StatelessWidget {
  final String lokasiTujuanUser;
  final bool isAsetPreselected;
  final String? selectedKomoditas;
  final AsetTersediaModel? chosenAset;
  final AsyncValue<List<AsetTersediaModel>> katalogAsync;
  final ValueChanged<String?> onKomoditasChanged;
  final void Function(AsetTersediaModel aset, int count) onFacilityChanged;

  /// Membuat kartu tahap 1 dengan data lokasi tujuan, komoditas, fasilitas, dan aset terpilih.
  const ModalPengalihanAsetTahap1Card({
    super.key,
    required this.lokasiTujuanUser,
    required this.isAsetPreselected,
    required this.selectedKomoditas,
    required this.chosenAset,
    required this.katalogAsync,
    required this.onKomoditasChanged,
    required this.onFacilityChanged,
  });

  /// Membangun kartu tahap 1: lokasi tujuan terkunci dan pemilih 2-step komoditas serta fasilitas asal.
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
          Text(
            'Tahap 1: Komoditas & Fasilitas Asal (Sumber)',
            style: Theme.of(context).textTheme.labelMedium,
          ),
          const SizedBox(height: 10),

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(LucideIcons.lock, size: 13, color: AppColors.textSecondary),
                  SizedBox(width: 5),
                  Text(
                    'Lokasi Tujuan (Terkunci):',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ),
              const SizedBox(height: 3),
              Text(
                lokasiTujuanUser,
                style: Theme.of(context).textTheme.titleSmall,
                maxLines: 2,
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
                  return Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      'Tidak ada aset fisik tersedia dari fasilitas lain yang siap dialihkan.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.warning),
                    ),
                  );
                }

                final uniqueKomoditas =
                    asets.map((a) => a.namaKomoditas).toSet().toList();

                final matchingAssets = selectedKomoditas != null
                    ? asets
                        .where((a) =>
                            a.namaKomoditas.trim().toLowerCase() ==
                            selectedKomoditas!.trim().toLowerCase())
                        .toList()
                    : <AsetTersediaModel>[];

                final Map<String, List<AsetTersediaModel>> facilityMap = {};
                for (final a in matchingAssets) {
                  final key =
                      '${a.tipePenyedia}_${a.penyediaId ?? a.namaPenyedia}';
                  facilityMap.putIfAbsent(key, () => []).add(a);
                }

                final currentFacilityKey = chosenAset != null
                    ? '${chosenAset!.tipePenyedia}_${chosenAset!.penyediaId ?? chosenAset!.namaPenyedia}'
                    : null;
                final validFacilityKey =
                    facilityMap.containsKey(currentFacilityKey)
                        ? currentFacilityKey
                        : null;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Step 1: select asset commodity
                    DropdownButtonFormField<String>(
                      key: const Key('dropdown_komoditas_aset'),
                      isExpanded: true,
                      itemHeight: null,
                      initialValue: selectedKomoditas,
                      decoration: const InputDecoration(
                        labelText: 'Pilih Komoditas Aset *',
                        prefixIcon: Icon(LucideIcons.armchair, size: 18),
                      ),
                      items: uniqueKomoditas.map((k) {
                        return DropdownMenuItem<String>(
                          value: k,
                          child: Text(
                            k,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        );
                      }).toList(),
                      onChanged: onKomoditasChanged,
                      validator: (v) =>
                          v == null ? 'Pilih komoditas aset' : null,
                    ),
                    const SizedBox(height: 12),

                    // Step 2: select origin provider facility
                    DropdownButtonFormField<String>(
                      key: const Key('dropdown_penyedia_asal_aset'),
                      isExpanded: true,
                      itemHeight: null,
                      initialValue: validFacilityKey,
                      decoration: const InputDecoration(
                        labelText: 'Fasilitas Asal Penyedia (Sumber) *',
                        prefixIcon: Icon(LucideIcons.building, size: 18),
                      ),
                      hint: selectedKomoditas == null
                          ? const Text('Pilih komoditas aset terlebih dahulu')
                          : null,
                      items: selectedKomoditas == null
                          ? const []
                          : facilityMap.entries.map((entry) {
                              final facilityAssets = entry.value;
                              final firstAset = facilityAssets.first;
                              final count = facilityAssets.length;
                              return DropdownMenuItem<String>(
                                value: entry.key,
                                child: Text(
                                  '${firstAset.namaPenyedia} (${firstAset.tipePenyedia}) - $count unit',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              );
                            }).toList(),
                      onChanged: selectedKomoditas == null
                          ? null
                          : (key) {
                              if (key != null && facilityMap.containsKey(key)) {
                                final items = facilityMap[key]!;
                                onFacilityChanged(items.first, items.length);
                              }
                            },
                      validator: (v) =>
                          v == null ? 'Pilih fasilitas asal' : null,
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

/// Panel ringkasan informasi aset fisik yang dipilih pada tahap 1.
class _ChosenAsetInfo extends StatelessWidget {
  final AsetTersediaModel aset;
  final double spacing;
  final String asalLabel;

  /// Membuat panel info aset terpilih dengan jarak dan label asal.
  const _ChosenAsetInfo({
    required this.aset,
    required this.spacing,
    required this.asalLabel,
  });

  /// Membangun ringkasan aset terpilih (nama, kode, lokasi asal) agar user bisa memverifikasi sebelum mengajukan.
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
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
                  style: Theme.of(context).textTheme.titleSmall,
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
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(color: AppColors.primaryPurple),
                ),
              ),
            ],
          ),
          SizedBox(height: spacing),
          Text(
            'Kode: ${aset.kodeAset} • SN: ${aset.nomorSeri}',
            style:
                Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary, fontFamily: 'JetBrains Mono'),
          ),
          SizedBox(height: spacing),
          Text(
            asalLabel,
            style: Theme.of(context).textTheme.labelMedium,
          ),
        ],
      ),
    );
  }
}
