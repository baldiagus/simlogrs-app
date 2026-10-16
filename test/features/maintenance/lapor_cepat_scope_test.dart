import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simlog_mobile/features/auth/data/models/user_model.dart';
import 'package:simlog_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:simlog_mobile/features/maintenance/data/models/tiket_maintenance_model.dart';
import 'package:simlog_mobile/features/maintenance/presentation/providers/tiket_maintenance_provider.dart';
import 'package:simlog_mobile/features/maintenance/presentation/screens/lapor_cepat_screen.dart';
import 'package:simlog_mobile/features/maintenance/presentation/widgets/aset_unit_picker_sheet.dart';
import 'package:simlog_mobile/features/maintenance/presentation/widgets/tiket_card_item.dart';

class MockAuthNotifier extends StateNotifier<AuthState> implements AuthNotifier {
  MockAuthNotifier(UserModel user) : super(AuthState.authenticated(user));

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('Model Deserialization Tests', () {
    test('AsetUnitModel deserializes isPinjaman and asalPenyedia correctly', () {
      final jsonWithLoan = {
        'id': 12,
        'kode_aset': 'AST-2026-001',
        'nama': 'Infusion Pump',
        'nomor_seri': 'SN-INF-12',
        'kategori': 'Medis',
        'kondisi': 'BAIK',
        'status': 'TERSEDIA',
        'is_pinjaman': true,
        'asal_penyedia': 'Instalasi Bedah Sentral',
      };
      final modelWithLoan = AsetUnitModel.fromJson(jsonWithLoan);
      expect(modelWithLoan.isPinjaman, isTrue);
      expect(modelWithLoan.asalPenyedia, 'Instalasi Bedah Sentral');

      final jsonDefault = {
        'id': 13,
        'kode_aset': 'AST-2026-002',
        'nama': 'Bed Pasien',
        'nomor_seri': 'SN-BED-13',
        'kategori': 'Non-Medis',
        'kondisi': 'BAIK',
        'status': 'TERSEDIA',
      };
      final modelDefault = AsetUnitModel.fromJson(jsonDefault);
      expect(modelDefault.isPinjaman, isFalse);
      expect(modelDefault.asalPenyedia, isNull);
    });

    test('TiketMaintenanceModel and TiketDetailModel deserialize isAsetPinjaman and namaPenyediaAsal', () {
      final jsonTiket = {
        'id': 101,
        'kode': 'MNT-2026-01',
        'status': 'DILAPORKAN',
        'prioritas': 'SEDANG',
        'deskripsi_masalah': 'Alarm berbunyi terus',
        'unit': 'IGD',
        'pelapor': 'dr. Pratama',
        'can_cancel': true,
        'aset': {'nama': 'Ventilator', 'kode_aset': 'AST-01', 'nomor_seri': 'SN-01'},
        'is_aset_pinjaman': true,
        'nama_penyedia_asal': 'ICU',
      };
      final tiketModel = TiketMaintenanceModel.fromJson(jsonTiket);
      expect(tiketModel.isAsetPinjaman, isTrue);
      expect(tiketModel.namaPenyediaAsal, 'ICU');

      final detailModel = TiketDetailModel.fromJson(jsonTiket);
      expect(detailModel.isAsetPinjaman, isTrue);
      expect(detailModel.namaPenyediaAsal, 'ICU');

      final jsonTiketDefault = {
        'id': 102,
        'kode': 'MNT-2026-02',
        'status': 'DILAPORKAN',
        'prioritas': 'SEDANG',
        'deskripsi_masalah': 'Kabel longgar',
        'unit': 'IGD',
        'pelapor': 'dr. Pratama',
        'can_cancel': false,
        'aset': {'nama': 'Tensimeter', 'kode_aset': 'AST-02', 'nomor_seri': 'SN-02'},
      };
      final tiketDefault = TiketMaintenanceModel.fromJson(jsonTiketDefault);
      expect(tiketDefault.isAsetPinjaman, isFalse);
      expect(tiketDefault.namaPenyediaAsal, isNull);

      final detailDefault = TiketDetailModel.fromJson(jsonTiketDefault);
      expect(detailDefault.isAsetPinjaman, isFalse);
      expect(detailDefault.namaPenyediaAsal, isNull);
    });
  });

