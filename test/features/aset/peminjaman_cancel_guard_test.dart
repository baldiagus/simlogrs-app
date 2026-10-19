import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simlog_mobile/features/aset/data/models/peminjaman_aset_model.dart';
import 'package:simlog_mobile/features/aset/presentation/widgets/sirkulasi_hub_peminjaman_tab.dart';
import 'package:simlog_mobile/features/auth/data/models/user_model.dart';
import 'package:simlog_mobile/features/auth/presentation/providers/auth_provider.dart';

class MockAuthNotifier extends StateNotifier<AuthState> implements AuthNotifier {
  MockAuthNotifier(UserModel user) : super(AuthState.authenticated(user));

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

const _petugas = UserModel(
  id: 101,
  name: 'Petugas Unit IGD',
  email: 'petugas@simlogrs.local',
  roles: ['petugas_unit'],
  permissions: [],
  unit: UnitModel(id: 1, nama: 'Instalasi Gawat Darurat', kode: 'IGD'),
);

PeminjamanAsetModel _diajukanBy(int diajukanOleh) => PeminjamanAsetModel(
      id: 20,
      kode: 'PINJ-2026-020',
      tipePenyedia: 'RUANGAN',
      namaPenyedia: 'Instalasi Bedah Sentral',
      unitPeminjam: 'Instalasi Gawat Darurat',
      pengaju: 'Pengaju',
      tanggalPinjam: '2026-10-10',
      tanggalKembaliRencana: '2026-10-20',
      keperluan: 'Operasi darurat',
      status: 'DIAJUKAN',
      isOverdue: false,
      jumlahAset: 1,
      items: const [
        PeminjamanItemAset(
          id: 1,
          asetId: 5,
          namaKomoditas: 'Syringe Pump',
          kodeAset: 'AST-MED-005',
          kondisiSaatPinjam: 'BAIK',
        ),
      ],
      diajukanOleh: diajukanOleh,
    );

Future<void> _pumpTab(WidgetTester tester, PeminjamanAsetModel item) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authStateProvider.overrideWith((ref) => MockAuthNotifier(_petugas)),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: SirkulasiHubPeminjamanTab(
            peminjamanAsync: AsyncValue.data([item]),
            onAjukan: () {},
            onExtend: (_, __) {},
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('Batalkan Pengajuan peminjaman guard', () {
    testWidgets('petugas_unit does not see cancel on loan submitted by Karu',
        (tester) async {
      await _pumpTab(tester, _diajukanBy(102));

      expect(find.text('Syringe Pump'), findsOneWidget);
      expect(find.text('Batalkan Pengajuan'), findsNothing);
    });

    testWidgets('petugas_unit sees cancel on own DIAJUKAN loan',
        (tester) async {
      await _pumpTab(tester, _diajukanBy(_petugas.id));

      expect(find.text('Batalkan Pengajuan'), findsOneWidget);
    });
  });
}
