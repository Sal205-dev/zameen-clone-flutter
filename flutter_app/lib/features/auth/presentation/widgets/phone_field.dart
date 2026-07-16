import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class CountryCode {
  final String dial; // e.g. '+92'
  final String name; // e.g. 'Pakistan'
  final String flag; // emoji flag

  const CountryCode(this.dial, this.name, this.flag);

  String get display => '$flag  $dial';
}

const _allCodes = [
  CountryCode('+92', 'Pakistan', '🇵🇰'),
  CountryCode('+971', 'UAE', '🇦🇪'),
  CountryCode('+966', 'Saudi Arabia', '🇸🇦'),
  CountryCode('+974', 'Qatar', '🇶🇦'),
  CountryCode('+973', 'Bahrain', '🇧🇭'),
  CountryCode('+968', 'Oman', '🇴🇲'),
  CountryCode('+965', 'Kuwait', '🇰🇼'),
  CountryCode('+1', 'USA / Canada', '🇺🇸'),
  CountryCode('+44', 'United Kingdom', '🇬🇧'),
  CountryCode('+61', 'Australia', '🇦🇺'),
  CountryCode('+49', 'Germany', '🇩🇪'),
  CountryCode('+33', 'France', '🇫🇷'),
  CountryCode('+39', 'Italy', '🇮🇹'),
  CountryCode('+34', 'Spain', '🇪🇸'),
  CountryCode('+91', 'India', '🇮🇳'),
  CountryCode('+880', 'Bangladesh', '🇧🇩'),
  CountryCode('+94', 'Sri Lanka', '🇱🇰'),
  CountryCode('+977', 'Nepal', '🇳🇵'),
  CountryCode('+90', 'Turkey', '🇹🇷'),
  CountryCode('+20', 'Egypt', '🇪🇬'),
  CountryCode('+27', 'South Africa', '🇿🇦'),
  CountryCode('+86', 'China', '🇨🇳'),
  CountryCode('+81', 'Japan', '🇯🇵'),
  CountryCode('+82', 'South Korea', '🇰🇷'),
  CountryCode('+55', 'Brazil', '🇧🇷'),
  CountryCode('+98', 'Iran', '🇮🇷'),
];

/// A phone number field with a tappable country-code prefix.
/// The selected [CountryCode] and the raw number are exposed via callbacks
/// so the parent form can assemble the full phone string on submit.
class PhoneField extends StatefulWidget {
  final TextEditingController numberController;
  final ValueChanged<CountryCode> onCountryChanged;
  final CountryCode initialCountry;
  final String? Function(String?)? validator;
  final VoidCallback? onChanged;
  final String? errorText;

  const PhoneField({
    super.key,
    required this.numberController,
    required this.onCountryChanged,
    required this.initialCountry,
    this.validator,
    this.onChanged,
    this.errorText,
  });

  @override
  State<PhoneField> createState() => _PhoneFieldState();
}

class _PhoneFieldState extends State<PhoneField> {
  late CountryCode _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.initialCountry;
  }

  Future<void> _pickCountry() async {
    final chosen = await showModalBottomSheet<CountryCode>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CountryPickerSheet(current: _selected),
    );
    if (chosen != null && chosen.dial != _selected.dial) {
      setState(() => _selected = chosen);
      widget.onCountryChanged(chosen);
    }
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.numberController,
      keyboardType: TextInputType.phone,
      textInputAction: TextInputAction.next,
      onChanged: (_) => widget.onChanged?.call(),
      decoration: InputDecoration(
        labelText: 'field_phone'.tr(),
        // The country code prefix lives in prefixIcon so it's part of
        // the standard InputDecoration layout, aligned correctly with the
        // label and the text field border.
        prefixIcon: GestureDetector(
          onTap: _pickCountry,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _selected.flag,
                  style: const TextStyle(fontSize: 18),
                ),
                const SizedBox(width: 6),
                Text(
                  _selected.dial,
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.arrow_drop_down_rounded,
                    size: 18, color: AppColors.textSecondary),
                Container(
                  width: 1,
                  height: 20,
                  margin: const EdgeInsets.only(left: 8),
                  color: AppColors.divider,
                ),
              ],
            ),
          ),
        ),
        prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
        errorText: widget.errorText,
      ),
      validator: widget.validator,
    );
  }
}

// ── Country picker bottom sheet ───────────────────────────────────────
class _CountryPickerSheet extends StatefulWidget {
  final CountryCode current;
  const _CountryPickerSheet({required this.current});

  @override
  State<_CountryPickerSheet> createState() => _CountryPickerSheetState();
}

class _CountryPickerSheetState extends State<_CountryPickerSheet> {
  String _query = '';

  List<CountryCode> get _filtered => _query.isEmpty
      ? _allCodes
      : _allCodes
          .where((c) =>
              c.name.toLowerCase().contains(_query.toLowerCase()) ||
              c.dial.contains(_query))
          .toList();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      constraints:
          BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.75),
      child: Column(
        children: [
          // Handle
          Container(
            width: 36,
            height: 4,
            margin: const EdgeInsets.only(top: 12, bottom: 12),
            decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2)),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('phone_select_country'.tr(),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            ),
          ),
          // Search
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: TextField(
              autofocus: false,
              decoration: InputDecoration(
                hintText: 'phone_search_hint'.tr(),
                prefixIcon: Icon(Icons.search_rounded, size: 20),
                contentPadding: EdgeInsets.symmetric(vertical: 10),
                isDense: true,
                fillColor: AppColors.background,
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          // List
          Flexible(
            child: ListView.builder(
              padding: const EdgeInsets.only(bottom: 24),
              itemCount: _filtered.length,
              itemBuilder: (context, index) {
                final code = _filtered[index];
                final isSelected = code.dial == widget.current.dial;
                return ListTile(
                  leading:
                      Text(code.flag, style: const TextStyle(fontSize: 22)),
                  title: Text(code.name,
                      style: TextStyle(
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.w400,
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.textPrimary)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(code.dial,
                          style: TextStyle(
                              fontWeight: FontWeight.w500,
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.textSecondary)),
                      if (isSelected) ...[
                        const SizedBox(width: 6),
                        const Icon(Icons.check_circle_rounded,
                            color: AppColors.primary, size: 18),
                      ],
                    ],
                  ),
                  tileColor: isSelected ? AppColors.primarySurface : null,
                  onTap: () => Navigator.of(context).pop(code),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
