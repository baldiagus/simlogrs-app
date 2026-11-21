import '../../../../core/network/user_error_message.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../shared/widgets/app_error_view.dart';
import '../../../../shared/widgets/app_filter_chip_bar.dart';
import '../../../../shared/widgets/app_loading_view.dart';
import '../../../../shared/widgets/app_search_bar.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/empty_state_view.dart';
import '../providers/persediaan_providers.dart';
import '../../../../shared/widgets/app_bottom_sheet_wrapper.dart';
import '../../data/models/buku_mutasi_model.dart';

/// Layar buku mutasi stok: daftar riwayat barang masuk/keluar gudang dengan pencarian dan filter jenis mutasi.
class BukuMutasiScreen extends ConsumerStatefulWidget {
  const BukuMutasiScreen({super.key});

  /// Membuat state layar buku mutasi.
  @override
  ConsumerState<BukuMutasiScreen> createState() => _BukuMutasiScreenState();
}

/// State layar buku mutasi; memantau daftar mutasi serta filter pencarian dan jenis dari provider.
class _BukuMutasiScreenState extends ConsumerState<BukuMutasiScreen> {
  void _showDetail(BuildContext context, BukuMutasiItemModel item) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      constraints: const BoxConstraints(maxWidth: 640),
      builder: (sheetContext) => AppBottomSheetWrapper(
        title: 'Detail Mutasi Stok',
        fixedHeader: true,
        maxHeightFactor: 0.9,
        trailing: IconButton(
          tooltip: 'Tutup detail mutasi',
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(sheetContext),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(item.namaBarang, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            ...<String, String>{
              'Kode barang': item.kodeBarang,
              'Jenis transaksi': item.jenis,
              'Tanggal/waktu': item.tanggal,
              'Perubahan jumlah': '${item.isMasuk ? '+' : '-'}${item.jumlah.abs()} ${item.satuan}',
              'Saldo sebelum': '${item.saldoSebelum} ${item.satuan}',
              'Saldo sesudah': '${item.saldoSesudah} ${item.satuan}',
              'Nomor batch': item.nomorBatch,
              'Gudang': item.gudang,
              'Rak/lokasi': item.lokasiRak,
              'Jenis referensi': item.referensiJenis ?? 'Tidak tersedia',
              'ID referensi': item.referensiId?.toString() ?? 'Tidak tersedia',
              'Keterangan': item.keterangan,
              'Dicatat oleh': item.petugas,
            }.entries.map((entry) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(entry.key, style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 4),
                Text(entry.value.trim().isEmpty || entry.value == '-' ? 'Tidak tersedia' : entry.value,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
              ]),
            )),
          ],
        ),
      ),
    );
  }


  /// Menyusun UI buku mutasi: bar pencarian, chip filter jenis, dan daftar mutasi dengan status loading/error/kosong.
  @override
  Widget build(BuildContext context) {
    final mutasiAsync = ref.watch(bukuMutasiListProvider);
    final selectedJenis = ref.watch(mutasiJenisFilterProvider);

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: const Text('Buku Mutasi Stok'),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.refreshCw, size: 18),
            tooltip: 'Muat ulang',
            onPressed: () => ref.refresh(bukuMutasiListProvider),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Search Bar & Filter Chips
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              color: AppColors.surface,
              child: Column(
                children: [
                  AppSearchBar(
                    hint: 'Cari komoditas, nomor batch, atau dokumen...',
                    onChanged: (val) {
                      ref.read(mutasiSearchQueryProvider.notifier).state = val;
                    },
                  ),
                  const SizedBox(height: 10),
                  AppFilterChipBar<String?>(
                    padding: EdgeInsets.zero,
                    selected: selectedJenis,
                    onSelected: (val) {
                      ref.read(mutasiJenisFilterProvider.notifier).state = val;
                    },
                    options: const [
                      AppFilterOption(label: 'Semua Transaksi', value: null),
                      AppFilterOption(label: 'Masuk (Inbound)', value: 'MASUK'),
                      AppFilterOption(label: 'Keluar (Distribusi)', value: 'KELUAR'),
                      AppFilterOption(label: 'Penyesuaian (Opname)', value: 'PENYESUAIAN'),
                      AppFilterOption(label: 'Transfer Rak', value: 'TRANSFER'),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(color: AppColors.border, height: 1),

            // Mutation List
            Expanded(
              child: mutasiAsync.when(
                loading: () => const AppLoadingView(),
                error: (err, _) => AppErrorView(
                  error: userErrorMessage(err, action: 'memuat buku mutasi'),
                  onRetry: () => ref.refresh(bukuMutasiListProvider),
                ),
                data: (items) {
                  if (items.isEmpty) {
                    return const EmptyStateView(
                      icon: LucideIcons.fileSpreadsheet,
                      title: 'Tidak Ada Mutasi',
                      message: 'Tidak ada catatan pergerakan stok yang cocok dengan kriteria pencarian.',
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: () => ref.refresh(bukuMutasiListProvider.future),
                    child: ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final m = items[index];
                      final isMasuk = m.isMasuk;

                      return Material(
                        color: AppColors.surface,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: const BorderSide(color: AppColors.border),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          onTap: () => _showDetail(context, m),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Wrap(spacing: 12, runSpacing: 6, children: [
                                  Text(m.jenis, style: TextStyle(fontWeight: FontWeight.w700,
                                    color: isMasuk ? AppColors.success : AppColors.danger)),
                                  Text(m.tanggal, style: Theme.of(context).textTheme.bodySmall),
                                ]),
                                const SizedBox(height: 10),
                                Text(m.namaBarang, maxLines: 2, overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                                const SizedBox(height: 8),
                                Text('${isMasuk ? '+' : '-'}${m.jumlah.abs()} ${m.satuan}',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: isMasuk ? AppColors.success : AppColors.danger)),
                                const SizedBox(height: 8),
                                Text('Batch: ${m.nomorBatch} • ${m.gudang}', maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.bodySmall),
                                const Divider(height: 24),
                                Wrap(spacing: 16, runSpacing: 8, children: [
                                  Text('Saldo: ${m.saldoSebelum} → ${m.saldoSesudah} ${m.satuan}'),
                                  const Text('Detail ›', style: TextStyle(
                                    color: AppColors.primaryPurple, fontWeight: FontWeight.w700)),
                                ]),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ));
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
