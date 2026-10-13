import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/app_formatters.dart';
import '../../../../shared/widgets/app_error_view.dart';
import '../../../../shared/widgets/app_loading_view.dart';
import '../../../../shared/widgets/app_paged_list_view.dart';
import '../../../../shared/widgets/empty_state_view.dart';
import '../../data/models/notifikasi_model.dart';
import '../providers/notifikasi_provider.dart';

/// Layar Inbox notifikasi: daftar berhalaman, tandai dibaca, dan aksi "Tandai semua dibaca".
class NotifikasiScreen extends ConsumerWidget {
  /// Dipanggil setelah item diketuk dan ditandai dibaca; router memakainya untuk navigasi ke dokumen terkait.
  final void Function(NotifikasiModel notifikasi)? onBuka;

  /// Membuat instance [NotifikasiScreen].
  const NotifikasiScreen({super.key, this.onBuka});

  /// Membangun AppBar, lalu loading/error/kosong/daftar sesuai state inbox.
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(notifikasiListProvider);
    final notifier = ref.read(notifikasiListProvider.notifier);
    final adaBelumDibaca = ref.watch(belumDibacaProvider) > 0;

    Widget body;
    if (state.isLoading && state.items.isEmpty) {
      body = const AppLoadingView(message: 'Memuat notifikasi...');
    } else if (state.errorMessage != null && state.items.isEmpty) {
      body = AppErrorView(
        title: 'Gagal Memuat Notifikasi',
        error: state.errorMessage,
        onRetry: notifier.loadInitial,
      );
    } else {
      body = AppPagedListView<NotifikasiModel>.fromState(
        state: state,
        onLoadMore: notifier.loadMore,
        onRefresh: notifier.refresh,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        emptyWidget: const Padding(
          padding: EdgeInsets.only(top: 120),
          child: EmptyStateView(
            title: 'Belum ada notifikasi',
            message: 'Pemberitahuan terbaru akan muncul di sini.',
            icon: LucideIcons.bellOff,
          ),
        ),
        itemBuilder: (context, index, item) => _NotifikasiTile(
          item: item,
          onTap: () {
            notifier.tandaiDibaca(item.id);
            onBuka?.call(item);
          },
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: const Text(
          'Notifikasi',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        actions: [
          TextButton.icon(
            onPressed: adaBelumDibaca ? notifier.bacaSemua : null,
            icon: const Icon(LucideIcons.checkCheck, size: 16),
            label: const Text('Tandai semua dibaca'),
          ),
        ],
      ),
      body: body,
    );
  }
}

/// Satu baris notifikasi: ikon per tipe, judul (tebal bila belum dibaca), pesan, dan waktu relatif.
class _NotifikasiTile extends StatelessWidget {
  final NotifikasiModel item;
  final VoidCallback onTap;

  /// Membuat [_NotifikasiTile].
  const _NotifikasiTile({required this.item, required this.onTap});

  /// Membangun kartu notifikasi yang dapat diketuk.
  @override
  Widget build(BuildContext context) {
    final belumDibaca = !item.dibaca;
    final (ikon, warna) = _gayaTipe(item.tipe);
    return Material(
      color: belumDibaca ? AppColors.tintBlueBg : AppColors.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: warna.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(ikon, size: 20, color: warna),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.judul,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.textPrimary,
                              fontWeight: belumDibaca ? FontWeight.bold : FontWeight.w500,
                            ),
                          ),
                        ),
                        if (belumDibaca)
                          Container(
                            key: const ValueKey('titik-belum-dibaca'),
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.only(left: 8),
                            decoration: const BoxDecoration(
                              color: AppColors.primaryPurple,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.pesan,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      waktuRelatif(item.dibuatPada),
                      style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Memilih ikon dan warna aksen berdasarkan kode tipe notifikasi (lihat kontrak bagian 4).
(IconData, Color) _gayaTipe(String tipe) {
  switch (tipe) {
    case 'APPROVAL_PR':
    case 'APPROVAL_AMPRAH':
      return (LucideIcons.clipboardCheck, AppColors.tintOrange);
    case 'PR_DIPUTUSKAN':
    case 'AMPRAH_DIPUTUSKAN':
    case 'PINJAM_DIPUTUSKAN':
      return (LucideIcons.fileCheck, AppColors.tintBlue);
    case 'PO_TERBIT':
    case 'SPPB_DIKIRIM':
      return (LucideIcons.package, AppColors.tintTeal);
    case 'ANTREAN_PICKING':
      return (LucideIcons.boxes, AppColors.tintTeal);
    case 'TIKET_BARU':
    case 'SPK_DITUGASKAN':
    case 'SPK_PREVENTIF':
    case 'PERBAIKAN_SELESAI':
      return (LucideIcons.cpu, AppColors.tintViolet);
    case 'PINJAM_BARU':
    case 'PENGALIHAN_MASUK':
      return (LucideIcons.arrowRightLeft, AppColors.tintBlue);
    case 'PINJAM_JATUH_TEMPO':
    case 'PINJAM_TERLAMBAT':
      return (LucideIcons.clockAlert, AppColors.danger);
    case 'OTORISASI_STOK':
      return (LucideIcons.layers, AppColors.warning);
    default:
      return (LucideIcons.bell, AppColors.primaryPurple);
  }
}

/// Mengubah waktu menjadi teks relatif Indonesia ("Baru saja", "5 menit lalu"); lewat 7 hari memakai tanggal.
String waktuRelatif(DateTime waktu, {DateTime? sekarang}) {
  final selisih = (sekarang ?? DateTime.now()).difference(waktu);
  if (selisih.inMinutes < 1) return 'Baru saja';
  if (selisih.inMinutes < 60) return '${selisih.inMinutes} menit lalu';
  if (selisih.inHours < 24) return '${selisih.inHours} jam lalu';
  if (selisih.inDays < 7) return '${selisih.inDays} hari lalu';
  return AppFormatters.tanggal(waktu.toLocal());
}
