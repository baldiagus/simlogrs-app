import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simlog_mobile/features/auth/data/models/user_model.dart';
import 'package:simlog_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:simlog_mobile/features/maintenance/data/models/jadwal_preventif_model.dart';
import 'package:simlog_mobile/features/maintenance/data/models/tiket_maintenance_model.dart';
import 'package:simlog_mobile/features/maintenance/presentation/providers/ipsrs_providers.dart';
import 'package:simlog_mobile/features/maintenance/presentation/providers/maintenance_provider.dart';
import 'package:simlog_mobile/features/maintenance/presentation/screens/ipsrs_hub_screen.dart';
import 'package:simlog_mobile/features/maintenance/data/models/spk_header_model.dart';
import 'package:simlog_mobile/features/maintenance/presentation/providers/tiket_maintenance_provider.dart';
import 'package:simlog_mobile/features/maintenance/presentation/screens/jadwal_preventif_screen.dart';
import 'package:simlog_mobile/shared/widgets/app_search_bar.dart';

class MockAuthNotifier extends StateNotifier<AuthState> implements AuthNotifier {
  MockAuthNotifier(UserModel user) : super(AuthState.authenticated(user));

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  const kepalaTeknisiUser = UserModel(
    id: 11,
    name: 'Ir. Gunawan, S.T.',
    email: 'karu_ipsrs@simlogrs.local',
    roles: ['kepala_teknisi', 'panel_user'],
    permissions: ['page_TeknisiDashboard', 'create_pemeliharaan::pemeliharaan::berkala'],
    unit: UnitModel(id: 2, nama: 'Instalasi Pemeliharaan Sarana Rumah Sakit', kode: 'IPSRS'),
  );

  const teknisiUser = UserModel(
    id: 8,
    name: 'Agus Priyono, A.Md.T.',
    email: 'teknisi@simlogrs.local',
    roles: ['teknisi', 'panel_user'],
    permissions: ['page_TeknisiDashboard'],
    unit: UnitModel(id: 2, nama: 'Instalasi Pemeliharaan Sarana Rumah Sakit', kode: 'IPSRS'),
  );

  testWidgets('IpsrsHubScreen for Kepala Teknisi hides Preventif tab and hides search bar', (tester) async {
    tester.view.physicalSize = const Size(400, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authStateProvider.overrideWith((ref) => MockAuthNotifier(kepalaTeknisiUser)),
          daftarTiketUnitProvider.overrideWith((ref, params) => Future.value(<TiketMaintenanceModel>[])),
          spkListProvider.overrideWith((ref, status) => Future.value(<SpkHeaderModel>[])),
        ],
        child: const MaterialApp(
          home: IpsrsHubScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify title is Pusat Komando IPSRS
    expect(find.text('Pusat Komando IPSRS'), findsOneWidget);

    // Verify tabs: Tiket Masuk and Semua SPK exist
    expect(find.text('Tiket Masuk'), findsOneWidget);
    expect(find.text('Semua SPK'), findsOneWidget);

    // Verify Preventif tab is hidden
    expect(find.text('Preventif'), findsNothing);

    // Verify searchbar is hidden for Kepala Teknisi in command mode
    expect(find.byType(AppSearchBar), findsNothing);
  });

  testWidgets('JadwalPreventifScreen shows Tambah Jadwal Servis button for Kepala Teknisi', (tester) async {
    tester.view.physicalSize = const Size(400, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authStateProvider.overrideWith((ref) => MockAuthNotifier(kepalaTeknisiUser)),
          jadwalPreventifListProvider.overrideWith((ref) => Future.value(<JadwalPreventifItemModel>[])),
        ],
        child: const MaterialApp(
          home: JadwalPreventifScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Tambah Jadwal Servis'), findsOneWidget);
  });

  testWidgets('JadwalPreventifScreen hides Tambah Jadwal Servis button for Teknisi biasa', (tester) async {
    tester.view.physicalSize = const Size(400, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authStateProvider.overrideWith((ref) => MockAuthNotifier(teknisiUser)),
          jadwalPreventifListProvider.overrideWith((ref) => Future.value(<JadwalPreventifItemModel>[])),
        ],
        child: const MaterialApp(
          home: JadwalPreventifScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Tambah Jadwal Servis'), findsNothing);
  });
}
