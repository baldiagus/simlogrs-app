import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simlog_mobile/features/auth/data/models/user_model.dart';
import 'package:simlog_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:simlog_mobile/features/maintenance/data/models/rekam_medis_aset_model.dart';
import 'package:simlog_mobile/features/maintenance/presentation/providers/ipsrs_providers.dart';
import 'package:simlog_mobile/features/maintenance/presentation/screens/rekam_medis_detail_screen.dart';

/// Notifier auth tiruan yang langsung terautentikasi sebagai [user].
class MockAuthNotifier extends StateNotifier<AuthState> implements AuthNotifier {
  MockAuthNotifier(UserModel user) : super(AuthState.authenticated(user));

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  const detail = RekamMedisDetailResponse(
    identitas: {
      'id': 1,
      'kode_aset': 'AST-1',
      'nama_sarana': 'Ventilator',
      'status': 'TERSEDIA',
      'total_servis': 0,
    },
    riwayatServis: [],
    jadwalPreventif: [
      {
        'id': 10,
        'kode': 'PRV-1',
        'jenis_maintenance': 'Kalibrasi',
        'interval': '6 Bulan Sekali',
        'tanggal_berikutnya': '2026-10-15',
        'teknisi': 'Budi',
        'status': 'AKTIF',
      },
    ],
  );

  /// Membuka layar Rekam Medis tab Preventif sebagai user dengan [role].
  Future<void> pumpAs(WidgetTester tester, String role) async {
    tester.view.physicalSize = const Size(400, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authStateProvider.overrideWith(
            (ref) => MockAuthNotifier(UserModel(id: 1, name: 'U', email: 'u@x.id', roles: [role], permissions: const [])),
          ),
          rekamMedisDetailProvider(1).overrideWith((ref) => Future.value(detail)),
        ],
        child: const MaterialApp(home: RekamMedisDetailScreen(asetId: 1)),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Preventif (1)'));
    await tester.pumpAndSettle();
  }

  testWidgets('Teknisi tidak melihat tombol Terbitkan SPK Servis', (tester) async {
    await pumpAs(tester, 'teknisi');
    expect(find.text('PRV-1'), findsOneWidget);
    expect(find.textContaining('Terbitkan SPK Servis'), findsNothing);
  });

  testWidgets('Kepala teknisi melihat tombol Terbitkan SPK Servis', (tester) async {
    await pumpAs(tester, 'kepala_teknisi');
    expect(find.textContaining('Terbitkan SPK Servis'), findsOneWidget);
  });
}
