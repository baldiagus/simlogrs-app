import '../../../auth/presentation/providers/auth_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/core_providers.dart';
import '../../data/models/dashboard_summary_model.dart';
import '../../data/repositories/dashboard_repository.dart';

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  final client = ref.watch(dioClientProvider);
  return DashboardRepository(client);
});

final dashboardSummaryProvider =
    FutureProvider.autoDispose<DashboardSummaryModel>((ref) async {
  final repository = ref.watch(dashboardRepositoryProvider);
  final user = ref.watch(authStateProvider).user;
  final canViewSpk = (user?.can('page_AdminLogistikDashboard') ?? false) ||
      (user?.can('view_any_pemeliharaan::spk::perbaikan') ?? false) ||
      (user?.hasRole('teknisi') ?? false) ||
      (user?.hasRole('admin_logistik') ?? false) ||
      (user?.hasRole('super_admin') ?? false);

  return await repository.getSummary(canViewSpk: canViewSpk);
});
