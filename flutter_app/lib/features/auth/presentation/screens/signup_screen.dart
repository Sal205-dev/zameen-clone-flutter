import 'dart:async';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/providers.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/auth_repository.dart';
import '../providers/auth_provider.dart';
import '../widgets/password_strength_indicator.dart';
import '../widgets/phone_field.dart';

/// Basic email shape check (something@something.tld) — a prerequisite,
/// not sufficient on its own since we also restrict to common providers
/// below.
final _emailRegex = RegExp(
  r'^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$',
);

/// Only these providers are accepted at signup — the 10 most common
/// global email services. Anything else (including work/company domains)
/// is rejected.
const _allowedEmailDomains = {
  'gmail.com',
  'yahoo.com',
  'outlook.com',
  'hotmail.com',
  'icloud.com',
  'aol.com',
  'protonmail.com',
  'live.com',
  'msn.com',
  'zoho.com',
};

bool _isAllowedEmail(String email) {
  final trimmed = email.trim().toLowerCase();
  if (!_emailRegex.hasMatch(trimmed)) return false;
  final domain = trimmed.split('@').last;
  return _allowedEmailDomains.contains(domain);
}

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController    = TextEditingController();
  final _phoneController    = TextEditingController();
  final _passwordController = TextEditingController();

  String _role = 'buyer';
  bool _obscurePassword = true;
  String? _errorMessage;
  String _passwordValue = '';

  // Username async availability state
  // null=not checked, 'checking', 'available', 'taken', 'invalid'
  String? _usernameStatus;
  String  _usernameMessage = '';
  Timer?  _usernameTimer;

  // Selected country code — default Pakistan
  CountryCode _country = const CountryCode('+92', 'Pakistan', '🇵🇰');

  @override
  void dispose() {
    _usernameTimer?.cancel();
    _usernameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _clearError() {
    if (_errorMessage != null) setState(() => _errorMessage = null);
  }

  // ── Username async check ──────────────────────────────────────────
  void _onUsernameChanged(String value) {
    _clearError();
    _usernameTimer?.cancel();

    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      setState(() { _usernameStatus = null; _usernameMessage = ''; });
      return;
    }

    // Show "checking" spinner after a short pause while the user types
    setState(() {
      _usernameStatus = 'checking';
      _usernameMessage = 'auth_checking_availability'.tr();
    });

    // Debounce: wait 600ms after the user stops typing before hitting the API
    _usernameTimer = Timer(const Duration(milliseconds: 600), () {
      _checkUsername(trimmed);
    });
  }

  Future<void> _checkUsername(String username) async {
    try {
      final repo = AuthRepository(
          ref.read(dioProvider), ref.read(tokenStorageProvider));
      final result = await repo.checkUsername(username);
      if (!mounted) return;
      setState(() {
        _usernameStatus  = result['status'] as String;
        _usernameMessage = result['message'] as String;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() { _usernameStatus = null; _usernameMessage = ''; });
    }
  }

  // ── Submit ────────────────────────────────────────────────────────
  Future<void> _submit() async {
    setState(() => _errorMessage = null);
    if (!_formKey.currentState!.validate()) return;

    // Block submit if username check shows it's taken
    if (_usernameStatus == 'taken' || _usernameStatus == 'invalid_chars') {
      setState(() => _errorMessage = _usernameMessage);
      return;
    }

    // Block submit if password isn't strong enough
    final strength = PasswordStrength.of(_passwordController.text);
    if (!strength.isAcceptable) {
      setState(() => _errorMessage = 'error_password_weak'.tr());
      return;
    }

    final fullPhone = '${_country.dial} ${_phoneController.text.trim()}';

    await ref.read(authNotifierProvider.notifier).signup(
          username: _usernameController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text,
          phone: fullPhone,
          role: _role,
        );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<dynamic>>(authNotifierProvider, (previous, next) {
      if (!mounted) return;
      final cameFromLoading = previous?.isLoading ?? false;
      if (next.hasError && cameFromLoading) {
        String message = next.error?.toString() ?? 'error_signup_failed'.tr();
        if (message.startsWith('Exception: ')) {
          message = message.replaceFirst('Exception: ', '');
        }
        setState(() => _errorMessage = message);
      }
    });

    final isLoading = ref.watch(authNotifierProvider).isLoading;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // ── Gradient header ──────────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(28, 40, 28, 28),
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
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.arrow_back_rounded,
                            color: Colors.white, size: 20),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text('auth_create_account_title'.tr(),
                        style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: -0.5)),
                    const SizedBox(height: 4),
                    Text('auth_join_subtitle'.tr(),
                        style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withValues(alpha: 0.72))),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  // Re-runs each field's validator on every change (not just
                  // on submit) once the user has interacted with it, so a
                  // field error clears itself the moment it becomes valid
                  // instead of staying stuck until the next submit press.
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),

                      // ── Role selector ────────────────────────────
                      Text('auth_role_prompt'.tr(),
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textSecondary)),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.divider),
                        ),
                        padding: const EdgeInsets.all(4),
                        child: Row(
                          children: [
                            _RoleTab(
                                label: 'role_buyer_renter'.tr(),
                                icon: Icons.search_rounded,
                                selected: _role == 'buyer',
                                onTap: () => setState(() => _role = 'buyer')),
                            _RoleTab(
                                label: 'role_agent_owner'.tr(),
                                icon: Icons.home_work_outlined,
                                selected: _role == 'agent',
                                onTap: () => setState(() => _role = 'agent')),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // ── Username ─────────────────────────────────
                      TextFormField(
                        controller: _usernameController,
                        textInputAction: TextInputAction.next,
                        onChanged: _onUsernameChanged,
                        decoration: InputDecoration(
                          labelText: 'field_username'.tr(),
                          hintText: 'hint_username_chars'.tr(),
                          prefixIcon: const Icon(
                              Icons.person_outline_rounded, size: 20),
                          suffixIcon: _buildUsernameStatus(),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'error_username_required'.tr();
                          }
                          if (v.trim().length < 3) {
                            return 'error_username_min_length'.tr();
                          }
                          if (_usernameStatus == 'taken') {
                            return _usernameMessage;
                          }
                          if (_usernameStatus == 'invalid_chars') {
                            return _usernameMessage;
                          }
                          return null;
                        },
                      ),
                      // Availability hint below the field
                      if (_usernameStatus == 'available')
                        Padding(
                          padding: const EdgeInsets.only(top: 6, left: 12),
                          child: Row(
                            children: [
                              const Icon(Icons.check_circle_rounded,
                                  size: 14, color: AppColors.success),
                              const SizedBox(width: 6),
                              Text(_usernameMessage,
                                  style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.success,
                                      fontWeight: FontWeight.w500)),
                            ],
                          ),
                        ),
                      const SizedBox(height: 14),

                      // ── Email ────────────────────────────────────
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        onChanged: (_) => _clearError(),
                        decoration: InputDecoration(
                          labelText: 'field_email'.tr(),
                          hintText: 'hint_email_example'.tr(),
                          prefixIcon: const Icon(Icons.email_outlined, size: 20),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'error_email_required'.tr();
                          }
                          if (!_isAllowedEmail(v)) {
                            return 'error_email_invalid'.tr();
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),

                      // ── Phone with country code ──────────────────
                      PhoneField(
                        numberController: _phoneController,
                        initialCountry: _country,
                        onCountryChanged: (c) =>
                            setState(() => _country = c),
                        onChanged: _clearError,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'error_phone_required'.tr();
                          }
                          if (v.trim().length < 7) {
                            return 'error_phone_invalid'.tr();
                          }
                          // ITU-T E.164 caps a full international number
                          // (country code + subscriber number) at 15 digits.
                          final subscriberDigits =
                              v.replaceAll(RegExp(r'\D'), '');
                          final countryDigits =
                              _country.dial.replaceAll(RegExp(r'\D'), '');
                          if (countryDigits.length + subscriberDigits.length >
                              15) {
                            return 'error_phone_too_long'.tr();
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),

                      // ── Password ─────────────────────────────────
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        textInputAction: TextInputAction.done,
                        onChanged: (v) {
                          _clearError();
                          setState(() => _passwordValue = v);
                        },
                        onFieldSubmitted: (_) =>
                            isLoading ? null : _submit(),
                        decoration: InputDecoration(
                          labelText: 'field_password'.tr(),
                          prefixIcon: const Icon(
                              Icons.lock_outline_rounded, size: 20),
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
                        validator: (v) {
                          if (v == null || v.isEmpty) {
                            return 'error_password_required'.tr();
                          }
                          final s = PasswordStrength.of(v);
                          if (!s.isAcceptable) {
                            return 'error_password_requirements'.tr();
                          }
                          return null;
                        },
                      ),

                      // Strength indicator — appears as soon as user types
                      if (_passwordValue.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        PasswordStrengthIndicator(password: _passwordValue),
                      ],

                      const SizedBox(height: 20),

                      // ── Inline error box ─────────────────────────
                      if (_errorMessage != null)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: AppColors.error.withValues(alpha: 0.07),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color:
                                    AppColors.error.withValues(alpha: 0.35)),
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

                      // ── Submit button ────────────────────────────
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
                              : Text('auth_create_account_title'.tr()),
                        ),
                      ),
                      const SizedBox(height: 24),
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

  /// Icon shown in the trailing position of the username field:
  /// spinner while checking, green tick if available, red X if taken.
  Widget? _buildUsernameStatus() {
    switch (_usernameStatus) {
      case 'checking':
        return const Padding(
          padding: EdgeInsets.all(12),
          child: SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
                strokeWidth: 2, color: AppColors.primary),
          ),
        );
      case 'available':
        return const Icon(Icons.check_circle_rounded,
            color: AppColors.success, size: 20);
      case 'taken':
      case 'invalid_chars':
        return const Icon(Icons.cancel_rounded,
            color: AppColors.error, size: 20);
      default:
        return null;
    }
  }
}

// ── Role tab ──────────────────────────────────────────────────────────
class _RoleTab extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _RoleTab({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? AppColors.surface : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
            boxShadow: selected
                ? const [BoxShadow(
                    color: AppColors.shadow,
                    blurRadius: 8,
                    offset: Offset(0, 2))]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size: 16,
                  color: selected
                      ? AppColors.primary
                      : AppColors.textSecondary),
              const SizedBox(width: 6),
              Text(label,
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: selected
                          ? FontWeight.w600
                          : FontWeight.w400,
                      color: selected
                          ? AppColors.primary
                          : AppColors.textSecondary)),
            ],
          ),
        ),
      ),
    );
  }
}
