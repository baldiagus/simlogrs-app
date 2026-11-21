import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simlog_mobile/features/auth/data/models/user_model.dart';
import 'package:simlog_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:simlog_mobile/features/gudang/data/models/stock_opname_model.dart';
import 'package:simlog_mobile/features/gudang/presentation/providers/persediaan_providers.dart';
import 'package:simlog_mobile/features/gudang/presentation/screens/stock_opname_hub_screen.dart';
import 'stock_opname_guard_test.dart' show MockAuthNotifier;

void main() {
  for (final size in [const Size(360, 800), const Size(402, 817), const Size(1280, 800)]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('uncounted opname stays readable at $size scale $scale', (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        const session = StokOpnameSesiModel(id: 1, kode: 'OPN-202610-001', gudangId: 1,
          gudangNama: 'Gudang Sentral Logistik Non-Medis dan Bahan Pelayanan Rumah Sakit',
          tanggalOpname: '2026-10-02', status: 'BERJALAN',
          catatan: 'Opname fisik berjalan untuk kebutuhan pelayanan dan perlengkapan ruangan.',
          petugasInisiasi: 'Joko Wahyudi, A.Md.', totalItem: 4, totalTerhitung: 0,
          totalSelisih: 0, details: []);
        await tester.pumpWidget(ProviderScope(overrides: [
          authStateProvider.overrideWith((ref) => MockAuthNotifier(const UserModel(
            id: 1, name: 'Kepala Gudang', email: 'gudang@example.test',
            roles: ['kepala_gudang'], permissions: []))),
          stockOpnameListProvider.overrideWith((ref) async => [session]),
        ], child: MaterialApp(builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)),
          child: child!), home: const StockOpnameHubScreen())));
        await tester.pumpAndSettle();
        expect(find.text('Belum ada hasil hitung'), findsOneWidget);
        expect(find.text('Cocok (0 Selisih)'), findsNothing);
        expect(find.text('Inisiasi Opname'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  }
}
