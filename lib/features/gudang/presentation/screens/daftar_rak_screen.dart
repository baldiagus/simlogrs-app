import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
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
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

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
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.canvas,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (val) {
                    ref.read(rakSearchQueryProvider.notifier).state = val.trim();
                  },
                  decoration: InputDecoration(
                    hintText: 'Cari kode rak atau nama lokasi...',
                    hintStyle: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                    prefixIcon:
                        const Icon(LucideIcons.search, size: 18, color: AppColors.textSecondary),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(LucideIcons.x, size: 16),
                            onPressed: () {
                              _searchController.clear();
                              ref.read(rakSearchQueryProvider.notifier).state = '';
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
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
                  loading: () => const Center(
                    child: CircularProgressIndicator(color: AppColors.primaryPurple),
                  ),
                  error: (error, _) => Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(LucideIcons.alertCircle, size: 48, color: AppColors.danger),
                          const SizedBox(height: 12),
                          const Text(
                            'Gagal Memuat Rak Gudang',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            error.toString().replaceAll('Exception: ', ''),
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () => ref.invalidate(daftarRakProvider),
                            icon: const Icon(LucideIcons.refreshCw, size: 16),
                            label: const Text('Coba Lagi'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryPurple,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
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
