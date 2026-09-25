import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/empty_state_view.dart';
import '../../../../shared/widgets/status_badge.dart';
import '../../../aset/presentation/screens/aset_detail_screen.dart';
import '../providers/register_aset_provider.dart';

class RegisterAsetScreen extends ConsumerStatefulWidget {
  const RegisterAsetScreen({super.key});

  @override
  ConsumerState<RegisterAsetScreen> createState() => _RegisterAsetScreenState();
}

class _RegisterAsetScreenState extends ConsumerState<RegisterAsetScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final asetAsync = ref.watch(registerAsetListProvider);
    final lokasiTipe = ref.watch(registerAsetLokasiTipeProvider);
    final status = ref.watch(registerAsetStatusProvider);
    final kondisi = ref.watch(registerAsetKondisiProvider);
    final rupiah = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: const Text('Register Master Aset'),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.refreshCw, size: 18),
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
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Cari kode AST-..., no. seri, nama alat...',
                      prefixIcon: const Icon(LucideIcons.search, size: 18),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(LucideIcons.x, size: 16),
                              onPressed: () {
                                _searchController.clear();
                                ref.read(registerAsetSearchQueryProvider.notifier).state = '';
                              },
                            )
                          : null,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    onChanged: (val) {
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
                          onPressed: () => ref.refresh(registerAsetListProvider),
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
                      icon: LucideIcons.qrCode,
                      title: 'Register Aset Tidak Ditemukan',
                      message: 'Tidak ada data aset fisik yang sesuai dengan filter atau kata kunci pencarian.',
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (ctx, idx) {
                      final item = items[idx];

                      return InkWell(
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
                                      color: AppColors.primaryPurple.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(
                                      LucideIcons.qrCode,
                                      color: AppColors.primaryPurple,
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
                                      rupiah.format(item.nilaiPerolehan),
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
