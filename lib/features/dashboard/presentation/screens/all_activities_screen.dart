import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/empty_state_view.dart';
import '../../../../shared/widgets/status_badge.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../aset/presentation/screens/sirkulasi_aset_hub_screen.dart';
import '../../../distribusi/presentation/screens/amprah_hub_screen.dart';
import '../../../distribusi/presentation/screens/detail_amprah_screen.dart';
import '../../../gudang/presentation/screens/inbound_po_list_screen.dart';
import '../../../maintenance/presentation/screens/detail_tiket_screen.dart';
import '../../../maintenance/presentation/screens/spk_detail_screen.dart';
import '../../../maintenance/presentation/screens/spk_list_screen.dart';
import '../../../pengadaan/presentation/screens/riwayat_pr_screen.dart';
import '../../data/models/dashboard_summary_model.dart';

class _ActivityFilterOption {
  final String label;
  final String? value; // null = Semua
  const _ActivityFilterOption(this.label, this.value);
}

class AllActivitiesScreen extends ConsumerStatefulWidget {
  final List<ActivityItemModel> activities;

  const AllActivitiesScreen({
    super.key,
    required this.activities,
  });

  @override
  ConsumerState<AllActivitiesScreen> createState() => _AllActivitiesScreenState();
}

class _AllActivitiesScreenState extends ConsumerState<AllActivitiesScreen> {
  final TextEditingController _searchController = TextEditingController();
  String? _selectedType; // null = Semua, 'pr', 'amprah', 'spk', 'tiket', 'po'

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<_ActivityFilterOption> _getRoleFilterOptions(UserModel? user) {
    if (user == null) {
      return const [
        _ActivityFilterOption('Semua', null),
      ];
    }

    final isHighLevelViewer = user.hasRole('super_admin') ||
        user.hasRole('admin_logistik') ||
        user.isAuditor ||
        user.isManajemen;
    if (isHighLevelViewer) {
      return const [
        _ActivityFilterOption('Semua', null),
        _ActivityFilterOption('Pengadaan PR', 'pr'),
        _ActivityFilterOption('Amprah Ruangan', 'amprah'),
        _ActivityFilterOption('Pinjam Aset', 'pinjam'),
        _ActivityFilterOption('SPK Teknisi', 'spk'),
        _ActivityFilterOption('Tiket Servis', 'tiket'),
        _ActivityFilterOption('PO Inbound', 'po'),
      ];
    }

    // Role Teknisi IPSRS: hanya SPK dan Tiket Servis
    if (user.isTeknisi) {
      return const [
        _ActivityFilterOption('Semua', null),
        _ActivityFilterOption('SPK Teknisi', 'spk'),
        _ActivityFilterOption('Tiket Servis', 'tiket'),
      ];
    }

    // Role Gudang (Kepala & Petugas): hanya Amprah dan PO Inbound
    if (user.isGudangUser) {
      return const [
        _ActivityFilterOption('Semua', null),
        _ActivityFilterOption('Amprah Ruangan', 'amprah'),
        _ActivityFilterOption('PO Inbound', 'po'),
        _ActivityFilterOption('Pinjam Gudang', 'pinjam'),
      ];
    }

    // Role Unit Pelayanan (Karu & Petugas Unit): Amprah, PR, dan Tiket Servis
    if (user.isKaru || user.hasRole('petugas_unit') || user.unit != null) {
      return const [
        _ActivityFilterOption('Semua', null),
        _ActivityFilterOption('Amprah Ruangan', 'amprah'),
        _ActivityFilterOption('Pengadaan PR', 'pr'),
        _ActivityFilterOption('Pinjam Aset', 'pinjam'),
        _ActivityFilterOption('Lapor Rusak', 'tiket'),
      ];
    }

    // Role Pengadaan & Manajemen: PR, PO Inbound, dan Amprah
    if (user.hasRole('pengadaan') || user.hasRole('manajemen')) {
      return const [
        _ActivityFilterOption('Semua', null),
        _ActivityFilterOption('Pengadaan PR', 'pr'),
        _ActivityFilterOption('PO Inbound', 'po'),
        _ActivityFilterOption('Amprah Ruangan', 'amprah'),
      ];
    }

    return const [
      _ActivityFilterOption('Semua', null),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).user;
    final query = _searchController.text.trim().toLowerCase();

    final filterOptions = _getRoleFilterOptions(user);
    final isSelectedValid = filterOptions.any((opt) => opt.value == _selectedType);
    final activeSelectedType = isSelectedValid ? _selectedType : null;

    final filtered = widget.activities.where((item) {
      if (activeSelectedType != null && item.type.toLowerCase() != activeSelectedType) {
        return false;
      }
      if (query.isNotEmpty) {
        final matchTitle = item.title.toLowerCase().contains(query);
        final matchSub = item.subtitle.toLowerCase().contains(query);
        final matchCode = (item.kode ?? '').toLowerCase().contains(query);
        final matchStatus = item.status.toLowerCase().contains(query);
        return matchTitle || matchSub || matchCode || matchStatus;
      }
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: const Text('Semua Aktivitas Sistem'),
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
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Cari kode, transaksi, atau unit...',
                      prefixIcon: const Icon(LucideIcons.search, size: 18),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(LucideIcons.x, size: 16),
                              onPressed: () {
                                setState(() {
                                  _searchController.clear();
                                });
                              },
                            )
                          : null,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 10),

                  // Filter Chips eksklusif hanya untuk fitur yang tersedia pada role
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: filterOptions.map((opt) {
                        return _buildFilterChip(opt.label, opt.value, activeSelectedType);
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(color: AppColors.border, height: 1),

            // Activity List
            Expanded(
              child: filtered.isEmpty
                  ? const EmptyStateView(
                      icon: LucideIcons.inbox,
                      title: 'Tidak Ada Aktivitas Ditemukan',
                      message: 'Tidak ada dokumen aktivitas yang sesuai dengan filter atau kata kunci.',
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final item = filtered[index];
                        final (iconData, iconColor, iconBg) = _resolveTypeStyle(item.type);

                        final subtitleText = item.waktuLalu.isNotEmpty
                            ? '${item.subtitle} • ${item.waktuLalu}'
                            : (item.timestamp.isNotEmpty ? '${item.subtitle} • ${item.timestamp}' : item.subtitle);

                        return InkWell(
                          onTap: () => _handleItemTap(context, item),
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: iconBg,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(iconData, size: 22, color: iconColor),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              item.title,
                                              style: const TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w700,
                                                color: AppColors.textPrimary,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          StatusBadge(status: item.status),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        subtitleText,
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: AppColors.textSecondary,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Icon(LucideIcons.chevronRight, size: 16, color: AppColors.textSecondary),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String? value, String? currentSelected) {
    final isSelected = currentSelected == value;

    return InkWell(
      onTap: () => setState(() => _selectedType = value),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryPurple : AppColors.canvas,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primaryPurple : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  (IconData, Color, Color) _resolveTypeStyle(String type) {
    switch (type.toLowerCase()) {
      case 'spk':
        return (LucideIcons.wrench, AppColors.tintOrange, AppColors.tintOrangeBg);
      case 'tiket':
        return (LucideIcons.alertTriangle, AppColors.danger, const Color(0xFFFEF2F2));
      case 'po':
      case 'inbound':
        return (LucideIcons.truck, AppColors.tintTeal, AppColors.tintTealBg);
      case 'amprah':
        return (LucideIcons.boxes, AppColors.tintBlue, AppColors.tintBlueBg);
      case 'pinjam':
        return (LucideIcons.repeat, AppColors.tintViolet, AppColors.tintVioletBg);
      case 'pr':
      default:
        return (LucideIcons.fileText, AppColors.tintViolet, AppColors.tintVioletBg);
    }
  }

  void _handleItemTap(BuildContext context, ActivityItemModel item) {
    final type = item.type.toLowerCase();
    final itemId = int.tryParse(item.id);

    if (type == 'spk') {
      if (itemId != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SpkDetailScreen(
              spkId: itemId,
              kodeSpk: item.kode ?? item.title,
            ),
          ),
        );
      } else {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const SpkListScreen()),
        );
      }
    } else if (type == 'tiket') {
      if (itemId != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DetailTiketScreen(
              tiketId: itemId,
              kodeTiket: item.kode ?? item.title,
            ),
          ),
        );
      } else {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const SpkListScreen()),
        );
      }
    } else if (type == 'amprah') {
      if (itemId != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DetailAmprahScreen(
              amprahId: itemId,
              kodeAmprah: item.kode ?? item.title,
            ),
          ),
        );
      } else {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AmprahHubScreen()),
        );
      }
    } else if (type == 'po' || type == 'inbound') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const InboundPoListScreen()),
      );
    } else if (type == 'pinjam') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const SirkulasiAsetHubScreen()),
      );
    } else if (type == 'pr') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const RiwayatPrScreen()),
      );
    }
  }
}
