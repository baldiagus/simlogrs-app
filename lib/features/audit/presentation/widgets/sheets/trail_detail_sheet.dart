import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:simlog_mobile/core/theme/app_colors.dart';
import 'package:simlog_mobile/features/audit/data/models/audit_models.dart';
import 'package:simlog_mobile/features/audit/data/repositories/audit_repository.dart';
import 'package:simlog_mobile/shared/widgets/app_loading_view.dart';

class TrailDetailSheet extends ConsumerWidget {
  final int logId;

  const TrailDetailSheet({super.key, required this.logId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(auditRepositoryProvider);

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: FutureBuilder<AuditTrailItemModel>(
        future: repo.getAuditTrailDetail(logId),
        builder: (ctx, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const AppLoadingView();
          }
          if (snap.hasError || snap.data == null) {
            return Center(child: Text('Gagal memuat detail log: ${snap.error}'));
          }

          final log = snap.data!;

          return Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 8, bottom: 4),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Log Forensik #${log.id}',
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                    Text(log.aksi,
                        style: const TextStyle(
                            fontWeight: FontWeight.w800, color: AppColors.primaryPurple)),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Text('Entitas: ${log.referensiJenis} ID ${log.referensiId}',
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    Text('Operator: ${log.penggunaNama} (${log.peran})',
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                    Text('Waktu: ${log.waktu}',
                        style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
                    Text('IP: ${log.ipAddress} • Device: ${log.device}',
                        style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
                    const SizedBox(height: 16),
                    const Text('Data Sebelum Perubahan (Nilai Lama):',
                        style: TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 12, color: AppColors.danger)),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                          color: AppColors.canvas, borderRadius: BorderRadius.circular(8)),
                      child: Text(
                        log.dataSebelum != null
                            ? log.dataSebelum.toString()
                            : '[Kosong / Nilai Awal]',
                        style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text('Data Sesudah Perubahan (Nilai Baru):',
                        style: TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 12, color: AppColors.success)),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                          color: AppColors.canvas, borderRadius: BorderRadius.circular(8)),
                      child: Text(
                        log.dataSesudah != null
                            ? log.dataSesudah.toString()
                            : '[Kosong / Dihapus]',
                        style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
