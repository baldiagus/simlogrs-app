import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/theme/app_colors.dart';
import '../../core/notifications/push_notification_service.dart';
import '../../features/notifikasi/presentation/providers/notifikasi_provider.dart';
import '../../features/notifikasi/presentation/screens/notifikasi_screen.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';

/// Baris atas pengguna berisi avatar inisial, identitas sesi, dan lonceng notifikasi dengan badge status.
class UserTopBar extends ConsumerWidget {
  /// Membuat instance [UserTopBar].
  const UserTopBar({super.key});

  /// Membangun antarmuka bar atas pengguna dengan avatar, teks sapaan, dan tombol aksi.
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).user;
    final initial = (user != null && user.name.isNotEmpty)
        ? user.name.substring(0, 1).toUpperCase()
        : 'U';
    final unitBadge = user?.unit?.kode ??
        user?.unit?.nama ??
        user?.gudang?.kode ??
        user?.gudang?.nama ??
        'Sentral RS';

    // Badge lonceng: sinkron dari server sekali saat bar dibangun, lalu dijaga oleh inbox.
    ref.watch(belumDibacaSinkronProvider);
    final belumDibaca = ref.watch(belumDibacaProvider);

    return Row(
      children: [
        // Avatar Bulat 44x44px
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            gradient: AppColors.primaryHeroGradient,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: const [
              BoxShadow(
                color: Color.fromRGBO(91, 80, 230, 0.2),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: Text(
              initial,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),

        // Sapaan & Nama Pengguna
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text(
                    'Selamat Bertugas,',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: ValueListenableBuilder<FcmStatus>(
                      valueListenable: PushNotificationService.instance.fcmStatus,
                      builder: (context, status, _) => _FcmStatusLabel(status: status),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Flexible(
                    child: Text(
                      user?.name ?? 'Pengguna',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceSecondary,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        unitBadge,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryPurple,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Lonceng Notifikasi dengan Badge Status
        Stack(
          clipBehavior: Clip.none,
          children: [
            IconButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const NotifikasiScreen()),
              ),
              icon: const Icon(
                LucideIcons.bell,
                size: 20,
                color: AppColors.textSecondary,
              ),
              tooltip: 'Notifikasi',
            ),
            if (belumDibaca > 0)
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                  decoration: BoxDecoration(
                    color: Colors.red.shade600,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    belumDibaca > 99 ? '99+' : '$belumDibaca',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      height: 1.0,
                    ),
                  ),
                ),
              ),
          ],
        ),

        // Tombol Keluar (Logout)
        IconButton(
          onPressed: () {
            ref.read(authStateProvider.notifier).logout();
          },
          icon: const Icon(
            LucideIcons.logOut,
            size: 20,
            color: AppColors.textSecondary,
          ),
          tooltip: 'Keluar',
        ),
      ],
    );
  }
}

/// Label status FCM berwarna: hijau bila aktif, kuning untuk izin ditolak/token belum terdaftar, abu untuk lainnya.
class _FcmStatusLabel extends StatelessWidget {
  final FcmStatus status;

  /// Membuat label status FCM untuk [status].
  const _FcmStatusLabel({required this.status});

  /// Membangun titik warna dan teks Indonesia singkat sesuai [status].
  @override
  Widget build(BuildContext context) {
    final (String label, MaterialColor warna) = switch (status) {
      FcmStatus.aktif => ('FCM Aktif', Colors.green),
      FcmStatus.tokenBelumTerdaftar => ('Token Belum Terdaftar', Colors.amber),
      FcmStatus.izinDitolak => ('Izin Ditolak', Colors.amber),
      FcmStatus.tidakTersedia => ('FCM Tidak Tersedia', Colors.grey),
      FcmStatus.belumDiinisialisasi => ('FCM Belum Siap', Colors.grey),
    };
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(color: warna.shade600, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: warna.shade800,
            ),
          ),
        ),
      ],
    );
  }
}
