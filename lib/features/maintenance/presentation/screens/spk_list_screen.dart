import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/empty_state_view.dart';
import '../../../../shared/widgets/status_badge.dart';
import '../../../../shared/widgets/app_error_view.dart';
import '../../../../shared/widgets/app_filter_chip_bar.dart';
import '../../../../shared/widgets/app_loading_view.dart';
import '../../data/models/spk_model.dart';
import '../providers/maintenance_provider.dart';
import 'spk_detail_screen.dart';

class SpkListScreen extends ConsumerStatefulWidget {
  final bool isEmbedded;
  final String initialStatus;
  final String? customTitle;

  const SpkListScreen({
    super.key,
    this.isEmbedded = false,
    this.initialStatus = 'SEMUA',
    this.customTitle,
  });

  @override
  ConsumerState<SpkListScreen> createState() => _SpkListScreenState();
}
class _SpkListScreenState extends ConsumerState<SpkListScreen> {
  late String _selectedStatus;

  @override
  void initState() {
    super.initState();
    _selectedStatus = widget.initialStatus;
  }
  @override
  Widget build(BuildContext context) {
    final spkListAsync = ref.watch(spkListProvider(_selectedStatus));

    return Scaffold(
      appBar: widget.isEmbedded
          ? null
          : AppBar(
              title: Text(widget.customTitle ?? 'Surat Perintah Kerja (SPK)'),
              actions: [
                IconButton(
                  icon: const Icon(LucideIcons.refreshCw, size: 18),
                  tooltip: 'Segarkan',
                  onPressed: () => ref.invalidate(spkListProvider(_selectedStatus)),
                ),
              ],
            ),
      body: SafeArea(
        child: Column(
          children: [
            // Filter Status Horizontal Pills
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              color: AppColors.surface,
              child: AppFilterChipBar<String>(
                selected: _selectedStatus,
                onSelected: (val) => setState(() => _selectedStatus = val),
                options: const [
                  AppFilterOption(label: 'Semua SPK', value: 'SEMUA'),
                  AppFilterOption(label: 'Ditugaskan', value: 'DITUGASKAN'),
                  AppFilterOption(label: 'Diterima', value: 'DITERIMA'),
                  AppFilterOption(label: 'Selesai', value: 'SELESAI'),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.border),

            // Content List
            Expanded(
              child: RefreshIndicator(
                color: AppColors.primaryPurple,
                onRefresh: () async => ref.invalidate(spkListProvider(_selectedStatus)),
                child: spkListAsync.when(
                  data: (list) {
                    if (list.isEmpty) {
                      return SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: SizedBox(
                          height: MediaQuery.of(context).size.height * 0.65,
                          child: const EmptyStateView(
                            icon: LucideIcons.wrench,
                            title: 'Tidak Ada Tugas SPK',
                            message: 'Saat ini belum ada surat perintah kerja perbaikan yang ditugaskan ke Anda.',
                          ),
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
                      itemCount: list.length,
                      itemBuilder: (context, index) {
                        final spk = list[index];
                        return _buildSpkCard(context, spk);
                      },
                    );
                  },
                  loading: () => const AppLoadingView(),
                  error: (err, _) => AppErrorView(
                    title: 'Gagal Memuat Tugas SPK',
                    error: err,
                    onRetry: () => ref.invalidate(spkListProvider(_selectedStatus)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildSpkCard(BuildContext context, SpkHeaderModel spk) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: spk.tiket.isCito
              ? AppColors.danger.withValues(alpha: 0.35)
              : AppColors.border,
          width: spk.tiket.isCito ? 1.5 : 1.0,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(15, 23, 42, 0.03),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => SpkDetailScreen(spkId: spk.id, kodeSpk: spk.kodeSpk),
            ),
          );
        },
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.tintTealBg,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          spk.kodeSpk,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.tintTeal,
                          ),
                        ),
                      ),
                      if (spk.tiket.isCito) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF2F2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'CITO',
                            style: TextStyle(
                              color: AppColors.danger,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  StatusBadge(status: spk.status),
                ],
              ),
              const SizedBox(height: 12),

              // Asset Name
              Text(
                spk.aset.nama,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Kode: ${spk.aset.kodeAset} • Lokasi: ${spk.aset.lokasi}',
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 8),

              // Problem Description Preview
              Text(
                spk.tiket.deskripsiMasalah,
                style: const TextStyle(fontSize: 12, color: AppColors.textPrimary, height: 1.4),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),

              // Footer Meta
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.surfaceSecondary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(LucideIcons.calendar, size: 13, color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Text(
                          'Target: ${spk.targetSelesai ?? '-'}',
                          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Text(
                          spk.status.toUpperCase() == 'SELESAI' ? 'Buka SPK' : 'Catat Lembar Kerja',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primaryPurple),
                        ),
                        const Icon(LucideIcons.chevronRight, size: 14, color: AppColors.primaryPurple),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
