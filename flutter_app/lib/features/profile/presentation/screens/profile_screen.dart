import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/mock/mock_data.dart';
import '../../../../core/theme/app_theme.dart';
import 'edit_profile_screen.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/presentation/screens/verify_email_screen.dart';
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
                    child: Text(user.isAgent ? 'role_agent_owner'.tr() : 'role_buyer_renter'.tr(),
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
                  if (!user.emailVerified) ...[
                    GestureDetector(
                      onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (_) =>
                                  VerifyEmailScreen(email: user.email))),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.orange.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.mark_email_unread_outlined,
                                color: Colors.orange.shade700, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text('verify_email_banner'.tr(),
                                  style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.orange.shade900)),
                            ),
                            Icon(Icons.arrow_forward_ios_rounded,
                                size: 14, color: Colors.orange.shade700),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
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
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('title_post_property'.tr(), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white)),
                                  Text('post_property_subtitle'.tr(), style: const TextStyle(fontSize: 12, color: Colors.white70)),
                                ],
                              ),
                            ),
                            const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white60, size: 16),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text('my_listings_title'.tr(), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
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
                        _SettingsTile(icon: Icons.person_outline_rounded, label: 'settings_edit_profile'.tr(), onTap: () {
                          Navigator.of(context).push(MaterialPageRoute(
                            builder: (_) => const EditProfileScreen(),
                          ));
                        }),
                        const Divider(height: 0, indent: 54),
                        _SettingsTile(icon: Icons.notifications_outlined, label: 'settings_notifications'.tr(), onTap: () {}),
                        const Divider(height: 0, indent: 54),
                        _SettingsTile(icon: Icons.help_outline_rounded, label: 'settings_help_support'.tr(), onTap: () {}),
                        const Divider(height: 0, indent: 54),
                        _SettingsTile(
                          icon: Icons.logout_rounded,
                          label: 'logout'.tr(),
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
        title: Text('confirm_logout_title'.tr()),
        content: Text('confirm_logout_body'.tr()),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('btn_cancel'.tr())),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(favoritesProvider.notifier).clear();
              ref.read(myListingIdsProvider.notifier).clear();
              ref.read(authNotifierProvider.notifier).logout();
            },
            child: Text('logout'.tr(), style: const TextStyle(color: AppColors.error)),
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
      error: (_, __) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Text('error_could_not_load_listings'.tr(),
            style: const TextStyle(color: AppColors.textSecondary)),
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
              child: Row(
                children: [
                  const Icon(Icons.home_outlined, color: AppColors.textHint),
                  const SizedBox(width: 12),
                  Text('empty_no_listings_posted'.tr(),
                      style: const TextStyle(
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
        title: Text('confirm_delete_listing_title'.tr()),
        content: Text(
          'confirm_delete_listing_body'.tr(namedArgs: {'title': p.title}),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('btn_cancel'.tr())),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('btn_delete'.tr(),
                style: const TextStyle(color: AppColors.error)),
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
          content: Text('listing_deleted_success'.tr()),
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
              PopupMenuItem(
                value: 'edit',
                child: Row(children: [
                  const Icon(Icons.edit_outlined,
                      size: 18, color: AppColors.primary),
                  const SizedBox(width: 10),
                  Text('title_edit_listing'.tr()),
                ]),
              ),
              PopupMenuItem(
                value: 'delete',
                child: Row(children: [
                  const Icon(Icons.delete_outline_rounded,
                      size: 18, color: AppColors.error),
                  const SizedBox(width: 10),
                  Text('btn_delete'.tr(),
                      style: const TextStyle(color: AppColors.error)),
                ]),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
