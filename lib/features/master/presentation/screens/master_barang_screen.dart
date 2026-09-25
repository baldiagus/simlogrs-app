import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/empty_state_view.dart';
import '../providers/master_barang_provider.dart';
import 'detail_barang_screen.dart';

class MasterBarangScreen extends ConsumerStatefulWidget {
  const MasterBarangScreen({super.key});

  @override
  ConsumerState<MasterBarangScreen> createState() => _MasterBarangScreenState();
}

class _MasterBarangScreenState extends ConsumerState<MasterBarangScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final barangAsync = ref.watch(masterBarangListProvider);
    final selectedTipe = ref.watch(masterBarangFilterTipeProvider);
    final rupiah = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: const Text('Katalog Master Barang'),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.refreshCw, size: 18),
            onPressed: () => ref.refresh(masterBarangListProvider),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Search & Filter Header
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              color: AppColors.surface,
              child: Column(
                children: [
                  // Search Bar
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Cari nama barang, kode SKU, spesifikasi...',
                      prefixIcon: const Icon(LucideIcons.search, size: 18),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(LucideIcons.x, size: 16),
                              onPressed: () {
                                _searchController.clear();
                                ref.read(masterBarangSearchQueryProvider.notifier).state = '';
                              },
                            )
                          : null,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    onChanged: (val) {
                      ref.read(masterBarangSearchQueryProvider.notifier).state = val;
                    },
                  ),
                  const SizedBox(height: 10),

                  // Tipe Filter Chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterChip('Semua', null, selectedTipe),
                        const SizedBox(width: 8),
                        _buildFilterChip('Habis Pakai', 'HABIS_PAKAI', selectedTipe),
                        const SizedBox(width: 8),
                        _buildFilterChip('Aset Inventaris', 'ASET', selectedTipe),
                        const SizedBox(width: 8),
                        _buildFilterChip('Suku Cadang', 'SPAREPART', selectedTipe),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(color: AppColors.border, height: 1),

            // List Items
            Expanded(
              child: barangAsync.when(
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
                          onPressed: () => ref.refresh(masterBarangListProvider),
                          icon: const Icon(LucideIcons.refreshCw, size: 16),
                          label: const Text('Coba Lagi'),
                        ),
                      ],
                    ),
                  ),
                ),
                data: (items) {
                  if (items.isEmpty) {
                    return const EmptyStateView(
                      icon: LucideIcons.packageSearch,
                      title: 'Komoditas Tidak Ditemukan',
                      message: 'Tidak ada data master barang yang sesuai dengan kata kunci atau filter yang dipilih.',
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (ctx, idx) {
                      final item = items[idx];
                      final isAset = item.tipe == 'ASET';

                      Color tipeColor = AppColors.tintBlue;
                      Color tipeBg = AppColors.tintBlueBg;
                      if (item.tipe == 'ASET') {
                        tipeColor = AppColors.tintViolet;
                        tipeBg = AppColors.tintVioletBg;
                      } else if (item.tipe == 'SPAREPART') {
                        tipeColor = AppColors.tintTeal;
                        tipeBg = AppColors.tintTealBg;
                      }

                      return InkWell(
                        onTap: () {
                          // Navigasi ke detail profil fisik komoditas
                          Navigator.push(
                            ctx,
                            MaterialPageRoute(
                              builder: (_) => DetailBarangScreen(
                                barangId: item.id,
                                initialNama: item.nama,
                              ),
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
                                      color: tipeBg,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      isAset
                                          ? LucideIcons.qrCode
                                          : (item.tipe == 'SPAREPART' ? LucideIcons.wrench : LucideIcons.package),
                                      color: tipeColor,
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
                                              item.kode,
                                              style: const TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w700,
                                                color: AppColors.textSecondary,
                                                fontFamily: 'monospace',
                                              ),
                                            ),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: tipeBg,
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                item.tipeLabel,
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w700,
                                                  color: tipeColor,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          item.nama,
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
                                          '${item.kategori} • ${item.merek}',
                                          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(color: AppColors.border, height: 18),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    rupiah.format(item.hargaEstimasi),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      Text(
                                        isAset
                                            ? '${item.totalAset} Unit Fisik'
                                            : 'Total: ${item.totalStokFisik} ${item.simbolSatuan}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w800,
                                          color: item.isHabis
                                              ? AppColors.danger
                                              : (item.isPerluPesan ? AppColors.warning : AppColors.success),
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      const Icon(LucideIcons.chevronRight, size: 16, color: AppColors.textSecondary),
                                    ],
                                  ),
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

  Widget _buildFilterChip(String label, String? value, String? currentSelected) {
    final isSelected = currentSelected == value;
    return InkWell(
      onTap: () {
        ref.read(masterBarangFilterTipeProvider.notifier).state = value;
      },
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
