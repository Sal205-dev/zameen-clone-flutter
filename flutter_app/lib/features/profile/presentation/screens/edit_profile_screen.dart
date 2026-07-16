import 'dart:async';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/providers.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/data/auth_repository.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _usernameController;

  String? _currentUsername; // original value — skip check if unchanged
  String? _usernameStatus;  // null | 'checking' | 'available' | 'taken' | 'invalid_chars'
  String  _usernameMessage = '';
  Timer?  _usernameTimer;
  bool    _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _currentUsername =
        ref.read(authNotifierProvider).value?.username ?? '';
    _usernameController = TextEditingController(text: _currentUsername);
  }

  @override
  void dispose() {
    _usernameTimer?.cancel();
    _usernameController.dispose();
    super.dispose();
  }

  // ── Username availability check — same logic as signup screen ──────
  void _onUsernameChanged(String value) {
    setState(() => _errorMessage = null);
    _usernameTimer?.cancel();

    final trimmed = value.trim();

    // If the user typed back their original username, skip the check
    if (trimmed == _currentUsername) {
      setState(() { _usernameStatus = 'same'; _usernameMessage = ''; });
      return;
    }

    if (trimmed.isEmpty) {
      setState(() { _usernameStatus = null; _usernameMessage = ''; });
      return;
    }

    setState(() {
      _usernameStatus  = 'checking';
      _usernameMessage = 'auth_checking_availability'.tr();
    });

    _usernameTimer =
        Timer(const Duration(milliseconds: 600), () => _checkUsername(trimmed));
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

  // ── Save ────────────────────────────────────────────────────────────
  Future<void> _save() async {
    setState(() => _errorMessage = null);
    if (!_formKey.currentState!.validate()) return;

    if (_usernameStatus == 'taken' || _usernameStatus == 'invalid_chars') {
      setState(() => _errorMessage = _usernameMessage);
      return;
    }

    setState(() => _isSaving = true);
    try {
      final newUsername = _usernameController.text.trim();
      // Only send the field if it actually changed
      await ref.read(authNotifierProvider.notifier).updateProfile(
            username: newUsername == _currentUsername ? null : newUsername,
          );
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('profile_updated_success'.tr()),
            backgroundColor: AppColors.primary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      String message = e.toString();
      if (message.startsWith('Exception: ')) {
        message = message.replaceFirst('Exception: ', '');
      }
      setState(() => _errorMessage = message);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasChanges =
        _usernameController.text.trim() != _currentUsername;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('settings_edit_profile'.tr()),
        actions: [
          // Save button in the app bar — only enabled when there's
          // an actual change and no pending availability check
          TextButton(
            onPressed: (_isSaving ||
                    !hasChanges ||
                    _usernameStatus == 'taken' ||
                    _usernameStatus == 'invalid_chars' ||
                    _usernameStatus == 'checking')
                ? null
                : _save,
            child: _isSaving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: AppColors.primary))
                : Text(
                    'btn_save'.tr(),
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: hasChanges &&
                              _usernameStatus != 'taken' &&
                              _usernameStatus != 'invalid_chars' &&
                              _usernameStatus != 'checking'
                          ? AppColors.primary
                          : AppColors.textHint,
                    ),
                  ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar
              Center(
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: AppColors.primarySurface,
                      child: Text(
                        (_currentUsername?.isNotEmpty == true
                                ? _currentUsername![0]
                                : '?')
                            .toUpperCase(),
                        style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _currentUsername ?? '',
                      style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              Text('field_username'.tr(),
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary)),
              const SizedBox(height: 8),

              // Username field
              TextFormField(
                controller: _usernameController,
                onChanged: (v) {
                  _onUsernameChanged(v);
                  setState(() {}); // rebuild to update Save button state
                },
                decoration: InputDecoration(
                  hintText: 'hint_your_username'.tr(),
                  prefixIcon: const Icon(
                      Icons.person_outline_rounded, size: 20),
                  suffixIcon: _buildStatusIcon(),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'error_username_empty'.tr();
                  }
                  if (v.trim().length < 3) return 'error_username_min_length'.tr();
                  if (_usernameStatus == 'taken') return _usernameMessage;
                  if (_usernameStatus == 'invalid_chars') {
                    return _usernameMessage;
                  }
                  return null;
                },
              ),

              // Status hint below field
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
              if (_usernameStatus == 'checking')
                Padding(
                  padding: const EdgeInsets.only(top: 6, left: 12),
                  child: Text(_usernameMessage,
                      style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary)),
                ),
              const SizedBox(height: 8),
              Text(
                'username_rules_hint'.tr(),
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textSecondary),
              ),

              // Error box
              if (_errorMessage != null) ...[
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.07),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: AppColors.error.withValues(alpha: 0.35)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.error_outline_rounded,
                          color: AppColors.error, size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(
                              color: AppColors.error,
                              fontSize: 13,
                              fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 32),

              // Save button at bottom too
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: (_isSaving ||
                          !hasChanges ||
                          _usernameStatus == 'taken' ||
                          _usernameStatus == 'invalid_chars' ||
                          _usernameStatus == 'checking')
                      ? null
                      : _save,
                  child: _isSaving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : Text('btn_save_changes'.tr()),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget? _buildStatusIcon() {
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
