import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/mock/dha_data.dart';
import '../../../../core/mock/mock_data.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/property_filter.dart';
import '../widgets/property_card.dart';

class ListingsScreen extends ConsumerStatefulWidget {
  const ListingsScreen({super.key});

  @override
  ConsumerState<ListingsScreen> createState() => _ListingsScreenState();
}

class _ListingsScreenState extends ConsumerState<ListingsScreen> {
  String? _city;
  String? _phase;
  String? _sector;
  String? _category;
  String? _purpose; // null = no filter, show all listings

  bool get _hasFilter =>
      _purpose != null || _city != null || _phase != null ||
      _sector != null || _category != null;

  void _selectCity(String city) {
    setState(() { _city = city; _phase = null; _sector = null; _category = null; });
    _applyFilter();
  }
  void _selectPhase(String phase) {
    setState(() { _phase = phase; _sector = null; _category = null; });
    _applyFilter();
  }
  void _selectSector(String sector) {
    setState(() { _sector = sector; _category = null; });
    _applyFilter();
  }
  void _selectCategory(String category) {
    setState(() => _category = category);
    _applyFilter();
  }
  void _selectPurpose(String purpose) {
    setState(() => _purpose = _purpose == purpose ? null : purpose);
    _applyFilter();
  }
  void _applyFilter() {
    ref.read(dhaFilterProvider.notifier).update((_) => DhaFilter(
      purpose: _purpose, city: _city, phase: _phase,
      sector: _sector, category: _category,
    ));
  }
  void _resetAll() {
    setState(() { _city = null; _phase = null; _sector = null;
                  _category = null; _purpose = null; });
    ref.read(dhaFilterProvider.notifier).reset();
  }

