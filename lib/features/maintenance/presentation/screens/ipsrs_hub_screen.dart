import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/empty_state_view.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/tiket_maintenance_provider.dart';
import '../widgets/tiket_card_item.dart';
import 'lapor_cepat_screen.dart';
import 'spk_list_screen.dart';

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
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final user = ref.read(authStateProvider).user;
    _canViewSpk = (user?.can('page_AdminLogistikDashboard') ?? false) ||
        (user?.can('view_any_pemeliharaan::spk::perbaikan') ?? false) ||
        (user?.hasRole('teknisi') ?? false) ||
        (user?.hasRole('admin_logistik') ?? false) ||
        (user?.hasRole('super_admin') ?? false);

    _tabController = TabController(length: _canViewSpk ? 2 : 1, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  TiketFilterParams get _filterParams => TiketFilterParams(
        status: _statusFilter,
        prioritas: _prioritasFilter,
        cari: _searchKeyword,
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: const Text('Lapor Kerusakan & IPSRS'),
        actions: [
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
                tabs: const [
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(LucideIcons.clipboardList, size: 16),
                        SizedBox(width: 6),
                        Text('Tiket Kerusakan Unit'),
                      ],
                    ),
                  ),
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(LucideIcons.wrench, size: 16),
                        SizedBox(width: 6),
                        Text('Tugas SPK Teknisi'),
                      ],
                    ),
                  ),
                ],
              )
            : null,
      ),
      floatingActionButton: FloatingActionButton.extended(
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
              children: [
                _buildTiketUnitView(),
                const SpkListScreen(),
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
              Container(
                decoration: BoxDecoration(
                  color: AppColors.canvas,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (v) => setState(() => _searchKeyword = v.trim()),
                  decoration: InputDecoration(
                    hintText: 'Cari kode tiket, nama alat, keluhan...',
                    hintStyle: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                    prefixIcon: const Icon(LucideIcons.search, size: 18, color: AppColors.textSecondary),
                    suffixIcon: _searchKeyword.isNotEmpty
                        ? IconButton(
                            icon: const Icon(LucideIcons.x, size: 16),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchKeyword = '');
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // Filter Status Horizontal Pills
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildPill(
                      label: 'Semua Status',
                      isSelected: _statusFilter == 'SEMUA',
                      onTap: () => setState(() => _statusFilter = 'SEMUA'),
                    ),
                    const SizedBox(width: 6),
                    _buildPill(
                      label: 'DILAPORKAN',
                      isSelected: _statusFilter == 'DILAPORKAN',
                      onTap: () => setState(() => _statusFilter = 'DILAPORKAN'),
                    ),
                    const SizedBox(width: 6),
                    _buildPill(
                      label: 'DITUGASKAN',
                      isSelected: _statusFilter == 'DITUGASKAN',
                      onTap: () => setState(() => _statusFilter = 'DITUGASKAN'),
                    ),
                    const SizedBox(width: 6),
                    _buildPill(
                      label: 'SEDANG DIKERJAKAN',
                      isSelected: _statusFilter == 'SEDANG_DIKERJAKAN',
                      onTap: () => setState(() => _statusFilter = 'SEDANG_DIKERJAKAN'),
                    ),
                    const SizedBox(width: 6),
                    _buildPill(
                      label: 'UJI FUNGSI',
                      isSelected: _statusFilter == 'UJI_FUNGSI',
                      onTap: () => setState(() => _statusFilter = 'UJI_FUNGSI'),
                    ),
                    const SizedBox(width: 6),
                    _buildPill(
                      label: 'SELESAI',
                      isSelected: _statusFilter == 'SELESAI',
                      onTap: () => setState(() => _statusFilter = 'SELESAI'),
                    ),
                    const SizedBox(width: 6),
                    _buildPill(
                      label: 'DIBATALKAN',
                      isSelected: _statusFilter == 'DIBATALKAN',
                      onTap: () => setState(() => _statusFilter = 'DIBATALKAN'),
                    ),
                  ],
                ),
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
              loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primaryPurple)),
              error: (err, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(LucideIcons.alertCircle, size: 40, color: AppColors.danger),
                      const SizedBox(height: 12),
                      const Text('Gagal Memuat Tiket Kerusakan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 6),
                      Text(err.toString().replaceAll('ApiException: ', ''), textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                      const SizedBox(height: 14),
                      ElevatedButton(
                        onPressed: () => ref.invalidate(daftarTiketUnitProvider),
                        child: const Text('Coba Lagi'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPill({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryPurple : AppColors.canvas,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isSelected ? AppColors.primaryPurple : AppColors.border),
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
