class PropertyModel {
  final int id;
  final String title;
  final String description;
  final String propertyType; // house | flat | plot | commercial
  final String purpose;      // sale | rent
  final double price;
  final String areaSize;
  final String areaUnit;
  final int? beds;
  final int? baths;

  // DHA location hierarchy
  final String city;     // e.g. Islamabad
  final String phase;    // e.g. Phase 2
  final String sector;   // e.g. Sector E  or  Block H
  final String address;  // full street address

  final double lat;
  final double lng;
  final PropertyAgent agent;

  /// 'property' = house/flat  |  'plot' = plot  |  'commercial' = commercial
  /// Used by the cascading search Category step.
  final String category;

  final String? coverImageUrl;
  final List<String> localImagePaths;

  /// Full image URLs returned by the real API
  /// (e.g. http://10.0.2.2:8000/media/property_images/photo.jpg).
  /// Empty for mock/seeded data — those fall back to coverImageUrl or placeholder.
  final List<String> imageUrls;

  /// URL of the optional video attached to this listing.
  /// Null if no video was uploaded.
  final String? videoUrl;
  final Map<String, String> amenities;

  const PropertyModel({
    required this.id,
    required this.title,
    required this.description,
    required this.propertyType,
    required this.purpose,
    required this.price,
    required this.areaSize,
    required this.areaUnit,
    this.beds,
    this.baths,
    required this.city,
    required this.phase,
    required this.sector,
    required this.address,
    required this.lat,
    required this.lng,
    required this.agent,
    required this.category,
    this.coverImageUrl,
    this.localImagePaths = const [],
    this.imageUrls = const [],
    this.videoUrl,
    this.amenities = const {},
  });

  /// Convenience getter — the area shown on cards and detail screen
  /// is the sector within the phase.
  String get area => sector;

  String get formattedPrice {
    if (price >= 10000000) {
      return 'PKR ${(price / 10000000).toStringAsFixed(2)} crore';
    }
    if (price >= 100000) {
      return 'PKR ${(price / 100000).toStringAsFixed(1)} lakh';
    }
    return 'PKR ${price.toStringAsFixed(0)}';
  }

  /// Parses a property from Django's PropertyListSerializer response.
  /// Called when the listings feed and my_listings fetch real API data.
  factory PropertyModel.fromApiJson(Map<String, dynamic> json) {
    final type = json['property_type'] as String? ?? 'house';
    return PropertyModel(
      id:           json['id'] as int,
      title:        json['title'] as String? ?? '',
      description:  json['description'] as String? ?? '',
      propertyType: type,
      purpose:      json['purpose'] as String? ?? 'sale',
      price:        double.tryParse(json['price'].toString()) ?? 0,
      areaSize:     json['area_size'].toString(),
      areaUnit:     json['area_unit'] as String? ?? 'marla',
      beds:         json['beds'] as int?,
      baths:        json['baths'] as int?,
      city:         json['city'] as String? ?? '',
      phase:        json['phase'] as String? ?? '',
      sector:       json['sector'] as String? ?? '',
      address:      '',
      lat:          0.0,
      lng:          0.0,
      agent: PropertyAgent(
        username:   json['agent_username'] as String? ?? '',
        phone:      json['agent_phone']    as String? ?? '',
        agencyName: json['agent_agency']   as String? ?? '',
      ),
      category: _typeToCategory(type),
      imageUrls: (json['image_urls'] as List<dynamic>? ?? [])
          .map((u) => u.toString())
          .toList(),
      videoUrl: json['video_url'] as String?,
      amenities: (json['amenities'] as Map<String, dynamic>? ?? {})
          .map((k, v) => MapEntry(k, v.toString())),
    );
  }

  static String _typeToCategory(String type) {
    if (type == 'plot')       return 'plot';
    if (type == 'commercial') return 'commercial';
    return 'property';
  }
}

class PropertyAgent {
  final String username;
  final String phone;
  final String agencyName;

  const PropertyAgent({
    required this.username,
    required this.phone,
    required this.agencyName,
  });
}