  Future<void> _showPicker({
    required String title,
    required List<String> items,
    required String? current,
    required ValueChanged<String> onSelect,
  }) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PickerSheet(
        title: title, items: items, current: current,
        onSelect: (v) { Navigator.of(context).pop(); onSelect(v); },
      ),
    );
  }

  Future<void> _showCategoryPicker() async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _CategoryPickerSheet(
        current: _category,
        onSelect: (v) { Navigator.of(context).pop(); _selectCategory(v); },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authNotifierProvider).value;
    final apiAsync = ref.watch(apiPropertiesProvider);
    final displayProperties = apiAsync.value ?? [];
    final isLoadingApi = apiAsync.isLoading;
    final showingFiltered = _hasFilter;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () => ref.read(apiPropertiesProvider.notifier).refresh(),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [

            SliverToBoxAdapter(child: _buildHeader(user?.username ?? 'common_guest'.tr())),

            // ── Filter card ───────────────────────────────────────────
            SliverToBoxAdapter(
              child: Container(
                color: AppColors.surface,
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                child: Column(
                  children: [
                    _BuyRentToggle(selected: _purpose, onChanged: _selectPurpose),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        _FilterChip(
                          label: 'filter_city'.tr(), value: _city,
                          active: _city != null, enabled: true,
                          onTap: () => _showPicker(
                            title: 'filter_select_city'.tr(), items: dhaCities,
                            current: _city, onSelect: _selectCity),
                        ),
                        const SizedBox(width: 8),
                        _FilterChip(
                          label: 'filter_phase'.tr(), value: _phase,
                          active: _phase != null, enabled: _city != null,
                          onTap: _city == null ? null : () => _showPicker(
                            title: 'filter_select_phase'.tr(),
                            items: getPhasesForCity(_city!),
                            current: _phase, onSelect: _selectPhase),
                        ),
                        const SizedBox(width: 8),
                        _FilterChip(
                          label: 'filter_sector'.tr(), value: _sector,
                          active: _sector != null, enabled: _phase != null,
                          onTap: _phase == null ? null : () => _showPicker(
                            title: 'filter_select_sector'.tr(),
                            items: getSectorsForPhase(_city!, _phase!),
                            current: _sector, onSelect: _selectSector),
                        ),
                        const SizedBox(width: 8),
                        _FilterChip(
                          label: 'filter_type'.tr(),
                          value: _category == null ? null : _catLabel(_category!),
                          active: _category != null, enabled: _sector != null,
                          onTap: _sector == null ? null : _showCategoryPicker,
                        ),
                      ],
                    ),
                    if (_hasFilter) ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(Icons.filter_alt_rounded,
                              size: 14, color: AppColors.primary),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              _breadcrumb(),
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w500),
                            ),
                          ),
                          GestureDetector(
                            onTap: _resetAll,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.error.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text('btn_clear'.tr(),
                                  style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.error,
                                      fontWeight: FontWeight.w600)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),

            const SliverToBoxAdapter(child: Divider(height: 0)),

            // ── Section header ─────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                child: Row(
                  children: [
                    if (!showingFiltered) ...[
                      const Text('🔥', style: TextStyle(fontSize: 18)),
                      const SizedBox(width: 8),
                      Text('hottest_listings'.tr(),
                          style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary)),
                    ] else ...[
                      const Icon(Icons.search_rounded,
                          size: 18, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Text(
                        (displayProperties.length == 1
                                ? 'results_found_one'
                                : 'results_found_other')
                            .tr(namedArgs: {
                          'count': '${displayProperties.length}'
                        }),
                        style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary),
                      ),
                    ],
                    const Spacer(),
                    if (isLoadingApi)
                      const SizedBox(
                        width: 14, height: 14,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: AppColors.primary),
                      )
                    else
                      Text(
                        'total_count'.tr(namedArgs: {
                          'count': '${displayProperties.length}'
                        }),
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textSecondary),
                      ),
                  ],
                ),
              ),
            ),

            // ── Property list ──────────────────────────────────────────
            displayProperties.isEmpty && !isLoadingApi
                ? SliverFillRemaining(
                    child: _EmptyResultsState(onReset: _resetAll))
                : SliverPadding(
                    padding: const EdgeInsets.only(bottom: 32, top: 4),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final property = displayProperties[index];
                          final favIds = ref.watch(favoritesProvider);
                          return PropertyCard(
                            property: property,
                            isFavorited: favIds.contains(property.id),
                            onFavoriteToggle: () => ref
                                .read(favoritesProvider.notifier)
                                .toggle(property.id),
                            onTap: () =>
                                context.push('/property/${property.id}'),
                          );
                        },
                        childCount: displayProperties.length,
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(String username) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 50, 20, 20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1580A8), Color(0xFF20A7DB)],
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Scaffold.of(context).openDrawer(),
            child: Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.menu_rounded,
                  color: Colors.white, size: 22),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_greeting(),
                    style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.75))),
                Text(username,
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: -0.3)),
              ],
            ),
          ),
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12)),
            child: Icon(Icons.notifications_outlined,
                color: Colors.white.withValues(alpha: 0.9), size: 22),
          ),
        ],
      ),
    );
  }

  String _breadcrumb() {
    final parts = <String>[];
    if (_purpose != null) {
      parts.add(_purpose == 'sale' ? 'purpose_buy'.tr() : 'purpose_rent'.tr());
    }
    if (_city != null)     parts.add(_city!);
    if (_phase != null)    parts.add(_phase!);
    if (_sector != null)   parts.add(_sector!);
    if (_category != null) parts.add(_catLabel(_category!));
    return parts.join(' › ');
  }

  String _catLabel(String cat) {
    switch (cat) {
      case 'property':   return 'type_house_flat'.tr();
      case 'plot':       return 'type_plot'.tr();
      case 'commercial': return 'type_commercial'.tr();
      default:           return cat;
    }
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'greeting_morning'.tr();
    if (h < 17) return 'greeting_afternoon'.tr();
    return 'greeting_evening'.tr();
  }
}

// ── Buy / Rent toggle ─────────────────────────────────────────────────
class _BuyRentToggle extends StatelessWidget {
  final String? selected;
  final ValueChanged<String> onChanged;
  const _BuyRentToggle({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 42,
      decoration: BoxDecoration(
          color: AppColors.background, borderRadius: BorderRadius.circular(22)),
      padding: const EdgeInsets.all(3),
      child: Row(
        children: [
          _Pill(label: 'purpose_buy'.tr(),  active: selected == 'sale',
              onTap: () => onChanged('sale')),
          _Pill(label: 'purpose_rent'.tr(), active: selected == 'rent',
              onTap: () => onChanged('rent')),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _Pill({required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: active ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(18),
          ),
          alignment: Alignment.center,
          child: Text(label,
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: active ? Colors.white : AppColors.textSecondary)),
        ),
      ),
    );
  }
}

// ── Compact filter chip ───────────────────────────────────────────────
class _FilterChip extends StatelessWidget {
  final String label;
  final String? value;
  final bool active;
  final bool enabled;
  final VoidCallback? onTap;

