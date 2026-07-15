import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/listings/data/property_api_repository.dart';
import '../../features/listings/domain/property_filter.dart';
import '../../features/listings/domain/property_model.dart';
import '../network/providers.dart';

// ── Agents ────────────────────────────────────────────────────────────
const _dhaIsb = PropertyAgent(
  username: 'dha_isb_official',
  phone: '051-111-342-211',
  agencyName: 'DHA Islamabad',
);
const _dhaKhi = PropertyAgent(
  username: 'dha_khi_official',
  phone: '021-111-342-211',
  agencyName: 'DHA Karachi',
);
const _dhaLhr = PropertyAgent(
  username: 'dha_lhr_official',
  phone: '042-111-342-211',
  agencyName: 'DHA Lahore',
);
const _dhaPsw = PropertyAgent(
  username: 'dha_psw_official',
  phone: '091-111-342-211',
  agencyName: 'DHA Peshawar',
);
const _dhaMlt = PropertyAgent(
  username: 'dha_mlt_official',
  phone: '061-111-342-211',
  agencyName: 'DHA Multan',
);

/// All DHA listings — spread across 5 cities, multiple phases and sectors.
/// Every property has a `city`, `phase`, and `sector` so the cascading
/// search (City → Phase → Sector → Category) filters correctly.
final _seedProperties = <PropertyModel>[

  // ── Islamabad ──────────────────────────────────────────────────────
  const PropertyModel(
    id: 1,
    title: '1 Kanal House — DHA Islamabad Phase 2',
    description: 'Beautifully constructed 1 kanal house on a prime 40ft road in Sector E. Double-story with a fully finished basement, modern kitchen, and landscaped garden. Available for immediate possession.',
    propertyType: 'house', purpose: 'sale', category: 'property',
    price: 30000000, areaSize: '1', areaUnit: 'kanal',
    beds: 5, baths: 5,
    city: 'Islamabad', phase: 'Phase 2', sector: 'Sector E',
    address: 'Street 15, Sector E, DHA Phase 2, Islamabad',
    lat: 33.5500, lng: 73.1000,
    agent: _dhaIsb,
    coverImageUrl: 'assets/images/property1.jpg',
    amenities: {
      'Built in year': '2019', 'Floors': '2 + Basement',
      'Parking Spaces': '3', 'Electricity Backup': 'Yes',
      'Servants Quarters': 'Yes', 'Double Glazed Windows': 'Yes',
    },
  ),

  const PropertyModel(
    id: 2,
    title: '10 Marla Plot — DHA Islamabad Phase 1',
    description: 'Ideal residential plot in a quiet cul-de-sac. Level ground, all utilities available at the plot. Registry and possession ready.',
    propertyType: 'plot', purpose: 'sale', category: 'plot',
    price: 18000000, areaSize: '10', areaUnit: 'marla',
    city: 'Islamabad', phase: 'Phase 1', sector: 'Sector D',
    address: 'Sector D, DHA Phase 1, Islamabad',
    lat: 33.5480, lng: 73.0950,
    agent: _dhaIsb,
    coverImageUrl: 'assets/images/property2.jpg',
    amenities: {
      'Corner Plot': 'No', 'Road Width': '30 ft',
      'Possession': 'Available', 'Boundary Wall': 'No',
    },
  ),

  const PropertyModel(
    id: 3,
    title: 'Furnished Flat — DHA Islamabad Phase 3',
    description: 'Bright and fully furnished apartment on the 4th floor with a panoramic view of the Margalla Hills. High-speed fibre internet, 24/7 security.',
    propertyType: 'flat', purpose: 'rent', category: 'property',
    price: 90000, areaSize: '2200', areaUnit: 'sqft',
    beds: 3, baths: 3,
    city: 'Islamabad', phase: 'Phase 3', sector: 'Sector B',
    address: 'Sector B, DHA Phase 3, Islamabad',
    lat: 33.5520, lng: 73.1020,
    agent: _dhaIsb,
    coverImageUrl: 'assets/images/property3.jpg',
    amenities: {
      'Furnished': 'Yes', 'Floor': '4th',
      'Internet': 'Fibre', 'Security': '24/7',
      'Elevator': 'Yes', 'Backup Power': 'Yes',
    },
  ),

  // ── Karachi ────────────────────────────────────────────────────────
  const PropertyModel(
    id: 4,
    title: '500 Sq Yd House — DHA Karachi Phase 6',
    description: 'Elegant bungalow on a 500 sq yd plot in one of DHA Karachi\'s most sought-after blocks. Marble flooring throughout, central AC, and a private rooftop terrace.',
    propertyType: 'house', purpose: 'sale', category: 'property',
    price: 65000000, areaSize: '500', areaUnit: 'sqyd',
    beds: 6, baths: 7,
    city: 'Karachi', phase: 'Phase 6', sector: 'Block H',
    address: 'Block H, DHA Phase 6, Karachi',
    lat: 24.8150, lng: 67.0750,
    agent: _dhaKhi,
    coverImageUrl: 'assets/images/property4.jpg',
    amenities: {
      'Built in year': '2018', 'Floors': '2',
      'Central AC': 'Yes', 'Rooftop Terrace': 'Yes',
      'Backup Power': 'Yes', 'Parking Spaces': '4',
    },
  ),

  const PropertyModel(
    id: 5,
    title: '240 Sq Yd Plot — DHA Karachi Phase 7',
    description: 'Residential plot in a well-developed block with wide roads, parks, and all civic amenities. Ideal for immediate construction.',
    propertyType: 'plot', purpose: 'sale', category: 'plot',
    price: 12000000, areaSize: '240', areaUnit: 'sqyd',
    city: 'Karachi', phase: 'Phase 7', sector: 'Block C',
    address: 'Block C, DHA Phase 7, Karachi',
    lat: 24.8200, lng: 67.0800,
    agent: _dhaKhi,
    coverImageUrl: 'assets/images/property5.jpg',
    amenities: {
      'Corner Plot': 'No', 'Road Width': '40 ft',
      'Park Facing': 'Yes', 'Possession': 'Available',
    },
  ),

  const PropertyModel(
    id: 6,
    title: 'Commercial Shop — DHA Karachi Phase 5',
    description: 'Ground floor commercial unit on a bustling main boulevard. High foot traffic, suitable for retail, showroom, or office use.',
    propertyType: 'commercial', purpose: 'rent', category: 'commercial',
    price: 250000, areaSize: '1000', areaUnit: 'sqft',
    city: 'Karachi', phase: 'Phase 5', sector: 'Block F',
    address: 'Shahbaz Commercial, Block F, Phase 5, Karachi',
    lat: 24.8100, lng: 67.0700,
    agent: _dhaKhi,
    coverImageUrl: 'assets/images/property6.jpg',
    amenities: {
      'Floor': 'Ground', 'Frontage': '25 ft',
      'Backup Power': 'Yes', 'Car Parking': 'Yes',
    },
  ),

  // ── Lahore ─────────────────────────────────────────────────────────
  const PropertyModel(
    id: 7,
    title: '1 Kanal House — DHA Lahore Phase 5',
    description: 'Immaculate owner-built house on a corner plot with a spacious front lawn. Marble and wooden flooring, modular kitchen, and servant quarter.',
    propertyType: 'house', purpose: 'sale', category: 'property',
    price: 45000000, areaSize: '1', areaUnit: 'kanal',
    beds: 5, baths: 5,
    city: 'Lahore', phase: 'Phase 5', sector: 'Sector D',
    address: 'Sector D, DHA Phase 5, Lahore',
    lat: 31.4700, lng: 74.4100,
    agent: _dhaLhr,
    coverImageUrl: 'assets/images/property1.jpg',
    amenities: {
      'Built in year': '2016', 'Corner Plot': 'Yes',
      'Floors': '2', 'Servant Quarter': 'Yes',
      'Backup Power': 'Yes', 'Parking': '3 cars',
    },
  ),

  const PropertyModel(
    id: 8,
    title: '10 Marla Plot — DHA Lahore Phase 6',
    description: 'Well-located residential plot on a 30ft road near the commercial area. All utilities connected. No constructions nearby obstructing light.',
    propertyType: 'plot', purpose: 'sale', category: 'plot',
    price: 22000000, areaSize: '10', areaUnit: 'marla',
    city: 'Lahore', phase: 'Phase 6', sector: 'Sector G',
    address: 'Sector G, DHA Phase 6, Lahore',
    lat: 31.4750, lng: 74.4200,
    agent: _dhaLhr,
    coverImageUrl: 'assets/images/property2.jpg',
    amenities: {
      'Road Width': '30 ft', 'Park Facing': 'No',
      'Possession': 'Available', 'Utility Connections': 'Done',
    },
  ),

  const PropertyModel(
    id: 9,
    title: '2 Bed Flat — DHA Lahore Phase 2',
    description: 'Well-maintained apartment in a secure gated complex. Close to Y-Block market and main boulevard. Includes dedicated parking spot.',
    propertyType: 'flat', purpose: 'rent', category: 'property',
    price: 65000, areaSize: '1400', areaUnit: 'sqft',
    beds: 2, baths: 2,
    city: 'Lahore', phase: 'Phase 2', sector: 'Sector H',
    address: 'Sector H, DHA Phase 2, Lahore',
    lat: 31.4600, lng: 74.3900,
    agent: _dhaLhr,
    coverImageUrl: 'assets/images/property3.jpg',
    amenities: {
      'Floor': '3rd', 'Parking': '1 spot',
      'Elevator': 'Yes', 'Backup Power': 'Yes',
    },
  ),

  const PropertyModel(
    id: 10,
    title: '2 Kanal House — DHA Lahore Phase 1',
    description: 'Grand heritage-style residence on a prime 2 kanal plot. Fully renovated interior with a private swimming pool, home theatre, and gym.',
    propertyType: 'house', purpose: 'sale', category: 'property',
    price: 120000000, areaSize: '2', areaUnit: 'kanal',
    beds: 7, baths: 8,
    city: 'Lahore', phase: 'Phase 1', sector: 'Sector M',
    address: 'Sector M, DHA Phase 1, Lahore',
    lat: 31.4500, lng: 74.3800,
    agent: _dhaLhr,
    coverImageUrl: 'assets/images/property4.jpg',
    amenities: {
      'Built in year': '2005, renovated 2022',
      'Swimming Pool': 'Yes', 'Home Theatre': 'Yes',
      'Gym': 'Yes', 'Smart Home': 'Yes', 'Floors': '3',
    },
  ),

  const PropertyModel(
    id: 11,
    title: '10 Marla Plot — DHA Lahore Phase 9 (Prism)',
    description: 'Possession-paid plot in the rapidly developing Phase 9 Prism. Roads laid, boundary walls allowed. Great investment opportunity.',
    propertyType: 'plot', purpose: 'sale', category: 'plot',
    price: 19500000, areaSize: '10', areaUnit: 'marla',
    city: 'Lahore', phase: 'Phase 9 (Prism)', sector: 'Sector C',
    address: 'Sector C, DHA Phase 9 Prism, Lahore',
    lat: 31.3900, lng: 74.2800,
    agent: _dhaLhr,
    coverImageUrl: 'assets/images/property5.jpg',
    amenities: {
      'Possession': 'Paid', 'Road Width': '40 ft',
      'Boundary Wall': 'Allowed', 'Park Facing': 'No',
    },
  ),

  // ── Peshawar ───────────────────────────────────────────────────────
  const PropertyModel(
    id: 12,
    title: '10 Marla House — DHA Peshawar Phase 1',
    description: 'Tastefully designed modern house in the peaceful Sector B. Walking distance from the DHA Peshawar main gate. Excellent security and clean environment.',
    propertyType: 'house', purpose: 'sale', category: 'property',
    price: 17000000, areaSize: '10', areaUnit: 'marla',
    beds: 4, baths: 4,
    city: 'Peshawar', phase: 'Phase 1', sector: 'Sector B',
    address: 'Sector B, DHA Phase 1, Peshawar',
    lat: 33.9900, lng: 71.5700,
    agent: _dhaPsw,
    coverImageUrl: 'assets/images/property6.jpg',
    amenities: {
      'Built in year': '2021', 'Floors': '2',
      'Backup Power': 'Yes', 'Parking': '2 cars',
      'Servant Quarter': 'Yes',
    },
  ),

  const PropertyModel(
    id: 13,
    title: '10 Marla Plot — DHA Peshawar Phase 2',
    description: 'Development-stage plot in DHA Peshawar\'s newest phase. Great entry-level investment with projected high appreciation.',
    propertyType: 'plot', purpose: 'sale', category: 'plot',
    price: 9500000, areaSize: '10', areaUnit: 'marla',
    city: 'Peshawar', phase: 'Phase 2', sector: 'Sector C',
    address: 'Sector C, DHA Phase 2, Peshawar',
    lat: 33.9850, lng: 71.5750,
    agent: _dhaPsw,
    coverImageUrl: 'assets/images/property1.jpg',
    amenities: {
      'Road Width': '30 ft', 'Possession': 'On Ballot',
      'Development Status': '60% complete',
    },
  ),

  const PropertyModel(
    id: 14,
    title: '5 Marla House — DHA Peshawar Phase 1',
    description: 'Compact yet well-designed 5 marla house ideal for a small family. Modern construction, quality fittings, and a front lawn.',
    propertyType: 'house', purpose: 'rent', category: 'property',
    price: 55000, areaSize: '5', areaUnit: 'marla',
    beds: 3, baths: 3,
    city: 'Peshawar', phase: 'Phase 1', sector: 'Sector E',
    address: 'Sector E, DHA Phase 1, Peshawar',
    lat: 33.9920, lng: 71.5720,
    agent: _dhaPsw,
    coverImageUrl: 'assets/images/property2.jpg',
    amenities: {
      'Furnished': 'No', 'Backup Power': 'Yes',
      'Front Lawn': 'Yes', 'Parking': '1 car',
    },
  ),

  // ── Multan ─────────────────────────────────────────────────────────
  const PropertyModel(
    id: 15,
    title: '10 Marla House — DHA Multan Phase 1',
    description: 'Brand new house in DHA Multan\'s Midcity project. Modern architecture, all premium fittings, and a community park just steps away.',
    propertyType: 'house', purpose: 'sale', category: 'property',
    price: 14000000, areaSize: '10', areaUnit: 'marla',
    beds: 4, baths: 4,
    city: 'Multan', phase: 'Phase 1 (Midcity)', sector: 'Block C',
    address: 'Block C, DHA Multan Midcity, Multan',
    lat: 30.1800, lng: 71.5200,
    agent: _dhaMlt,
    coverImageUrl: 'assets/images/property3.jpg',
    amenities: {
      'Built in year': '2023', 'Floors': '2',
      'Backup Power': 'Yes', 'Park Facing': 'Yes',
      'Parking': '2 cars',
    },
  ),

  const PropertyModel(
    id: 16,
    title: '5 Marla Plot — DHA Multan Phase 1',
    description: 'Affordable entry-level residential plot in DHA Multan. Excellent for first-time buyers looking to build in a secure, planned community.',
    propertyType: 'plot', purpose: 'sale', category: 'plot',
    price: 5500000, areaSize: '5', areaUnit: 'marla',
    city: 'Multan', phase: 'Phase 1 (Midcity)', sector: 'Block F',
    address: 'Block F, DHA Multan Midcity, Multan',
    lat: 30.1750, lng: 71.5180,
    agent: _dhaMlt,
    coverImageUrl: 'assets/images/property4.jpg',
    amenities: {
      'Road Width': '25 ft', 'Possession': 'Available',
      'Utility Connections': 'Done', 'Corner Plot': 'No',
    },
  ),
];

