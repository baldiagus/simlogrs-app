import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/empty_state_view.dart';
import '../../../../shared/widgets/status_badge.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../distribusi/presentation/screens/amprah_hub_screen.dart';
import '../../../distribusi/presentation/screens/detail_amprah_screen.dart';
import '../../../gudang/presentation/screens/inbound_po_list_screen.dart';
import '../../../maintenance/presentation/screens/detail_tiket_screen.dart';
import '../../../maintenance/presentation/screens/spk_detail_screen.dart';
import '../../../maintenance/presentation/screens/spk_list_screen.dart';
import '../../../pengadaan/presentation/screens/riwayat_pr_screen.dart';
import '../../data/models/dashboard_summary_model.dart';

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

  bool _isFilterAvailableForRole(String? type, UserModel? user) {
    if (type == null) return true; // 'Semua' selalu aktif
    if (user == null) return true;

    final isAdmin = user.hasRole('super_admin') || user.hasRole('admin_logistik');
    if (isAdmin) return true;

    final isTeknisi = user.isTeknisi;
    final isGudang = user.isGudangUser;
    final isPengadaan = user.hasRole('pengadaan') || user.hasRole('manajemen');
    final isUnitUser = user.unit != null || user.hasRole('petugas_unit') || user.hasRole('kepala_unit');

    switch (type.toLowerCase()) {
      case 'spk':
        return isTeknisi;
      case 'tiket':
        return isTeknisi || isUnitUser;
      case 'pr':
        return (isUnitUser && !isTeknisi) || isPengadaan;
      case 'amprah':
        return (isUnitUser && !isTeknisi) || isGudang;
      case 'po':
      case 'inbound':
        return isGudang || isPengadaan;
      default:
        return true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).user;
    final query = _searchController.text.trim().toLowerCase();

    final filtered = widget.activities.where((item) {
      if (_selectedType != null && item.type.toLowerCase() != _selectedType) {
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

                  // Filter Chips dengan status ketersediaan berbasis role
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterChip('Semua', null, true),
                        _buildFilterChip('Pengadaan PR', 'pr', _isFilterAvailableForRole('pr', user)),
                        _buildFilterChip('Amprah Ruangan', 'amprah', _isFilterAvailableForRole('amprah', user)),
                        _buildFilterChip('SPK Teknisi', 'spk', _isFilterAvailableForRole('spk', user)),
                        _buildFilterChip('Tiket Servis', 'tiket', _isFilterAvailableForRole('tiket', user)),
                        _buildFilterChip('PO Inbound', 'po', _isFilterAvailableForRole('po', user)),
                      ],
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

  Widget _buildFilterChip(String label, String? value, bool isEnabled) {
    final isSelected = _selectedType == value;

    if (!isEnabled) {
      return InkWell(
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Filter $label tidak tersedia untuk wewenang role Anda.'),
              duration: const Duration(seconds: 1),
            ),
          );
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          margin: const EdgeInsets.only(right: 8),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.surfaceSecondary.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.border.withValues(alpha: 0.5),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(LucideIcons.lock, size: 11, color: AppColors.textMuted),
              const SizedBox(width: 4),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      );
    }

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
    } else if (type == 'pr') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const RiwayatPrScreen()),
      );
    }
  }
}
