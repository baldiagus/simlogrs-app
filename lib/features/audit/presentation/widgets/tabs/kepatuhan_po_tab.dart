import '../../../../../core/network/user_error_message.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:simlog_mobile/core/theme/app_colors.dart';
import 'package:simlog_mobile/core/theme/app_shadows.dart';
import 'package:simlog_mobile/core/utils/app_formatters.dart';
import 'package:simlog_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:simlog_mobile/features/audit/data/models/audit_models.dart';
import 'package:simlog_mobile/features/audit/presentation/providers/audit_provider.dart';
import 'package:simlog_mobile/shared/widgets/app_error_view.dart';
import 'package:simlog_mobile/shared/widgets/app_loading_view.dart';
import 'package:simlog_mobile/shared/widgets/empty_state_view.dart';

/// Tab audit kepatuhan pengadaan PO vs PR; [onTerbitkanCapa] dipanggil saat auditor menerbitkan CAPA dari PO.
class KepatuhanPoTab extends ConsumerStatefulWidget {
  final ValueChanged<KepatuhanPoModel> onTerbitkanCapa;

  const KepatuhanPoTab({super.key, required this.onTerbitkanCapa});

  /// Membuat state tab kepatuhan PO.
  @override
  ConsumerState<KepatuhanPoTab> createState() => _KepatuhanPoTabState();
}

/// State tab kepatuhan PO: menyimpan controller pencarian PO.
class _KepatuhanPoTabState extends ConsumerState<KepatuhanPoTab> {
  final TextEditingController _poSearchCtrl = TextEditingController();

  /// Membuang controller pencarian agar tidak bocor memori.
  @override
  void dispose() {
    _poSearchCtrl.dispose();
    super.dispose();
  }

  /// Membangun tab kepatuhan PO: filter anomali, pencarian, dan daftar PO dari [kepatuhanPengadaanProvider].
  @override
  Widget build(BuildContext context) {
    final currentFilter = ref.watch(kepatuhanPoFilterProvider);
    final poListAsync = ref.watch(kepatuhanPengadaanProvider);
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
                controller: _poSearchCtrl,
                decoration: InputDecoration(
                  hintText: 'Cari kode PO atau nama vendor...',
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
                  ref.read(kepatuhanPoSearchProvider.notifier).state = val;
                },
              ),
              const SizedBox(height: 10),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildPoFilterChip('SEMUA', 'Semua PO', currentFilter),
                    const SizedBox(width: 6),
                    _buildPoFilterChip('TANPA_PR', 'Tanpa PR (Mayor)', currentFilter),
                    const SizedBox(width: 6),
                    _buildPoFilterChip('TERLAMBAT', 'Terlambat Kirim', currentFilter),
                    const SizedBox(width: 6),
                    _buildPoFilterChip('SELISIH_RCV', 'Selisih Diterima', currentFilter),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: poListAsync.when(
            data: (pos) {
              if (pos.isEmpty) {
                return const EmptyStateView(
                  icon: LucideIcons.shieldCheck,
                  title: 'Semua Transaksi Patuh',
                  message:
                      'Tidak ditemukan transaksi PO dengan anomali kepatuhan pada filter ini.',
                );
              }

              return RefreshIndicator(
                onRefresh: () async => ref.refresh(kepatuhanPengadaanProvider),
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: pos.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (ctx, i) => _buildKepatuhanPoCard(pos[i], isAuditor),
                ),
              );
            },
            loading: () => const AppLoadingView(),
            error: (err, _) => AppErrorView(
              title: 'Gagal Memuat Kepatuhan PO',
              error: userErrorMessage(err, action: 'memuat kepatuhan PO'),
              onRetry: () => ref.refresh(kepatuhanPengadaanProvider),
            ),
          ),
        ),
      ],
    );
  }

  /// Membangun chip filter anomali PO; chip [current] ditandai terpilih dan ketukan mengubah filter.
  Widget _buildPoFilterChip(String value, String label, String current) {
    final isSelected = value == current;
    return InkWell(
      onTap: () {
        ref.read(kepatuhanPoFilterProvider.notifier).state = value;
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryPurple : AppColors.canvas,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isSelected ? AppColors.primaryPurple : AppColors.border),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(color: isSelected ? AppColors.surface : AppColors.textSecondary, fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500),
        ),
      ),
    );
  }

  /// Membangun kartu PO beserta tag anomali; auditor mendapat tombol untuk menerbitkan CAPA.
  Widget _buildKepatuhanPoCard(KepatuhanPoModel po, bool isAuditor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: po.isCompliant ? AppColors.border : AppColors.danger.withValues(alpha: 0.3),
        ),
        boxShadow: AppShadows.softCard,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
                Text(
                  po.kode,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontFamily: 'JetBrains Mono'),
                ),
              if (po.isCompliant)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(6)),
                  child: Text('PATUH',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(color: AppColors.success)),
                )
              else
                  Wrap(
                    spacing: 4,
                    alignment: WrapAlignment.end,
                    children: po.anomaliTags.map((tag) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                            color: AppColors.danger.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(4)),
                        child: Text(
                          tag,
                          style: Theme.of(context).textTheme.labelMedium?.copyWith(color: AppColors.danger),
                        ),
                      );
                    }).toList(),
                  ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Rekanan / Vendor: ${po.pemasok}',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 2),
          Text(
            po.prKode != null
                ? 'Dasar PR: ${po.prKode} (${po.prUnit ?? "-"})'
                : 'Dasar PR: [Diterbitkan Tanpa PR]',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(color: po.prKode != null ? AppColors.textSecondary : AppColors.danger, fontWeight: po.prKode != null ? FontWeight.normal : FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
                Text(
                  'Nilai PO: ${AppFormatters.rupiah(po.totalBiaya)}',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(color: AppColors.tintBlue),
                ),
              const SizedBox(height: 4),
              Text(
                'Estimasi: ${po.estimasiTanggalKirim}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
              ),
            ],
          ),
          if (!po.isCompliant && isAuditor) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => widget.onTerbitkanCapa(po),
                icon: const Icon(LucideIcons.shieldAlert, size: 14, color: AppColors.danger),
                label: Text('Terbitkan Temuan CAPA',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.danger)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.danger),
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
