import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:simlog_mobile/core/theme/app_colors.dart';

/// Label field wajib (dengan tanda bintang merah) pada form terbitkan temuan.
class FormTerbitkanTemuanRequiredLabel extends StatelessWidget {
  const FormTerbitkanTemuanRequiredLabel(this.text, {super.key});

  final String text;

  /// Membangun teks label dengan tanda bintang merah penanda field wajib.
  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        text: text,
        style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 12,
            color: AppColors.textPrimary),
        children: const [
          TextSpan(text: '*', style: TextStyle(color: AppColors.danger)),
        ],
      ),
    );
  }
}

/// Dekorasi input teks dengan border error pada form terbitkan temuan.
InputDecoration formTerbitkanTemuanTextDecoration(
    {required String hintText, String? counterText}) {
  return InputDecoration(
    counterText: counterText,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: AppColors.border),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: AppColors.danger),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: AppColors.danger, width: 1.5),
    ),
    hintText: hintText,
    hintStyle: const TextStyle(fontSize: 12, color: AppColors.textMuted),
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
  );
}

/// Dropdown pilihan tingkat risiko temuan (Mayor / Moderat / Minor).
class FormTerbitkanTemuanRisikoDropdown extends StatelessWidget {
  const FormTerbitkanTemuanRisikoDropdown(
      {super.key, required this.value, required this.onChanged});

  final String value;
  final ValueChanged<String> onChanged;

  /// Membuat satu item dropdown risiko dengan titik warna dan label.
  static DropdownMenuItem<String> _item(
      String value, Color color, String label) {
    return DropdownMenuItem(
      value: value,
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  /// Membangun dropdown risiko dengan indikator warna tiap tingkat.
  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      decoration: InputDecoration(
        isDense: true,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
      items: [
        _item('Mayor', AppColors.danger, 'Mayor (Risiko Kritis / Keuangan)'),
        _item('Moderat', AppColors.warning, 'Moderat (Ketidakpatuhan SOP)'),
        _item('Minor', AppColors.tintBlue, 'Minor (Administratif Ringan)'),
      ],
      onChanged: (val) {
        if (val != null) onChanged(val);
      },
    );
  }
}

/// Field tanggal (label wajib + tile yang membuka date picker).
class FormTerbitkanTemuanDateField extends StatelessWidget {
  const FormTerbitkanTemuanDateField({
    super.key,
    required this.label,
    required this.icon,
    required this.iconColor,
    required this.valueText,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color iconColor;
  final String valueText;
  final VoidCallback onTap;

  /// Membangun label field tanggal beserta tile yang memanggil [onTap] untuk membuka date picker.
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FormTerbitkanTemuanRequiredLabel(label),
        const SizedBox(height: 4),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(icon, size: 14, color: iconColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(valueText,
                      style: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Tombol submit "Daftarkan Temuan ke SPI" dengan state loading.
class FormTerbitkanTemuanSubmitButton extends StatelessWidget {
  const FormTerbitkanTemuanSubmitButton(
      {super.key, required this.isLoading, required this.onPressed});

  final bool isLoading;
  final VoidCallback onPressed;

  /// Membangun tombol submit penuh lebar; dinonaktifkan dan menampilkan spinner saat [isLoading].
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: isLoading ? null : onPressed,
        icon: isLoading
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2))
            : const Icon(LucideIcons.send, size: 16, color: Colors.white),
        label: Text(
            isLoading ? 'Mendaftarkan Temuan...' : 'Daftarkan Temuan ke SPI',
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w700)),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryPurple,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }
}
