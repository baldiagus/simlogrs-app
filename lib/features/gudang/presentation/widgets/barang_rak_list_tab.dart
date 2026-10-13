import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../shared/widgets/empty_state_view.dart';
import '../../../../shared/widgets/app_search_bar.dart';
import '../../data/models/barang_rak_model.dart';

/// Tab daftar barang (stok per batch) di dalam rak, dengan kolom pencarian lokal.
class BarangRakListTab extends StatefulWidget {
  final List<BarangRakModel> items;

  const BarangRakListTab({
    super.key,
    required this.items,
  });

  /// Membuat state pencarian untuk tab barang rak.
  @override
  State<BarangRakListTab> createState() => _BarangRakListTabState();
}

/// State tab barang rak; menyimpan kata kunci pencarian dan memfilter daftar barang.
class _BarangRakListTabState extends State<BarangRakListTab> {
  String _searchQuery = '';

  /// Membangun kolom pencarian dan daftar barang yang sudah difilter, atau tampilan kosong bila tidak ada hasil.
  @override
  Widget build(BuildContext context) {
    final filtered = widget.items.where((b) {
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return b.namaBarang.toLowerCase().contains(q) ||
          b.kodeBarang.toLowerCase().contains(q) ||
          b.kategori.toLowerCase().contains(q) ||
          (b.nomorBatch?.toLowerCase().contains(q) ?? false);
    }).toList();

    return Column(
      children: [
        // In-Shelf Search Bar
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: AppSearchBar(
            hint: 'Cari barang, batch, atau kode...',
            onChanged: (val) => setState(() => _searchQuery = val.trim()),
            onClear: () => setState(() => _searchQuery = ''),
          ),
        ),
        // List
        Expanded(
          child: filtered.isEmpty
              ? EmptyStateView(
                  icon: LucideIcons.boxes,
                  title: _searchQuery.isEmpty
                      ? 'Tidak Ada Stok Barang'
                      : 'Barang Tidak Ditemukan',
                  message: _searchQuery.isEmpty
                      ? 'Rak ini saat ini belum memiliki barang atau stok batch yang tersimpan.'
                      : 'Tidak ada barang yang cocok dengan kata kunci "$_searchQuery".',
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final item = filtered[index];
                    return _buildBarangCard(item);
                  },
                ),
        ),
      ],
    );
  }

  /// Membangun kartu satu barang/batch dengan penanda status kedaluwarsa (aman, mendekati, kadaluwarsa).
  Widget _buildBarangCard(BarangRakModel item) {
    Color expColor = AppColors.success;
    String expLabel = 'Aman';
    if (item.isKadaluwarsa) {
      expColor = AppColors.danger;
      expLabel = 'Kadaluwarsa';
    } else if (item.isMendekatiKadaluwarsa) {
      expColor = AppColors.warning;
      expLabel = 'Segera Exp';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.softCard,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon Box based on Tipe Komoditas
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: item.isAset
                      ? AppColors.tintOrangeBg
                      : (item.isSparepart ? AppColors.tintTealBg : AppColors.tintBlueBg),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  item.isAset
                      ? LucideIcons.armchair
                      : (item.isSparepart ? LucideIcons.wrench : LucideIcons.boxes),
                  size: 20,
                  color: item.isAset
                      ? AppColors.tintOrange
                      : (item.isSparepart ? AppColors.tintTeal : AppColors.tintBlue),
                ),
              ),
              const SizedBox(width: 12),

              // Title & Category
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: item.isAset
                                ? AppColors.tintOrangeBg
                                : (item.isSparepart ? AppColors.tintTealBg : AppColors.tintBlueBg),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            item.tipeLabel,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: item.isAset
                                  ? AppColors.tintOrange
                                  : (item.isSparepart ? AppColors.tintTeal : AppColors.tintBlue),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.namaBarang,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${item.kodeBarang} • ${item.kategori} • ${item.merek}',
                      style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),

              // Stock pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.canvas,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${item.kuantitasStok}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primaryPurple,
                      ),
                    ),
                    Text(
                      item.satuan,
                      style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(height: 1, color: AppColors.border),
          const SizedBox(height: 8),

          // Batch & Expired
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(LucideIcons.tag, size: 12, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Text(
                    'Batch: ${item.nomorBatch ?? '-'}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(color: expColor, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    item.tanggalKedaluwarsa != null
                        ? 'Exp: ${item.tanggalKedaluwarsa} ($expLabel)'
                        : 'Non-Exp',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: expColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
