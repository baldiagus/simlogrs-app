import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_toast.dart';
import '../../../../shared/widgets/custom_button.dart';
import '../../../../shared/widgets/empty_state_view.dart';
import '../../../../shared/widgets/app_error_view.dart';
import '../../../../shared/widgets/app_filter_chip_bar.dart';
import '../../../../shared/widgets/app_loading_view.dart';
import '../../../../shared/widgets/app_search_bar.dart';
import '../../../../shared/widgets/app_confirm_dialog.dart';
import '../../data/models/jadwal_preventif_model.dart';
import '../../data/repositories/ipsrs_repository.dart';
import '../providers/ipsrs_providers.dart';
import '../providers/maintenance_provider.dart';
import '../../../dashboard/presentation/providers/dashboard_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../widgets/form_tambah_jadwal_sheet.dart';
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


  Future<void> _confirmEksekusi(JadwalPreventifItemModel j) async {
    final confirmed = await AppConfirmDialog.show(
      context,
      title: 'Terbitkan SPK Servis Preventif',
      message:
          'Terbitkan Surat Perintah Kerja (SPK) untuk pemeliharaan berkala "${j.jenisMaintenance}" pada sarana ${j.namaSarana} (${j.kodeAset}) dan tugaskan ke ${j.teknisiNama}?',
      confirmLabel: 'Terbitkan SPK Sekarang',
      icon: LucideIcons.calendarCheck,
    );
    if (!confirmed || !mounted) return;
    try {
      final res = await ref.read(ipsrsRepositoryProvider).eksekusiPreventif(j.id);
      if (!mounted) return;
      ref.invalidate(jadwalPreventifListProvider);
      ref.invalidate(spkListProvider);
      ref.invalidate(dashboardSummaryProvider);
      AppToast.success(context, 'SPK ${res['kode_spk'] ?? ''} berhasil diterbitkan dan ditugaskan.');
    } catch (e) {
      if (!mounted) return;
      AppToast.error(context, e.toString());
    }
  }
  @override
  Widget build(BuildContext context) {
    final jadwalAsync = ref.watch(jadwalPreventifListProvider);
    final selectedFilter = ref.watch(preventifStatusFilterProvider);
    final user = ref.watch(authStateProvider).user;
    final canTerbitkanSpk = (user?.isTeknisi == true) ||
        (user?.isKepalaTeknisi == true) ||
        (user?.isAdminLogistik == true) ||
        (user?.hasRole('super_admin') == true);
    final canTambahJadwal = (user?.isKepalaTeknisi == true) || (user?.hasRole('super_admin') == true);

    return Scaffold(
      backgroundColor: AppColors.canvas,
      floatingActionButton: canTambahJadwal
          ? FloatingActionButton.extended(
              heroTag: null,
              onPressed: () => FormTambahJadwalSheet.show(context),
              backgroundColor: AppColors.primaryPurple,
              foregroundColor: Colors.white,
              icon: const Icon(LucideIcons.plus, size: 18),
              label: const Text('Tambah Jadwal Servis', style: TextStyle(fontWeight: FontWeight.w700)),
            )
          : null,
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
                  AppSearchBar(
                    hint: 'Cari alat, kode aset, atau pekerjaan...',
                    onChanged: (val) {
                      ref.read(preventifSearchQueryProvider.notifier).state = val;
                    },
                  ),
                  const SizedBox(height: 10),
                  AppFilterChipBar<String>(
                    padding: EdgeInsets.zero,
                    selected: selectedFilter,
                    onSelected: (val) {
                      ref.read(preventifStatusFilterProvider.notifier).state = val;
                    },
                    options: const [
                      AppFilterOption(label: 'Semua Jadwal', value: 'SEMUA'),
                      AppFilterOption(label: 'Terlambat (Overdue)', value: 'OVERDUE'),
                      AppFilterOption(label: 'Hari Ini', value: 'HARI_INI'),
                      AppFilterOption(label: 'Mendatang', value: 'MENDATANG'),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(color: AppColors.border, height: 1),

            // Schedule List
            Expanded(
              child: jadwalAsync.when(
                loading: () => const AppLoadingView(),
                error: (err, _) => AppErrorView(
                  error: err,
                  onRetry: () => ref.refresh(jadwalPreventifListProvider),
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
                            if (canTerbitkanSpk) ...[
                              const SizedBox(height: 12),
                              CustomButton(
                                text: 'Terbitkan SPK Servis',
                                height: 38,
                                backgroundColor: AppColors.primaryPurple,
                                icon: const Icon(LucideIcons.playCircle, size: 16, color: Colors.white),
                                onPressed: () => _confirmEksekusi(j),
                              ),
                            ],
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
}
