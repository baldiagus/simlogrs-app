import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/empty_state_view.dart';
import '../../../../shared/widgets/status_badge.dart';
import '../../data/models/dashboard_summary_model.dart';

class LiveActivityFeed extends StatelessWidget {
  final List<ActivityItemModel> activities;

  const LiveActivityFeed({
    super.key,
    required this.activities,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Aktivitas Sistem Terkini',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        if (activities.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: EmptyStateView(
              title: 'Belum Ada Antrean',
              message: 'Tidak ada dokumen antrean aktif saat ini. Data bersumber langsung dari API backend.',
              icon: LucideIcons.checkCheck,
            ),
          )
        else
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
              itemCount: activities.length,
              separatorBuilder: (_, __) => const Divider(
                color: AppColors.border,
                height: 1,
                indent: 16,
                endIndent: 16,
              ),
              itemBuilder: (context, index) {
                final item = activities[index];
                final isPr = item.type == 'pr';

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      // Category Box Icon
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: isPr ? AppColors.tintVioletBg : AppColors.tintBlueBg,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          isPr ? LucideIcons.fileText : LucideIcons.truck,
                          size: 20,
                          color: isPr ? AppColors.tintViolet : AppColors.tintBlue,
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
                              '${item.subtitle} • ${item.timestamp}',
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
                );
              },
            ),
          ),
      ],
    );
  }
}
