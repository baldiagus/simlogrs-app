import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simlog_mobile/shared/widgets/app_toast.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

const _returnMessage =
    'Anda tidak berwenang mengonfirmasi pengembalian aset ini. '
    'Konfirmasi hanya dapat dilakukan oleh petugas dari ruangan atau '
    'gudang penyedia asal aset, atau admin yang berwenang.';

void main() {
  testWidgets('AppToast shows the complete return error on a narrow screen',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 640);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(() async {
      await tester.pump(const Duration(seconds: 4));
      await tester.pumpWidget(const SizedBox.shrink());
    });
    late BuildContext toastContext;
    await tester.pumpWidget(MaterialApp(
      home: Builder(builder: (context) {
        toastContext = context;
        return const Scaffold();
      }),
    ));
    AppToast.error(toastContext, _returnMessage);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    final text = find.text(_returnMessage);
    final paragraph = tester.renderObject<RenderParagraph>(text);
    expect(paragraph.didExceedMaxLines, isFalse);
    final lastCharacter = paragraph.getBoxesForSelection(const TextSelection(
      baseOffset: _returnMessage.length - 1,
      extentOffset: _returnMessage.length,
    ));
    expect(lastCharacter, isNotEmpty);
    final bottomRight =
        paragraph.localToGlobal(lastCharacter.last.toRect().bottomRight);
    expect(tester.getRect(text).contains(bottomRight - const Offset(0.1, 0.1)),
        isTrue);
    expect(bottomRight.dy, lessThan(640));
    await tester.pump(const Duration(seconds: 4));
  });

  for (final width in [320.0, 360.0, 400.0]) {
    for (final scale in [1.0, 1.5, 2.0]) {
      testWidgets('toast text remains accessible at ${width}dp and ${scale}x',
          (tester) async {
        for (final type in AppToastType.values) {
          await _showToast(tester, _returnMessage,
              size: Size(width, 640), scale: scale, type: type);
          final text = find.text(_returnMessage);
          expect(tester.renderObject<RenderParagraph>(text).didExceedMaxLines,
              isFalse);
          final scroll = _messageScroll(_returnMessage);
          final position = tester
              .state<ScrollableState>(find.descendant(
                  of: scroll, matching: find.byType(Scrollable)))
              .position;
          position.jumpTo(position.maxScrollExtent);
          await tester.pump();
          expect(tester.getRect(scroll).height, lessThanOrEqualTo(320));
          _expectEndVisible(tester, _returnMessage, tester.getRect(scroll));
          expect(tester.takeException(), isNull);
          await tester.pump(const Duration(seconds: 31));
        }
      });
    }
  }

  testWidgets(
      'long landscape toast scrolls without dismissing or covering controls',
      (tester) async {
    final message = '${List.filled(12, _returnMessage).join(' ')} SELESAI.';
    await _showToast(tester, message,
        size: const Size(640, 320),
        scale: 2,
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 16));
    final scroll = _messageScroll(message);
    final viewport = tester.getRect(scroll);
    expect(viewport.height, lessThanOrEqualTo(135));
    expect(viewport.top, greaterThan(24));
    expect(viewport.bottom, lessThan(304));
    final before = _lastCharacterRect(tester, message).top;
    await tester.drag(scroll, const Offset(0, -60));
    await tester.pumpAndSettle();
    expect(find.text(message), findsOneWidget);
    expect(_lastCharacterRect(tester, message).top, lessThan(before));
    final position = tester
        .state<ScrollableState>(
            find.descendant(of: scroll, matching: find.byType(Scrollable)))
        .position;
    position.jumpTo(position.maxScrollExtent);
    await tester.pump();
    _expectEndVisible(tester, message, viewport);
    final close = find.byIcon(LucideIcons.x);
    expect(tester.getRect(close).bottom, lessThan(304));
    expect(tester.takeException(), isNull);
    await tester.tap(close);
    await tester.pumpAndSettle();
    expect(find.text(message), findsNothing);
  });

  testWidgets('toast stays above keyboard and inside safe area',
      (tester) async {
    await _showToast(tester, _returnMessage,
        scale: 2,
        padding: const EdgeInsets.only(top: 24, bottom: 20),
        keyboardHeight: 320);
    final scroll = _messageScroll(_returnMessage);
    final viewport = tester.getRect(scroll);
    expect(viewport.height, lessThanOrEqualTo(143));
    expect(viewport.top, greaterThan(24));
    expect(viewport.bottom, lessThan(320));
    final position = tester
        .state<ScrollableState>(
            find.descendant(of: scroll, matching: find.byType(Scrollable)))
        .position;
    position.jumpTo(position.maxScrollExtent);
    await tester.pump();
    _expectEndVisible(tester, _returnMessage, viewport);
    expect(tester.takeException(), isNull);
    await tester.pump(const Duration(seconds: 31));
  });

  testWidgets('short toast remains compact and dismisses on upward swipe',
      (tester) async {
    for (final type in AppToastType.values) {
      await _showToast(tester, 'Tersimpan.', type: type);
      expect(tester.getRect(_messageScroll('Tersimpan.')).height, lessThan(30));
      await tester.drag(find.text('Tersimpan.'), const Offset(0, -60));
      await tester.pumpAndSettle();
      expect(find.text('Tersimpan.'), findsNothing);
    }
  });

  testWidgets('replacement keeps its custom duration after old timer expires',
      (tester) async {
    final context = await _showToast(tester, 'Pesan lama',
        duration: const Duration(seconds: 1));
    AppToast.info(context, 'Pesan baru', duration: const Duration(seconds: 5));
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    expect(find.text('Pesan lama'), findsNothing);
    expect(find.text('Pesan baru'), findsOneWidget);
    await tester.pump(const Duration(seconds: 4));
    expect(find.text('Pesan baru'), findsNothing);
  });

  testWidgets(
      'AppToast renders at top and automatically disappears after 3 seconds',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (ctx) => ElevatedButton(
              onPressed: () {
                AppToast.success(ctx, 'Penerimaan berhasil disimpan');
              },
              child: const Text('Show Toast'),
            ),
          ),
        ),
      ),
    );

    // Initial state: no toast
    expect(find.text('Penerimaan berhasil disimpan'), findsNothing);

    // Tap button to show toast
    await tester.tap(find.text('Show Toast'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300)); // Animation in

    // Toast is visible at the top
    expect(find.text('Penerimaan berhasil disimpan'), findsOneWidget);

    // Advance 2 seconds (not yet disappeared)
    await tester.pump(const Duration(seconds: 2));
    expect(find.text('Penerimaan berhasil disimpan'), findsOneWidget);

    // Advance remaining 1.5 seconds (total > 3s)
    await tester.pump(const Duration(milliseconds: 1500));
    await tester.pumpAndSettle();

    // Toast has disappeared
    expect(find.text('Penerimaan berhasil disimpan'), findsNothing);
  });

  testWidgets('AppToast disappears immediately on tap', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (ctx) => ElevatedButton(
              onPressed: () {
                AppToast.error(ctx, 'Gagal memproses data');
              },
              child: const Text('Show Error Toast'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Show Error Toast'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Gagal memproses data'), findsOneWidget);

    // Tap toast to dismiss early
    await tester.tap(find.text('Gagal memproses data'));
    await tester.pumpAndSettle();

    expect(find.text('Gagal memproses data'), findsNothing);
  });
}

