import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simlog_mobile/features/aset/presentation/providers/peminjaman_provider.dart';
import 'package:simlog_mobile/features/aset/presentation/screens/sirkulasi_aset_hub_screen.dart';
import 'package:simlog_mobile/features/auth/data/models/user_model.dart';
import 'package:simlog_mobile/features/auth/presentation/providers/auth_provider.dart';

class MockAuthNotifier extends StateNotifier<AuthState> implements AuthNotifier {
  MockAuthNotifier(UserModel user) : super(AuthState.authenticated(user));

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  const manajemenUser = UserModel(
    id: 9,
    name: 'Drs. H. Mulyono, M.Kes',
    email: 'manajemen@simlogrs.local',
    roles: ['manajemen'],
    permissions: ['view_any_master::aset'],
    unit: UnitModel(id: 8, nama: 'Direktorat & Manajemen Eksekutif', kode: 'DIREKSI'),
    gudang: GudangModel(id: 1, nama: 'Gudang Sentral Logistik Non-Medis', kode: 'GUD_SENTRAL'),
  );

  testWidgets('Role Manajemen has access to Otorisasi tab and Pinjaman Saya tab', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authStateProvider.overrideWith((ref) => MockAuthNotifier(manajemenUser)),
          daftarPeminjamanSayaProvider.overrideWith((ref) => Future.value([])),
          daftarApprovalPeminjamanProvider.overrideWith((ref) => Future.value([])),
          daftarPeminjamanAktifDipinjamProvider.overrideWith((ref) => Future.value([])),
          daftarPeminjamanAktifDipinjamkanProvider.overrideWith((ref) => Future.value([])),
        ],
        child: const MaterialApp(
          home: SirkulasiAsetHubScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Pinjaman Saya'), findsOneWidget);
    expect(find.text('Otorisasi'), findsOneWidget);
    expect(find.text('Siap Kembali'), findsOneWidget);
  });
}
