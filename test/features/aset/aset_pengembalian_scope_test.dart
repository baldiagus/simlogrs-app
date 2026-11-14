import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simlog_mobile/features/aset/data/models/aset_detail_model.dart';
import 'package:simlog_mobile/features/aset/presentation/screens/aset_detail_screen.dart';
import 'package:simlog_mobile/features/auth/data/models/user_model.dart';
import 'package:simlog_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'aset_detail_screen_test.dart' show MockAuthNotifier;

void main() {
  for (final (label, unitId, permissions, roles, allowed) in [
    ('borrower with permission', 2, ['create_layanan_unit::pengembalian::aset'], ['kepala_unit'], false),
    ('provider with permission', 1, ['create_layanan_unit::pengembalian::aset'], ['kepala_unit'], true),
    ('provider without permission', 1, <String>[], ['kepala_unit'], false),
    ('foreign unit with permission', 3, ['update_layanan_unit::pengembalian::aset'], ['kepala_unit'], false),
    ('admin in borrower unit', 2, <String>[], ['admin_logistik'], true),
  ]) {
    testWidgets('profile return access: $label', (tester) async {
      final asset = AsetDetailModel.fromJson({
        'id': 1, 'kode_aset': 'AST-1', 'status': 'DIPINJAM',
        'unit_id': 2, 'penanggung_jawab': 'Peminjam',
        'tipe_penyedia': 'RUANGAN', 'penyedia_id': 1,
        'peminjaman_aktif': {'peminjaman_id': 10, 'peminjaman_detail_id': 11,
          'kode_pinjam': 'PIN-10', 'unit_peminjam': 'Peminjam'},
      });
      final user = UserModel(id: 1, name: label, email: 'test@example.test',
        roles: roles, permissions: permissions,
        unit: UnitModel(id: unitId, nama: 'Peminjam', kode: 'U'));
      await tester.pumpWidget(ProviderScope(overrides: [
        authStateProvider.overrideWith((ref) => MockAuthNotifier(user)),
      ], child: MaterialApp(home: AsetDetailScreen(initialAset: asset))));
      await tester.pumpAndSettle();
      expect(find.text('Kembalikan Fisik'), allowed ? findsOneWidget : findsNothing);
      if (!allowed) {
        expect(find.text('Peminjam menyerahkan fisik aset kepada penyedia asal untuk proses inspeksi pengembalian resmi.'), findsOneWidget);
      }
    });
  }
}