Future<BuildContext> _showToast(
  WidgetTester tester,
  String message, {
  Size size = const Size(320, 640),
  double scale = 1,
  EdgeInsets padding = EdgeInsets.zero,
  double keyboardHeight = 0,
  AppToastType type = AppToastType.error,
  Duration duration = const Duration(seconds: 30),
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
  late BuildContext toastContext;
  await tester.pumpWidget(MaterialApp(
    builder: (context, child) => MediaQuery(
      data: MediaQueryData(
        size: size,
        padding: padding,
        viewInsets: EdgeInsets.only(bottom: keyboardHeight),
        textScaler: TextScaler.linear(scale),
      ),
      child: child!,
    ),
    home: Builder(builder: (context) {
      toastContext = context;
      return const Scaffold();
    }),
  ));
  AppToast.show(toastContext, message, type: type, duration: duration);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
  return toastContext;
}

Finder _messageScroll(String message) => find
    .ancestor(
        of: find.text(message), matching: find.byType(SingleChildScrollView))
    .first;

Rect _lastCharacterRect(WidgetTester tester, String message) {
  final paragraph = tester.renderObject<RenderParagraph>(find.text(message));
  final boxes = paragraph.getBoxesForSelection(TextSelection(
    baseOffset: message.length - 1,
    extentOffset: message.length,
  ));
  expect(boxes, isNotEmpty);
  return boxes.last.toRect().shift(paragraph.localToGlobal(Offset.zero));
}

void _expectEndVisible(WidgetTester tester, String message, Rect viewport) {
  final last = _lastCharacterRect(tester, message).deflate(0.1);
  expect(viewport.contains(last.topLeft), isTrue);
  expect(viewport.contains(last.bottomRight), isTrue);
}
