import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simlog_mobile/features/aset/data/models/aset_detail_model.dart';
import 'package:simlog_mobile/features/aset/data/models/peminjaman_aset_model.dart';
import 'package:simlog_mobile/features/aset/presentation/screens/aset_detail_screen.dart';
import 'package:simlog_mobile/features/aset/presentation/widgets/aset_detail_loan_actions.dart';
import 'package:simlog_mobile/features/aset/presentation/widgets/sirkulasi_hub_peminjaman_tab.dart';
import 'package:simlog_mobile/features/aset/presentation/widgets/sirkulasi_hub_siap_kembali_tab.dart';
import 'package:simlog_mobile/features/auth/data/models/user_model.dart';
import 'package:simlog_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:simlog_mobile/shared/widgets/custom_button.dart';

class MockAuthNotifier extends StateNotifier<AuthState> implements AuthNotifier {
  MockAuthNotifier(UserModel user) : super(AuthState.authenticated(user));

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
const _dummyUserPetugas = UserModel(
  id: 101,
  name: 'Petugas Unit IGD',
  email: 'petugas@simlogrs.local',
  roles: ['petugas_unit'],
  permissions: [],
  unit: UnitModel(id: 1, nama: 'Instalasi Gawat Darurat', kode: 'IGD'),
);

const _dummyUserKepala = UserModel(
  id: 102,
  name: 'Karu IGD',
  email: 'karu@simlogrs.local',
  roles: ['kepala_unit'],
  permissions: [],
  unit: UnitModel(id: 1, nama: 'Instalasi Gawat Darurat', kode: 'IGD'),
);

const _dummyUserKepalaTeknisi = UserModel(
  id: 103,
  name: 'Kepala Teknisi IPSRS',
  email: 'kateknisi@simlogrs.local',
  roles: ['kepala_teknisi'],
  permissions: [],
  unit: UnitModel(id: 3, nama: 'IPSRS', kode: 'IPSRS'),
);

const _dummyItemDipinjam = PeminjamanAsetModel(
  id: 10,
  kode: 'PINJ-2026-001',
  tipePenyedia: 'RUANGAN',
  namaPenyedia: 'Instalasi Bedah Sentral',
  unitPeminjam: 'Instalasi Gawat Darurat',
  pengaju: 'Petugas IGD',
  tanggalPinjam: '2026-10-10',
  tanggalKembaliRencana: '2026-10-20',
  keperluan: 'Operasi darurat',
  status: 'DIPINJAM',
  isOverdue: false,
  jumlahAset: 1,
  items: [
    PeminjamanItemAset(
      id: 1,
      asetId: 5,
      namaKomoditas: 'Syringe Pump',
      kodeAset: 'AST-MED-005',
      kondisiSaatPinjam: 'BAIK',
    ),
  ],
);

const _dummyAsetDipinjamDetail = AsetDetailModel(
  id: 5,
  kodeAset: 'AST-MED-005',
  nomorSeri: 'SN-SYR-005',
  namaKomoditas: 'Syringe Pump Terumo',
  kategori: 'Alat Kesehatan Medik',
  merek: 'Terumo',
  spesifikasi: 'Model TE-331',
  status: 'DIPINJAM',
  kondisi: 'BAIK',
  lokasiTercatat: 'Instalasi Bedah Sentral',
  penanggungJawab: 'Instalasi Bedah Sentral',
  unitId: 2,
  nilaiPerolehan: 35000000,
  tanggalPerolehan: '2025-01-10',
  totalRiwayatServis: 0,
  peminjamanAktif: PeminjamanAktifInfo(
    peminjamanId: 10,
    kodePinjam: 'PINJ-2026-001',
    unitPeminjam: 'Instalasi Gawat Darurat',
    tanggalKembaliRencana: '2026-10-20',
    isOverdue: false,
  ),
);

void main() {
  group('Perpanjang Peminjaman RBAC UI Guard', () {
    testWidgets('SirkulasiHubPeminjamanTab hides Perpanjang button for petugas_unit', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authStateProvider.overrideWith((ref) => MockAuthNotifier(_dummyUserPetugas)),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: SirkulasiHubPeminjamanTab(
                peminjamanAsync: const AsyncValue.data([_dummyItemDipinjam]),
                onAjukan: () {},
                onExtend: (_, __) {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Syringe Pump'), findsOneWidget);
      expect(find.text('Perpanjang'), findsNothing);
    });

    testWidgets('SirkulasiHubPeminjamanTab shows Perpanjang button for kepala_unit', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authStateProvider.overrideWith((ref) => MockAuthNotifier(_dummyUserKepala)),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: SirkulasiHubPeminjamanTab(
                peminjamanAsync: const AsyncValue.data([_dummyItemDipinjam]),
                onAjukan: () {},
                onExtend: (_, __) {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Syringe Pump'), findsOneWidget);
      expect(find.text('Perpanjang'), findsOneWidget);
    });

    testWidgets('SirkulasiHubSiapKembaliTab hides Perpanjang button for petugas_unit in dipinjam list', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authStateProvider.overrideWith((ref) => MockAuthNotifier(_dummyUserPetugas)),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: SirkulasiHubSiapKembaliTab(
                dipinjamAsync: const AsyncValue.data([_dummyItemDipinjam]),
                dipinjamkanAsync: const AsyncValue.data([]),
                subPerspektif: 'dipinjam',
                onSubPerspektifChanged: (_) {},
                onExtend: (_, __) {},
                onReturn: (_, __) {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Syringe Pump'), findsOneWidget);
      expect(find.text('Perpanjang'), findsNothing);
    });

    testWidgets('SirkulasiHubSiapKembaliTab shows Perpanjang button for kepala_unit in dipinjam list', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authStateProvider.overrideWith((ref) => MockAuthNotifier(_dummyUserKepala)),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: SirkulasiHubSiapKembaliTab(
                dipinjamAsync: const AsyncValue.data([_dummyItemDipinjam]),
                dipinjamkanAsync: const AsyncValue.data([]),
                subPerspektif: 'dipinjam',
                onSubPerspektifChanged: (_) {},
                onExtend: (_, __) {},
                onReturn: (_, __) {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Syringe Pump'), findsOneWidget);
      expect(find.text('Perpanjang'), findsOneWidget);
    });

    testWidgets('SirkulasiHubSiapKembaliTab shows Perpanjang button for kepala_teknisi in dipinjam list', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authStateProvider.overrideWith((ref) => MockAuthNotifier(_dummyUserKepalaTeknisi)),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: SirkulasiHubSiapKembaliTab(
                dipinjamAsync: const AsyncValue.data([_dummyItemDipinjam]),
                dipinjamkanAsync: const AsyncValue.data([]),
                subPerspektif: 'dipinjam',
                onSubPerspektifChanged: (_) {},
                onExtend: (_, __) {},
                onReturn: (_, __) {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Syringe Pump'), findsOneWidget);
      expect(find.text('Perpanjang'), findsOneWidget);
    });

    testWidgets('AsetDetailLoanActions flex layout when canPerpanjang is false vs true', (tester) async {
      // canPerpanjang: false, isProviderOwner: true -> Kembalikan Fisik takes flex 1 (full width)
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AsetDetailLoanActions(
              aset: _dummyAsetDipinjamDetail,
              isProviderOwner: true,
              isActionLoading: false,
              canPerpanjang: false,
              onPerpanjang: () {},
              onPengembalian: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Perpanjang'), findsNothing);
      expect(find.text('Kembalikan Fisik'), findsOneWidget);
      final expandedKembalikan = tester.widget<Expanded>(
        find.ancestor(of: find.byType(CustomButton), matching: find.byType(Expanded)),
      );
      expect(expandedKembalikan.flex, equals(1));

      // canPerpanjang: true, isProviderOwner: true -> Perpanjang (flex 2) & Kembalikan Fisik (flex 3)
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AsetDetailLoanActions(
              aset: _dummyAsetDipinjamDetail,
              isProviderOwner: true,
              isActionLoading: false,
              canPerpanjang: true,
              onPerpanjang: () {},
              onPengembalian: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Perpanjang'), findsOneWidget);
      expect(find.text('Kembalikan Fisik'), findsOneWidget);
      final expandedKembalikanFlex3 = tester.widget<Expanded>(
        find.ancestor(of: find.byType(CustomButton), matching: find.byType(Expanded)),
      );
      expect(expandedKembalikanFlex3.flex, equals(3));
    });

    testWidgets('AsetDetailScreen hides Perpanjang for petugas_unit and shows for kepala_unit', (tester) async {
      tester.view.physicalSize = const Size(400, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      // Petugas Unit: no Perpanjang button
      // Petugas Unit: no Perpanjang button
      await tester.pumpWidget(
        ProviderScope(
          key: const ValueKey('petugas'),
          overrides: [
            authStateProvider.overrideWith((ref) => MockAuthNotifier(_dummyUserPetugas)),
          ],
          child: const MaterialApp(
            home: AsetDetailScreen(initialAset: _dummyAsetDipinjamDetail),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Perpanjang', skipOffstage: false), findsNothing);

      // Kepala Unit: Perpanjang button visible
      await tester.pumpWidget(
        ProviderScope(
          key: const ValueKey('kepala'),
          overrides: [
            authStateProvider.overrideWith((ref) => MockAuthNotifier(_dummyUserKepala)),
          ],
          child: const MaterialApp(
            home: AsetDetailScreen(initialAset: _dummyAsetDipinjamDetail),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Perpanjang', skipOffstage: false), findsOneWidget);
    });

    testWidgets('AsetDetailScreen shows Perpanjang button for kepala_teknisi', (tester) async {
      tester.view.physicalSize = const Size(400, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        ProviderScope(
          key: const ValueKey('kepala_teknisi'),
          overrides: [
            authStateProvider.overrideWith((ref) => MockAuthNotifier(_dummyUserKepalaTeknisi)),
          ],
          child: const MaterialApp(
            home: AsetDetailScreen(initialAset: _dummyAsetDipinjamDetail),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Perpanjang', skipOffstage: false), findsOneWidget);
    });
  });
}
