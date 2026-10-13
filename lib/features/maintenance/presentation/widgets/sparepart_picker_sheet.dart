import 'package:flutter/material.dart';
import 'package:simlog_mobile/features/pengadaan/data/models/master_barang_model.dart';
import 'package:simlog_mobile/features/pengadaan/presentation/widgets/barang_picker_bottom_sheet.dart';

class SparepartPickerSheet extends StatelessWidget {
  final ValueChanged<MasterBarangModel> onSelected;

  /// Membuat SparepartPickerSheet.
  const SparepartPickerSheet({super.key, required this.onSelected});

  /// Tampilkan sheet sebagai bottom sheet; hasilnya true jika data tersimpan.
  static Future<void> show(
    BuildContext context, {
    required ValueChanged<MasterBarangModel> onSelected,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => BarangPickerBottomSheet(
        filterTipe: 'SPAREPART',
        onBarangSelected: onSelected,
      ),
    );
  }

  /// Membangun tampilan SparepartPickerSheet.
  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
