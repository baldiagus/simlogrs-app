import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simlog_mobile/core/theme/app_theme.dart';
import 'package:simlog_mobile/features/audit/data/models/audit_models.dart';
import 'package:simlog_mobile/features/audit/presentation/widgets/sheets/detail_temuan_sheet.dart';
import 'package:simlog_mobile/features/audit/presentation/widgets/sheets/form_terbitkan_temuan_fields.dart';
import 'package:simlog_mobile/features/audit/presentation/widgets/sheets/form_terbitkan_temuan_sheet.dart';
import 'package:simlog_mobile/features/auth/data/models/user_model.dart';
import 'package:simlog_mobile/features/master/presentation/providers/master_barang_provider.dart';

Future<void> _openSheet(
  WidgetTester tester,
  Widget sheet,
  double scale,
) async {
  tester.view.physicalSize = const Size(343, 762);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        masterUnitListProvider.overrideWith((ref) async => [
              const UnitModel(id: 1, nama: 'Unit Pelayanan Rawat Inap Terpadu'),
            ]),
        masterGudangListProvider.overrideWith((ref) async => [
              const GudangModel(id: 1, nama: 'Gudang Sentral Logistik Rumah Sakit'),
            ]),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(scale),
          ),
          child: child!,
        ),
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showModalBottomSheet<void>(
                context: context,
                isScrollControlled: true,
                builder: (_) => sheet,
              ),
              child: const Text('Buka formulir'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Buka formulir'));
  await tester.pumpAndSettle();
}

void _expectWithinSheet(WidgetTester tester, Finder field, Finder sheet) {
  final fieldRect = tester.getRect(field);
  final sheetRect = tester.getRect(sheet);
  expect(fieldRect.left, greaterThanOrEqualTo(sheetRect.left));
  expect(fieldRect.right, lessThanOrEqualTo(sheetRect.right));
}

void main() {
  for (final scale in [1.0, 2.0]) {
    testWidgets('CAPA evaluation keeps full selected option at 343px / $scale',
        (tester) async {
      await _openSheet(
        tester,
        DetailTemuanSheet(
          temuan: TemuanCapaModel.fromJson({
            'id': 7,
            'kode': 'CAPA-2026-000007',
            'objek_audit': 'Gudang Sentral Logistik Rumah Sakit',
            'ringkasan': 'Ketidaksesuaian dokumentasi pemeriksaan logistik.',
            'status_capa': 'In Progress',
          }),
          canTindakLanjut: false,
          canEvaluasi: true,
        ),
        scale,
      );
      final dropdown = find.byType(DropdownButtonFormField<String>);
      await tester.ensureVisible(dropdown);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.tap(dropdown);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      const option = 'In Progress (Tolak / Perlu Perbaikan Lanjut)';
      await tester.tap(find.text(option).last);
      await tester.pumpAndSettle();
      expect(find.text(option), findsOneWidget);
      _expectWithinSheet(tester, find.text(option), find.byType(DetailTemuanSheet));
      expect(tester.takeException(), isNull);
    });

    testWidgets('Audit registration dates remain reachable at 343px / $scale',
        (tester) async {
      await _openSheet(tester, const FormTerbitkanTemuanSheet(), scale);
      expect(find.text('Registrasi Temuan Audit Baru'), findsOneWidget);
      expect(tester.takeException(), isNull);
      final dates = find.byType(FormTerbitkanTemuanDateField);
      expect(dates, findsNWidgets(2));
      expect(tester.getTopLeft(dates.last).dy,
          greaterThan(tester.getBottomLeft(dates.first).dy));
      for (var index = 0; index < 2; index++) {
        final date = dates.at(index);
        await tester.ensureVisible(date);
        await tester.pumpAndSettle();
        _expectWithinSheet(tester, date, find.byType(FormTerbitkanTemuanSheet));
        final value = find.descendant(of: date, matching: find.byType(InkWell));
        await tester.tap(value);
        await tester.pumpAndSettle();
        expect(find.byType(DatePickerDialog), findsOneWidget);
        expect(tester.takeException(), isNull);
        final dialogContext = tester.element(find.byType(DatePickerDialog));
        Navigator.of(dialogContext).pop();
        await tester.pumpAndSettle();
      }
      await tester.ensureVisible(find.text('Daftarkan Temuan ke SPI'));
      await tester.pumpAndSettle();
      expect(find.text('Unit Terperiksa (Opsional)'), findsOneWidget);
      expect(find.text('Gudang Terperiksa (Opsional)'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
