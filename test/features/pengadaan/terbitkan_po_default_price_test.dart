import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simlog_mobile/features/pengadaan/data/models/approval_item_model.dart';
import 'package:simlog_mobile/features/pengadaan/data/models/po_model.dart';
import 'package:simlog_mobile/features/pengadaan/data/models/pr_model.dart';
import 'package:simlog_mobile/features/pengadaan/presentation/providers/pengadaan_provider.dart';
import 'package:simlog_mobile/features/pengadaan/presentation/widgets/terbitkan_po_sheet.dart';

void main() {
  test('PrDetailItemModel parses harga_beli_terakhir and harga_estimasi correctly from JSON', () {
    final json = {
      'id': 1,
      'barang_id': 1,
      'nama_barang': 'HVS A4',
      'kode_barang': 'BRG-2026-001',
      'satuan': 'Box',
      'jumlah': 20,
      'catatan': null,
      'harga_beli_terakhir': 60000,
      'harga_estimasi': 70000,
    };

    final item = PrDetailItemModel.fromJson(json);
    expect(item.hargaBeliTerakhir, 60000.0);
    expect(item.hargaEstimasi, 70000.0);
  });

  testWidgets('TerbitkanPoSheet initializes unit prices with harga_beli_terakhir and calculates total correctly', (tester) async {
    const prItem = ApprovalItemModel(
      id: 1,
      tipe: 'PR',
      kode: 'PR-2026-001',
      unit: 'Instalasi Gawat Darurat',
      pengaju: 'dr. Pratama, Sp.EM',
      tanggal: '2026-09-30',
      urgensi: 'REGULER',
      status: 'DITERUSKAN_KE_PENGADAAN',
      jumlahItem: 2,
      items: [
        ApprovalDetailItem(
          barangId: 1,
          namaBarang: 'HVS A4',
          kodeBarang: 'BRG-2026-001',
          satuan: 'Box',
          jumlah: 20,
          hargaBeliTerakhir: 60000,
          hargaEstimasi: 70000,
        ),
        ApprovalDetailItem(
          barangId: 2,
          namaBarang: 'Printer',
          kodeBarang: 'BRG-2026-002',
          satuan: 'Pieces',
          jumlah: 5,
          hargaBeliTerakhir: 2000000,
          hargaEstimasi: 3000000,
        ),
      ],
    );

    const mockVendors = [
      PemasokOptionModel(
        id: 1,
        kode: 'VND-001',
        nama: 'CV Graha Logistik Medis',
      ),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          pemasokListProvider.overrideWith((ref) => Future.value(mockVendors)),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: TerbitkanPoSheet(prItem: prItem),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify initial values in TextField controllers: 60000 for HVS A4, 2000000 for Printer
    expect(find.text('60000'), findsOneWidget);
    expect(find.text('2000000'), findsOneWidget);

    // Verify reference price text displayed
    expect(find.textContaining('60.000'), findsWidgets);
    expect(find.textContaining('2.000.000'), findsWidgets);

    // Total: 20 * 60,000 + 5 * 2,000,000 = 1,200,000 + 10,000,000 = Rp 11.200.000
    expect(find.textContaining('11.200.000'), findsOneWidget);
  });
}
