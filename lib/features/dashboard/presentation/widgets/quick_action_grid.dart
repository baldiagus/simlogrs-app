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
  final bool isKepalaTeknisi;
  final bool isAdminLogistik;
  final bool isAuditor;
  final bool isManajemen;
  final bool isPengadaan;
  final bool isKaru;
  final bool isKepalaGudang;
  final bool isPetugasGudang;
  final VoidCallback? onStockOpnameTap;
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
    this.isKepalaTeknisi = false,
    this.isAdminLogistik = false,
    this.isAuditor = false,
    this.isManajemen = false,
    this.isPengadaan = false,
    this.isKaru = false,
    this.isKepalaGudang = false,
    this.onAuditSpiTap,
    this.isPetugasGudang = false,
    this.onStockOpnameTap,
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
    if (isKepalaTeknisi) {
      return (
        'Aksi Komando & Disposisi IPSRS',
        [
          _QuickActionItem(
            title: 'Atur Tiket Servis',
            subtitle: 'Disposisi SPK Teknisi',
            icon: LucideIcons.clipboardList,
            bgColor: AppColors.tintOrangeBg,
            iconColor: AppColors.tintOrange,
            onTap: onLaporRusakTap,
          ),
          _QuickActionItem(
            title: 'Semua SPK',
            subtitle: 'Monitoring SPK Aktif',
            icon: LucideIcons.wrench,
            bgColor: AppColors.tintVioletBg,
            iconColor: AppColors.primaryPurple,
            onTap: onSpkTap ?? onLaporRusakTap,
          ),
          _QuickActionItem(
            title: 'Jadwal Preventif',
            subtitle: 'Kalender Servis Berkala',
            icon: LucideIcons.calendarClock,
            bgColor: AppColors.tintTealBg,
            iconColor: AppColors.tintTeal,
            onTap: onPreventifTap ?? onLaporRusakTap,
          ),
          _QuickActionItem(
            title: 'Rekam Medis Aset',
            subtitle: 'Audit Kesehatan Alat',
            icon: LucideIcons.stethoscope,
            bgColor: AppColors.tintBlueBg,
            iconColor: AppColors.tintBlue,
            onTap: onRekamMedisTap ?? onAsetTap,
          ),
        ],
      );
    }

    if (isTeknisi) {
      return (
        'Aksi Cepat Teknisi IPSRS',
        [
          _QuickActionItem(
            title: 'Tugas SPK',
            subtitle: 'Surat Perintah Kerja',
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

    final isPetugasUnit = !isKaru &&
        !isGudangUser &&
        !isAdminLogistik &&
        !isAuditor &&
        !isManajemen &&
        !isPengadaan &&
        !isTeknisi;

    return (
      'Aksi Cepat Operasional',
      [
        _QuickActionItem(
          title: 'Approval Cepat',
          subtitle: isPetugasUnit
              ? (pendingCount > 0 ? '$pendingCount menunggu' : 'Tidak ada antrean')
              : (pendingCount > 0 ? '$pendingCount menunggu' : 'Semua disetujui'),
          icon: LucideIcons.checkSquare,
          bgColor: AppColors.tintVioletBg,
          iconColor: AppColors.tintViolet,
          onTap: onApprovalTap,
        ),
        _QuickActionItem(
          title: (isAdminLogistik || isKepalaGudang)
              ? 'Sirkulasi Aset'
              : (isPetugasGudang
                  ? 'Stock Opname'
                  : (isGudangUser ? 'Daftar Rak Gudang' : 'Amprah Ruangan')),
          subtitle: (isAdminLogistik || isKepalaGudang)
              ? 'Peminjaman & Gudang'
              : (isPetugasGudang
                  ? 'Hitung Fisik di Rak'
                  : (isGudangUser ? 'Stok & Aset per Rak' : 'Distribusi & SPPB')),
          icon: (isAdminLogistik || isKepalaGudang)
              ? LucideIcons.armchair
              : (isPetugasGudang
                  ? LucideIcons.clipboardCheck
                  : (isGudangUser ? LucideIcons.archive : LucideIcons.boxes)),
          bgColor: (isAdminLogistik || isKepalaGudang)
              ? AppColors.tintOrangeBg
              : (isPetugasGudang ? AppColors.tintVioletBg : AppColors.tintBlueBg),
          iconColor: (isAdminLogistik || isKepalaGudang)
              ? AppColors.tintOrange
              : (isPetugasGudang ? AppColors.primaryPurple : AppColors.tintBlue),
          onTap: (isAdminLogistik || isKepalaGudang)
              ? onAsetTap
              : (isPetugasGudang
                  ? (onStockOpnameTap ?? onRakGudangTap)
                  : (isGudangUser ? onRakGudangTap : (onAmprahTap ?? onRakGudangTap))),
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
