import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/empty_state_view.dart';
import '../../../../shared/widgets/status_badge.dart';
import '../../../distribusi/presentation/screens/amprah_hub_screen.dart';
import '../../../gudang/presentation/screens/inbound_po_list_screen.dart';
import '../../../maintenance/presentation/screens/spk_list_screen.dart';
import '../../../pengadaan/presentation/screens/riwayat_pr_screen.dart';
import '../../data/models/dashboard_summary_model.dart';

class AllActivitiesScreen extends StatefulWidget {
  final List<ActivityItemModel> activities;

  const AllActivitiesScreen({
    super.key,
    required this.activities,
  });

  @override
  State<AllActivitiesScreen> createState() => _AllActivitiesScreenState();
}

class _AllActivitiesScreenState extends State<AllActivitiesScreen> {
  final TextEditingController _searchController = TextEditingController();
  String? _selectedType; // null = Semua, 'pr', 'amprah', 'spk', 'tiket', 'po'

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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

                  // Filter Chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterChip('Semua', null),
                        const SizedBox(width: 8),
                        _buildFilterChip('Pengadaan PR', 'pr'),
                        const SizedBox(width: 8),
                        _buildFilterChip('Amprah Ruangan', 'amprah'),
                        const SizedBox(width: 8),
                        _buildFilterChip('SPK Teknisi', 'spk'),
                        const SizedBox(width: 8),
                        _buildFilterChip('Tiket Servis', 'tiket'),
                        const SizedBox(width: 8),
                        _buildFilterChip('PO Inbound', 'po'),
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

  Widget _buildFilterChip(String label, String? value) {
    final isSelected = _selectedType == value;
    return InkWell(
      onTap: () => setState(() => _selectedType = value),
      borderRadius: BorderRadius.circular(20),
      child: Container(
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
    if (type == 'spk' || type == 'tiket') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const SpkListScreen()),
      );
    } else if (type == 'amprah') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const AmprahHubScreen()),
      );
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
