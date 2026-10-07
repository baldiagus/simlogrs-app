import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simlog_mobile/features/aset/data/models/pengalihan_model.dart';
import 'package:simlog_mobile/features/aset/presentation/providers/pengalihan_provider.dart';
import 'package:simlog_mobile/features/aset/presentation/screens/pengalihan_hub_screen.dart';
import 'package:simlog_mobile/features/auth/data/models/user_model.dart';
import 'package:simlog_mobile/features/auth/presentation/providers/auth_provider.dart';

class MockAuthNotifier extends StateNotifier<AuthState> implements AuthNotifier {
  MockAuthNotifier(UserModel user) : super(AuthState.authenticated(user));

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  const testGudangUser = UserModel(
    id: 3,
    name: 'Hendra Kusuma, S.T.',
    email: 'kepalagudang@simlogrs.local',
    roles: ['kepala_gudang'],
    permissions: ['view_any_gudang_stok::pengalihan::barang'],
    gudang: GudangModel(id: 1, nama: 'Gudang Sentral', kode: 'GUD_SENTRAL'),
  );

  testWidgets('PengalihanHubScreen toggles dynamic FAB between Aset and Barang', (tester) async {
    tester.view.physicalSize = const Size(400, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authStateProvider.overrideWith((ref) => MockAuthNotifier(testGudangUser)),
          daftarPengalihanProvider('aktif').overrideWith((ref) => Future.value(<PengalihanItemModel>[])),
          daftarPengalihanProvider('otorisasi').overrideWith((ref) => Future.value(<PengalihanItemModel>[])),
          daftarPengalihanProvider('riwayat').overrideWith((ref) => Future.value(<PengalihanItemModel>[])),
          countOtorisasiPengalihanProvider.overrideWith((ref) => Future.value(0)),
        ],
        child: const MaterialApp(
          home: PengalihanHubScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Default kategori is ASET
    // FAB should show "Ajukan Pengalihan Aset"
    expect(find.text('Ajukan Pengalihan Aset'), findsWidgets);

    // Tap "Barang Gudang" chip
    final barangChip = find.text('Barang Gudang');
    expect(barangChip, findsOneWidget);
    await tester.tap(barangChip);
    await tester.pumpAndSettle();

    // FAB should now dynamically switch to "Ajukan Pengalihan Barang"
    expect(find.text('Ajukan Pengalihan Barang'), findsWidgets);

    // Tap "Aset Fisik" chip to switch back
    final asetChip = find.text('Aset Fisik');
    await tester.tap(asetChip);
    await tester.pumpAndSettle();

    // FAB should switch back to "Ajukan Pengalihan Aset"
    expect(find.text('Ajukan Pengalihan Aset'), findsWidgets);
  });
}
