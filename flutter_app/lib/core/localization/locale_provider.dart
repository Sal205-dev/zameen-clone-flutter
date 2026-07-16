import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const _localeStorageKey = 'app_locale';

/// Holds the app's current locale (English or Urdu) and persists the
/// user's choice so it survives app restarts.
class LocaleNotifier extends StateNotifier<Locale> {
  LocaleNotifier() : super(const Locale('en')) {
    _restore();
  }

  final _storage = const FlutterSecureStorage();

  Future<void> _restore() async {
    final saved = await _storage.read(key: _localeStorageKey);
    if (saved == 'ur') state = const Locale('ur');
  }

  Future<void> toggle() async {
    state = state.languageCode == 'en' ? const Locale('ur') : const Locale('en');
    await _storage.write(key: _localeStorageKey, value: state.languageCode);
  }
}

final localeProvider = StateNotifierProvider<LocaleNotifier, Locale>(
  (ref) => LocaleNotifier(),
);
