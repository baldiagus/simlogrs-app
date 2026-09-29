import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:simlog_mobile/core/theme/app_colors.dart';
import 'package:simlog_mobile/core/theme/app_shadows.dart';
import 'package:simlog_mobile/features/audit/data/models/audit_models.dart';
import 'package:simlog_mobile/features/audit/presentation/providers/audit_provider.dart';
import 'package:simlog_mobile/shared/widgets/app_error_view.dart';
import 'package:simlog_mobile/shared/widgets/app_loading_view.dart';
import 'package:simlog_mobile/shared/widgets/empty_state_view.dart';

class AuditTrailTab extends ConsumerStatefulWidget {
  final ValueChanged<int> onOpenDetail;

  const AuditTrailTab({super.key, required this.onOpenDetail});

  @override
  ConsumerState<AuditTrailTab> createState() => _AuditTrailTabState();
}

class _AuditTrailTabState extends ConsumerState<AuditTrailTab> {
  String? _trailAksi;
  final TextEditingController _trailSearchCtrl = TextEditingController();

  @override
  void dispose() {
    _trailSearchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filter = AuditTrailFilter(
      aksi: _trailAksi,
      search: _trailSearchCtrl.text.trim().isEmpty ? null : _trailSearchCtrl.text.trim(),
    );
    final trailAsync = ref.watch(auditTrailProvider(filter));

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          color: AppColors.surface,
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _trailSearchCtrl,
                  decoration: InputDecoration(
                    hintText: 'Cari referensi, pengguna, IP...',
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
                  onSubmitted: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 8),
              DropdownButton<String?>(
                value: _trailAksi,
                hint: const Text('Semua Aksi', style: TextStyle(fontSize: 12)),
                underline: const SizedBox.shrink(),
                style: const TextStyle(fontSize: 12, color: AppColors.textPrimary),
                items: const [
                  DropdownMenuItem(value: null, child: Text('Semua Aksi')),
                  DropdownMenuItem(value: 'TAMBAH', child: Text('TAMBAH')),
                  DropdownMenuItem(value: 'UBAH', child: Text('UBAH')),
                  DropdownMenuItem(value: 'HAPUS', child: Text('HAPUS')),
                  DropdownMenuItem(value: 'APPROVE', child: Text('APPROVE')),
                  DropdownMenuItem(value: 'REJECT', child: Text('REJECT')),
                  DropdownMenuItem(value: 'ADJUSTMENT', child: Text('ADJUSTMENT')),
                ],
                onChanged: (val) => setState(() => _trailAksi = val),
              ),
            ],
          ),
        ),
        Expanded(
          child: trailAsync.when(
            data: (items) {
              if (items.isEmpty) {
                return const EmptyStateView(
                  icon: LucideIcons.fileSearch,
                  title: 'Tidak Ada Log Audit',
                  message:
                      'Tidak ditemukan rekaman log audit forensik dengan kriteria filter saat ini.',
                );
              }

              return RefreshIndicator(
                onRefresh: () async => ref.refresh(auditTrailProvider(filter)),
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (ctx, i) => _buildTrailCard(items[i]),
                ),
              );
            },
            loading: () => const AppLoadingView(),
            error: (err, _) => AppErrorView(
              title: 'Gagal Memuat Log Audit',
              error: err,
              onRetry: () => ref.refresh(auditTrailProvider(filter)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTrailCard(AuditTrailItemModel item) {
    Color badgeColor;
    Color badgeBg;

    switch (item.aksi.toUpperCase()) {
      case 'TAMBAH':
        badgeColor = AppColors.success;
        badgeBg = const Color(0xFFECFDF5);
        break;
      case 'UBAH':
        badgeColor = AppColors.tintBlue;
        badgeBg = AppColors.tintBlueBg;
        break;
      case 'HAPUS':
      case 'REJECT':
        badgeColor = AppColors.danger;
        badgeBg = const Color(0xFFFEF2F2);
        break;
      case 'APPROVE':
        badgeColor = AppColors.tintViolet;
        badgeBg = AppColors.tintVioletBg;
        break;
      default:
        badgeColor = AppColors.tintOrange;
        badgeBg = AppColors.tintOrangeBg;
    }

    return InkWell(
      onTap: () => widget.onOpenDetail(item.id),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
          boxShadow: AppShadows.softCard,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: badgeBg, borderRadius: BorderRadius.circular(6)),
                  child: Text(
                    item.aksi,
                    style: TextStyle(color: badgeColor, fontWeight: FontWeight.w800, fontSize: 11),
                  ),
                ),
                Text(
                  item.waktu,
                  style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${item.referensiJenis} #${item.referensiId}',
              style: const TextStyle(
                  fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(LucideIcons.user, size: 13, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    '${item.penggunaNama} (${item.peran})',
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                const Icon(LucideIcons.globe, size: 13, color: AppColors.textMuted),
                const SizedBox(width: 4),
                Text(
                  'IP: ${item.ipAddress}',
                  style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                ),
                const Spacer(),
                if (item.hasDataSebelum || item.hasDataSesudah)
                  const Text(
                    'Lihat Diff Data ->',
                    style: TextStyle(
                        fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.primaryPurple),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
