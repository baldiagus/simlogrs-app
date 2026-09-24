import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class UrgensiSelectorWidget extends StatelessWidget {
  final String selectedUrgensi;
  final ValueChanged<String> onChanged;

  const UrgensiSelectorWidget({
    super.key,
    required this.selectedUrgensi,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tingkat Urgensi Pengadaan',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _buildChip('REGULER', 'Reguler', AppColors.primaryPurple, AppColors.tintVioletBg),
            const SizedBox(width: 8),
            _buildChip('MENDESAK', 'Mendesak', AppColors.warning, const Color(0xFFFFFBEB)),
            const SizedBox(width: 8),
            _buildChip('CITO', 'CITO (Darurat)', AppColors.danger, const Color(0xFFFEF2F2)),
          ],
        ),
      ],
    );
  }

  Widget _buildChip(String value, String label, Color activeColor, Color activeBg) {
    final isSelected = selectedUrgensi.toUpperCase() == value;

    return Expanded(
      child: InkWell(
        onTap: () => onChanged(value),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? activeBg : AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? activeColor : AppColors.border,
              width: isSelected ? 1.5 : 1.0,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? activeColor : AppColors.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
