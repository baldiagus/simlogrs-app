import 'package:flutter_test/flutter_test.dart';
import 'package:simlog_mobile/core/notifications/notification_payload.dart';
import 'package:simlog_mobile/core/notifications/push_notification_service.dart';

/// Pengujian [NotificationTapNotifier]: payload awal dikonsumsi sekali saja.
void main() {
  final payload = NotificationPayload(
    tipe: 'APPROVAL_PR',
    referensiId: '14',
    judul: 'j',
    pesan: 'p',
    timestamp: DateTime(2026, 10, 13),
  );

  test('consume mengembalikan payload tersimpan lalu mengosongkannya', () {
    final notifier = NotificationTapNotifier(null);
    addTearDown(notifier.dispose);

    notifier.value = payload;

    expect(notifier.consume(), payload);
    expect(notifier.value, isNull);
    expect(notifier.consume(), isNull);
  });

  test('consume tidak memancarkan event stream sehingga tidak terbuka dua kali', () async {
    final notifier = NotificationTapNotifier(null);
    addTearDown(notifier.dispose);
    final diterima = <NotificationPayload?>[];
    final sub = notifier.listen(diterima.add);
    addTearDown(sub.cancel);

    notifier.value = payload;
    notifier.consume();
    await Future<void>.delayed(Duration.zero);

    expect(diterima, [payload]);
  });
}