  const _FilterChip({
    required this.label, required this.active,
    this.value, this.enabled = true, this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasValue = value != null;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: hasValue ? AppColors.primarySurface : AppColors.background,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: hasValue ? AppColors.primary : AppColors.divider,
              width: hasValue ? 1.5 : 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value != null && value!.length > 8
                    ? '${value!.substring(0, 7)}…'
                    : (value ?? label),
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: hasValue ? FontWeight.w600 : FontWeight.w400,
                    color: hasValue
                        ? AppColors.primary
                        : enabled ? AppColors.textPrimary : AppColors.textHint),
              ),
              const SizedBox(height: 2),
              Icon(
                hasValue
                    ? Icons.arrow_drop_down_rounded
                    : Icons.chevron_right_rounded,
                size: 14,
                color: hasValue ? AppColors.primary : AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Picker sheets ─────────────────────────────────────────────────────
class _PickerSheet extends StatefulWidget {
  final String title;
  final List<String> items;
  final String? current;
  final ValueChanged<String> onSelect;
  const _PickerSheet({required this.title, required this.items,
                      required this.current, required this.onSelect});
  @override State<_PickerSheet> createState() => _PickerSheetState();
}
class _PickerSheetState extends State<_PickerSheet> {
  String _q = '';
  List<String> get _f => _q.isEmpty
      ? widget.items
      : widget.items.where((i) => i.toLowerCase().contains(_q.toLowerCase())).toList();
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 36, height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 16),
              decoration: BoxDecoration(color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2))),
          Padding(padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: Align(alignment: Alignment.centerLeft,
              child: Text(widget.title, style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w700)))),
          if (widget.items.length > 6)
            Padding(padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: TextField(autofocus: false,
                decoration: InputDecoration(hintText: 'common_search_hint'.tr(),
                  prefixIcon: const Icon(Icons.search_rounded, size: 20),
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  isDense: true, fillColor: AppColors.background),
                onChanged: (v) => setState(() => _q = v))),
          Flexible(child: ListView.builder(
            padding: const EdgeInsets.only(bottom: 24), shrinkWrap: true,
            itemCount: _f.length,
            itemBuilder: (context, i) {
              final item = _f[i];
              final sel = item == widget.current;
              return Container(color: sel ? AppColors.primarySurface : null,
                child: ListTile(dense: true,
                  title: Text(item, style: TextStyle(fontSize: 14,
                      fontWeight: sel ? FontWeight.w600 : FontWeight.w400,
                      color: sel ? AppColors.primary : AppColors.textPrimary)),
                  trailing: sel ? const Icon(Icons.check_circle_rounded,
                      color: AppColors.primary, size: 20) : null,
                  onTap: () => widget.onSelect(item)));
            })),
        ],
      ),
    );
  }
}

class _CategoryPickerSheet extends StatelessWidget {
  final String? current;
  final ValueChanged<String> onSelect;
  const _CategoryPickerSheet({required this.current, required this.onSelect});
  // Third/fourth tuple items are translation keys, resolved via .tr() at
  // render time (not pre-translated here — this list is a compile-time
  // const, but the current locale is only known at build()).
  static const _cats = [
    ('property',   Icons.home_rounded,      'type_house_flat',  'cat_property_desc'),
    ('plot',       Icons.landscape_rounded, 'type_plot',         'cat_plot_desc'),
    ('commercial', Icons.store_rounded,     'type_commercial',   'cat_commercial_desc'),
  ];
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 36, height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 20),
              decoration: BoxDecoration(color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2))),
          Align(alignment: Alignment.centerLeft,
            child: Text('select_property_type'.tr(), style: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.w700))),
          const SizedBox(height: 16),
          ..._cats.map((r) {
            final sel = current == r.$1;
            return GestureDetector(
              onTap: () => onSelect(r.$1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: sel ? AppColors.primarySurface : AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: sel ? AppColors.primary : AppColors.divider,
                      width: sel ? 1.5 : 1)),
                child: Row(children: [
                  Container(width: 40, height: 40,
                    decoration: BoxDecoration(
                      color: sel ? AppColors.primary : AppColors.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.divider)),
                    child: Icon(r.$2, size: 20,
                        color: sel ? Colors.white : AppColors.textSecondary)),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(r.$3.tr(), style: TextStyle(fontSize: 14,
                          fontWeight: sel ? FontWeight.w600 : FontWeight.w500,
                          color: sel ? AppColors.primary : AppColors.textPrimary)),
                      Text(r.$4.tr(), style: const TextStyle(
                          fontSize: 12, color: AppColors.textSecondary)),
                    ])),
                  if (sel) const Icon(Icons.check_circle_rounded,
                      color: AppColors.primary, size: 20),
                ]),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _EmptyResultsState extends StatelessWidget {
  final VoidCallback onReset;
  const _EmptyResultsState({required this.onReset});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.search_off_rounded, size: 48, color: AppColors.textHint),
          const SizedBox(height: 12),
          Text('empty_no_listings'.tr(),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text('empty_try_different'.tr(),
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          const SizedBox(height: 16),
          TextButton(onPressed: onReset, child: Text('btn_reset_search'.tr())),
        ],
      ),
    );
  }
}
