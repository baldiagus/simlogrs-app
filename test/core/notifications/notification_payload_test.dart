import 'package:flutter_test/flutter_test.dart';
import 'package:simlog_mobile/core/notifications/notification_payload.dart';

/// Pengujian unit untuk parsing dan fungsionalitas [NotificationPayload].
void main() {
  group('NotificationPayload fromMap parsing', () {
    test('berhasil mem-parsing tipe APPROVAL_PR', () {
      final map = {
        'tipe': 'APPROVAL_PR',
        'referensi_id': 'PR-2026-001',
        'judul': 'Persetujuan Purchase Requisition',
        'pesan': 'Ada pengajuan PR baru yang memerlukan persetujuan.',
        'timestamp': '2026-10-13T08:00:00.000Z',
      };

      final payload = NotificationPayload.fromMap(map);

      expect(payload.tipe, 'APPROVAL_PR');
      expect(payload.referensiId, 'PR-2026-001');
      expect(payload.judul, 'Persetujuan Purchase Requisition');
      expect(payload.pesan, 'Ada pengajuan PR baru yang memerlukan persetujuan.');
      expect(payload.timestamp, DateTime.parse('2026-10-13T08:00:00.000Z'));
    });

    test('berhasil mem-parsing tipe APPROVAL_AMPRAH', () {
      final map = {
        'tipe': 'APPROVAL_AMPRAH',
        'referensi_id': 'AMP-2026-002',
        'judul': 'Persetujuan Amprah Barang',
        'pesan': 'Permintaan amprah unit IGD menunggu konfirmasi.',
        'timestamp': '2026-10-13T08:30:00.000Z',
      };

      final payload = NotificationPayload.fromMap(map);

      expect(payload.tipe, 'APPROVAL_AMPRAH');
      expect(payload.referensiId, 'AMP-2026-002');
      expect(payload.judul, 'Persetujuan Amprah Barang');
      expect(payload.pesan, 'Permintaan amprah unit IGD menunggu konfirmasi.');
      expect(payload.timestamp, DateTime.parse('2026-10-13T08:30:00.000Z'));
    });

    test('berhasil mem-parsing tipe TIKET_SPK', () {
      final map = {
        'tipe': 'TIKET_SPK',
        'referensi_id': 'SPK-2026-003',
        'judul': 'Penugasan SPK Pemeliharaan',
        'pesan': 'SPK perbaikan tensimeter telah diterbitkan.',
        'timestamp': '2026-10-13T09:00:00.000Z',
      };

      final payload = NotificationPayload.fromMap(map);

      expect(payload.tipe, 'TIKET_SPK');
      expect(payload.referensiId, 'SPK-2026-003');
      expect(payload.judul, 'Penugasan SPK Pemeliharaan');
      expect(payload.pesan, 'SPK perbaikan tensimeter telah diterbitkan.');
      expect(payload.timestamp, DateTime.parse('2026-10-13T09:00:00.000Z'));
    });

    test('mendukung kunci alternatif seperti type, title, body, dan timestamp integer', () {
      final epochMs = DateTime.utc(2026, 10, 13, 9, 30).millisecondsSinceEpoch;
      final map = {
        'type': 'APPROVAL_PO',
        'referensiId': 'PO-999',
        'title': 'Persetujuan PO',
        'body': 'PO butuh tanda tangan',
        'timestamp': epochMs,
      };

      final payload = NotificationPayload.fromMap(map);

      expect(payload.tipe, 'APPROVAL_PO');
      expect(payload.referensiId, 'PO-999');
      expect(payload.judul, 'Persetujuan PO');
      expect(payload.pesan, 'PO butuh tanda tangan');
      expect(payload.timestamp, DateTime.fromMillisecondsSinceEpoch(epochMs));
    });
  });

  group('NotificationPayload isApproval', () {
    test('mengembalikan true untuk tipe persetujuan (APPROVAL_*)', () {
      final payloadPr = NotificationPayload.fromMap({'tipe': 'APPROVAL_PR'});
      final payloadAmprah = NotificationPayload.fromMap({'tipe': 'APPROVAL_AMPRAH'});
      final payloadPo = NotificationPayload.fromMap({'tipe': 'approval_po'});
      final payloadSpasi = NotificationPayload.fromMap({'tipe': '  APPROVAL_CUSTOM  '});

      expect(payloadPr.isApproval, isTrue);
      expect(payloadAmprah.isApproval, isTrue);
      expect(payloadPo.isApproval, isTrue);
      expect(payloadSpasi.isApproval, isTrue);
    });

    test('mengembalikan false untuk tipe selain persetujuan', () {
      final payloadSpk = NotificationPayload.fromMap({'tipe': 'TIKET_SPK'});
      final payloadInfo = NotificationPayload.fromMap({'tipe': 'INFO_SISTEM'});
      final payloadKosong = NotificationPayload.fromMap({'tipe': ''});
      final payloadNon = NotificationPayload.fromMap({'tipe': 'NON_APPROVAL'});

      expect(payloadSpk.isApproval, isFalse);
      expect(payloadInfo.isApproval, isFalse);
      expect(payloadKosong.isApproval, isFalse);
      expect(payloadNon.isApproval, isFalse);
    });
  });

  group('NotificationPayload fallback nilai default saat map parsial', () {
    test('menggunakan fallback default saat map kosong', () {
      final sebelum = DateTime.now().subtract(const Duration(seconds: 1));
      final payload = NotificationPayload.fromMap({});
      final sesudah = DateTime.now().add(const Duration(seconds: 1));

      expect(payload.tipe, isEmpty);
      expect(payload.referensiId, isNull);
      expect(payload.judul, isEmpty);
      expect(payload.pesan, isEmpty);
      expect(payload.timestamp.isAfter(sebelum), isTrue);
      expect(payload.timestamp.isBefore(sesudah), isTrue);
    });

    test('menggunakan fallback default saat nilai map berupa null', () {
      final payload = NotificationPayload.fromMap({
        'tipe': null,
        'referensi_id': null,
        'judul': null,
        'pesan': null,
        'timestamp': null,
      });

      expect(payload.tipe, isEmpty);
      expect(payload.referensiId, isNull);
      expect(payload.judul, isEmpty);
      expect(payload.pesan, isEmpty);
      expect(payload.timestamp, isA<DateTime>());
    });

    test('tetap mengisi field yang tersedia dan menggunakan fallback untuk field yang hilang', () {
      final payload = NotificationPayload.fromMap({
        'tipe': 'TIKET_SPK',
        'judul': 'Notifikasi Baru',
      });

      expect(payload.tipe, 'TIKET_SPK');
      expect(payload.referensiId, isNull);
      expect(payload.judul, 'Notifikasi Baru');
      expect(payload.pesan, isEmpty);
      expect(payload.timestamp, isA<DateTime>());
    });
  });

  group('NotificationPayload toMap dan serialisasi', () {
    test('toMap dan toJson menghasilkan struktur data yang konsisten', () {
      final waktu = DateTime.parse('2026-10-13T12:00:00.000Z');
      final payload = NotificationPayload(
        tipe: 'APPROVAL_PR',
        referensiId: 'PR-100',
        judul: 'Persetujuan PR',
        pesan: 'Rincian PR',
        timestamp: waktu,
      );

      final map = payload.toMap();
      expect(map['tipe'], 'APPROVAL_PR');
      expect(map['referensi_id'], 'PR-100');
      expect(map['judul'], 'Persetujuan PR');
      expect(map['pesan'], 'Rincian PR');
      expect(map['timestamp'], waktu.toIso8601String());

      final json = payload.toJson();
      final decoded = NotificationPayload.fromJson(json);
      expect(decoded.tipe, payload.tipe);
      expect(decoded.referensiId, payload.referensiId);
      expect(decoded.judul, payload.judul);
      expect(decoded.pesan, payload.pesan);
      expect(decoded.timestamp, payload.timestamp);
    });
  });
}
