import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/empty_state_view.dart';
import '../../../../shared/widgets/status_badge.dart';
import '../providers/ipsrs_providers.dart';
import 'rekam_medis_detail_screen.dart';

class RekamMedisKatalogScreen extends ConsumerStatefulWidget {
  const RekamMedisKatalogScreen({super.key});

  @override
  ConsumerState<RekamMedisKatalogScreen> createState() => _RekamMedisKatalogScreenState();
}

class _RekamMedisKatalogScreenState extends ConsumerState<RekamMedisKatalogScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final katalogAsync = ref.watch(rekamMedisKatalogProvider);
    final selectedKondisi = ref.watch(rekamMedisKondisiFilterProvider);

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: const Text('Buku Rekam Medis Sarana'),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.refreshCw, size: 18),
            onPressed: () => ref.refresh(rekamMedisKatalogProvider),
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
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Cari kode AST-..., nomor seri, atau alat...',
                      prefixIcon: const Icon(LucideIcons.search, size: 18),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(LucideIcons.x, size: 16),
                              onPressed: () {
                                _searchController.clear();
                                ref.read(rekamMedisSearchQueryProvider.notifier).state = '';
                              },
                            )
                          : null,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    onChanged: (val) {
                      ref.read(rekamMedisSearchQueryProvider.notifier).state = val;
                    },
                  ),
                  const SizedBox(height: 10),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterChip('Semua Kondisi', null, selectedKondisi),
                        const SizedBox(width: 8),
                        _buildFilterChip('Kondisi: Baik', 'BAIK', selectedKondisi),
                        const SizedBox(width: 8),
                        _buildFilterChip('Rusak Ringan', 'RUSAK_RINGAN', selectedKondisi),
                        const SizedBox(width: 8),
                        _buildFilterChip('Rusak Berat', 'RUSAK_BERAT', selectedKondisi),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(color: AppColors.border, height: 1),

            // Asset List
            Expanded(
              child: katalogAsync.when(
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
                          onPressed: () => ref.refresh(rekamMedisKatalogProvider),
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
                      icon: LucideIcons.stethoscope,
                      title: 'Sarana Tidak Ditemukan',
                      message: 'Tidak ada sarana medis atau non-medis yang cocok dengan kata kunci pencarian.',
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final a = items[index];

                      return InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => RekamMedisDetailScreen(
                                asetId: a.id,
                                initialNama: a.namaSarana,
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
                          child: Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: AppColors.primaryPurple.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(LucideIcons.stethoscope, color: AppColors.primaryPurple, size: 22),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            a.kodeAset,
                                            style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w800,
                                              fontFamily: 'monospace',
                                              color: AppColors.textPrimary,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        StatusBadge(status: a.kondisi),
                                      ],
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      a.namaSarana,
                                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    Row(
                                      children: [
                                        const Icon(LucideIcons.mapPin, size: 12, color: AppColors.textSecondary),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            '${a.lokasi} • SN: ${a.nomorSeri}',
                                            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: a.totalServis > 0 ? AppColors.tintOrangeBg : AppColors.surfaceSecondary,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        '${a.totalServis}x Servis Tercatat',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          color: a.totalServis > 0 ? AppColors.tintOrange : AppColors.textSecondary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(LucideIcons.chevronRight, size: 18, color: AppColors.textSecondary),
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

  Widget _buildFilterChip(String label, String? value, String? selected) {
    final isSelected = selected == value;
    return InkWell(
      onTap: () {
        ref.read(rekamMedisKondisiFilterProvider.notifier).state = value;
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
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
