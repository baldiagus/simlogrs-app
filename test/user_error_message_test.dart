import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simlog_mobile/core/network/api_response.dart';
import 'package:simlog_mobile/core/network/user_error_message.dart';
import 'package:simlog_mobile/shared/widgets/app_error_view.dart';

void main() {
  test('server and unknown exception details never become UI messages', () {
    for (final status in [400, 401, 403, 404, 409, 422, 429, 500, 503]) {
      final message = userErrorMessage(
        ApiException(message: 'SQL password=secret', statusCode: status),
        action: 'mengirim laporan',
      );
      expect(message, isNot(contains('SQL')));
      expect(message, isNot(contains('secret')));
    }
    expect(
      userErrorMessage(StateError('SQL password=secret'), action: 'mengirim laporan'),
      'Terjadi kendala saat mengirim laporan. Silakan coba lagi.',
    );
  });

  test('HTTP conflict instructs reloading rather than blindly retrying', () {
    expect(
      userErrorMessage(ApiException(message: 'private', statusCode: 409)),
      'Data atau status transaksi telah berubah. Muat ulang data sebelum melanjutkan.',
    );
  });

  test('wrapped permission failures preserve safe action-specific guidance', () {
    final error = DioException(
      requestOptions: RequestOptions(path: '/aset/kembalikan'),
      error: ApiException(message: 'private', statusCode: 403),
    );
    expect(userErrorMessage(error, forbiddenMessage: 'Hanya penyedia yang berwenang.'),
        'Hanya penyedia yang berwenang.');
  });

  test('unwrapped timeout provides actionable connection guidance', () {
    expect(
      userErrorMessage(DioException(
        requestOptions: RequestOptions(path: '/audit'),
        type: DioExceptionType.receiveTimeout,
      )),
      'Server belum merespons. Silakan coba beberapa saat lagi.',
    );
  });

  testWidgets('error surface hides exception details on a narrow screen', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: AppErrorView(
      error: ApiException(message: 'SQL password=secret', statusCode: 403),
      onRetry: () {},
    ))));
    expect(find.textContaining('secret'), findsNothing);
    expect(find.textContaining('Hubungi admin'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
