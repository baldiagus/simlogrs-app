import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_error_view.dart';
import '../../../../shared/widgets/app_loading_view.dart';
import '../../../../shared/widgets/app_search_bar.dart';
import '../../../../shared/widgets/empty_state_view.dart';
import '../providers/gudang_provider.dart';
import '../widgets/rak_card_item.dart';
import 'detail_rak_screen.dart';

class DaftarRakScreen extends ConsumerStatefulWidget {
  const DaftarRakScreen({super.key});

  @override
  ConsumerState<DaftarRakScreen> createState() => _DaftarRakScreenState();
}

class _DaftarRakScreenState extends ConsumerState<DaftarRakScreen> {

  @override
  Widget build(BuildContext context) {
    final rakListAsync = ref.watch(daftarRakProvider);

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Daftar Rak Gudang',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              'Monitoring Ruang Simpan & Inventaris',
              style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Search Bar Filter
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: AppColors.surface,
              child: AppSearchBar(
                hint: 'Cari kode rak atau nama lokasi...',
                onChanged: (val) {
                  ref.read(rakSearchQueryProvider.notifier).state = val.trim();
                },
              ),
            ),
            const Divider(height: 1, color: AppColors.border),

            // Content List
            Expanded(
              child: RefreshIndicator(
                color: AppColors.primaryPurple,
                onRefresh: () async {
                  ref.invalidate(daftarRakProvider);
                },
                child: rakListAsync.when(
                  loading: () => const AppLoadingView(),
                  error: (error, _) => AppErrorView(
                    title: 'Gagal Memuat Rak Gudang',
                    error: error,
                    onRetry: () => ref.invalidate(daftarRakProvider),
                  ),
                  data: (rakList) {
                    if (rakList.isEmpty) {
                      return const EmptyStateView(
                        icon: LucideIcons.archive,
                        title: 'Tidak Ada Rak Gudang',
                        message:
                            'Belum ada data rak penyimpanan atau tidak ditemukan rak yang sesuai dengan kueri pencarian.',
                      );
                    }

                    return ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      itemCount: rakList.length,
                      itemBuilder: (context, index) {
                        final rak = rakList[index];
                        return RakCardItem(
                          rak: rak,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => DetailRakScreen(
                                  rakId: rak.id,
                                  kodeRak: rak.kode,
                                  namaRak: rak.nama,
                                ),
                              ),
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
