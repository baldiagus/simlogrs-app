import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simlog_mobile/features/anggaran/data/models/anggaran_models.dart';
import 'package:simlog_mobile/features/anggaran/presentation/providers/anggaran_provider.dart';
import 'package:simlog_mobile/features/anggaran/presentation/screens/pagu_realisasi_screen.dart';
import 'package:simlog_mobile/features/auth/data/models/user_model.dart';
import 'package:simlog_mobile/features/auth/presentation/providers/auth_provider.dart';

class _AuthenticatedNotifier extends StateNotifier<AuthState>
    implements AuthNotifier {
  _AuthenticatedNotifier()
      : super(AuthState.authenticated(const UserModel(
          id: 1,
          name: 'Budget auditor',
          email: 'auditor@example.test',
          roles: ['super_admin'],
          permissions: [],
        )));

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  for (final size in const [Size(360, 800), Size(402, 817), Size(1280, 800)]) {
    for (final scale in [1.0, 2.0]) {
      for (final state in ['data', 'loading', 'error']) {
        testWidgets('budget header $state at $size with text scale $scale',
            (tester) async {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final requestedYears = <String>[];
          final pending = Completer<AnggaranScreeningModel>();
          final container = ProviderContainer(overrides: [
            authStateProvider.overrideWith((ref) => _AuthenticatedNotifier()),
            selectedTahunAnggaranProvider.overrideWith((ref) => '2026'),
            screeningAnggaranProvider.overrideWith((ref) {
              final year = ref.watch(selectedTahunAnggaranProvider);
              requestedYears.add(year);
              if (state == 'loading') return pending.future;
              if (state == 'error') {
                return Future<AnggaranScreeningModel>.error(
                  StateError('Budget unavailable'),
                );
              }
              return Future.value(AnggaranScreeningModel.fromJson({'tahun': year}));
            }),
          ]);
          addTearDown(container.dispose);
          await tester.pumpWidget(UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  textScaler: TextScaler.linear(scale),
                ),
                child: child!,
              ),
              home: const PaguRealisasiScreen(),
            ),
          ));
          await tester.pump();

          final title = find.text('Pagu & Realisasi Anggaran');
          final dropdown = find.byType(DropdownButton<String>);
          final refresh = find.byTooltip('Muat ulang');
          expect(title, findsOneWidget);
          expect(find.text('Screening Pengeluaran Logistik & Suku Cadang'), findsNothing);
          expect(dropdown, findsOneWidget);
          expect(find.ancestor(of: dropdown, matching: find.byType(AppBar)), findsOneWidget);
          expect(tester.getRect(title).right, lessThanOrEqualTo(tester.getRect(dropdown).left));
          expect(tester.getRect(dropdown).right, lessThanOrEqualTo(tester.getRect(refresh).left));
          expect(tester.getSize(dropdown).height, greaterThanOrEqualTo(48));
          expect(tester.getSize(refresh).height, greaterThanOrEqualTo(48));
          expect(tester.takeException(), isNull);

          await tester.tap(dropdown);
          await tester.pump(const Duration(milliseconds: 300));
          await tester.tap(find.text('TA 2025').last);
          await tester.pump(const Duration(milliseconds: 300));
          await tester.pump();
          expect(container.read(selectedTahunAnggaranProvider), '2025');
          expect(requestedYears.last, '2025');
          expect(tester.takeException(), isNull);

          final requestsBeforeRefresh = requestedYears.length;
          await tester.tap(refresh);
          await tester.pump();
          await tester.pump();
          expect(requestedYears.length, greaterThan(requestsBeforeRefresh));
          expect(requestedYears.last, '2025');
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox.shrink());
        });
      }
    }
  }
}
