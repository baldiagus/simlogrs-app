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

/// Layar buku mutasi stok: daftar riwayat barang masuk/keluar gudang dengan pencarian dan filter jenis mutasi.
class BukuMutasiScreen extends ConsumerStatefulWidget {
  const BukuMutasiScreen({super.key});

  /// Membuat state layar buku mutasi.
  @override
  ConsumerState<BukuMutasiScreen> createState() => _BukuMutasiScreenState();
}

/// State layar buku mutasi; memantau daftar mutasi serta filter pencarian dan jenis dari provider.
class _BukuMutasiScreenState extends ConsumerState<BukuMutasiScreen> {


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
                  error: err,
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

                      return Container(
                        padding: const EdgeInsets.all(14),
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
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: isMasuk ? const Color(0xFFECFDF5) : const Color(0xFFFEF2F2),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            isMasuk ? LucideIcons.arrowDownLeft : LucideIcons.arrowUpRight,
                                            size: 13,
                                            color: isMasuk ? AppColors.success : AppColors.danger,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            m.jenis,
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w800,
                                              color: isMasuk ? AppColors.success : AppColors.danger,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      m.tanggal,
                                      style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                    ),
                                  ],
                                ),
                                Text(
                                  '${isMasuk ? '+' : '-'}${m.jumlah} ${m.satuan}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w900,
                                    color: isMasuk ? AppColors.success : AppColors.danger,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              m.namaBarang,
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Batch: ${m.nomorBatch} • ${m.gudang} (Rak: ${m.lokasiRak})',
                              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                            ),
                            if (m.keterangan != '-') ...[
                              const SizedBox(height: 4),
                              Text(
                                m.keterangan,
                                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontStyle: FontStyle.italic),
                              ),
                            ],
                            const Divider(color: AppColors.border, height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Flexible(
                                  child: Text(
                                    'Saldo: ${m.saldoSebelum} -> ${m.saldoSesudah} ${m.satuan}',
                                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(LucideIcons.user, size: 12, color: AppColors.textSecondary),
                                    const SizedBox(width: 4),
                                    Text(
                                      m.petugas,
                                      style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
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