// ── Providers ──────────────────────────────────────────────────────────

/// Master property list — includes anything posted during this session.
class MockDataNotifier extends Notifier<List<PropertyModel>> {
  @override
  List<PropertyModel> build() => List.of(_seedProperties);

  void addProperty(PropertyModel property) {
    state = [property, ...state];
  }

  int get nextId =>
      state.isEmpty ? 1 : state.map((p) => p.id).reduce((a, b) => a > b ? a : b) + 1;
}

final mockDataProvider =
    NotifierProvider<MockDataNotifier, List<PropertyModel>>(MockDataNotifier.new);

/// DHA cascading filter — built up step by step in the search UI.
class DhaFilterNotifier extends Notifier<DhaFilter> {
  @override
  DhaFilter build() => const DhaFilter();

  void update(DhaFilter Function(DhaFilter current) updater) {
    state = updater(state);
  }

  void reset() => state = const DhaFilter();
}

final dhaFilterProvider =
    NotifierProvider<DhaFilterNotifier, DhaFilter>(DhaFilterNotifier.new);

/// Also keep `propertyFilterProvider` as an alias so existing screens
/// (favorites, profile) that import it don't break.
final propertyFilterProvider = dhaFilterProvider;

/// Filtered list — synchronous since it's all in-memory.
final filteredPropertiesProvider = Provider<List<PropertyModel>>((ref) {
  final all = ref.watch(mockDataProvider);
  final filter = ref.watch(dhaFilterProvider);
  return all.where(filter.matches).toList();
});

