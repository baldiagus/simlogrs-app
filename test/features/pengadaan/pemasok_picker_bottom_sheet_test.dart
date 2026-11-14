import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simlog_mobile/core/network/api_response.dart';
import 'package:simlog_mobile/features/pengadaan/data/models/po_model.dart';
import 'package:simlog_mobile/features/pengadaan/presentation/providers/pengadaan_provider.dart';
import 'package:simlog_mobile/features/pengadaan/presentation/widgets/pemasok_picker_bottom_sheet.dart';

const _vendors = [
  PemasokOptionModel(id: 7, kode: 'VND-A', nama: 'CV Sumber Makmur'),
  PemasokOptionModel(id: 19, kode: 'VND-B', nama: 'CV Sumber Makmur'),
  PemasokOptionModel(id: 41, kode: 'VND-C', nama: 'PT Sentosa'),
];

Future<ProviderContainer> _openPicker(
  WidgetTester tester,
  Future<List<PemasokOptionModel>> Function() load,
  List<int?> results, {
  int? selectedId,
  double textScale = 1,
}) async {
  await tester.pumpWidget(ProviderScope(
    overrides: [pemasokListProvider.overrideWith((ref) => load())],
    child: MaterialApp(
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(textScale),
        ),
        child: child!,
      ),
      home: Builder(
          builder: (context) => Scaffold(
                body: ElevatedButton(
                  onPressed: () async {
                    results.add(await showModalBottomSheet<int>(
                      context: context,
                      isScrollControlled: true,
                      useSafeArea: true,
                      builder: (_) => PemasokPickerBottomSheet(
                        selectedPemasokId: selectedId,
                      ),
                    ));
                  },
                  child: const Text('Buka pemilih'),
                ),
              )),
    ),
  ));
  final container = ProviderScope.containerOf(
    tester.element(find.byType(Scaffold)),
    listen: false,
  );
  await tester.tap(find.text('Buka pemilih'));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
  return container;
}

Future<void> _search(WidgetTester tester, String query) async {
  await tester.enterText(find.byType(TextField), query);
  await tester.pump(const Duration(milliseconds: 350));
}