  group('AsetUnitPickerSheet Widget Tests', () {
    testWidgets('shows loan badge when asset has isPinjaman == true', (tester) async {
      final assets = [
        const AsetUnitModel(
          id: 1,
          kodeAset: 'AST-IGD-001',
          nama: 'Defibrillator Lifepak',
          nomorSeri: 'SN-001',
          kategori: 'Medis',
          kondisi: 'BAIK',
          status: 'TERSEDIA',
          isPinjaman: false,
        ),
        const AsetUnitModel(
          id: 2,
          kodeAset: 'AST-BEDAH-002',
          nama: 'Ventilator Transport',
          nomorSeri: 'SN-002',
          kategori: 'Medis',
          kondisi: 'BAIK',
          status: 'TERSEDIA',
          isPinjaman: true,
          asalPenyedia: 'Instalasi Bedah Sentral',
        ),
        const AsetUnitModel(
          id: 3,
          kodeAset: 'AST-ICU-003',
          nama: 'Syringe Pump',
          nomorSeri: 'SN-003',
          kategori: 'Medis',
          kondisi: 'BAIK',
          status: 'TERSEDIA',
          isPinjaman: true,
          asalPenyedia: null,
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            asetUnitTersediaProvider.overrideWith((ref) async => assets),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: AsetUnitPickerSheet(
                onAsetSelected: (_) {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Defibrillator Lifepak'), findsOneWidget);
      expect(find.text('Ventilator Transport'), findsOneWidget);
      expect(find.text('Aset Pinjaman dari: Instalasi Bedah Sentral'), findsOneWidget);
      expect(find.text('Aset Pinjaman'), findsOneWidget);
    });
  });

  group('TiketCardItem Widget Tests', () {
    testWidgets('shows loan badge when isAsetPinjaman is true with provider name', (tester) async {
      const itemWithProvider = TiketMaintenanceModel(
        id: 1,
        kode: 'MNT-2026-001',
        status: 'DILAPORKAN',
        prioritas: 'SEDANG',
        deskripsiMasalah: 'Perlu penggantian kabel daya',
        unit: 'IGD',
        pelapor: 'dr. Pratama',
        canCancel: false,
        aset: {'nama': 'Mesin EKG', 'kode_aset': 'AST-EKG-01', 'nomor_seri': 'SN-01'},
        isAsetPinjaman: true,
        namaPenyediaAsal: 'Instalasi Rawat Inap',
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TiketCardItem(item: itemWithProvider),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Pinjaman: Instalasi Rawat Inap'), findsOneWidget);
    });

    testWidgets('shows generic loan badge when isAsetPinjaman is true without provider name', (tester) async {
      const itemWithoutProvider = TiketMaintenanceModel(
        id: 2,
        kode: 'MNT-2026-002',
        status: 'DILAPORKAN',
        prioritas: 'SEDANG',
        deskripsiMasalah: 'Tombol power macet',
        unit: 'IGD',
        pelapor: 'dr. Pratama',
        canCancel: false,
        aset: {'nama': 'Tensimeter Digital', 'kode_aset': 'AST-TNS-01', 'nomor_seri': 'SN-02'},
        isAsetPinjaman: true,
        namaPenyediaAsal: null,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TiketCardItem(item: itemWithoutProvider),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Aset Pinjaman'), findsOneWidget);
    });
  });

  group('LaporCepatScreen Scope Validation Tests', () {
    const unitUser = UserModel(
      id: 5,
      name: 'Ns. Ratna, S.Kep.',
      email: 'ratna@simlogrs.local',
      roles: ['staf_unit'],
      permissions: [],
      unit: UnitModel(id: 1, nama: 'Instalasi Gawat Darurat', kode: 'IGD'),
    );

    const adminUser = UserModel(
      id: 1,
      name: 'Admin Utama',
      email: 'admin@simlogrs.local',
      roles: ['super_admin'],
      permissions: [],
    );

    final availableAssets = [
      const AsetUnitModel(
        id: 10,
        kodeAset: 'AST-IGD-001',
        nama: 'Defibrillator Ruangan IGD',
        nomorSeri: 'SN-IGD-01',
        kategori: 'Medis',
        kondisi: 'BAIK',
        status: 'TERSEDIA',
        isPinjaman: false,
      ),
      const AsetUnitModel(
        id: 11,
        kodeAset: 'AST-BEDAH-002',
        nama: 'Syringe Pump Pinjaman',
        nomorSeri: 'SN-BEDAH-02',
        kategori: 'Medis',
        kondisi: 'BAIK',
        status: 'TERSEDIA',
        isPinjaman: true,
        asalPenyedia: 'Instalasi Bedah Sentral',
      ),
    ];

    testWidgets('shows hint AST-IGD-001, blocks unowned code with red warning banner and submit error', (tester) async {
      tester.view.physicalSize = const Size(600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authStateProvider.overrideWith((ref) => MockAuthNotifier(unitUser)),
            asetUnitTersediaProvider.overrideWith((ref) async => availableAssets),
          ],
          child: const MaterialApp(
            home: LaporCepatScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Check hint text
      expect(find.text('misal: AST-IGD-001'), findsOneWidget);

      // Type unowned asset code
      final kodeField = find.byType(TextFormField).first;
      await tester.enterText(kodeField, 'AST-LAB-999');
      await tester.pump();

      // Red warning banner appears
      expect(
        find.text('Aset ini milik unit lain dan tidak sedang dipinjam oleh ruangan Anda. Pelaporan diblokir.'),
        findsOneWidget,
      );

      // Fill in description to test submit validation blockage
      final deskripsiField = find.byType(TextFormField).at(1);
      await tester.enterText(deskripsiField, 'Kerusakan pada unit sensor alat');
      await tester.pump();

      // Tap submit button
      await tester.tap(find.text('Kirim Laporan Kerusakan'));
      await tester.pumpAndSettle();

      // Warning text still present (via banner and/or validation error) and screen does not pop
      expect(
        find.text('Aset ini milik unit lain dan tidak sedang dipinjam oleh ruangan Anda. Pelaporan diblokir.'),
        findsWidgets,
      );
      expect(find.byType(LaporCepatScreen), findsOneWidget);
    });

    testWidgets('allows owned asset code without warning banner', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authStateProvider.overrideWith((ref) => MockAuthNotifier(unitUser)),
            asetUnitTersediaProvider.overrideWith((ref) async => availableAssets),
          ],
          child: const MaterialApp(
            home: LaporCepatScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final kodeField = find.byType(TextFormField).first;
      await tester.enterText(kodeField, 'AST-IGD-001');
      await tester.pump();

      expect(
        find.text('Aset ini milik unit lain dan tidak sedang dipinjam oleh ruangan Anda. Pelaporan diblokir.'),
        findsNothing,
      );
      expect(find.textContaining('Aset Pinjaman'), findsNothing);
    });

    testWidgets('allows borrowed asset code and shows amber info badge', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authStateProvider.overrideWith((ref) => MockAuthNotifier(unitUser)),
            asetUnitTersediaProvider.overrideWith((ref) async => availableAssets),
          ],
          child: const MaterialApp(
            home: LaporCepatScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final kodeField = find.byType(TextFormField).first;
      await tester.enterText(kodeField, 'AST-BEDAH-002');
      await tester.pump();

      expect(
        find.text('Aset ini milik unit lain dan tidak sedang dipinjam oleh ruangan Anda. Pelaporan diblokir.'),
        findsNothing,
      );
      expect(
        find.text('Aset Pinjaman dari: Instalasi Bedah Sentral'),
        findsOneWidget,
      );
    });

    testWidgets('super_admin is not blocked even if code is not in availableAssets', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authStateProvider.overrideWith((ref) => MockAuthNotifier(adminUser)),
            asetUnitTersediaProvider.overrideWith((ref) async => availableAssets),
          ],
          child: const MaterialApp(
            home: LaporCepatScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final kodeField = find.byType(TextFormField).first;
      await tester.enterText(kodeField, 'AST-LAB-999');
      await tester.pump();

      expect(
        find.text('Aset ini milik unit lain dan tidak sedang dipinjam oleh ruangan Anda. Pelaporan diblokir.'),
        findsNothing,
      );
    });
  });
}