/// Single property lookup by id — used by the detail screen.
final propertyByIdProvider = Provider.family<PropertyModel?, int>((ref, id) {
  final all = ref.watch(mockDataProvider);
  for (final p in all) {
    if (p.id == id) return p;
  }
  return null;
});

/// Fetches full property details from the real API (GET /api/properties/<id>/).
/// Falls back to seeded mock data for IDs that don't exist in the database.
/// Used by PropertyDetailScreen so it shows real data — correct description,
/// amenities, agent details, and images — not the in-memory seeded list.
final apiPropertyDetailProvider =
    FutureProvider.autoDispose.family<PropertyModel?, int>((ref, id) async {
  final repo = ref.read(propertyApiRepositoryProvider);
  final apiProperty = await repo.getPropertyById(id);
  if (apiProperty != null) return apiProperty;

  // Fall back to seeded mock data (IDs 1–16 that aren't in the database)
  final all = ref.read(mockDataProvider);
  for (final p in all) {
    if (p.id == id) return p;
  }
  return null;
});

/// Favorited property ids.
class FavoritesNotifier extends Notifier<Set<int>> {
  @override
  Set<int> build() => {};

  void toggle(int propertyId) {
    final updated = Set<int>.from(state);
    if (updated.contains(propertyId)) {
      updated.remove(propertyId);
    } else {
      updated.add(propertyId);
    }
    state = updated;
  }

