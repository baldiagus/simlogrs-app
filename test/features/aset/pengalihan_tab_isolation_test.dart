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
  const testUser = UserModel(
    id: 3,
    name: 'Hendra Kusuma, S.T.',
    email: 'kepalagudang@simlogrs.local',
    roles: ['kepala_gudang'],
    permissions: ['view_any_gudang_stok::pengalihan::barang', 'update_gudang_stok::pengalihan::barang'],
    gudang: GudangModel(id: 1, nama: 'Gudang Sentral', kode: 'GUD_SENTRAL'),
  );

  final dummyAktifItem = [
    const PengalihanItemModel(
      id: 201,
      kode: 'TRF-MY-REQUEST',
      tipe: 'BARANG',
      tipeAsal: 'GUDANG',
      asalNama: 'Gudang Sentral',
      tipeTujuan: 'GUDANG',
      tujuanNama: 'Gudang Farmasi',
      status: 'DIAJUKAN',
      tanggalPengalihan: '2026-10-07',
      namaItem: 'Kasa Steril',
      jumlah: 10,
      canCancel: true,
      canApprove: false,
    ),
  ];

  final dummyOtorisasiItem = [
    const PengalihanItemModel(
      id: 102,
      kode: 'TRF-BRG-202610-005',
      tipe: 'BARANG',
      tipeAsal: 'GUDANG',
      asalNama: 'Gudang Sentral',
      tipeTujuan: 'GUDANG',
      tujuanNama: 'Gudang Suku Cadang IPSRS',
      status: 'DIAJUKAN',
      tanggalPengalihan: '2026-10-07',
      namaItem: 'Kertas A4',
      jumlah: 10,
      canCancel: false,
      canApprove: true,
    ),
  ];

  testWidgets('PengalihanHubScreen isolates Setujui/Tolak actions to Otorisasi tab only', (tester) async {
    tester.view.physicalSize = const Size(400, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authStateProvider.overrideWith((ref) => MockAuthNotifier(testUser)),
          daftarPengalihanProvider('aktif').overrideWith((ref) => Future.value(dummyAktifItem)),
          daftarPengalihanProvider('otorisasi').overrideWith((ref) => Future.value(dummyOtorisasiItem)),
          daftarPengalihanProvider('riwayat').overrideWith((ref) => Future.value(<PengalihanItemModel>[])),
          countOtorisasiPengalihanProvider.overrideWith((ref) => Future.value(1)),
        ],
        child: const MaterialApp(
          home: PengalihanHubScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // 1. On Tab Aktif:
    // Should show TRF-MY-REQUEST with "Batalkan" button, but NEVER "Setujui" or "Tolak"
    expect(find.text('TRF-MY-REQUEST'), findsOneWidget);
    expect(find.text('Batalkan'), findsOneWidget);
    expect(find.text('Setujui'), findsNothing);
    expect(find.text('Tolak'), findsNothing);

    // 2. Switch to Tab Otorisasi
    final otorisasiTab = find.text('Otorisasi');
    await tester.tap(otorisasiTab);
    await tester.pumpAndSettle();

    // On Tab Otorisasi:
    // Should show TRF-BRG-202610-005 with "Setujui" and "Tolak" buttons, but NEVER "Batalkan"
    expect(find.text('TRF-BRG-202610-005'), findsOneWidget);
    expect(find.text('Setujui'), findsOneWidget);
    expect(find.text('Tolak'), findsOneWidget);
    expect(find.text('Batalkan'), findsNothing);
  });
}
