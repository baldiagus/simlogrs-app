import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:simlog_mobile/features/distribusi/data/models/amprah_model.dart';
import 'package:simlog_mobile/features/distribusi/data/models/sppb_model.dart';
import 'package:simlog_mobile/features/distribusi/presentation/widgets/amprah_card_item.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:simlog_mobile/features/auth/data/models/user_model.dart';
import 'package:simlog_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:simlog_mobile/features/distribusi/presentation/providers/distribusi_provider.dart';
import 'package:simlog_mobile/features/distribusi/presentation/screens/detail_amprah_screen.dart';
import 'package:simlog_mobile/features/distribusi/presentation/widgets/sppb_card_item.dart';

class MockAuthNotifier extends StateNotifier<AuthState> implements AuthNotifier {
  MockAuthNotifier(UserModel user) : super(AuthState.authenticated(user));

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
void main() {
  group('Distribusi Card Layout Tests', () {
    testWidgets('AmprahCardItem renders structured 2-line metadata with icons', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      const item = AmprahHeaderModel(
        id: 28,
        kode: 'REQ-202610-028',
        unit: 'Instalasi Pemeliharaan Sarana Rumah Sakit',
        gudang: 'Gudang Sentral Logistik Non-Medis',
        pengaju: 'Ir. Gunawan, S.T.',
        tanggalPermintaan: '2026-10-15',
        urgensi: 'REGULER',
        status: 'DISETUJUI_KARU',
        canCancel: false,
        jumlahItem: 1,
        items: [],
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Padding(
              padding: EdgeInsets.all(16),
              child: AmprahCardItem(item: item),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Pastikan nama pengaju, tanggal terformat, dan tujuan terpisah dalam baris terstruktur
      expect(find.text('Ir. Gunawan, S.T.'), findsOneWidget);
      expect(find.text('15/10/2026'), findsOneWidget);
      expect(find.text('Tujuan: Gudang Sentral Logistik Non-Medis'), findsOneWidget);

      // Pastikan ada icon user, calendar, dan warehouse
      expect(find.byIcon(LucideIcons.user), findsOneWidget);
      expect(find.byIcon(LucideIcons.calendar), findsOneWidget);
      expect(find.byIcon(LucideIcons.warehouse), findsOneWidget);

      // Pastikan string lama yang menumpuk tidak ada lagi
      final err = tester.takeException();
      if (err is FlutterError) {
        FlutterError.dumpErrorToConsole(FlutterErrorDetails(exception: err));
      }
      expect(err, isNull);
    });

    testWidgets('SppbCardItem renders structured 2-line metadata with icons', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      const item = SppbHeaderModel(
        id: 1,
        kode: 'SPPB-20261015-0001',
        unit: 'Bagian Logistik & Pengadaan',
        gudang: 'Gudang Sentral Logistik Non-Medis',
        pengirim: 'Bambang Supriyadi, S.Kom',
        tanggalKirim: '2026-10-15',
        status: 'DIKIRIM',
        totalItem: 1,
        items: [
          SppbDetailItemModel(
            barangId: 1,
            namaBarang: 'Freon AC',
            kodeBarang: 'BHP-001',
            nomorBatch: 'dfef',
            jumlahDikirim: 1,
            satuan: 'Unit',
          ),
        ],
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Padding(
              padding: EdgeInsets.all(16),
              child: SppbCardItem(item: item),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Pastikan kurir, tanggal terformat, dan asal gudang terpisah dalam baris terstruktur
      expect(find.text('Kurir: Bambang Supriyadi, S.Kom'), findsOneWidget);
      expect(find.text('15/10/2026'), findsOneWidget);
      expect(find.text('Asal: Gudang Sentral Logistik Non-Medis'), findsOneWidget);

      // Pastikan ada icon truck, calendar, dan warehouse
      expect(find.byIcon(LucideIcons.truck), findsWidgets);
      expect(find.byIcon(LucideIcons.calendar), findsOneWidget);
      expect(find.byIcon(LucideIcons.warehouse), findsOneWidget);

      // Pastikan string lama tidak ada lagi
      expect(find.textContaining('Asal: Gudang Sentral Logistik Non-Medis • Tgl Kirim:'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('DetailAmprahScreen renders Tujuan: ... with multi-line wrap', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      const dummyAmprah = AmprahHeaderModel(
        id: 28,
        kode: 'REQ-202610-028',
        unit: 'Instalasi Pemeliharaan Sarana Rumah Sakit',
        gudang: 'Gudang Sentral Logistik Non-Medis',
        pengaju: 'Ir. Gunawan, S.T.',
        tanggalPermintaan: '2026-10-15',
        urgensi: 'REGULER',
        status: 'DISETUJUI_KARU',
        canCancel: false,
        jumlahItem: 1,
        items: [],
      );

      const testUser = UserModel(
        id: 1,
        name: 'Admin Logistik',
        email: 'adminlogistik@simlogrs.local',
        username: 'adminlogistik',
        roles: ['admin_logistik'],
        permissions: ['page_AdminLogistikDashboard'],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authStateProvider.overrideWith((ref) => MockAuthNotifier(testUser)),
            detailAmprahProvider(28).overrideWith((ref) => Future.value(dummyAmprah)),
          ],
          child: const MaterialApp(
            home: DetailAmprahScreen(amprahId: 28, kodeAmprah: 'REQ-202610-028'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Pastikan teks bertuliskan 'Tujuan: Gudang Sentral Logistik Non-Medis'
      expect(find.text('Tujuan: Gudang Sentral Logistik Non-Medis'), findsOneWidget);
      // Pastikan teks 'Gudang Tujuan:' sudah tidak ada
      expect(find.textContaining('Gudang Tujuan:'), findsNothing);
      expect(find.text('Ir. Gunawan, S.T.'), findsOneWidget);
      expect(find.text('15/10/2026'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
