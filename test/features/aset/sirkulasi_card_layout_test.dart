import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:simlog_mobile/features/aset/data/models/peminjaman_aset_model.dart';
import 'package:simlog_mobile/features/aset/presentation/providers/peminjaman_provider.dart';
import 'package:simlog_mobile/features/aset/presentation/screens/sirkulasi_aset_hub_screen.dart';
import 'package:simlog_mobile/features/aset/presentation/widgets/peminjaman_card_item.dart';
import 'package:simlog_mobile/features/aset/presentation/widgets/sirkulasi_hub_common_widgets.dart';
import 'package:simlog_mobile/features/aset/presentation/widgets/sirkulasi_hub_otorisasi_card.dart';
import 'package:simlog_mobile/features/auth/data/models/user_model.dart';
import 'package:simlog_mobile/features/auth/presentation/providers/auth_provider.dart';

class MockAuthNotifier extends StateNotifier<AuthState> implements AuthNotifier {
  MockAuthNotifier(UserModel user) : super(AuthState.authenticated(user));

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('Sirkulasi Aset Card & Tab Layout Tests', () {
    testWidgets('PeminjamanCardItem renders structured 4-tier detail layout with badges & icons', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      const item = PeminjamanAsetModel(
        id: 12,
        kode: 'PINJ-2026-012',
        tipePenyedia: 'RUANGAN',
        namaPenyedia: 'Instalasi Pemeliharaan Sarana Rumah Sakit',
        unitPeminjam: 'Instalasi Gawat Darurat',
        pengaju: 'Ir. Gunawan, S.T.',
        tanggalPinjam: '2026-10-15',
        tanggalKembaliRencana: '2026-10-18',
        keperluan: 'Pencetakan laporan darurat pasien',
        status: 'DIPINJAM',
        isOverdue: false,
        jumlahAset: 1,
        items: [
          PeminjamanItemAset(
            id: 1,
            asetId: 1,
            namaKomoditas: 'Printer Epson',
            kodeAset: 'AST-2026-012',
            kondisiSaatPinjam: 'BAIK',
          ),
        ],
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Padding(
              padding: EdgeInsets.all(16),
              child: PeminjamanCardItem(item: item),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Pastikan nama aset, kode aset dalam badge pill, asal, tanggal terformat, dan keperluan tampil
      expect(find.text('Printer Epson'), findsOneWidget);
      expect(find.text('AST-2026-012'), findsOneWidget);
      expect(find.text('Asal: Instalasi Pemeliharaan Sarana Rumah Sakit'), findsOneWidget);
      expect(find.text('15/10/2026 s/d 18/10/2026'), findsOneWidget);
      expect(find.text('Keperluan: Pencetakan laporan darurat pasien'), findsOneWidget);

      // Pastikan ada icon building, calendar, fileText
      expect(find.byIcon(LucideIcons.building2), findsOneWidget);
      expect(find.byIcon(LucideIcons.calendar), findsOneWidget);
      expect(find.byIcon(LucideIcons.fileText), findsOneWidget);

      // Pastikan string lama tidak ada lagi
      expect(find.textContaining('Kode: AST-2026-012 • Asal:'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('SirkulasiHubOtorisasiCard renders structured 4-tier detail layout with badges & icons', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      const item = ApprovalPeminjamanModel(
        id: 13,
        kode: 'PINJ-2026-013',
        tipePenyedia: 'RUANGAN',
        namaAset: 'Printer Epson',
        kodeAset: 'AST-2026-018',
        unitPeminjam: 'Instalasi Pemeliharaan Sarana Rumah Sakit',
        pengaju: 'Ir. Gunawan, S.T.',
        tanggalPinjam: '2026-10-15',
        tanggalKembaliRencana: '2026-10-22',
        keperluan: 'Pencetakan berkas audit',
        status: 'DIAJUKAN',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(16),
              child: SirkulasiHubOtorisasiCard(item: item, onAksi: (_) {}),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Pastikan kode aset terpisah, pemohon, tanggal terformat, dan keperluan tampil
      expect(find.text('Printer Epson'), findsOneWidget);
      expect(find.text('AST-2026-018'), findsOneWidget);
      expect(find.text('Pemohon: Instalasi Pemeliharaan Sarana Rumah Sakit (Ir. Gunawan, S.T.)'), findsOneWidget);
      expect(find.text('Jadwal: 15/10/2026 s/d 22/10/2026'), findsOneWidget);
      expect(find.text('Keperluan: Pencetakan berkas audit'), findsOneWidget);

      expect(find.byIcon(LucideIcons.user), findsOneWidget);
      expect(find.byIcon(LucideIcons.calendar), findsOneWidget);
      expect(find.byIcon(LucideIcons.fileText), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('SirkulasiAsetHubScreen renders balanced TabBar (isScrollable: false)', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      const karuUser = UserModel(
        id: 1,
        name: 'Karu Melati',
        email: 'karu@simlogrs.local',
        roles: ['kepala_unit'],
        permissions: ['update_layanan_unit::approval::peminjaman'],
        unit: UnitModel(id: 3, nama: 'Ruang Melati', kode: 'MELATI'),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authStateProvider.overrideWith((ref) => MockAuthNotifier(karuUser)),
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

      final tabBarFinder = find.byType(TabBar);
      expect(tabBarFinder, findsOneWidget);
      final TabBar tabBar = tester.widget(tabBarFinder);
      expect(tabBar.isScrollable, isFalse);

      expect(find.byType(SirkulasiHubBadgeTab), findsNWidgets(3));
      expect(find.text('Pinjaman Saya'), findsOneWidget);
      expect(find.text('Otorisasi'), findsOneWidget);
      expect(find.text('Siap Kembali'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
