import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simlog_mobile/core/theme/app_theme.dart';
import 'package:simlog_mobile/features/auth/data/models/user_model.dart';
import 'package:simlog_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:simlog_mobile/features/audit/data/models/audit_models.dart';
import 'package:simlog_mobile/features/audit/presentation/providers/audit_provider.dart';
import 'package:simlog_mobile/features/audit/presentation/screens/audit_spi_hub_screen.dart';

class _Auth extends StateNotifier<AuthState> implements AuthNotifier {
  _Auth() : super(AuthState.authenticated(const UserModel(id: 1, name: 'Auditor', email: 'audit@test.local', roles: ['auditor'], permissions: [])));
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  for (final scale in [1.0, 2.0]) {
    testWidgets('Audit summary remains one reachable row at 343px / $scale', (tester) async {
      tester.view.physicalSize = const Size(343, 762);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(ProviderScope(overrides: [
        authStateProvider.overrideWith((ref) => _Auth()),
        auditSummaryProvider.overrideWith((ref) async => AuditSummaryModel.fromJson({
          'capa': {'total_in_progress': 4, 'closing_rate': 42.9},
          'kepatuhan_po': {'total_anomali': 5},
          'selisih_opname': {'sesi_berselisih': 3},
        })),
        selisihOpnameProvider.overrideWith((ref) async => <String, dynamic>{}),
      ], child: MaterialApp(theme: AppTheme.lightTheme,
        builder: (context, child) => MediaQuery(data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)), child: child!),
        home: const AuditSpiHubScreen(initialTab: 2))));
      await tester.pumpAndSettle();
      final values = ['4', '42.9%', '5', '3'];
      final firstY = tester.getTopLeft(find.text(values.first)).dy;
      for (final value in values) {
        expect(tester.getTopLeft(find.text(value)).dy, closeTo(firstY, 0.1));
      }
      if (scale == 1) {
        for (final label in ['Open CAPA', 'Closing Rate', 'Anomali PO', 'Selisih Opname']) {
          final rect = tester.getRect(find.text(label).last);
          expect(rect.left, greaterThanOrEqualTo(0));
          expect(rect.right, lessThanOrEqualTo(343));
        }
      } else {
        await tester.ensureVisible(find.text('3'));
        expect(find.text('3').hitTestable(), findsOneWidget);
      }
      expect(tester.takeException(), isNull);
    });
  }
}
