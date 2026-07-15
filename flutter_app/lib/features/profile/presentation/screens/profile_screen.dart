import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/mock/mock_data.dart';
import '../../../../core/theme/app_theme.dart';
import 'edit_profile_screen.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../listings/domain/property_model.dart';
import '../../../listings/presentation/screens/post_listing_screen.dart';
import '../../../listings/presentation/widgets/property_card.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authNotifierProvider).value;
    if (user == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF1580A8), Color(0xFF20A7DB)],
                ),
              ),
              padding: const EdgeInsets.fromLTRB(20, 56, 20, 32),
              child: Column(
                children: [
                  Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 2),
                    ),
                    child: Center(
                      child: Text(user.username[0].toUpperCase(), style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w700, color: Colors.white)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(user.username, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: -0.3)),
                  Text(user.email, style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.65))),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
                    ),
                    child: Text(user.isAgent ? 'Agent / Owner' : 'Buyer / Renter',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.white)),
                  ),
                ],
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (user.isAgent) ...[
                    // Post listing CTA
                    GestureDetector(
                      onTap: () => context.push('/post-listing'),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [AppColors.primary, AppColors.primaryLight]),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
                              child: const Icon(Icons.add_home_outlined, color: Colors.white, size: 22),
                            ),
                            const SizedBox(width: 14),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Post a property', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white)),
                                  Text('List your property for sale or rent', style: TextStyle(fontSize: 12, color: Colors.white70)),
                                ],
                              ),
                            ),
                            const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white60, size: 16),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text('My listings', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    const _MyListings(),
                    const SizedBox(height: 16),
                  ],

                  // Settings section
                  Container(
                    decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16),
                        boxShadow: const [BoxShadow(color: Color(0x08000000), blurRadius: 8)]),
                    child: Column(
                      children: [
                        _SettingsTile(icon: Icons.person_outline_rounded, label: 'Edit profile', onTap: () {
                          Navigator.of(context).push(MaterialPageRoute(
                            builder: (_) => const EditProfileScreen(),
                          ));
                        }),
                        const Divider(height: 0, indent: 54),
                        _SettingsTile(icon: Icons.notifications_outlined, label: 'Notifications', onTap: () {}),
                        const Divider(height: 0, indent: 54),
                        _SettingsTile(icon: Icons.help_outline_rounded, label: 'Help & support', onTap: () {}),
                        const Divider(height: 0, indent: 54),
                        _SettingsTile(
                          icon: Icons.logout_rounded,
                          label: 'Log out',
                          color: AppColors.error,
                          onTap: () => _confirmLogout(context, ref),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmLogout(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Log out?'),
        content: const Text("You'll need to log in again to access your account."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(favoritesProvider.notifier).clear();
              ref.read(myListingIdsProvider.notifier).clear();
              ref.read(authNotifierProvider.notifier).logout();
            },
            child: const Text('Log out', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;
  const _SettingsTile({required this.icon, required this.label, required this.onTap, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.textPrimary;
    return ListTile(
      leading: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: color == null ? AppColors.primarySurface : AppColors.error.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(9),
        ),
        child: Icon(icon, size: 18, color: color == null ? AppColors.primary : AppColors.error),
      ),
      title: Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: c)),
      trailing: color == null ? const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textHint) : null,
      onTap: onTap,
    );
  }
}

class _MyListings extends ConsumerWidget {
  const _MyListings();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final myListingsAsync = ref.watch(myApiListingsProvider);

    return myListingsAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Text('Could not load listings',
            style: TextStyle(color: AppColors.textSecondary)),
      ),
      data: (properties) {
        if (properties.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.divider)),
              child: const Row(
                children: [
                  Icon(Icons.home_outlined, color: AppColors.textHint),
                  SizedBox(width: 12),
                  Text("You haven't posted any properties yet",
                      style: TextStyle(
                          fontSize: 13, color: AppColors.textSecondary)),
                ],
              ),
            ),
          );
        }
        return Column(
          children: properties.map((p) => _MyListingCard(
            property: p,
            onTap: () => context.push('/property/${p.id}'),
            onEdit: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => PostListingScreen(editProperty: p),
            )),
            onDelete: () => _confirmDelete(context, ref, p),
          )).toList(),
        );
      },
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, WidgetRef ref, PropertyModel p) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete listing?'),
        content: Text(
          '"${p.title}" will be permanently removed from the database.',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete',
                style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final repo = ref.read(propertyApiRepositoryProvider);
      await repo.deleteProperty(p.id);
      ref.invalidate(myApiListingsProvider);
      ref.invalidate(apiPropertiesProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('Listing deleted'),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
        ));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.toString()),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
  }
}

// ── My listing card with edit/delete three-dot menu ───────────────────
class _MyListingCard extends StatelessWidget {
  final PropertyModel property;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _MyListingCard({
    required this.property,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        PropertyCard(property: property, onTap: onTap),
        // Three-dot menu — top-right corner of the card
        Positioned(
          top: 14, right: 14,
          child: PopupMenuButton<String>(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            icon: Container(
              width: 30, height: 30,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: Color(0x22000000), blurRadius: 6)
                ],
              ),
              child: const Icon(Icons.more_vert_rounded,
                  size: 17, color: AppColors.textPrimary),
            ),
            onSelected: (value) {
              if (value == 'edit')   onEdit();
              if (value == 'delete') onDelete();
            },
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: 'edit',
                child: Row(children: [
                  Icon(Icons.edit_outlined,
                      size: 18, color: AppColors.primary),
                  SizedBox(width: 10),
                  Text('Edit listing'),
                ]),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(children: [
                  Icon(Icons.delete_outline_rounded,
                      size: 18, color: AppColors.error),
                  SizedBox(width: 10),
                  Text('Delete',
                      style: TextStyle(color: AppColors.error)),
                ]),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
