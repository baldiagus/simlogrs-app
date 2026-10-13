import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/custom_button.dart';
import '../../../../shared/widgets/app_toast.dart';
import '../providers/auth_provider.dart';

class GantiPasswordWajibScreen extends ConsumerStatefulWidget {
  const GantiPasswordWajibScreen({super.key});

  /// Membuat state layar ganti password wajib yang menyimpan form dan status tampil/sembunyi password.
  @override
  ConsumerState<GantiPasswordWajibScreen> createState() => _GantiPasswordWajibScreenState();
}

class _GantiPasswordWajibScreenState extends ConsumerState<GantiPasswordWajibScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;

  /// Membersihkan controller input password agar tidak bocor memori setelah layar ditutup.
  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  /// Validasi form lalu kirim password baru ke server; tampilkan toast sukses atau error.
  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isLoading = true);
    try {
      await ref.read(authStateProvider.notifier).gantiPasswordWajib(
            passwordSaatIni: _currentPasswordController.text,
            passwordBaru: _newPasswordController.text,
            passwordBaruConfirmation: _confirmPasswordController.text,
          );
      if (mounted) {
        AppToast.success(context, 'Kata sandi berhasil diperbarui.');
      }
    } catch (e) {
      if (mounted) {
        AppToast.error(
          context,
          e.toString().replaceAll('ApiException: ', '').replaceAll('Exception: ', ''),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Membangun form ganti password yang tidak bisa ditutup sampai password berhasil diperbarui.
  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: AppColors.canvas,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          automaticallyImplyLeading: false,
          title: const Text(
            'Ganti Kata Sandi Wajib',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(LucideIcons.logOut, size: 20, color: AppColors.danger),
              tooltip: 'Keluar Akun',
              onPressed: () => ref.read(authStateProvider.notifier).logout(),
            ),
          ],
        ),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFFBEB),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
                      ),
                      child: const Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(LucideIcons.shieldAlert, size: 20, color: AppColors.warning),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Kata sandi Anda telah direset atau mewajibkan pembaruan demi keamanan. Silakan tentukan kata sandi baru untuk melanjutkan.',
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
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _currentPasswordController,
                      obscureText: _obscureCurrent,
                      decoration: InputDecoration(
                        labelText: 'Kata Sandi Saat Ini / Sementara',
                        prefixIcon: const Icon(LucideIcons.lockKeyhole, size: 20),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureCurrent ? LucideIcons.eyeOff : LucideIcons.eye,
                            size: 18,
                          ),
                          tooltip: _obscureCurrent ? 'Tampilkan kata sandi' : 'Sembunyikan kata sandi',
                          onPressed: () => setState(() => _obscureCurrent = !_obscureCurrent),
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Kata sandi saat ini wajib diisi';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _newPasswordController,
                      obscureText: _obscureNew,
                      decoration: InputDecoration(
                        labelText: 'Kata Sandi Baru',
                        helperText: 'Minimal 8 karakter, huruf & angka',
                        prefixIcon: const Icon(LucideIcons.key, size: 20),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureNew ? LucideIcons.eyeOff : LucideIcons.eye,
                            size: 18,
                          ),
                          tooltip: _obscureNew ? 'Tampilkan kata sandi' : 'Sembunyikan kata sandi',
                          onPressed: () => setState(() => _obscureNew = !_obscureNew),
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.length < 8) return 'Kata sandi minimal 8 karakter';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _confirmPasswordController,
                      obscureText: _obscureConfirm,
                      decoration: InputDecoration(
                        labelText: 'Ulangi Kata Sandi Baru',
                        prefixIcon: const Icon(LucideIcons.checkCheck, size: 20),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirm ? LucideIcons.eyeOff : LucideIcons.eye,
                            size: 18,
                          ),
                          tooltip: _obscureConfirm ? 'Tampilkan kata sandi' : 'Sembunyikan kata sandi',
                          onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                        ),
                      ),
                      validator: (v) {
                        if (v != _newPasswordController.text) {
                          return 'Konfirmasi kata sandi tidak cocok';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 28),
                    CustomButton(
                      text: 'Perbarui Kata Sandi',
                      isLoading: _isLoading,
                      onPressed: _submit,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
