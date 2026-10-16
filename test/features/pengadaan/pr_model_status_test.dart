import 'package:flutter_test/flutter_test.dart';
import 'package:simlog_mobile/features/pengadaan/data/models/pr_model.dart';

PrHeaderModel _pr(String status) => PrHeaderModel(
      id: 1,
      kode: 'PR-001',
      unit: 'Unit',
      pengaju: 'Staf',
      tanggalPermintaan: '2026-01-01',
      urgensi: 'REGULER',
      status: status,
      jumlahItem: 0,
      items: const [],
    );

void main() {
  group('PrHeaderModel.isDisetujui', () {
    const cases = <String, bool>{
      PrStatus.diajukan: false,
      PrStatus.ditolak: false,
      PrStatus.disetujui: true,
      PrStatus.disetujuiKaru: true,
      PrStatus.diteruskanKePengadaan: true,
      PrStatus.diproses: true,
      PrStatus.selesai: true,
      'disetujui': true,
      'diteruskan_ke_pengadaan': true,
      'diproses': true,
      'selesai': true,
      'disetujui_karu': true,
      'diajukan': false,
      'ditolak': false,
      'POSTPONED': false,
      'PO': false,
      '': false,
    };

    cases.forEach((status, expected) {
      test('"$status" => $expected', () {
        expect(_pr(status).isDisetujui, expected);
      });
    });
  });
}
