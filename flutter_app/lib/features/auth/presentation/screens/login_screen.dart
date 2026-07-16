import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../providers/auth_provider.dart';
import 'signup_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  String? _errorMessage;
  bool _loginFailed = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _clearError() {
    if (_errorMessage != null) {
      setState(() {
        _errorMessage = null;
        _loginFailed = false;
      });
    }
  }

  Future<void> _submit() async {
    setState(() {
      _errorMessage = null;
      _loginFailed = false;
    });
    if (!_formKey.currentState!.validate()) return;
    await ref.read(authNotifierProvider.notifier).login(
          username: _usernameController.text.trim(),
          password: _passwordController.text,
        );
  }

  void _goToSignup() {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const SignupScreen()));
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<dynamic>>(authNotifierProvider, (previous, next) {
      if (!mounted) return;

      // ── Only show an error if it came directly after a loading state ──
      //
      // Without this guard, the listener can fire with a stale error from
      // a previous failed attempt when the auth state transitions (e.g.
      // error → loading → data). The brief window where the old error is
      // still in the state causes a flash of the error box even though the
      // login actually succeeded.
      //
      // By requiring `previous?.isLoading == true`, we guarantee the error
      // we're showing is the result of the login attempt that just completed
      // — not a leftover from an earlier failure.
      final cameFromLoading = previous?.isLoading ?? false;

      if (next.hasError && cameFromLoading) {
        String message = next.error?.toString() ?? 'error_login_failed'.tr();
        if (message.startsWith('Exception: ')) {
          message = message.replaceFirst('Exception: ', '');
        }
        setState(() {
          _errorMessage = message;
          _loginFailed = true;
        });
      }
    });

    final isLoading = ref.watch(authNotifierProvider).isLoading;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // ── Gradient header ────────────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(28, 48, 28, 36),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF1580A8),
                      Color(0xFF20A7DB),
                      Color(0xFF4BBEE6),
                    ],
                  ),
                  borderRadius:
                      BorderRadius.vertical(bottom: Radius.circular(32)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.location_city_rounded,
                        color: Colors.white, size: 36),
                    const SizedBox(height: 20),
                    Text('auth_welcome_back'.tr(),
                        style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: -0.5)),
                    const SizedBox(height: 6),
                    Text('auth_signin_subtitle'.tr(),
                        style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withValues(alpha: 0.75))),
                  ],
                ),
              ),

              // ── Form ───────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),

                      // Username
                      TextFormField(
                        controller: _usernameController,
                        textInputAction: TextInputAction.next,
                        onChanged: (_) => _clearError(),
                        decoration: InputDecoration(
                          labelText: 'field_username'.tr(),
                          prefixIcon: const Icon(Icons.person_outline_rounded,
                              size: 20),
                        ),
                        validator: (v) =>
                            (v == null || v.trim().isEmpty)
                                ? 'error_username_required'.tr()
                                : null,
                      ),
                      const SizedBox(height: 16),

                      // Password
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        textInputAction: TextInputAction.done,
                        onChanged: (_) => _clearError(),
                        onFieldSubmitted: (_) =>
                            isLoading ? null : _submit(),
                        decoration: InputDecoration(
                          labelText: 'field_password'.tr(),
                          prefixIcon: const Icon(Icons.lock_outline_rounded,
                              size: 20),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              size: 20,
                            ),
                            onPressed: () => setState(() =>
                                _obscurePassword = !_obscurePassword),
                          ),
                        ),
                        validator: (v) =>
                            (v == null || v.isEmpty)
                                ? 'error_password_required'.tr()
                                : null,
                      ),
                      const SizedBox(height: 20),

                      // ── Inline error box ─────────────────────────
                      if (_errorMessage != null)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color:
                                AppColors.error.withValues(alpha: 0.07),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: AppColors.error
                                    .withValues(alpha: 0.35)),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Padding(
                                padding: EdgeInsets.only(top: 1),
                                child: Icon(Icons.error_outline_rounded,
                                    color: AppColors.error, size: 18),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  _errorMessage!,
                                  style: const TextStyle(
                                      color: AppColors.error,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      height: 1.4),
                                ),
                              ),
                            ],
                          ),
                        ),

                      // ── Login button ─────────────────────────────
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: isLoading ? null : _submit,
                          child: isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white))
                              : Text('btn_login'.tr()),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // ── Divider ───────────────────────────────────
                      Row(
                        children: [
                          const Expanded(child: Divider()),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12),
                            child: Text('common_or'.tr(),
                                style: TextStyle(
                                    color: Colors.grey.shade500,
                                    fontSize: 13)),
                          ),
                          const Expanded(child: Divider()),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // ── Create account ────────────────────────────
                      if (_loginFailed)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.primarySurface,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                                color: AppColors.primary
                                    .withValues(alpha: 0.3)),
                          ),
                          child: Column(
                            children: [
                              const Icon(Icons.person_add_alt_1_rounded,
                                  color: AppColors.primary, size: 28),
                              const SizedBox(height: 8),
                              Text('auth_no_account_title'.tr(),
                                  style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600)),
                              const SizedBox(height: 4),
                              Text(
                                'auth_no_account_subtitle'.tr(),
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary),
                              ),
                              const SizedBox(height: 14),
                              SizedBox(
                                width: double.infinity,
                                height: 46,
                                child: ElevatedButton(
                                  onPressed: _goToSignup,
                                  child: Text('btn_create_account'.tr()),
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: OutlinedButton(
                            onPressed: _goToSignup,
                            child: Text('btn_create_account'.tr()),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
