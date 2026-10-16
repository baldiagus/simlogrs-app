import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/empty_state_view.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/models/audit_models.dart';
import '../providers/audit_provider.dart';
import '../widgets/sheets/detail_temuan_sheet.dart';
import '../widgets/tabs/temuan_capa_tab.dart';

/// Layar mandiri register Temuan & CAPA untuk auditee (unit/gudang terperiksa) maupun auditor.
class TemuanCapaScreen extends ConsumerWidget {
  const TemuanCapaScreen({super.key});

  /// Membangun layar CAPA; tanpa [UserModel.hasCapaAccess] menampilkan 'Akses Ditolak (403)'.
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).user;

    if (!(user?.hasCapaAccess ?? false)) {
      return Scaffold(
        backgroundColor: AppColors.canvas,
        appBar: AppBar(title: const Text('Temuan & CAPA')),
        body: Center(
          child: EmptyStateView(
            icon: LucideIcons.shieldAlert,
            title: 'Akses Ditolak (403)',
            message: 'Anda tidak memiliki wewenang untuk mengakses Temuan & CAPA.',
            action: ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(LucideIcons.arrowLeft, size: 16),
              label: const Text('Kembali ke Beranda'),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: const Text(
          'Temuan & CAPA',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17),
        ),
        backgroundColor: AppColors.surface,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.refreshCw, size: 18),
            tooltip: 'Muat ulang',
            onPressed: () {
              ref.invalidate(registerTemuanProvider);
              ref.invalidate(capaMenungguCountProvider);
            },
          ),
        ],
      ),
      body: TemuanCapaTab(onOpenDetail: (temuan) => _bukaDetail(context, user, temuan)),
    );
  }

  /// Membuka sheet detail temuan dengan hak tindak lanjut/evaluasi sesuai user.
  void _bukaDetail(BuildContext context, UserModel? user, TemuanCapaModel temuan) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DetailTemuanSheet(
        temuan: temuan,
        canTindakLanjut: canTindakLanjutTemuan(user, temuan),
        canEvaluasi: canEvaluasiTemuan(user),
      ),
    );
  }
}