  void clear() => state = {};
}

final favoritesProvider =
    NotifierProvider<FavoritesNotifier, Set<int>>(FavoritesNotifier.new);

final favoritedPropertiesProvider = Provider<List<PropertyModel>>((ref) {
  final all = ref.watch(mockDataProvider);
  final favIds = ref.watch(favoritesProvider);
  return all.where((p) => favIds.contains(p.id)).toList();
});

/// Ids of properties posted in this session (for the agent's profile).
class MyListingIdsNotifier extends Notifier<Set<int>> {
  @override
  Set<int> build() => {};

  void add(int propertyId) => state = {...state, propertyId};
  void clear() => state = {};
}

final myListingIdsProvider =
    NotifierProvider<MyListingIdsNotifier, Set<int>>(MyListingIdsNotifier.new);

final myListingsProvider = Provider<List<PropertyModel>>((ref) {
  final all = ref.watch(mockDataProvider);
  final myIds = ref.watch(myListingIdsProvider);
  return all.where((p) => myIds.contains(p.id)).toList();
});

// ── Real API-backed providers ─────────────────────────────────────────
// These replace the mock providers once the Django backend is running.
// They re-fetch automatically whenever dhaFilterProvider changes.

final propertyApiRepositoryProvider = Provider<PropertyApiRepository>((ref) {
  return PropertyApiRepository(ref.watch(dioProvider));
});

/// Fetches properties from the real Django API, filtered by the current
/// DhaFilter. Falls back to an empty list if the server is not running
/// rather than crashing — the listings screen shows a "no results" state.
class ApiPropertiesNotifier extends AsyncNotifier<List<PropertyModel>> {
  @override
  Future<List<PropertyModel>> build() async {
    final filter = ref.watch(dhaFilterProvider);
    final repo   = ref.watch(propertyApiRepositoryProvider);
    return repo.getProperties(filter);
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    final filter = ref.read(dhaFilterProvider);
    final repo   = ref.read(propertyApiRepositoryProvider);
    state = AsyncValue.data(await repo.getProperties(filter));
  }
}

final apiPropertiesProvider =
    AsyncNotifierProvider<ApiPropertiesNotifier, List<PropertyModel>>(
  ApiPropertiesNotifier.new,
);

/// The logged-in agent's own listings from the real API.
final myApiListingsProvider =
    FutureProvider.autoDispose<List<PropertyModel>>((ref) async {
  final repo = ref.watch(propertyApiRepositoryProvider);
  return repo.getMyListings();
});
