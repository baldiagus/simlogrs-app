import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/utils/app_formatters.dart';
import '../../data/models/dashboard_summary_model.dart';

class HeroStatusCard extends StatelessWidget {
  final DashboardSummaryModel summary;
  final VoidCallback onInspectPressed;

  const HeroStatusCard({
    super.key,
    required this.summary,
    required this.onInspectPressed,
  });

  /// Membangun kartu utama berisi metrik hero dan sub-metrik ringkasan dashboard.
  @override
  Widget build(BuildContext context) {
    final hero = summary.hero;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: const BoxDecoration(
        gradient: AppColors.primaryHeroGradient,
        borderRadius: BorderRadius.all(Radius.circular(24)),
        boxShadow: AppShadows.heroCard,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Title & Action Pill
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  hero.judul,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: onInspectPressed,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0x33FFFFFF),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0x22FFFFFF)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        hero.labelTombol,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 14),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Total Number
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              hero.satuan == 'Rp'
                  ? AppFormatters.rupiah(hero.total)
                  : '${hero.total} ${hero.satuan}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
          ),
          const SizedBox(height: 18),

          // Sub Info breakdown
          if (hero.subMetrik.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0x1A000000),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  for (int i = 0; i < hero.subMetrik.length; i++) ...[
                    if (i > 0)
                      Container(width: 1, height: 20, color: const Color(0x33FFFFFF)),
                    Expanded(
                      child: _buildSubItem(
                        hero.subMetrik[i].label,
                        hero.subMetrik[i].nilai,
                      ),
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }

  /// Membangun satu item sub-metrik (nilai di atas, label di bawah) di dalam kartu hero.
  Widget _buildSubItem(String label, String value) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
