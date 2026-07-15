import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/mock/mock_data.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../listings/presentation/widgets/property_card.dart';

class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favorites = ref.watch(favoritedPropertiesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Saved properties'),
        actions: [
          if (favorites.isNotEmpty)
            TextButton(
              onPressed: () {
                for (final p in favorites) { ref.read(favoritesProvider.notifier).toggle(p.id); }
              },
              child: const Text('Clear all', style: TextStyle(color: AppColors.error, fontSize: 13)),
            ),
        ],
      ),
      body: favorites.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(color: Colors.red.shade50, shape: BoxShape.circle),
                    child: Icon(Icons.favorite_border_rounded, size: 36, color: Colors.red.shade300),
                  ),
                  const SizedBox(height: 16),
                  const Text('No saved properties', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  const Text('Tap the heart on any listing to save it', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.only(top: 8, bottom: 24),
              itemCount: favorites.length,
              itemBuilder: (context, index) {
                final property = favorites[index];
                return PropertyCard(
                  property: property,
                  isFavorited: true,
                  onFavoriteToggle: () => ref.read(favoritesProvider.notifier).toggle(property.id),
                  onTap: () => context.push('/property/${property.id}'),
                );
              },
            ),
    );
  }
}
