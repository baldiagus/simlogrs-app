import 'package:flutter_test/flutter_test.dart';
import 'package:simlog_mobile/core/notifications/notification_payload.dart';
import 'package:simlog_mobile/core/notifications/notification_router.dart';

/// Membuat payload uji dengan [tipe] tertentu.
NotificationPayload _payload(String tipe) => NotificationPayload(
      tipe: tipe,
      judul: 'j',
      pesan: 'p',
      timestamp: DateTime(2026, 10, 13),
    );

/// Pengujian pemetaan tipe notifikasi kontrak bagian 4 ke [NotificationTarget].
void main() {
  const kontrak = <String, NotificationTarget>{
    'APPROVAL_PR': NotificationTarget.approvalPr,
    'PR_DIPUTUSKAN': NotificationTarget.riwayatPr,
    'PO_TERBIT': NotificationTarget.inboundPo,
    'APPROVAL_AMPRAH': NotificationTarget.approvalAmprah,
    'ANTREAN_PICKING': NotificationTarget.antreanPicking,
    'AMPRAH_DIPUTUSKAN': NotificationTarget.detailAmprah,
    'SPPB_DIKIRIM': NotificationTarget.sppbInbound,
    'TIKET_BARU': NotificationTarget.hubIpsrs,
    'SPK_DITUGASKAN': NotificationTarget.detailSpk,
    'PERBAIKAN_SELESAI': NotificationTarget.detailTiket,
    'PINJAM_BARU': NotificationTarget.otorisasiSirkulasi,
    'PINJAM_DIPUTUSKAN': NotificationTarget.peminjamanSaya,
    'PENGALIHAN_MASUK': NotificationTarget.hubPengalihan,
    'OTORISASI_STOK': NotificationTarget.otorisasiPenyesuaian,
    'PINJAM_JATUH_TEMPO': NotificationTarget.peminjamanSaya,
    'PINJAM_TERLAMBAT': NotificationTarget.peminjamanSaya,
    'SPK_PREVENTIF': NotificationTarget.detailSpk,
  };

  group('resolveTarget', () {
    kontrak.forEach((tipe, target) {
      test('$tipe -> ${target.name}', () {
        expect(resolveTarget(_payload(tipe)), target);
      });
    });

    test('tipe huruf kecil dan berspasi tetap dikenali', () {
      expect(resolveTarget(_payload('  approval_pr ')), NotificationTarget.approvalPr);
      expect(resolveTarget(_payload('Pinjam_Terlambat')), NotificationTarget.peminjamanSaya);
    });

    test('UMUM membuka inbox', () {
      expect(resolveTarget(_payload('UMUM')), NotificationTarget.inbox);
    });

    test('tipe asing atau kosong menjadi tidakDikenal', () {
      expect(resolveTarget(_payload('TIPE_BARU_XYZ')), NotificationTarget.tidakDikenal);
      expect(resolveTarget(_payload('')), NotificationTarget.tidakDikenal);
    });
  });
}
