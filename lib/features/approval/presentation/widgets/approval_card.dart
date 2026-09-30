import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/custom_button.dart';
import '../../../../shared/widgets/status_badge.dart';
import '../../data/models/approval_item_model.dart';
import '../../../pengadaan/data/models/pr_model.dart';

class ApprovalCard extends StatefulWidget {
  final ApprovalItemModel item;
  final bool canApprove;
  final VoidCallback onApproveTap;
  final VoidCallback onRejectTap;
  final VoidCallback? onSerahkanTap;
  final VoidCallback? onTerbitkanPoTap;
  const ApprovalCard({
    super.key,
    required this.item,
    required this.canApprove,
    required this.onApproveTap,
    required this.onRejectTap,
    this.onSerahkanTap,
    this.onTerbitkanPoTap,
  });

  @override
  State<ApprovalCard> createState() => _ApprovalCardState();
}

class _ApprovalCardState extends State<ApprovalCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final isPr = item.tipe == 'PR';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: item.isCito ? AppColors.danger.withValues(alpha: 0.3) : AppColors.border,
          width: item.isCito ? 1.5 : 1.0,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(15, 23, 42, 0.03),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Row
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: isPr ? AppColors.tintVioletBg : AppColors.tintBlueBg,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                isPr ? LucideIcons.fileText : LucideIcons.truck,
                                size: 14,
                                color: isPr ? AppColors.tintViolet : AppColors.tintBlue,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                item.kode,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: isPr ? AppColors.tintViolet : AppColors.tintBlue,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        if (item.isCito)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF2F2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'CITO',
                              style: TextStyle(
                                color: AppColors.danger,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        if (item.status != null) ...[
                          const SizedBox(width: 6),
                          StatusBadge(status: item.status!),
                        ],
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Unit & Pemohon
                Text(
                  item.unit ?? 'Unit Pemohon',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(LucideIcons.user, size: 13, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      'Oleh: ${item.pengaju ?? 'Staf'}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Icon(LucideIcons.calendar, size: 13, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      item.tanggal,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Items summary & toggle
          InkWell(
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: AppColors.surfaceSecondary.withValues(alpha: 0.6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(LucideIcons.boxes, size: 15, color: AppColors.primaryPurple),
                      const SizedBox(width: 6),
                      Text(
                        '${item.jumlahItem} Item Barang',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Text(
                        _isExpanded ? 'Sembunyikan' : 'Lihat Rincian',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryPurple,
                        ),
                      ),
                      Icon(
                        _isExpanded ? LucideIcons.chevronUp : LucideIcons.chevronDown,
                        size: 14,
                        color: AppColors.primaryPurple,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Expanded items list
          if (_isExpanded) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                children: item.items.map((detail) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                detail.namaBarang,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              if (detail.kodeBarang != null)
                                Text(
                                  detail.kodeBarang!,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textMuted,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceSecondary,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'x${detail.jumlah}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],

          // Action Buttons Divider & Row
          const Divider(height: 1, color: AppColors.border),
          Padding(
            padding: const EdgeInsets.all(12),
            child: isPr && (item.status == PrStatus.diteruskanKePengadaan || item.status == PrStatus.disetujui)
                ? (widget.onTerbitkanPoTap != null
                    ? CustomButton(
                        text: 'Terbitkan PO (Pesanan Pembelian)',
                        height: 42,
                        backgroundColor: AppColors.primaryPurple,
                        textColor: Colors.white,
                        icon: const Icon(LucideIcons.filePlus, size: 16, color: Colors.white),
                        onPressed: widget.onTerbitkanPoTap,
                      )
                    : (widget.onSerahkanTap != null && widget.canApprove
                        ? CustomButton(
                            text: 'Serahkan ke Bagian Pengadaan',
                            height: 42,
                            backgroundColor: AppColors.primaryPurple,
                            textColor: Colors.white,
                            icon: const Icon(LucideIcons.send, size: 16, color: Colors.white),
                            onPressed: widget.onSerahkanTap,
                          )
                        : const Padding(
                            padding: EdgeInsets.symmetric(vertical: 4),
                            child: Text(
                              'Telah disetujui • Menunggu penerbitan PO oleh Bagian Pengadaan',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.textMuted,
                                fontStyle: FontStyle.italic,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          )))
                : (widget.canApprove
                    ? Row(
                        children: [
                          Expanded(
                            child: CustomButton(
                              text: 'Tolak',
                              height: 42,
                              backgroundColor: const Color(0xFFFEF2F2),
                              textColor: AppColors.danger,
                              icon: const Icon(LucideIcons.x, size: 16, color: AppColors.danger),
                              onPressed: widget.onRejectTap,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: CustomButton(
                              text: 'Setujui',
                              height: 42,
                              backgroundColor: AppColors.success,
                              textColor: Colors.white,
                              icon: const Icon(LucideIcons.check, size: 16, color: Colors.white),
                              onPressed: widget.onApproveTap,
                            ),
                          ),
                        ],
                      )
                    : const Padding(
                        padding: EdgeInsets.symmetric(vertical: 4),
                        child: Text(
                          'Menunggu otorisasi pejabat yang berwenang',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.textMuted,
                            fontStyle: FontStyle.italic,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      )),
          ),
        ],
      ),
    );
  }
}
