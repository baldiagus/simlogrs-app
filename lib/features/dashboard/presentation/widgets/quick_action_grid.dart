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
  final VoidCallback? onPengadaanTap;
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
    this.onPengadaanTap,
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

  /// Menentukan judul seksi dan daftar aksi cepat operasional yang ditampilkan.
  (String, List<_QuickActionItem>) _resolveSection() {
    return (
      'Aksi Cepat Operasional',
      [
        _QuickActionItem(
          title: 'Pengadaan',
          subtitle: isGudangUser ? 'Inbound PO & Usulan PR' : 'Usulan PR & Pesanan PO',
          icon: LucideIcons.shoppingBag,
          bgColor: AppColors.tintVioletBg,
          iconColor: AppColors.tintViolet,
          onTap: onPengadaanTap ?? onApprovalTap,
        ),
        _QuickActionItem(
          title: 'Amprah Ruangan',
          subtitle: isGudangUser ? 'Penyaluran Stok SPPB' : 'Distribusi & SPPB',
          icon: LucideIcons.boxes,
          bgColor: AppColors.tintBlueBg,
          iconColor: AppColors.tintBlue,
          onTap: onAmprahTap ?? onRakGudangTap,
        ),
        _QuickActionItem(
          title: 'Sirkulasi Aset',
          subtitle: (isAdminLogistik || isKepalaGudang)
              ? 'Peminjaman & Gudang'
              : 'Peminjaman & Cek',
          icon: LucideIcons.armchair,
          bgColor: AppColors.tintOrangeBg,
          iconColor: AppColors.tintOrange,
          onTap: onAsetTap,
        ),
        _QuickActionItem(
          title: 'Lapor Rusak',
          subtitle: 'Tiket & Lapor Cepat',
          icon: LucideIcons.wrench,
          bgColor: AppColors.tintTealBg,
          iconColor: AppColors.tintTeal,
          onTap: onLaporRusakTap,
        ),
      ],
    );
  }

  /// Membangun seksi aksi cepat beserta grid kartu aksinya.
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

  /// Membungkus satu aksi menjadi kartu dengan efek tekan (tactile).
  Widget _buildActionCard(_QuickActionItem item) {
    return _TactileActionCard(item: item);
  }
}

class _TactileActionCard extends StatefulWidget {
  final _QuickActionItem item;
  const _TactileActionCard({required this.item});

  /// Membuat state untuk animasi tekan pada kartu aksi.
  @override
  State<_TactileActionCard> createState() => _TactileActionCardState();
}

class _TactileActionCardState extends State<_TactileActionCard> {
  bool _isPressed = false;

  /// Membangun kartu aksi dengan animasi skala saat ditekan agar terasa responsif.
  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: _isPressed ? 0.97 : 1.0,
      duration: const Duration(milliseconds: 140),
      curve: Curves.easeOutCubic,
      child: InkWell(
        onTap: widget.item.onTap,
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
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
                  color: widget.item.bgColor,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  widget.item.icon,
                  color: widget.item.iconColor,
                  size: 22,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                widget.item.title,
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
                widget.item.subtitle,
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
      ),
    );
  }
}
