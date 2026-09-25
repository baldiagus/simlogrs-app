import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/custom_button.dart';
import '../../../../shared/widgets/empty_state_view.dart';
import '../../data/models/jadwal_preventif_model.dart';
import '../../data/repositories/ipsrs_repository.dart';
import '../providers/ipsrs_providers.dart';
class JadwalPreventifScreen extends ConsumerStatefulWidget {
  final bool isEmbedded;

  const JadwalPreventifScreen({
    super.key,
    this.isEmbedded = false,
  });

  @override
  ConsumerState<JadwalPreventifScreen> createState() => _JadwalPreventifScreenState();
}

class _JadwalPreventifScreenState extends ConsumerState<JadwalPreventifScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _confirmEksekusi(JadwalPreventifItemModel j) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Terbitkan SPK Servis Preventif'),
        content: Text(
          'Terbitkan Surat Perintah Kerja (SPK) untuk pemeliharaan berkala "${j.jenisMaintenance}" pada sarana ${j.namaSarana} (${j.kodeAset}) dan tugaskan ke ${j.teknisiNama}?',
          style: const TextStyle(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final messenger = ScaffoldMessenger.of(context);
              try {
                final res = await ref.read(ipsrsRepositoryProvider).eksekusiPreventif(j.id);
                ref.invalidate(jadwalPreventifListProvider);
                messenger.showSnackBar(
                  SnackBar(
                    content: Text('SPK ${res['kode_spk'] ?? ''} berhasil diterbitkan dan ditugaskan.'),
                    backgroundColor: AppColors.success,
                  ),
                );
              } catch (e) {
                messenger.showSnackBar(
                  SnackBar(content: Text(e.toString()), backgroundColor: AppColors.danger),
                );
              }
            },
            child: const Text('Terbitkan SPK Sekarang'),
          ),
        ],
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    final jadwalAsync = ref.watch(jadwalPreventifListProvider);
    final selectedFilter = ref.watch(preventifStatusFilterProvider);

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: widget.isEmbedded
          ? null
          : AppBar(
              title: const Text('Jadwal Preventif Berkala'),
              actions: [
                IconButton(
                  icon: const Icon(LucideIcons.refreshCw, size: 18),
                  onPressed: () => ref.refresh(jadwalPreventifListProvider),
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
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Cari alat, kode aset, atau pekerjaan...',
                      prefixIcon: const Icon(LucideIcons.search, size: 18),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(LucideIcons.x, size: 16),
                              onPressed: () {
                                _searchController.clear();
                                ref.read(preventifSearchQueryProvider.notifier).state = '';
                              },
                            )
                          : null,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    onChanged: (val) {
                      ref.read(preventifSearchQueryProvider.notifier).state = val;
                    },
                  ),
                  const SizedBox(height: 10),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterChip('Semua Jadwal', 'SEMUA', selectedFilter),
                        const SizedBox(width: 8),
                        _buildFilterChip('Terlambat (Overdue)', 'OVERDUE', selectedFilter),
                        const SizedBox(width: 8),
                        _buildFilterChip('Hari Ini', 'HARI_INI', selectedFilter),
                        const SizedBox(width: 8),
                        _buildFilterChip('Mendatang', 'MENDATANG', selectedFilter),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(color: AppColors.border, height: 1),

            // Schedule List
            Expanded(
              child: jadwalAsync.when(
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
                          onPressed: () => ref.refresh(jadwalPreventifListProvider),
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
                      icon: LucideIcons.calendarCheck,
                      title: 'Tidak Ada Jadwal Preventif',
                      message: 'Tidak ada agenda pemeliharaan preventif yang cocok dengan kriteria filter.',
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final j = items[index];

                      Color badgeColor = AppColors.tintBlue;
                      Color badgeBg = AppColors.tintBlueBg;
                      String statusText = 'Mendatang';

                      if (j.isOverdue) {
                        badgeColor = AppColors.danger;
                        badgeBg = const Color(0xFFFEF2F2);
                        statusText = 'Terlambat (${j.sisaHari?.abs()}h)';
                      } else if (j.isHariIni) {
                        badgeColor = AppColors.warning;
                        badgeBg = const Color(0xFFFFFBEB);
                        statusText = 'Jatuh Tempo Hari Ini';
                      }

                      return Container(
                        padding: const EdgeInsets.all(16),
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
                                    const Icon(LucideIcons.calendar, size: 16, color: AppColors.primaryPurple),
                                    const SizedBox(width: 6),
                                    Text(
                                      j.kode,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w800,
                                        fontFamily: 'monospace',
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: badgeBg,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    statusText,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: badgeColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              j.jenisMaintenance,
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${j.namaSarana} (${j.kodeAset})',
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primaryPurple),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Lokasi: ${j.lokasi} • ${j.intervalLabel}',
                              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                            ),
                            const Divider(color: AppColors.border, height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const Icon(LucideIcons.clock, size: 13, color: AppColors.textSecondary),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Jatuh Tempo: ${j.tanggalBerikutnya}',
                                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    const Icon(LucideIcons.user, size: 13, color: AppColors.textSecondary),
                                    const SizedBox(width: 4),
                                    Text(
                                      j.teknisiNama,
                                      style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            CustomButton(
                              text: 'Terbitkan SPK Servis',
                              height: 38,
                              backgroundColor: AppColors.primaryPurple,
                              icon: const Icon(LucideIcons.playCircle, size: 16, color: Colors.white),
                              onPressed: () => _confirmEksekusi(j),
                            ),
                          ],
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

  Widget _buildFilterChip(String label, String value, String selected) {
    final isSelected = selected == value;
    return InkWell(
      onTap: () {
        ref.read(preventifStatusFilterProvider.notifier).state = value;
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
