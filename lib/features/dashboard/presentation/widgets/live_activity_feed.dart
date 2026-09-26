import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/empty_state_view.dart';
import '../../../../shared/widgets/status_badge.dart';
import '../../../aset/presentation/screens/sirkulasi_aset_hub_screen.dart';
import '../../../distribusi/presentation/screens/amprah_hub_screen.dart';
import '../../../distribusi/presentation/screens/detail_amprah_screen.dart';
import '../../../gudang/presentation/screens/inbound_po_list_screen.dart';
import '../../../maintenance/presentation/screens/spk_list_screen.dart';
import '../../../maintenance/presentation/screens/spk_detail_screen.dart';
import '../../../maintenance/presentation/screens/detail_tiket_screen.dart';
import '../../../pengadaan/presentation/screens/riwayat_pr_screen.dart';
import '../../data/models/dashboard_summary_model.dart';
import '../screens/all_activities_screen.dart';

class LiveActivityFeed extends StatelessWidget {
  final List<ActivityItemModel> activities;

  const LiveActivityFeed({
    super.key,
    required this.activities,
  });

  @override
  Widget build(BuildContext context) {
    final hasMore = activities.length > 5;
    final displayItems = hasMore ? activities.take(5).toList() : activities;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header Baris: Judul & Tombol "Lihat Semua" (jika > 5 data)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Aktivitas Sistem Terkini',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            if (hasMore)
              InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AllActivitiesScreen(activities: activities),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(10),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Lihat Semua (${activities.length})',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryPurple,
                        ),
                      ),
                      const SizedBox(width: 2),
                      const Icon(
                        LucideIcons.chevronRight,
                        size: 14,
                        color: AppColors.primaryPurple,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 14),

        if (activities.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: EmptyStateView(
              title: 'Belum Ada Antrean',
              message: 'Tidak ada dokumen antrean aktif saat ini. Data bersumber langsung dari API backend.',
              icon: LucideIcons.checkCheck,
            ),
          )
        else ...[
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(vertical: 6),
              itemCount: displayItems.length,
              separatorBuilder: (_, __) => const Divider(
                color: AppColors.border,
                height: 1,
                indent: 16,
                endIndent: 16,
              ),
              itemBuilder: (context, index) {
                final item = displayItems[index];
                final (iconData, iconColor, iconBg) = _resolveTypeStyle(item.type);

                final subtitleText = item.waktuLalu.isNotEmpty
                    ? '${item.subtitle} • ${item.waktuLalu}'
                    : (item.timestamp.isNotEmpty ? '${item.subtitle} • ${item.timestamp}' : item.subtitle);

                return InkWell(
                  onTap: () => _handleItemTap(context, item),
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        // Category Box Icon
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: iconBg,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(
                            iconData,
                            size: 20,
                            color: iconColor,
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Title & Subtitle
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.title,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 3),
                              Text(
                                subtitleText,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textSecondary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Status Badge
                        StatusBadge(status: item.status),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Tombol Bawah jika ada lebih dari 5 data
          if (hasMore) ...[
            const SizedBox(height: 10),
            InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AllActivitiesScreen(activities: activities),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(14),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Lihat Semua ${activities.length} Riwayat Aktivitas',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryPurple,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(LucideIcons.arrowRight, size: 14, color: AppColors.primaryPurple),
                  ],
                ),
              ),
            ),
          ],
        ],
      ],
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
