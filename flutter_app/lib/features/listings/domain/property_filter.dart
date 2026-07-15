import 'property_model.dart';

/// DHA-specific filter. The cascading search on the home screen builds
/// this up step by step: purpose → city → phase → sector → category.
/// `matches()` runs the filter against the in-memory mock list.
class DhaFilter {
  final String? purpose;   // 'sale' | 'rent' | null = both
  final String? city;
  final String? phase;
  final String? sector;
  final String? category;  // 'property' | 'plot' | null = both

  const DhaFilter({
    this.purpose,
    this.city,
    this.phase,
    this.sector,
    this.category,
  });

  DhaFilter copyWith({
    String? purpose,
    String? city,
    String? phase,
    String? sector,
    String? category,
    bool clearPurpose = false,
    bool clearCity = false,
    bool clearPhase = false,
    bool clearSector = false,
    bool clearCategory = false,
  }) {
    return DhaFilter(
      purpose:  clearPurpose  ? null : (purpose  ?? this.purpose),
      city:     clearCity     ? null : (city     ?? this.city),
      phase:    clearPhase    ? null : (phase    ?? this.phase),
      sector:   clearSector   ? null : (sector   ?? this.sector),
      category: clearCategory ? null : (category ?? this.category),
    );
  }

  bool get hasAnySelection =>
      city != null || phase != null || sector != null || category != null;

  /// Converts the filter to query params for GET /api/properties/.
  /// Category 'property' (house/flat) is not sent — the API returns both
  /// house and flat by default; we exclude 'plot' and 'commercial' instead.
  Map<String, dynamic> toQueryParams() {
    final params = <String, dynamic>{};
    if (purpose != null) params['purpose'] = purpose;
    if (city   != null) params['city']    = city;
    if (phase  != null) params['phase']   = phase;
    if (sector != null) params['sector']  = sector;
    if (category == 'plot')       params['property_type'] = 'plot';
    if (category == 'commercial') params['property_type'] = 'commercial';
    return params;
  }

  /// In-memory filter — equivalent to the backend WHERE clause we'd use
  /// with PostGIS once the backend is connected.
  bool matches(PropertyModel p) {
    if (purpose != null && p.purpose != purpose) return false;
    if (city != null && p.city != city) return false;
    if (phase != null && p.phase != phase) return false;
    if (sector != null && p.sector != sector) return false;
    if (category != null && p.category != category) return false;
    return true;
  }
}
