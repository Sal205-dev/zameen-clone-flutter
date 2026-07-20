import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../providers/auth_provider.dart';
import '../widgets/password_strength_indicator.dart';

/// Two-stage flow in one screen:
///  1. Enter email -> request a 6-digit code (emailed via the backend).
///  2. Enter that code + a new password -> reset.
class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  final _newPasswordController = TextEditingController();

  bool _codeStage = false;
  bool _obscurePassword = true;
  bool _submitting = false;
  String? _errorMessage;
  String _passwordValue = '';

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    _newPasswordController.dispose();
    super.dispose();
  }

  Future<void> _requestCode() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _submitting = true; _errorMessage = null; });
    try {
      final repo = ref.read(authRepositoryProvider);
      await repo.requestPasswordReset(_emailController.text.trim());
      if (mounted) setState(() => _codeStage = true);
    } catch (e) {
      if (mounted) setState(() => _errorMessage = '$e');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _confirmReset() async {
    if (!_formKey.currentState!.validate()) return;
    final strength = PasswordStrength.of(_newPasswordController.text);
    if (!strength.isAcceptable) {
      setState(() => _errorMessage = 'error_password_weak'.tr());
      return;
    }
    setState(() { _submitting = true; _errorMessage = null; });
    try {
      final repo = ref.read(authRepositoryProvider);
      await repo.confirmPasswordReset(
        email: _emailController.text.trim(),
        code: _codeController.text.trim(),
        newPassword: _newPasswordController.text,
      );
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('password_reset_success'.tr()),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ));
      }
    } catch (e) {
      if (mounted) setState(() => _errorMessage = '$e');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text('forgot_password_title'.tr())),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _codeStage
                      ? 'forgot_password_code_hint'.tr()
                      : 'forgot_password_email_hint'.tr(),
                  style: const TextStyle(
                      fontSize: 13, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 20),

                TextFormField(
                  controller: _emailController,
                  enabled: !_codeStage,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'field_email'.tr(),
                    prefixIcon: const Icon(Icons.email_outlined, size: 20),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'error_email_required'.tr()
                      : null,
                ),

                if (_codeStage) ...[
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _codeController,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    decoration: InputDecoration(
                      labelText: 'field_reset_code'.tr(),
                      prefixIcon: const Icon(Icons.pin_outlined, size: 20),
                      counterText: '',
                    ),
                    validator: (v) => (v == null || v.trim().length != 6)
                        ? 'error_code_required'.tr()
                        : null,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _newPasswordController,
                    obscureText: _obscurePassword,
                    onChanged: (v) => setState(() => _passwordValue = v),
                    decoration: InputDecoration(
                      labelText: 'field_new_password'.tr(),
                      prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
                      suffixIcon: IconButton(
                        icon: Icon(_obscurePassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined, size: 20),
                        onPressed: () => setState(
                            () => _obscurePassword = !_obscurePassword),
                      ),
                    ),
                    validator: (v) => (v == null || v.isEmpty)
                        ? 'error_password_required'.tr()
                        : null,
                  ),
                  if (_passwordValue.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    PasswordStrengthIndicator(password: _passwordValue),
                  ],
                  const SizedBox(height: 4),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton(
                      onPressed: _submitting ? null : _requestCode,
                      child: Text('resend_code'.tr()),
                    ),
                  ),
                ],

                if (_errorMessage != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.07),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: AppColors.error.withValues(alpha: 0.35)),
                    ),
                    child: Text(_errorMessage!,
                        style: const TextStyle(
                            color: AppColors.error,
                            fontSize: 13,
                            fontWeight: FontWeight.w500)),
                  ),
                ],

                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _submitting
                        ? null
                        : (_codeStage ? _confirmReset : _requestCode),
                    child: _submitting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : Text(_codeStage
                            ? 'btn_reset_password'.tr()
                            : 'btn_send_code'.tr()),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
