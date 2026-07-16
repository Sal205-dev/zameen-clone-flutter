import 'package:flutter/widgets.dart';

/// Hand-rolled translation table for the app's core navigation chrome
/// (bottom nav, drawer, language toggle). Screen content isn't
/// translated yet — this is phase one of localization, extended
/// screen-by-screen later.
class AppStrings {
  final Locale locale;
  const AppStrings(this.locale);

  static AppStrings of(BuildContext context) =>
      AppStrings(Localizations.localeOf(context));

  bool get _ur => locale.languageCode == 'ur';

  // Bottom nav
  String get navHome => _ur ? 'ہوم' : 'Home';
  String get navProjects => _ur ? 'منصوبے' : 'Projects';
  String get navSearch => _ur ? 'تلاش' : 'Search';
  String get navFavorites => _ur ? 'پسندیدہ' : 'Favorites';
  String get navProfile => _ur ? 'پروفائل' : 'Profile';
  String get comingSoon => _ur ? 'جلد آ رہا ہے' : 'Coming soon';

  // Drawer
  String get tagline => _ur ? 'بہتر زندگی گزاریں' : 'Live better';
  String get loginOrCreateAccount =>
      _ur ? 'لاگ اِن یا اکاؤنٹ بنائیں' : 'Login or Create Account';
  String get addProperty => _ur ? 'پراپرٹی شامل کریں' : 'Add Property';
  String get searchProperties =>
      _ur ? 'پراپرٹی تلاش کریں' : 'Search Properties';
  String get newProjects => _ur ? 'نئے منصوبے' : 'New Projects';
  String get savedSearches => _ur ? 'محفوظ شدہ تلاش' : 'Saved Searches';
  String get dhaTools => _ur ? 'ڈی ایچ اے ٹولز' : 'DHA Tools';
  String get newBadge => _ur ? 'نیا' : 'New';
  String get dhaNews => _ur ? 'ڈی ایچ اے خبریں' : 'DHA News';
  String get dhaBlog => _ur ? 'ڈی ایچ اے بلاگ' : 'DHA Blog';
  String get appControls => _ur ? 'ایپ کی ترتیبات' : 'APP CONTROLS';
  // Shows the *other* language — tapping it switches TO that language.
  String get switchLanguageLabel => _ur ? 'English' : 'اردو';
  String get aboutUs => _ur ? 'ہمارے بارے میں' : 'About Us';
  String get logout => _ur ? 'لاگ آؤٹ' : 'Log out';
}
