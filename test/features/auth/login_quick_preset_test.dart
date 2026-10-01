import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simlog_mobile/core/security/security_device_service.dart';
import 'package:simlog_mobile/features/auth/presentation/screens/login_screen.dart';

void main() {
  testWidgets('LoginScreen displays Kepala Teknisi quick preset chip and populates credentials on tap', (tester) async {
    tester.view.physicalSize = const Size(400, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          isDeviceRootedProvider.overrideWith((ref) => Future.value(false)),
        ],
        child: const MaterialApp(
          home: LoginScreen(),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Verify chip exists
    final chipFinder = find.text('Kepala Teknisi');
    expect(chipFinder, findsOneWidget);

    // Tap chip
    await tester.tap(chipFinder);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Verify email and password text fields are populated
    expect(find.text('karu_ipsrs@simlogrs.local'), findsOneWidget);
    expect(find.text('SimlogRS@2026!'), findsOneWidget);
  });
}
