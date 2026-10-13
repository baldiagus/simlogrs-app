import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/app_formatters.dart';
import '../../../../shared/widgets/app_error_view.dart';
import '../../../../shared/widgets/app_loading_view.dart';
import '../../../../shared/widgets/app_search_bar.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/empty_state_view.dart';
import '../../../../shared/widgets/status_badge.dart';
import '../../../aset/presentation/screens/aset_detail_screen.dart';
import '../providers/register_aset_provider.dart';

/// Layar register master aset: pencarian, filter lokasi/status/kondisi, dan daftar aset fisik menuju detail.
class RegisterAsetScreen extends ConsumerStatefulWidget {
  const RegisterAsetScreen({super.key});

  /// Membuat state layar register aset.
  @override
  ConsumerState<RegisterAsetScreen> createState() => _RegisterAsetScreenState();
}

/// State layar register aset; memantau provider daftar aset dan filter-nya.
class _RegisterAsetScreenState extends ConsumerState<RegisterAsetScreen> {

  /// Membangun scaffold register aset dengan header pencarian, chip filter, dan daftar aset (loading, error, kosong, data).
  @override
  Widget build(BuildContext context) {
    final asetAsync = ref.watch(registerAsetListProvider);
    final lokasiTipe = ref.watch(registerAsetLokasiTipeProvider);
    final status = ref.watch(registerAsetStatusProvider);
    final kondisi = ref.watch(registerAsetKondisiProvider);


    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: const Text('Register Master Aset'),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.refreshCw, size: 18),
            // Muat ulang daftar aset dari server.
            onPressed: () => ref.refresh(registerAsetListProvider),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Filter & Search Header
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              color: AppColors.surface,
              child: Column(
                children: [
                  // Search Bar
                  AppSearchBar(
                    hint: 'Cari kode AST-..., no. seri, nama alat...',
                    onChanged: (val) {
                      // Simpan kata kunci ke provider pencarian agar daftar difilter ulang.
                      ref.read(registerAsetSearchQueryProvider.notifier).state = val;
                    },
                  ),
                  const SizedBox(height: 10),

                  // Filter Chips: Lokasi Tipe
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterChip(
                          'Semua Lokasi',
                          null,
                          lokasiTipe,
                          // Setiap chip lokasi menyimpan pilihan ke provider filter lokasi.
                          (v) => ref.read(registerAsetLokasiTipeProvider.notifier).state = v,
                        ),
                        const SizedBox(width: 8),
                        _buildFilterChip(
                          'Di Ruangan Unit',
                          'RUANGAN',
                          lokasiTipe,
                          (v) => ref.read(registerAsetLokasiTipeProvider.notifier).state = v,
                        ),
                        const SizedBox(width: 8),
                        _buildFilterChip(
                          'Di Gudang Sentral',
                          'GUDANG',
                          lokasiTipe,
                          (v) => ref.read(registerAsetLokasiTipeProvider.notifier).state = v,
                        ),
                        const SizedBox(width: 12),
                        Container(width: 1, height: 20, color: AppColors.border),
                        const SizedBox(width: 12),
                        _buildFilterChip(
                          'Semua Status',
                          null,
                          status,
                          // Setiap chip status menyimpan pilihan ke provider filter status.
                          (v) => ref.read(registerAsetStatusProvider.notifier).state = v,
                        ),
                        const SizedBox(width: 8),
                        _buildFilterChip(
                          'Tersedia',
                          'TERSEDIA',
                          status,
                          (v) => ref.read(registerAsetStatusProvider.notifier).state = v,
                        ),
                        const SizedBox(width: 8),
                        _buildFilterChip(
                          'Dipinjam',
                          'DIPINJAM',
                          status,
                          (v) => ref.read(registerAsetStatusProvider.notifier).state = v,
                        ),
                        const SizedBox(width: 8),
                        _buildFilterChip(
                          'Digunakan',
                          'DIGUNAKAN',
                          status,
                          (v) => ref.read(registerAsetStatusProvider.notifier).state = v,
                        ),
                        const SizedBox(width: 8),
                        _buildFilterChip(
                          'Maintenance',
                          'DALAM_MAINTENANCE',
                          status,
                          (v) => ref.read(registerAsetStatusProvider.notifier).state = v,
                        ),
                        const SizedBox(width: 12),
                        Container(width: 1, height: 20, color: AppColors.border),
                        const SizedBox(width: 12),
                        _buildFilterChip(
                          'Kondisi: Baik',
                          'BAIK',
                          kondisi,
                          // Chip kondisi bersifat toggle: klik lagi pada chip aktif untuk menghapus filter.
                          (v) => ref.read(registerAsetKondisiProvider.notifier).state = (kondisi == 'BAIK' ? null : 'BAIK'),
                        ),
                        const SizedBox(width: 8),
                        _buildFilterChip(
                          'Kondisi: Rusak',
                          'RUSAK_RINGAN',
                          kondisi,
                          (v) => ref.read(registerAsetKondisiProvider.notifier).state = (kondisi == 'RUSAK_RINGAN' ? null : 'RUSAK_RINGAN'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(color: AppColors.border, height: 1),

            // List Items
            Expanded(
              child: asetAsync.when(
                loading: () => const AppLoadingView(),
                error: (err, _) => AppErrorView(
                  error: err,
                  // Coba lagi dengan memuat ulang daftar aset.
                  onRetry: () => ref.refresh(registerAsetListProvider),
                ),
                // Tampilkan empty state bila kosong, selain itu daftar kartu aset.
                data: (items) {
                  if (items.isEmpty) {
                    return const EmptyStateView(
                      icon: LucideIcons.qrCode,
                      title: 'Register Aset Tidak Ditemukan',
                      message: 'Tidak ada data aset fisik yang sesuai dengan filter atau kata kunci pencarian.',
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    // Bangun kartu satu aset fisik beserta status dan lokasinya.
                    itemBuilder: (ctx, idx) {
                      final item = items[idx];

                      return InkWell(
                        // Buka detail aset saat kartu diketuk.
                        onTap: () {
                          // Navigasi langsung ke profil fisik aset AST-...
                          Navigator.push(
                            ctx,
                            MaterialPageRoute(
                              builder: (_) => AsetDetailScreen(asetId: item.id),
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
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: AppColors.tintVioletBg,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(
                                      LucideIcons.qrCode,
                                      color: AppColors.tintViolet,
                                      size: 22,
                                    ),
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
                                              item.kodeAset,
                                              style: const TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w800,
                                                color: AppColors.textPrimary,
                                                fontFamily: 'monospace',
                                              ),
                                            ),
                                            StatusBadge(status: item.status),
                                          ],
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          item.namaKomoditas,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w800,
                                            color: AppColors.textPrimary,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'No. Seri: ${item.nomorSeri} • Kondisi: ${item.kondisi.replaceAll('_', ' ')}',
                                          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(color: AppColors.border, height: 16),
                              Row(
                                children: [
                                  const Icon(LucideIcons.mapPin, size: 13, color: AppColors.textSecondary),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      item.lokasiNama,
                                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  if (item.nilaiPerolehan > 0)
                                    Text(
                                      AppFormatters.rupiah(item.nilaiPerolehan),
                                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                                    ),
                                  const SizedBox(width: 4),
                                  const Icon(LucideIcons.chevronRight, size: 16, color: AppColors.textSecondary),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Membangun satu chip filter; tampil terpilih bila [currentSelected] sama dengan [value], memanggil [onSelect] saat diketuk.
  Widget _buildFilterChip(
    String label,
    String? value,
    String? currentSelected,
    ValueChanged<String?> onSelect,
  ) {
    final isSelected = currentSelected == value;
    return InkWell(
      onTap: () => onSelect(value),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryPurple : AppColors.canvas,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primaryPurple : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
