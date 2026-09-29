import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_error_view.dart';
import '../../../../shared/widgets/app_filter_chip_bar.dart';
import '../../../../shared/widgets/app_loading_view.dart';
import '../../../../shared/widgets/app_search_bar.dart';
import '../../../../shared/widgets/empty_state_view.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/tiket_maintenance_provider.dart';
import '../widgets/tiket_card_item.dart';
import 'lapor_cepat_screen.dart';
import 'spk_list_screen.dart';
import 'jadwal_preventif_screen.dart';
import 'rekam_medis_katalog_screen.dart';
class IpsrsHubScreen extends ConsumerStatefulWidget {
  const IpsrsHubScreen({super.key});

  @override
  ConsumerState<IpsrsHubScreen> createState() => _IpsrsHubScreenState();
}

class _IpsrsHubScreenState extends ConsumerState<IpsrsHubScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _canViewSpk = false;

  String _statusFilter = 'SEMUA';
  String _prioritasFilter = 'SEMUA';
  String _searchKeyword = '';


  @override
  void initState() {
    super.initState();
    final user = ref.read(authStateProvider).user;
    _canViewSpk = (user?.can('page_AdminLogistikDashboard') ?? false) ||
        (user?.can('view_any_pemeliharaan::spk::perbaikan') ?? false) ||
        (user?.hasRole('teknisi') ?? false) ||
        (user?.hasRole('admin_logistik') ?? false) ||
        (user?.hasRole('super_admin') ?? false);
    _tabController = TabController(length: _canViewSpk ? 3 : 1, vsync: this);
  }
  @override
  void dispose() {
    _tabController.dispose();

    super.dispose();
  }

  TiketFilterParams get _filterParams => TiketFilterParams(
        status: _statusFilter,
        prioritas: _prioritasFilter,
        cari: _searchKeyword,
      );

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).user;
    final isTeknisi = user?.isTeknisi ?? false;

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: Text(isTeknisi ? 'Pekerjaan Teknisi IPSRS' : 'Lapor Kerusakan & IPSRS'),
        actions: [
          if (_canViewSpk)
            IconButton(
              icon: const Icon(LucideIcons.stethoscope, size: 20),
              tooltip: 'Rekam Medis Aset',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const RekamMedisKatalogScreen()),
                );
              },
            ),
          IconButton(
            icon: const Icon(LucideIcons.refreshCw, size: 18),
            tooltip: 'Segarkan',
            onPressed: () {
              ref.invalidate(daftarTiketUnitProvider);
            },
          ),
        ],
        bottom: _canViewSpk
            ? TabBar(
                controller: _tabController,
                indicatorColor: AppColors.primaryPurple,
                indicatorWeight: 3,
                labelColor: AppColors.primaryPurple,
                unselectedLabelColor: AppColors.textSecondary,
                labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                tabs: isTeknisi
                    ? const [
                        Tab(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(LucideIcons.wrench, size: 15),
                              SizedBox(width: 5),
                              Flexible(child: Text('Tugas SPK', maxLines: 1, overflow: TextOverflow.ellipsis)),
                            ],
                          ),
                        ),
                        Tab(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(LucideIcons.calendarClock, size: 15),
                              SizedBox(width: 5),
                              Flexible(child: Text('Preventif', maxLines: 1, overflow: TextOverflow.ellipsis)),
                            ],
                          ),
                        ),
                        Tab(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(LucideIcons.clipboardList, size: 15),
                              SizedBox(width: 5),
                              Flexible(child: Text('Tiket Masuk', maxLines: 1, overflow: TextOverflow.ellipsis)),
                            ],
                          ),
                        ),
                      ]
                    : const [
                        Tab(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(LucideIcons.clipboardList, size: 15),
                              SizedBox(width: 5),
                              Flexible(child: Text('Tiket Unit', maxLines: 1, overflow: TextOverflow.ellipsis)),
                            ],
                          ),
                        ),
                        Tab(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(LucideIcons.wrench, size: 15),
                              SizedBox(width: 5),
                              Flexible(child: Text('SPK Teknisi', maxLines: 1, overflow: TextOverflow.ellipsis)),
                            ],
                          ),
                        ),
                        Tab(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(LucideIcons.calendarClock, size: 15),
                              SizedBox(width: 5),
                              Flexible(child: Text('Preventif', maxLines: 1, overflow: TextOverflow.ellipsis)),
                            ],
                          ),
                        ),
                      ],
              )
            : null,
      ),
      floatingActionButton: isTeknisi
          ? null
          : FloatingActionButton.extended(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const LaporCepatScreen()),
                );
              },
              backgroundColor: AppColors.primaryPurple,
              foregroundColor: Colors.white,
              icon: const Icon(LucideIcons.plus, size: 18),
              label: const Text('Lapor Kerusakan', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
      body: _canViewSpk
          ? TabBarView(
              controller: _tabController,
              children: isTeknisi
                  ? [
                      const SpkListScreen(isEmbedded: true),
                      const JadwalPreventifScreen(isEmbedded: true),
                      _buildTiketUnitView(),
                    ]
                  : [
                      _buildTiketUnitView(),
                      const SpkListScreen(isEmbedded: true),
                      const JadwalPreventifScreen(isEmbedded: true),
                    ],
            )
          : _buildTiketUnitView(),
    );
  }

  Widget _buildTiketUnitView() {
    final tiketListAsync = ref.watch(daftarTiketUnitProvider(_filterParams));

    return Column(
      children: [
        // Search & Filters Toolbar
        Container(
          color: AppColors.surface,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Search input
              AppSearchBar(
                hint: 'Cari kode tiket, nama alat, keluhan...',
                onChanged: (v) => setState(() => _searchKeyword = v.trim()),
                onClear: () => setState(() => _searchKeyword = ''),
              ),
              const SizedBox(height: 10),
              AppFilterChipBar<String>(
                padding: EdgeInsets.zero,
                selected: _statusFilter,
                onSelected: (val) => setState(() => _statusFilter = val),
                options: const [
                  AppFilterOption(label: 'Semua Status', value: 'SEMUA'),
                  AppFilterOption(label: 'DILAPORKAN', value: 'DILAPORKAN'),
                  AppFilterOption(label: 'DITUGASKAN', value: 'DITUGASKAN'),
                  AppFilterOption(label: 'SEDANG DIKERJAKAN', value: 'SEDANG_DIKERJAKAN'),
                  AppFilterOption(label: 'UJI FUNGSI', value: 'UJI_FUNGSI'),
                  AppFilterOption(label: 'SELESAI', value: 'SELESAI'),
                  AppFilterOption(label: 'DIBATALKAN', value: 'DIBATALKAN'),
                ],
              ),
              const SizedBox(height: 6),

              // Filter Prioritas Pills
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    const Text('Prioritas: ', style: TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
                    const SizedBox(width: 4),
                    _buildPrioritasPill('SEMUA', 'Semua'),
                    const SizedBox(width: 6),
                    _buildPrioritasPill('CITO', 'CITO (Darurat)', color: AppColors.danger),
                    const SizedBox(width: 6),
                    _buildPrioritasPill('TINGGI', 'Tinggi', color: AppColors.warning),
                    const SizedBox(width: 6),
                    _buildPrioritasPill('SEDANG', 'Sedang', color: AppColors.tintBlue),
                    const SizedBox(width: 6),
                    _buildPrioritasPill('RENDAH', 'Rendah'),
                  ],
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: AppColors.border),

        // List View
        Expanded(
          child: RefreshIndicator(
            color: AppColors.primaryPurple,
            onRefresh: () async => ref.invalidate(daftarTiketUnitProvider),
            child: tiketListAsync.when(
              data: (list) {
                if (list.isEmpty) {
                  return SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: SizedBox(
                      height: MediaQuery.of(context).size.height * 0.6,
                      child: EmptyStateView(
                        icon: LucideIcons.clipboardCheck,
                        title: 'Tidak Ada Tiket Kerusakan',
                        message: 'Belum ada laporan kerusakan sarana yang sesuai pada ruangan Anda.',
                        action: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const LaporCepatScreen()),
                            );
                          },
                          icon: const Icon(LucideIcons.plus, size: 16),
                          label: const Text('Buat Laporan Baru'),
                        ),
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
                  itemCount: list.length,
                  itemBuilder: (context, index) {
                    final item = list[index];
                    return TiketCardItem(
                      item: item,
                      onCancelTap: () async {
                        final ok = await ref.read(tiketActionProvider.notifier).batalkanTiket(item.id);
                        if (!context.mounted) return;
                        final s = ref.read(tiketActionProvider);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(ok ? (s.successMessage ?? 'Dibatalkan') : (s.errorMessage ?? 'Gagal')),
                            backgroundColor: ok ? AppColors.success : AppColors.danger,
                          ),
                        );
                      },
                    );
                  },
                );
              },
              loading: () => const AppLoadingView(),
              error: (err, _) => AppErrorView(
                title: 'Gagal Memuat Tiket Kerusakan',
                error: err,
                onRetry: () => ref.invalidate(daftarTiketUnitProvider),
              ),
            ),
          ),
        ),
      ],
    );
  }


  Widget _buildPrioritasPill(String val, String label, {Color? color}) {
    final isSelected = _prioritasFilter == val;
    final effectiveColor = color ?? AppColors.textPrimary;

    return InkWell(
      onTap: () => setState(() => _prioritasFilter = val),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: isSelected ? effectiveColor.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? effectiveColor : AppColors.border,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
            color: isSelected ? effectiveColor : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
