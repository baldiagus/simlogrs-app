import 'dart:ui' show SemanticsFlag;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simlog_mobile/core/models/pagination_meta.dart';
import 'package:simlog_mobile/features/audit/data/models/audit_models.dart';
import 'package:simlog_mobile/features/audit/data/repositories/audit_repository.dart';
import 'package:simlog_mobile/features/audit/presentation/providers/audit_provider.dart';
import 'package:simlog_mobile/features/audit/presentation/widgets/tabs/audit_trail_tab.dart';

class _Repository extends Fake implements AuditRepository {
  final calls = <({String? aksi, String? search, int page})>[];

  @override
  Future<PagedResponse<AuditTrailItemModel>> getAuditTrail({
    String? aksi,
    String? entitas,
    String? search,
    int page = 1,
  }) async {
    calls.add((aksi: aksi, search: search, page: page));
    return PagedResponse.empty();
  }
}

Future<void> _pumpTab(WidgetTester tester, _Repository repository, {
  double textScale = 1,
}) async {
  await tester.pumpWidget(ProviderScope(
    overrides: [
      auditTrailProvider.overrideWith((ref) =>
          AuditTrailNotifier(repository)..loadInitial()),
    ],
    child: MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
        child: Scaffold(body: AuditTrailTab(onOpenDetail: (_) {})),
      ),
    ),
  ));
  await tester.pumpAndSettle();
}

Finder _chip(String label) => find.widgetWithText(ChoiceChip, label);

void main() {
  testWidgets('friendly single-select chips send exact API action codes and retain search',
      (tester) async {
    final repository = _Repository();
    await _pumpTab(tester, repository);
    expect(find.byType(DropdownButton<String?>), findsNothing);
    expect(tester.widget<ChoiceChip>(_chip('Semua Aksi')).selected, isTrue);
    await tester.enterText(find.byType(TextField), '  operator  ');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    const options = {
      'Ditambahkan': 'TAMBAH',
      'Diubah': 'UBAH',
      'Dihapus': 'HAPUS',
      'Disetujui': 'APPROVE',
      'Ditolak': 'REJECT',
      'Penyesuaian Stok': 'ADJUSTMENT',
    };
    for (final option in options.entries) {
      await tester.ensureVisible(_chip(option.key));
      await tester.tap(_chip(option.key));
      await tester.pumpAndSettle();
      expect(repository.calls.last,
          (aksi: option.value, search: 'operator', page: 1));
      expect(tester.widgetList<ChoiceChip>(find.byType(ChoiceChip))
          .where((chip) => chip.selected), hasLength(1));
      expect(tester.widget<ChoiceChip>(_chip(option.key)).selected, isTrue);
    }

    await tester.ensureVisible(_chip('Semua Aksi'));
    await tester.tap(_chip('Semua Aksi'));
    await tester.pumpAndSettle();
    expect(repository.calls.last, (aksi: null, search: 'operator', page: 1));
    expect(find.text('  operator  '), findsOneWidget);
    final count = repository.calls.length;
    await tester.tap(_chip('Semua Aksi'));
    await tester.pumpAndSettle();
    expect(repository.calls, hasLength(count));
  });

  testWidgets('last chip is reachable at 343px with large text and exposes selection',
      (tester) async {
    tester.view.physicalSize = const Size(343, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final semantics = tester.ensureSemantics();
    try {
      final repository = _Repository();
      await _pumpTab(tester, repository, textScale: 2);
      await tester.ensureVisible(_chip('Penyesuaian Stok'));
      await tester.tap(_chip('Penyesuaian Stok'));
      await tester.pumpAndSettle();
      expect(repository.calls.last.aksi, 'ADJUSTMENT');
      expect(tester.getSemantics(_chip('Penyesuaian Stok'))
          .hasFlag(SemanticsFlag.isSelected), isTrue);
      expect(tester.takeException(), isNull);
    } finally {
      semantics.dispose();
    }
  });

  testWidgets('chip can be selected with keyboard activation', (tester) async {
    final repository = _Repository();
    await _pumpTab(tester, repository);
    // Tab follows the search field and the selected Semua Aksi chip.
    await tester.tap(find.byType(TextField));
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pumpAndSettle();
    expect(repository.calls.last.aksi, 'TAMBAH');
  });
}
