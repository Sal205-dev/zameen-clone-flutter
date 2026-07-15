import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import '../../../../core/mock/mock_data.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../listings/domain/property_model.dart';

double _haversineKm(double lat1, double lng1, double lat2, double lng2) {
  const r = 6371.0;
  final dLat = (lat2 - lat1) * math.pi / 180;
  final dLng = (lng2 - lng1) * math.pi / 180;
  final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(lat1 * math.pi / 180) * math.cos(lat2 * math.pi / 180) * math.sin(dLng / 2) * math.sin(dLng / 2);
  return r * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
}

class MapSearchScreen extends ConsumerStatefulWidget {
  const MapSearchScreen({super.key});

  @override
  ConsumerState<MapSearchScreen> createState() => _MapSearchScreenState();
}

class _MapSearchScreenState extends ConsumerState<MapSearchScreen> {
  final _mapController = MapController();
  static const _defaultCenter = LatLng(33.6844, 73.0479);
  double _radiusKm = 15;
  List<PropertyModel> _results = [];
  bool _hasSearched = false;
  PropertyModel? _selected;

  void _runSearch() {
    final center = _mapController.camera.center;
    final all = ref.read(mockDataProvider);
    final filtered = all
        .where((p) => _haversineKm(center.latitude, center.longitude, p.lat, p.lng) <= _radiusKm)
        .toList()
      ..sort((a, b) => _haversineKm(center.latitude, center.longitude, a.lat, a.lng)
          .compareTo(_haversineKm(center.latitude, center.longitude, b.lat, b.lng)));
    setState(() { _results = filtered; _hasSearched = true; _selected = null; });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _runSearch());
  }

  @override
  Widget build(BuildContext context) {
    final all = ref.watch(mockDataProvider);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Full screen map
          FlutterMap(
            mapController: _mapController,
            options: const MapOptions(initialCenter: _defaultCenter, initialZoom: 11),
            children: [
              TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png', userAgentPackageName: 'com.example.dha_app'),
              MarkerLayer(
                markers: all.map((p) {
                  final isSelected = _selected?.id == p.id;
                  return Marker(
                    point: LatLng(p.lat, p.lng),
                    width: isSelected ? 100 : 72,
                    height: isSelected ? 42 : 32,
                    child: GestureDetector(
                      onTap: () { setState(() => _selected = _selected?.id == p.id ? null : p); },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.accent : AppColors.primary,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [BoxShadow(color: (isSelected ? AppColors.accent : AppColors.primary).withValues(alpha: 0.4), blurRadius: 8, offset: const Offset(0, 2))],
                        ),
                        child: Text(p.formattedPrice.replaceAll('PKR ', '').replaceAll(' ', ''),
                            style: TextStyle(fontSize: isSelected ? 11 : 10, fontWeight: FontWeight.w700, color: Colors.white)),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),

          // Top safe area + back button
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Container(
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12),
                        boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 8)]),
                    child: const _MapTitle(),
                  ),
                ],
              ),
            ),
          ),

          // Selected property mini card
          if (_selected != null)
            Positioned(
              left: 16,
              right: 16,
              bottom: 200,
              child: GestureDetector(
                onTap: () => context.push('/property/${_selected!.id}'),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [BoxShadow(color: Color(0x18000000), blurRadius: 16, offset: Offset(0, 4))],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [AppColors.primaryLight, AppColors.primary]),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.home_rounded, color: Colors.white, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_selected!.formattedPrice, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.primary)),
                            Text(_selected!.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, color: AppColors.textPrimary)),
                            Text('${_selected!.area}, ${_selected!.city}', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textHint),
                    ],
                  ),
                ),
              ),
            ),

          // Bottom controls panel
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [BoxShadow(color: Color(0x14000000), blurRadius: 20, offset: Offset(0, -4))],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 36, height: 4, margin: const EdgeInsets.only(bottom: 14),
                      decoration: BoxDecoration(color: AppColors.divider, borderRadius: BorderRadius.circular(2))),
                  Row(
                    children: [
                      const Icon(Icons.radio_button_checked_rounded, color: AppColors.primary, size: 16),
                      const SizedBox(width: 8),
                      Text('Search radius: ${_radiusKm.toStringAsFixed(0)} km',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                      const Spacer(),
                      Text('${_hasSearched ? _results.length : all.length} found',
                          style: const TextStyle(fontSize: 13, color: AppColors.primary, fontWeight: FontWeight.w600)),
                    ],
                  ),
                  Slider(
                    value: _radiusKm,
                    min: 1,
                    max: 50,
                    divisions: 49,
                    activeColor: AppColors.primary,
                    inactiveColor: AppColors.primarySurface,
                    onChanged: (v) => setState(() => _radiusKm = v),
                  ),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: _runSearch,
                      icon: const Icon(Icons.search_rounded, size: 18),
                      label: const Text('Search this area'),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // My location FAB
          Positioned(
            right: 16,
            bottom: 175,
            child: FloatingActionButton.small(
              heroTag: 'loc',
              backgroundColor: AppColors.surface,
              onPressed: () => _mapController.move(_defaultCenter, 13),
              child: const Icon(Icons.my_location_rounded, color: AppColors.primary, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}

class _MapTitle extends StatelessWidget {
  const _MapTitle();
  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.map_rounded, color: AppColors.primary, size: 18),
          SizedBox(width: 6),
          Text('Map search', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        ],
      ),
    );
  }
}
