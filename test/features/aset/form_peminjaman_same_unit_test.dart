import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simlog_mobile/features/aset/data/models/aset_tersedia_model.dart';
import 'package:simlog_mobile/features/aset/presentation/screens/form_peminjaman_aset_screen.dart';
import 'package:simlog_mobile/features/auth/data/models/user_model.dart';
import 'package:simlog_mobile/features/auth/presentation/providers/auth_provider.dart';

class MockAuthNotifier extends StateNotifier<AuthState> implements AuthNotifier {
  MockAuthNotifier(UserModel user) : super(AuthState.authenticated(user));

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  const userDireksi = UserModel(
    id: 9,
    name: 'Drs. H. Mulyono, M.Kes',
    email: 'manajemen@simlogrs.local',
    roles: ['manajemen'],
    permissions: [],
    unit: UnitModel(id: 8, nama: 'Direktorat & Manajemen Eksekutif', kode: 'DIREKSI'),
  );

  const asetSameUnit = AsetTersediaModel(
    id: 2,
    kodeAset: 'AST-2026-002',
    nomorSeri: 'prnt-1a',
    namaKomoditas: 'Printer',
    kategori: 'Elektronik',
    satuan: 'Pieces',
    merek: 'Epson',
    kondisi: 'BAIK',
    tipePenyedia: 'RUANGAN',
    penyediaId: 8, // same as userDireksi unit_id: 8
    namaPenyedia: 'Direktorat & Manajemen Eksekutif',
    lokasiLengkap: 'Direktorat & Manajemen Eksekutif',
  );

  testWidgets('FormPeminjamanAsetScreen displays warning banner when asset is from the same unit', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authStateProvider.overrideWith((ref) => MockAuthNotifier(userDireksi)),
        ],
        child: const MaterialApp(
          home: FormPeminjamanAsetScreen(
            preselectedAset: asetSameUnit,
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify warning banner
    expect(
      find.text('Aset ini sudah berada di ruangan Anda. Peminjaman hanya berlaku untuk aset dari gudang sentral atau ruangan lain.'),
      findsOneWidget,
    );

    // Verify submit button is disabled
    final buttonFinder = find.widgetWithText(ElevatedButton, 'Kirim Permohonan Pinjam');
    final button = tester.widget<ElevatedButton>(buttonFinder);
    expect(button.onPressed, isNull);
  });
}
