import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:simlog_mobile/core/theme/app_colors.dart';
import 'package:simlog_mobile/core/theme/app_shadows.dart';
import 'package:simlog_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:simlog_mobile/features/audit/data/models/audit_models.dart';
import 'package:simlog_mobile/features/audit/presentation/providers/audit_provider.dart';
import 'package:simlog_mobile/shared/widgets/app_error_view.dart';
import 'package:simlog_mobile/shared/widgets/app_loading_view.dart';
import 'package:simlog_mobile/shared/widgets/empty_state_view.dart';

/// Tab register temuan audit & CAPA; [onOpenDetail] dipanggil dengan temuan yang diketuk.
class TemuanCapaTab extends ConsumerStatefulWidget {
  final ValueChanged<TemuanCapaModel> onOpenDetail;

  const TemuanCapaTab({super.key, required this.onOpenDetail});

  /// Membuat state tab temuan CAPA.
  @override
  ConsumerState<TemuanCapaTab> createState() => _TemuanCapaTabState();
}

/// State tab temuan CAPA: menyimpan filter status, risiko, dan teks pencarian.
class _TemuanCapaTabState extends ConsumerState<TemuanCapaTab> {
  String? _capaStatus;
  String? _capaRisiko;
  final TextEditingController _capaSearchCtrl = TextEditingController();

  /// Membuang controller pencarian agar tidak bocor memori.
  @override
  void dispose() {
    _capaSearchCtrl.dispose();
    super.dispose();
  }

