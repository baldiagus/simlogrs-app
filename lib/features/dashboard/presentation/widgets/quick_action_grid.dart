import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';

class _QuickActionItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color bgColor;
  final Color iconColor;
  final VoidCallback onTap;

  const _QuickActionItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.bgColor,
    required this.iconColor,
    required this.onTap,
  });
}

class QuickActionGrid extends StatelessWidget {
  final int pendingCount;
  final bool isGudangUser;
  final bool isTeknisi;
  final bool isAdminLogistik;
  final bool isAuditor;
  final bool isManajemen;
  final bool isPengadaan;
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
  final VoidCallback? onPaguRealisasiTap;

  const QuickActionGrid({
    super.key,
    required this.pendingCount,
    this.isGudangUser = false,
    this.isTeknisi = false,
    this.isAdminLogistik = false,
    this.isAuditor = false,
    this.isManajemen = false,
    this.isPengadaan = false,
    this.onAuditSpiTap,
    this.onPaguRealisasiTap,
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

  (String, List<_QuickActionItem>) _resolveSection() {
    if (isTeknisi) {
      return (
        'Aksi Cepat Teknisi IPSRS',
        [
          _QuickActionItem(
            title: 'Perintah Kerja',
            subtitle: 'SPK Tugas Servis',
            icon: LucideIcons.clipboardCheck,
            bgColor: AppColors.tintVioletBg,
            iconColor: AppColors.primaryPurple,
            onTap: onSpkTap ?? onApprovalTap,
          ),
          _QuickActionItem(
            title: 'Lembar Kerja',
            subtitle: 'Log Pengerjaan Fisik',
            icon: LucideIcons.wrench,
            bgColor: AppColors.tintOrangeBg,
            iconColor: AppColors.tintOrange,
            onTap: onLembarKerjaTap ?? onLaporRusakTap,
          ),
          _QuickActionItem(
            title: 'Rekam Medis Aset',
            subtitle: 'Histori & Kesehatan',
            icon: LucideIcons.stethoscope,
            bgColor: AppColors.tintBlueBg,
            iconColor: AppColors.tintBlue,
            onTap: onRekamMedisTap ?? onAsetTap,
          ),
          _QuickActionItem(
            title: 'Jadwal Preventif',
            subtitle: 'Kalender Servis Rutin',
            icon: LucideIcons.calendarClock,
            bgColor: AppColors.tintTealBg,
            iconColor: AppColors.tintTeal,
            onTap: onPreventifTap ?? onRakGudangTap,
          ),
        ],
      );
    }

    if (isAuditor || isManajemen) {
      return (
        isAuditor ? 'Aksi Pengawasan SPI' : 'Aksi Eksekutif Direksi',
        [
          _QuickActionItem(
            title: 'Audit SPI Hub',
            subtitle: 'Forensik & CAPA',
            icon: LucideIcons.shieldAlert,
            bgColor: AppColors.tintVioletBg,
            iconColor: AppColors.primaryPurple,
            onTap: onAuditSpiTap ?? onApprovalTap,
          ),
          _QuickActionItem(
            title: 'Pagu & Realisasi',
            subtitle: 'Logistik & IPSRS',
            icon: LucideIcons.banknote,
            bgColor: AppColors.tintTealBg,
            iconColor: AppColors.tintTeal,
            onTap: onPaguRealisasiTap ?? onApprovalTap,
          ),
          _QuickActionItem(
            title: 'Sirkulasi Aset',
            subtitle: 'Peminjaman & Cek',
            icon: LucideIcons.armchair,
            bgColor: AppColors.tintOrangeBg,
            iconColor: AppColors.tintOrange,
            onTap: onAsetTap,
          ),
          _QuickActionItem(
            title: 'Pantau SPK',
            subtitle: 'Semua SPK RS (Lihat)',
            icon: LucideIcons.clipboardCheck,
            bgColor: AppColors.tintTealBg,
            iconColor: AppColors.tintTeal,
            onTap: onSpkTap ?? onLaporRusakTap,
          ),
          _QuickActionItem(
            title: 'Amprah Ruangan',
            subtitle: 'Distribusi & SPPB',
            icon: LucideIcons.boxes,
            bgColor: AppColors.tintBlueBg,
            iconColor: AppColors.tintBlue,
            onTap: onAmprahTap ?? onRakGudangTap,
          ),
          _QuickActionItem(
            title: 'Inbound PO',
            subtitle: 'Status Vendor',
            icon: LucideIcons.truck,
            bgColor: AppColors.tintBlueBg,
            iconColor: AppColors.tintBlue,
            onTap: onInboundTap ?? onAsetTap,
          ),
        ],
      );
    }

    if (isPengadaan) {
      return (
        'Aksi Cepat Pengadaan & Belanja',
        [
          _QuickActionItem(
            title: 'Verifikasi PR',
            subtitle: '$pendingCount menunggu verifikasi',
            icon: LucideIcons.checkSquare,
            bgColor: AppColors.tintVioletBg,
            iconColor: AppColors.tintViolet,
            onTap: onApprovalTap,
          ),
          _QuickActionItem(
            title: 'Sirkulasi Aset',
            subtitle: 'Peminjaman & Cek',
            icon: LucideIcons.armchair,
            bgColor: AppColors.tintOrangeBg,
            iconColor: AppColors.tintOrange,
            onTap: onAsetTap,
          ),
          _QuickActionItem(
            title: 'Amprah Ruangan',
            subtitle: 'Distribusi & SPPB',
            icon: LucideIcons.boxes,
            bgColor: AppColors.tintBlueBg,
            iconColor: AppColors.tintBlue,
            onTap: onAmprahTap ?? onRakGudangTap,
          ),
          _QuickActionItem(
            title: 'Inbound PO',
            subtitle: 'Status Vendor',
            icon: LucideIcons.truck,
            bgColor: AppColors.tintBlueBg,
            iconColor: AppColors.tintBlue,
            onTap: onInboundTap ?? onAsetTap,
          ),
        ],
      );
    }

    return (
      'Aksi Cepat Operasional',
      [
        _QuickActionItem(
          title: 'Approval Cepat',
          subtitle: '$pendingCount menunggu',
          icon: LucideIcons.checkSquare,
          bgColor: AppColors.tintVioletBg,
          iconColor: AppColors.tintViolet,
          onTap: onApprovalTap,
        ),
        _QuickActionItem(
          title: isAdminLogistik
              ? 'Sirkulasi Aset'
              : (isGudangUser ? 'Daftar Rak Gudang' : 'Amprah Ruangan'),
          subtitle: isAdminLogistik
              ? 'Peminjaman & Cek'
              : (isGudangUser ? 'Stok & Aset per Rak' : 'Distribusi & SPPB'),
          icon: isAdminLogistik
              ? LucideIcons.armchair
              : (isGudangUser ? LucideIcons.archive : LucideIcons.boxes),
          bgColor: isAdminLogistik ? AppColors.tintOrangeBg : AppColors.tintBlueBg,
          iconColor: isAdminLogistik ? AppColors.tintOrange : AppColors.tintBlue,
          onTap: isAdminLogistik
              ? onAsetTap
              : (isGudangUser ? onRakGudangTap : (onAmprahTap ?? onRakGudangTap)),
        ),
        _QuickActionItem(
          title: isGudangUser ? 'Penerimaan PO' : 'Sirkulasi Aset',
          subtitle: isGudangUser ? 'Inbound Vendor' : 'Peminjaman & Cek',
          icon: isGudangUser ? LucideIcons.truck : LucideIcons.armchair,
          bgColor: isGudangUser ? AppColors.tintBlueBg : AppColors.tintOrangeBg,
          iconColor: isGudangUser ? AppColors.tintBlue : AppColors.tintOrange,
          onTap: isGudangUser ? (onInboundTap ?? onAsetTap) : onAsetTap,
        ),
        _QuickActionItem(
          title: isGudangUser ? 'Picking FEFO' : 'Lapor Rusak',
          subtitle: isGudangUser ? 'Alokasi Kirim SPPB' : 'IPSRS Fieldwork',
          icon: isGudangUser ? LucideIcons.arrowRightCircle : LucideIcons.wrench,
          bgColor: isGudangUser ? AppColors.tintVioletBg : AppColors.tintTealBg,
          iconColor: isGudangUser ? AppColors.primaryPurple : AppColors.tintTeal,
          onTap: isGudangUser
              ? (onPickingTap ?? onLaporRusakTap)
              : onLaporRusakTap,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final (sectionTitle, items) = _resolveSection();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          sectionTitle,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        for (int i = 0; i < items.length; i += 2) ...[
          if (i > 0) const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildActionCard(items[i])),
              const SizedBox(width: 12),
              if (i + 1 < items.length)
                Expanded(child: _buildActionCard(items[i + 1]))
              else
                const Spacer(),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildActionCard(_QuickActionItem item) {
    return InkWell(
      onTap: item.onTap,
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
                color: item.bgColor,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                item.icon,
                color: item.iconColor,
                size: 22,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              item.title,
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
              item.subtitle,
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
