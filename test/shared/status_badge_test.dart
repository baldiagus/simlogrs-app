import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simlog_mobile/shared/widgets/status_badge.dart';

void main() {
  testWidgets('StatusBadge displays DIKIRIM SEBAGIAN with amber background for partial delivery', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: StatusBadge(status: 'DIKIRIM_SEBAGIAN'),
        ),
      ),
    );

    expect(find.text('DIKIRIM SEBAGIAN'), findsOneWidget);

    final container = tester.widget<Container>(find.byType(Container));
    final decoration = container.decoration as BoxDecoration;
    expect(decoration.color, const Color(0xFFFFFBEB));
  });
}