  /// Membangun tab register temuan & CAPA: filter status/risiko, pencarian, dan daftar dari [registerTemuanProvider].
  @override
  Widget build(BuildContext context) {
    ref.watch(temuanFilterProvider);
    final temuanAsync = ref.watch(registerTemuanProvider);
    final user = ref.watch(authStateProvider).user;
    final isAuditor = user?.isAuditor ?? false;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          color: AppColors.surface,
          child: Column(
            children: [
              TextField(
                controller: _capaSearchCtrl,
                decoration: InputDecoration(
                  hintText: 'Cari objek audit, kode AUD...',
                  prefixIcon: const Icon(LucideIcons.search, size: 16),
                  contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  isDense: true,
                  filled: true,
                  fillColor: AppColors.canvas,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
                onSubmitted: (val) {
                  ref.read(temuanFilterProvider.notifier).state = TemuanFilter(
                    status: _capaStatus,
                    risiko: _capaRisiko,
                    search: val.trim().isEmpty ? null : val.trim(),
                  );
                },
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: DropdownButton<String?>(
                      isExpanded: true,
                      value: _capaStatus,
                      hint: const Text('Semua Status', style: TextStyle(fontSize: 11)),
                      underline: const SizedBox.shrink(),
                      style: const TextStyle(fontSize: 11, color: AppColors.textPrimary),
                      items: const [
                        DropdownMenuItem(value: null, child: Text('Semua Status')),
                        DropdownMenuItem(value: 'In Progress', child: Text('In Progress')),
                        DropdownMenuItem(value: 'In Review', child: Text('In Review')),
                        DropdownMenuItem(value: 'Closed', child: Text('Closed')),
                      ],
                      onChanged: (val) {
                        setState(() => _capaStatus = val);
                        ref.read(temuanFilterProvider.notifier).state = TemuanFilter(
                          status: val,
                          risiko: _capaRisiko,
                          search: _capaSearchCtrl.text.trim().isEmpty
                              ? null
                              : _capaSearchCtrl.text.trim(),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButton<String?>(
                      isExpanded: true,
                      value: _capaRisiko,
                      hint: const Text('Semua Risiko', style: TextStyle(fontSize: 11)),
                      underline: const SizedBox.shrink(),
                      style: const TextStyle(fontSize: 11, color: AppColors.textPrimary),
                      items: const [
                        DropdownMenuItem(value: null, child: Text('Semua Risiko')),
                        DropdownMenuItem(value: 'Mayor', child: Text('Mayor')),
                        DropdownMenuItem(value: 'Moderat', child: Text('Moderat')),
                        DropdownMenuItem(value: 'Minor', child: Text('Minor')),
                      ],
                      onChanged: (val) {
                        setState(() => _capaRisiko = val);
                        ref.read(temuanFilterProvider.notifier).state = TemuanFilter(
                          status: _capaStatus,
                          risiko: val,
                          search: _capaSearchCtrl.text.trim().isEmpty
                              ? null
                              : _capaSearchCtrl.text.trim(),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: temuanAsync.when(
            data: (temuans) {
              if (temuans.isEmpty) {
                return const EmptyStateView(
                  icon: LucideIcons.clipboardList,
                  title: 'Register CAPA Bersih',
                  message:
                      'Tidak ditemukan rekaman temuan audit pada kriteria filter saat ini.',
                );
              }

              return RefreshIndicator(
                onRefresh: () async => ref.refresh(registerTemuanProvider),
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: temuans.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (ctx, i) => _buildTemuanCard(temuans[i], isAuditor),
                ),
              );
            },
            loading: () => const AppLoadingView(),
            error: (err, _) => AppErrorView(
              title: 'Gagal Memuat Register Temuan',
              error: err,
              onRetry: () => ref.refresh(registerTemuanProvider),
            ),
          ),
        ),
      ],
    );
  }

  /// Membangun kartu temuan dengan warna sesuai risiko dan status CAPA; ketuk membuka detail temuan.
  Widget _buildTemuanCard(TemuanCapaModel temuan, bool isAuditor) {
    Color riskColor;
    switch (temuan.tingkatRisiko) {
      case 'Mayor':
        riskColor = AppColors.danger;
        break;
      case 'Moderat':
        riskColor = AppColors.warning;
        break;
      default:
        riskColor = AppColors.tintBlue;
    }

    Color statusColor;
    Color statusBg;
    switch (temuan.statusCapa) {
      case 'Closed':
        statusColor = AppColors.success;
        statusBg = const Color(0xFFECFDF5);
        break;
      case 'In Review':
        statusColor = AppColors.tintViolet;
        statusBg = AppColors.tintVioletBg;
        break;
      default:
        statusColor = temuan.isOverdue ? AppColors.danger : AppColors.warning;
        statusBg = temuan.isOverdue ? const Color(0xFFFEF2F2) : const Color(0xFFFFFBEB);
    }

    return InkWell(
      onTap: () => widget.onOpenDetail(temuan),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: temuan.isOverdue
                  ? AppColors.danger.withValues(alpha: 0.5)
                  : AppColors.border),
          boxShadow: AppShadows.softCard,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          temuan.kode,
                          style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                              color: AppColors.textPrimary),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: riskColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: riskColor.withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          temuan.tingkatRisiko,
                          style: TextStyle(
                              color: riskColor, fontWeight: FontWeight.w700, fontSize: 9),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration:
                      BoxDecoration(color: statusBg, borderRadius: BorderRadius.circular(6)),
                  child: Text(
                    temuan.statusCapa,
                    style: TextStyle(
                        color: statusColor, fontWeight: FontWeight.w800, fontSize: 10),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              temuan.objekAudit,
              style: const TextStyle(
                  fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 4),
            Text(
              temuan.ringkasan,
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(LucideIcons.calendar, size: 12, color: AppColors.textMuted),
                const SizedBox(width: 4),
                Text(
                  'Due: ${temuan.dueDateCapa}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: temuan.isOverdue ? FontWeight.w700 : FontWeight.normal,
                    color: temuan.isOverdue ? AppColors.danger : AppColors.textMuted,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    temuan.unit != '-'
                        ? 'Unit: ${temuan.unit}'
                        : (temuan.gudang != null && temuan.gudang != '-'
                            ? 'Gudang: ${temuan.gudang}'
                            : 'Sentral'),
                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                    textAlign: TextAlign.end,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
