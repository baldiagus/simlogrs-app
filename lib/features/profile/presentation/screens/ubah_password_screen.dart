import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_toast.dart';
import '../../../../shared/widgets/custom_button.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

/// Layar formulir untuk mengubah kata sandi akun pengguna.
class UbahPasswordScreen extends ConsumerStatefulWidget {
  /// Membuat instance layar ubah kata sandi.
  const UbahPasswordScreen({super.key});

  /// Membuat state untuk layar ubah kata sandi.
  @override
  ConsumerState<UbahPasswordScreen> createState() => _UbahPasswordScreenState();
}

/// State layar formulir ubah kata sandi yang menangani interaksi form dan validasi realtime.
class _UbahPasswordScreenState extends ConsumerState<UbahPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordCtrl = TextEditingController();
  final _newPasswordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();

  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;

  /// Memeriksa apakah kata sandi baru memenuhi syarat minimal 8 karakter.
  bool get _isMinLengthMet => _newPasswordCtrl.text.length >= 8;

  /// Memeriksa apakah kata sandi baru mengandung kombinasi huruf dan angka.
  bool get _isAlphaNumericMet {
    final text = _newPasswordCtrl.text;
    return RegExp(r'[a-zA-Z]').hasMatch(text) && RegExp(r'[0-9]').hasMatch(text);
  }

  /// Memeriksa apakah konfirmasi kata sandi terisi dan cocok dengan kata sandi baru.
  bool get _isConfirmMatched =>
      _confirmPasswordCtrl.text.isNotEmpty &&
      _confirmPasswordCtrl.text == _newPasswordCtrl.text;

  /// Menginisialisasi listener controller agar indikator syarat kata sandi diperbarui secara realtime.
  @override
  void initState() {
    super.initState();
    _newPasswordCtrl.addListener(_handlePasswordChanged);
    _confirmPasswordCtrl.addListener(_handlePasswordChanged);
  }

  /// Memperbarui tampilan UI saat teks kata sandi baru atau konfirmasi berubah.
  void _handlePasswordChanged() {
    setState(() {});
  }

  /// Membersihkan listener dan controller saat widget dihapus dari pohon widget.
  @override
  void dispose() {
    _newPasswordCtrl.removeListener(_handlePasswordChanged);
    _confirmPasswordCtrl.removeListener(_handlePasswordChanged);
    _currentPasswordCtrl.dispose();
    _newPasswordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    super.dispose();
  }

  /// Memvalidasi seluruh form dan mengirim permintaan ubah kata sandi ke backend.
  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isLoading = true);
    try {
      await ref.read(authStateProvider.notifier).gantiPasswordWajib(
            passwordSaatIni: _currentPasswordCtrl.text,
            passwordBaru: _newPasswordCtrl.text,
            passwordBaruConfirmation: _confirmPasswordCtrl.text,
          );
      if (mounted) {
        AppToast.success(context, 'Kata sandi berhasil diperbarui.');
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        final pesan = e
            .toString()
            .replaceAll('ApiException: ', '')
            .replaceAll('Exception: ', '');
        AppToast.error(context, pesan);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Membangun satu butir indikator syarat kata sandi beserta status centang atau lingkarannya.
  Widget _buildChecklistItem({
    required bool isValid,
    required String label,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Icon(
            isValid ? LucideIcons.checkCircle2 : LucideIcons.circle,
            size: 16,
            color: isValid ? AppColors.success : AppColors.textMuted,
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isValid ? AppColors.textPrimary : AppColors.textSecondary,
              fontWeight: isValid ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  /// Membangun antarmuka layar ubah kata sandi dengan AppBar, banner informasi, form input, dan tombol simpan.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: const Text('Ubah Kata Sandi'),
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          tooltip: 'Kembali',
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Banner Informasi
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.tintVioletBg,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppColors.primaryPurple.withValues(alpha: 0.2),
                    ),
                  ),
                  child: const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        LucideIcons.info,
                        size: 18,
                        color: AppColors.primaryPurple,
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Kata sandi baru akan berlaku untuk login di SIMLOG RS Web Portal dan Aplikasi Mobile.',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textPrimary,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // 1. Kata Sandi Saat Ini
                TextFormField(
                  controller: _currentPasswordCtrl,
                  obscureText: _obscureCurrent,
                  decoration: InputDecoration(
                    labelText: 'Kata Sandi Saat Ini',
                    prefixIcon: const Icon(LucideIcons.lockKeyhole, size: 20),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureCurrent ? LucideIcons.eyeOff : LucideIcons.eye,
                        size: 18,
                      ),
                      tooltip: _obscureCurrent
                          ? 'Tampilkan kata sandi'
                          : 'Sembunyikan kata sandi',
                      onPressed: () =>
                          setState(() => _obscureCurrent = !_obscureCurrent),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Kata sandi saat ini wajib diisi';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // 2. Kata Sandi Baru
                TextFormField(
                  controller: _newPasswordCtrl,
                  obscureText: _obscureNew,
                  decoration: InputDecoration(
                    labelText: 'Kata Sandi Baru',
                    prefixIcon: const Icon(LucideIcons.keyRound, size: 20),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureNew ? LucideIcons.eyeOff : LucideIcons.eye,
                        size: 18,
                      ),
                      tooltip: _obscureNew
                          ? 'Tampilkan kata sandi'
                          : 'Sembunyikan kata sandi',
                      onPressed: () => setState(() => _obscureNew = !_obscureNew),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) {
                      return 'Kata sandi baru wajib diisi';
                    }
                    if (v.length < 8) {
                      return 'Kata sandi minimal 8 karakter';
                    }
                    if (!RegExp(r'[a-zA-Z]').hasMatch(v) ||
                        !RegExp(r'[0-9]').hasMatch(v)) {
                      return 'Kombinasi huruf dan angka wajib dipenuhi';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // 3. Konfirmasi Kata Sandi Baru
                TextFormField(
                  controller: _confirmPasswordCtrl,
                  obscureText: _obscureConfirm,
                  decoration: InputDecoration(
                    labelText: 'Konfirmasi Kata Sandi Baru',
                    prefixIcon: const Icon(LucideIcons.checkCheck, size: 20),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirm ? LucideIcons.eyeOff : LucideIcons.eye,
                        size: 18,
                      ),
                      tooltip: _obscureConfirm
                          ? 'Tampilkan kata sandi'
                          : 'Sembunyikan kata sandi',
                      onPressed: () =>
                          setState(() => _obscureConfirm = !_obscureConfirm),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) {
                      return 'Konfirmasi kata sandi baru wajib diisi';
                    }
                    if (v != _newPasswordCtrl.text) {
                      return 'Konfirmasi kata sandi tidak cocok';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Indikator Syarat Kata Sandi
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Syarat Kata Sandi:',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildChecklistItem(
                        isValid: _isMinLengthMet,
                        label: 'Minimal 8 karakter',
                      ),
                      _buildChecklistItem(
                        isValid: _isAlphaNumericMet,
                        label: 'Kombinasi huruf dan angka',
                      ),
                      _buildChecklistItem(
                        isValid: _isConfirmMatched,
                        label: 'Konfirmasi cocok',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Tombol Simpan
                CustomButton(
                  text: 'Simpan Kata Sandi Baru',
                  isLoading: _isLoading,
                  onPressed: _submit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
