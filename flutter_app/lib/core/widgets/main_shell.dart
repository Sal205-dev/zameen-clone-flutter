import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../../features/favorites/presentation/screens/favorites_screen.dart';
import '../../features/listings/presentation/screens/listings_screen.dart';
import '../../features/map_search/presentation/screens/map_search_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../theme/app_theme.dart';
import 'app_drawer.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  Widget _buildScreen(int index) {
    switch (index) {
      case 0: return const ListingsScreen();
      case 1: return _PlaceholderScreen(label: 'nav_projects'.tr());
      case 2: return const MapSearchScreen();
      case 3: return const FavoritesScreen();
      case 4: return const ProfileScreen();
      default: return const ListingsScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: AppDrawer(
        onFavoritesTap: () => setState(() => _currentIndex = 3),
      ),
      body: _buildScreen(_currentIndex),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          boxShadow: [
            BoxShadow(color: Color(0x12000000), blurRadius: 20, offset: Offset(0, -4))
          ],
        ),
        child: SafeArea(
          child: SizedBox(
            height: 64,
            child: Row(
              children: [
                _NavItem(
                  icon: Icons.home_outlined, activeIcon: Icons.home_rounded,
                  label: 'nav_home'.tr(), index: 0, current: _currentIndex,
                  onTap: (i) => setState(() => _currentIndex = i),
                ),
                _NavItem(
                  icon: Icons.location_city_outlined, activeIcon: Icons.location_city_rounded,
                  label: 'nav_projects'.tr(), index: 1, current: _currentIndex,
                  onTap: (i) => setState(() => _currentIndex = i),
                ),

                // Floating centre search button
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _currentIndex = 2),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 52, height: 52,
                          decoration: BoxDecoration(
                            color: _currentIndex == 2
                                ? AppColors.primaryDark
                                : AppColors.primary,
                            shape: BoxShape.circle,
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x44000000),
                                blurRadius: 10,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Icon(Icons.search_rounded,
                              color: Colors.white, size: 26),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'nav_search'.tr(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: _currentIndex == 2
                                ? AppColors.primary
                                : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                _NavItem(
                  icon: Icons.favorite_border_rounded, activeIcon: Icons.favorite_rounded,
                  label: 'nav_favorites'.tr(), index: 3, current: _currentIndex,
                  onTap: (i) => setState(() => _currentIndex = i),
                ),
                _NavItem(
                  icon: Icons.person_outline_rounded, activeIcon: Icons.person_rounded,
                  label: 'nav_profile'.tr(), index: 4, current: _currentIndex,
                  onTap: (i) => setState(() => _currentIndex = i),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon, activeIcon;
  final String label;
  final int index, current;
  final ValueChanged<int> onTap;

  const _NavItem({
    required this.icon, required this.activeIcon, required this.label,
    required this.index, required this.current, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final selected = index == current;
    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(index),
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              selected ? activeIcon : icon,
              color: selected ? AppColors.primary : AppColors.textSecondary,
              size: 22,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                color: selected ? AppColors.primary : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlaceholderScreen extends StatelessWidget {
  final String label;
  const _PlaceholderScreen({required this.label});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.construction_rounded,
                size: 48, color: AppColors.textHint),
            const SizedBox(height: 12),
            Text(label,
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text('coming_soon'.tr(),
                style: const TextStyle(color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}
