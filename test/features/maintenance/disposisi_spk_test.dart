import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simlog_mobile/features/auth/data/models/user_model.dart';
import 'package:simlog_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:simlog_mobile/features/maintenance/data/models/tiket_maintenance_model.dart';
import 'package:simlog_mobile/features/maintenance/presentation/providers/tiket_maintenance_provider.dart';
import 'package:simlog_mobile/features/maintenance/presentation/screens/detail_tiket_screen.dart';
import 'package:simlog_mobile/features/maintenance/presentation/widgets/tiket_card_item.dart';

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
    permissions: [
      'page_TeknisiDashboard',
      'create_pemeliharaan::spk::perbaikan',
      'view_pemeliharaan::spk::perbaikan',
    ],
    unit: UnitModel(id: 2, nama: 'Instalasi Pemeliharaan Sarana Rumah Sakit', kode: 'IPSRS'),
  );

  const teknisiUser = UserModel(
    id: 8,
    name: 'Agus Teknisi',
    email: 'teknisi@simlogrs.local',
    roles: ['teknisi'],
    permissions: [],
    unit: UnitModel(id: 2, nama: 'Instalasi Pemeliharaan Sarana Rumah Sakit', kode: 'IPSRS'),
  );

  const karuUser = UserModel(
    id: 6,
    name: 'Ns. Siti Rahma, S.Kep.',
    email: 'karu@simlogrs.local',
    roles: ['kepala_unit'],
    permissions: [],
    unit: UnitModel(id: 3, nama: 'Rawat Inap Bedah', kode: 'BEDAH'),
  );
  const dummyTiket = TiketMaintenanceModel(
    id: 1,
    kode: 'MNT-202610-001',
    aset: {
      'id': 10,
      'kode': 'AST-2026-001',
      'nama': 'Printer Epson L3110',
      'kategori': 'Peralatan Elektronik',
      'lokasi': 'Ruang Rawat Inap',
    },
    unit: 'Rawat Inap Bedah',
    pelapor: 'Ns. Siti Rahma, S.Kep.',
    deskripsiMasalah: 'Printer macet kertas tidak mau narik',
    prioritas: 'TINGGI',
    status: 'DILAPORKAN',
    dibuatPada: '2026-10-01',
    canCancel: true,
  );

  const dummyTiketDetail = TiketDetailModel(
    id: 1,
    kode: 'MNT-202610-001',
    aset: {
      'id': 10,
      'kode': 'AST-2026-001',
      'nama': 'Printer Epson L3110',
      'kategori': 'Peralatan Elektronik',
    },
    unit: 'Rawat Inap Bedah',
    pelapor: 'Ns. Siti Rahma, S.Kep.',
    deskripsiMasalah: 'Printer macet kertas tidak mau narik',
    prioritas: 'TINGGI',
    status: 'DILAPORKAN',
    canCancel: true,
    dibuatPada: '2026-10-01 09:00:00',
    penugasan: [],
    riwayatLog: [],
  );

  testWidgets('TiketCardItem displays Disposisi SPK button when onDisposisiTap is provided', (tester) async {
    bool disposisiTapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TiketCardItem(
            item: dummyTiket,
            onDisposisiTap: () {
              disposisiTapped = true;
            },
          ),
        ),
      ),
    );

    expect(find.text('Disposisi SPK'), findsOneWidget);
    expect(find.text('Batalkan'), findsNothing);

    await tester.tap(find.text('Disposisi SPK'));
    await tester.pump();

    expect(disposisiTapped, isTrue);
  });

  testWidgets('DetailTiketScreen displays Disposisi SPK ke Teknisi button for Kepala Teknisi and hides Batalkan', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authStateProvider.overrideWith((ref) => MockAuthNotifier(kepalaTeknisiUser)),
          detailTiketUnitProvider(1).overrideWith((ref) => Future.value(dummyTiketDetail)),
        ],
        child: const MaterialApp(
          home: DetailTiketScreen(
            tiketId: 1,
            kodeTiket: 'MNT-202610-001',
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Disposisi & Penugasan Teknisi'), findsOneWidget);
    expect(find.text('Disposisi SPK ke Teknisi'), findsOneWidget);
    expect(find.text('Batalkan Tiket Kerusakan'), findsNothing);
  });

  testWidgets('DetailTiketScreen hides Batalkan Tiket Kerusakan button for field Teknisi', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authStateProvider.overrideWith((ref) => MockAuthNotifier(teknisiUser)),
          detailTiketUnitProvider(1).overrideWith((ref) => Future.value(dummyTiketDetail)),
        ],
        child: const MaterialApp(
          home: DetailTiketScreen(
            tiketId: 1,
            kodeTiket: 'MNT-202610-001',
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Batalkan Tiket Kerusakan'), findsNothing);
  });

  testWidgets('DetailTiketScreen shows Batalkan Tiket Kerusakan button for Karu pelapor when canCancel is true', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authStateProvider.overrideWith((ref) => MockAuthNotifier(karuUser)),
          detailTiketUnitProvider(1).overrideWith((ref) => Future.value(dummyTiketDetail)),
        ],
        child: const MaterialApp(
          home: DetailTiketScreen(
            tiketId: 1,
            kodeTiket: 'MNT-202610-001',
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Batalkan Tiket Kerusakan'), findsOneWidget);
  });
}