void main() {
  testWidgets('nama/kode, query pendek, clear, dan ID vendor bernama sama',
      (tester) async {
    var loads = 0;
    final results = <int?>[];
    await _openPicker(tester, () async {
      loads++;
      return _vendors;
    }, results);
    await tester.pumpAndSettle();

    for (final query in ['m', 'ma', 'mak', '  MaKmUr  ']) {
      await _search(tester, query);
      expect(find.text('CV Sumber Makmur'), findsNWidgets(2));
      expect(find.text('PT Sentosa'), findsNothing);
    }
    await _search(tester, 'tidak-ada');
    expect(find.text('Vendor tidak ditemukan'), findsOneWidget);
    await tester.tap(find.byTooltip('Hapus teks'));
    await tester.pump();
    expect(find.text('PT Sentosa'), findsOneWidget);
    await _search(tester, '  vNd-b  ');
    expect(find.text('VND-A'), findsNothing);
    expect(find.text('VND-B'), findsOneWidget);
    expect(loads, 1,
        reason: 'Pengetikan tidak memuat ulang daftar dari server.');
    await tester.tap(find.text('VND-B'));
    await tester.pumpAndSettle();
    expect(results, [19]);
  });

  testWidgets('menemukan vendor di luar item yang mula-mula terlihat',
      (tester) async {
    final vendors = [
      ...List.generate(
          180,
          (i) => PemasokOptionModel(
                id: i + 1,
                kode: 'UMUM-$i',
                nama: 'Pemasok Umum $i',
              )),
      const PemasokOptionModel(
        id: 501,
        kode: 'VND-Z999',
        nama: 'Rekanan Tujuan',
      ),
    ];
    final results = <int?>[];
    await _openPicker(tester, () async => vendors, results);
    await tester.pumpAndSettle();
    expect(find.text('Rekanan Tujuan'), findsNothing);
    await _search(tester, 'z999');
    await tester.tap(find.text('Rekanan Tujuan'));
    await tester.pumpAndSettle();
    expect(results, [501]);
  });

  testWidgets('loading, kegagalan/retry, dan daftar kosong bukan hasil kosong',
      (tester) async {
    final pending = Completer<List<PemasokOptionModel>>();
    var loads = 0;
    await _openPicker(tester, () {
      loads++;
      return loads == 1 ? pending.future : Future.value([]);
    }, <int?>[]);
    expect(find.text('Memuat vendor...'), findsOneWidget);
    expect(find.byType(ListTile), findsNothing);
    pending.completeError(ApiException(message: 'Server uji tidak tersedia'));
    await tester.pumpAndSettle();
    expect(find.text('Gagal Memuat Vendor'), findsOneWidget);
    expect(find.text('Vendor tidak ditemukan'), findsNothing);
    await tester.tap(find.text('Coba Lagi'));
    await tester.pumpAndSettle();
    expect(find.text('Belum ada vendor aktif'), findsOneWidget);
    expect(find.text('Gagal Memuat Vendor'), findsNothing);
    expect(find.text('Vendor tidak ditemukan'), findsNothing);
  });

  testWidgets('refresh membuang hasil lama sebelum vendor dapat dipilih',
      (tester) async {
    var vendors = _vendors;
    final results = <int?>[];
    final container = await _openPicker(
      tester,
      () async => vendors,
      results,
      selectedId: 7,
    );
    await tester.pumpAndSettle();
    expect(find.byTooltip('Vendor terpilih'), findsOneWidget);
    vendors = [_vendors.last];
    container.invalidate(pemasokListProvider);
    await tester.pumpAndSettle();
    expect(find.text('VND-A'), findsNothing);
    expect(find.byTooltip('Vendor terpilih'), findsNothing);
    await tester.tap(find.text('VND-C'));
    await tester.pumpAndSettle();
    expect(results, [41]);
  });

  testWidgets(
      'batal saat debounce aktif dan buka ulang tidak membawa query lama',
      (tester) async {
    final results = <int?>[];
    await _openPicker(tester, () async => _vendors, results, selectedId: 7);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'sentosa');
    await tester.tap(find.byTooltip('Tutup'));
    await tester.pumpAndSettle();
    expect(results, [null]);
    await tester.tap(find.text('Buka pemilih'));
    await tester.pumpAndSettle();
    expect(find.text('CV Sumber Makmur'), findsNWidgets(2));
    expect(find.text('PT Sentosa'), findsOneWidget);
    expect(find.byTooltip('Vendor terpilih'), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(results, [null, null]);
  });

  testWidgets(
      'nama/kode panjang tetap dapat dipilih di layar kecil dan keyboard',
      (tester) async {
    tester.view.physicalSize = const Size(320, 740);
    tester.view.devicePixelRatio = 1;
    tester.view.viewInsets = const FakeViewPadding(bottom: 280);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetViewInsets);
    const vendor = PemasokOptionModel(
      id: 83,
      kode: 'VENDOR-SARANA-PRASARANA-RUMAH-SAKIT-083',
      nama: 'PT Rekanan Penyedia Sarana Prasarana dan Kebutuhan Rumah Sakit',
    );
    final results = <int?>[];
    await _openPicker(
      tester,
      () async => [vendor],
      results,
      textScale: 1.4,
    );
    await tester.pumpAndSettle();
    expect(find.byTooltip('Tutup').hitTestable(), findsOneWidget);
    await tester.ensureVisible(find.text(vendor.kode));
    await tester.pumpAndSettle();
    expect(find.text(vendor.kode).hitTestable(), findsOneWidget);
    await tester.tap(find.text(vendor.kode));
    await tester.pumpAndSettle();
    expect(results, [83]);
  });
}
