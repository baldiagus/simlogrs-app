import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/theme/app_colors.dart';
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

    final avatar = Container(
          constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
          padding: const EdgeInsets.all(8),
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
            widthFactor: 1,
            heightFactor: 1,
            child: Text(
              initial,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Theme.of(context).colorScheme.onPrimary,
              ),
            ),
          ),
        );
    final identity = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Selamat Bertugas,',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 1.5),
              Text(
                user?.name ?? 'Pengguna',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 2.5),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                decoration: BoxDecoration(
                  color: AppColors.surfaceSecondary,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  unitBadge,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ],
          );
    final actions = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
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
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onError,
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final needsReflow = constraints.maxWidth < 280 ||
            MediaQuery.textScalerOf(context).scale(14) > 18;
        if (needsReflow) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [avatar, const Spacer(), actions],
              ),
              const SizedBox(height: 8),
              identity,
            ],
          );
        }
        return Row(
          children: [
            avatar,
            const SizedBox(width: 12),
            Expanded(child: identity),
            actions,
          ],
        );
      },
    );
  }
}

