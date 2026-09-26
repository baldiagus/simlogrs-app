import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';

class QuickActionGrid extends StatelessWidget {
  final int pendingCount;
  final bool isGudangUser;
  final bool isTeknisi;
  final bool isAdminLogistik;
  final bool isAuditor;
  final bool isManajemen;
  final VoidCallback onApprovalTap;
  final VoidCallback onRakGudangTap;
  final VoidCallback onAsetTap;
  final VoidCallback onLaporRusakTap;
  final VoidCallback? onInboundTap;
  final VoidCallback? onAmprahTap;
  final VoidCallback? onPickingTap;
  final VoidCallback? onSpkTap;
  final VoidCallback? onLembarKerjaTap;
  final VoidCallback? onRekamMedisTap;
  final VoidCallback? onPreventifTap;
  final VoidCallback? onAuditSpiTap;

  const QuickActionGrid({
    super.key,
    required this.pendingCount,
    this.isGudangUser = false,
    this.isTeknisi = false,
    this.isAdminLogistik = false,
    this.isAuditor = false,
    this.isManajemen = false,
    this.onAuditSpiTap,
    required this.onApprovalTap,
    required this.onRakGudangTap,
    required this.onAsetTap,
    required this.onLaporRusakTap,
    this.onInboundTap,
    this.onAmprahTap,
    this.onPickingTap,
    this.onSpkTap,
    this.onLembarKerjaTap,
    this.onRekamMedisTap,
    this.onPreventifTap,
  });

  @override
  Widget build(BuildContext context) {
    if (isTeknisi) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Aksi Cepat Teknisi IPSRS',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildActionCard(
                  title: 'Perintah Kerja',
                  subtitle: 'SPK Tugas Servis',
                  icon: LucideIcons.clipboardCheck,
                  bgColor: AppColors.tintVioletBg,
                  iconColor: AppColors.primaryPurple,
                  onTap: onSpkTap ?? onApprovalTap,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionCard(
                  title: 'Lembar Kerja',
                  subtitle: 'Log Pengerjaan Fisik',
                  icon: LucideIcons.wrench,
                  bgColor: AppColors.tintOrangeBg,
                  iconColor: AppColors.tintOrange,
                  onTap: onLembarKerjaTap ?? onLaporRusakTap,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildActionCard(
                  title: 'Rekam Medis Aset',
                  subtitle: 'Histori & Kesehatan',
                  icon: LucideIcons.stethoscope,
                  bgColor: AppColors.tintBlueBg,
                  iconColor: AppColors.tintBlue,
                  onTap: onRekamMedisTap ?? onAsetTap,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionCard(
                  title: 'Jadwal Preventif',
                  subtitle: 'Kalender Servis Rutin',
                  icon: LucideIcons.calendarClock,
                  bgColor: AppColors.tintTealBg,
                  iconColor: AppColors.tintTeal,
                  onTap: onPreventifTap ?? onRakGudangTap,
                ),
              ),
            ],
          ),
        ],
      );
    }
    if (isAuditor || isManajemen) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isAuditor ? 'Aksi Pengawasan SPI' : 'Aksi Eksekutif Direksi',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildActionCard(
                  title: 'Audit SPI Hub',
                  subtitle: 'Forensik & CAPA',
                  icon: LucideIcons.shieldAlert,
                  bgColor: AppColors.tintVioletBg,
                  iconColor: AppColors.primaryPurple,
                  onTap: onAuditSpiTap ?? onApprovalTap,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionCard(
                  title: 'Sirkulasi Aset',
                  subtitle: 'Peminjaman & Cek',
                  icon: LucideIcons.armchair,
                  bgColor: AppColors.tintOrangeBg,
                  iconColor: AppColors.tintOrange,
                  onTap: onAsetTap,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildActionCard(
                  title: 'Amprah Ruangan',
                  subtitle: 'Distribusi & SPPB',
                  icon: LucideIcons.boxes,
                  bgColor: AppColors.tintBlueBg,
                  iconColor: AppColors.tintBlue,
                  onTap: onAmprahTap ?? onRakGudangTap,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionCard(
                  title: 'Pantau SPK',
                  subtitle: 'Semua SPK RS (Lihat)',
                  icon: LucideIcons.clipboardCheck,
                  bgColor: AppColors.tintTealBg,
                  iconColor: AppColors.tintTeal,
                  onTap: onSpkTap ?? onLaporRusakTap,
                ),
              ),
            ],
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Aksi Cepat Operasional',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                title: 'Approval Cepat',
                subtitle: '$pendingCount menunggu',
                icon: LucideIcons.checkSquare,
                bgColor: AppColors.tintVioletBg,
                iconColor: AppColors.tintViolet,
                onTap: onApprovalTap,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: isAdminLogistik
                  ? _buildActionCard(
                      title: 'Sirkulasi Aset',
                      subtitle: 'Peminjaman & Cek',
                      icon: LucideIcons.armchair,
                      bgColor: AppColors.tintOrangeBg,
                      iconColor: AppColors.tintOrange,
                      onTap: onAsetTap,
                    )
                  : isGudangUser
                      ? _buildActionCard(
                          title: 'Daftar Rak Gudang',
                          subtitle: 'Stok & Aset per Rak',
                          icon: LucideIcons.archive,
                          bgColor: AppColors.tintBlueBg,
                          iconColor: AppColors.tintBlue,
                          onTap: onRakGudangTap,
                        )
                      : _buildActionCard(
                          title: 'Amprah Ruangan',
                          subtitle: 'Distribusi & SPPB',
                          icon: LucideIcons.boxes,
                          bgColor: AppColors.tintBlueBg,
                          iconColor: AppColors.tintBlue,
                          onTap: onAmprahTap ?? onRakGudangTap,
                        ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: isGudangUser
                  ? _buildActionCard(
                      title: 'Penerimaan PO',
                      subtitle: 'Inbound Vendor',
                      icon: LucideIcons.truck,
                      bgColor: AppColors.tintBlueBg,
                      iconColor: AppColors.tintBlue,
                      onTap: onInboundTap ?? onAsetTap,
                    )
                  : _buildActionCard(
                      title: 'Sirkulasi Aset',
                      subtitle: 'Peminjaman & Cek',
                      icon: LucideIcons.armchair,
                      bgColor: AppColors.tintOrangeBg,
                      iconColor: AppColors.tintOrange,
                      onTap: onAsetTap,
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: isGudangUser
                  ? _buildActionCard(
                      title: 'Picking FEFO',
                      subtitle: 'Alokasi Kirim SPPB',
                      icon: LucideIcons.arrowRightCircle,
                      bgColor: AppColors.tintVioletBg,
                      iconColor: AppColors.primaryPurple,
                      onTap: onPickingTap ?? onLaporRusakTap,
                    )
                  : _buildActionCard(
                      title: 'Lapor Rusak',
                      subtitle: 'IPSRS Fieldwork',
                      icon: LucideIcons.wrench,
                      bgColor: AppColors.tintTealBg,
                      iconColor: AppColors.tintTeal,
                      onTap: onLaporRusakTap,
                    ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color bgColor,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
          boxShadow: const [
            BoxShadow(
              color: Color.fromRGBO(15, 23, 42, 0.03),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: 22,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 3),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
