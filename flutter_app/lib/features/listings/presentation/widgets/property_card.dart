import 'dart:io';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/property_model.dart';

class PropertyCard extends StatelessWidget {
  final PropertyModel property;
  final VoidCallback onTap;
  final VoidCallback? onFavoriteToggle;
  final bool isFavorited;

  const PropertyCard({
    super.key,
    required this.property,
    required this.onTap,
    this.onFavoriteToggle,
    this.isFavorited = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(color: Color(0x0D000000), blurRadius: 12, offset: Offset(0, 3)),
          BoxShadow(color: Color(0x07000000), blurRadius: 3, offset: Offset(0, 1)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Image area ──────────────────────────────────────
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(18)),
                    child: AspectRatio(
                      aspectRatio: 16 / 9,
                      child: _buildImage(),
                    ),
                  ),
                  // Dark scrim so price text is readable
                  Positioned(
                    left: 0, right: 0, bottom: 0,
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(18)),
                      child: Container(
                        height: 60,
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [Color(0x88000000), Colors.transparent],
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Purpose badge top-left
                  Positioned(
                    top: 10, left: 10,
                    child: _PurposeBadge(purpose: property.purpose),
                  ),
                  // Favorite heart top-right
                  if (onFavoriteToggle != null)
                    Positioned(
                      top: 8, right: 8,
                      child: GestureDetector(
                        onTap: onFavoriteToggle,
                        child: Container(
                          width: 34, height: 34,
                          decoration: BoxDecoration(
                            color: isFavorited
                                ? AppColors.error
                                : Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: const [
                              BoxShadow(color: Color(0x22000000), blurRadius: 8)
                            ],
                          ),
                          child: Icon(
                            isFavorited
                                ? Icons.favorite_rounded
                                : Icons.favorite_border_rounded,
                            color: isFavorited
                                ? Colors.white
                                : AppColors.textSecondary,
                            size: 17,
                          ),
                        ),
                      ),
                    ),
                  // Price overlaid on the image bottom-left
                  Positioned(
                    bottom: 10, left: 12,
                    child: Text(
                      property.formattedPrice,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: -0.3,
                        shadows: [Shadow(color: Colors.black45, blurRadius: 4)],
                      ),
                    ),
                  ),
                ],
              ),

              // ── Info section ─────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      property.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                          letterSpacing: -0.2),
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        const Icon(Icons.location_on_rounded,
                            size: 13, color: AppColors.primary),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            '${property.area.isNotEmpty ? '${property.area}, ' : ''}${property.city}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Container(height: 1, color: AppColors.divider),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        if (property.beds != null) ...[
                          _Stat(icon: Icons.bed_rounded,
                              label: '${property.beds} bed'),
                          const SizedBox(width: 14),
                        ],
                        if (property.baths != null) ...[
                          _Stat(icon: Icons.bathtub_rounded,
                              label: '${property.baths} bath'),
                          const SizedBox(width: 14),
                        ],
                        _Stat(
                            icon: Icons.straighten_rounded,
                            label:
                                '${property.areaSize} ${property.areaUnit}'),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                              color: AppColors.primarySurface,
                              borderRadius: BorderRadius.circular(6)),
                          child: Text(property.propertyType,
                              style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.primary)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImage() {
    if (property.imageUrls.isNotEmpty) {
      return Image.network(
        property.imageUrls.first,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return _loadingPlaceholder();
        },
        errorBuilder: (context, error, stack) => _placeholder(),
      );
    }
    if (property.coverImageUrl != null &&
        property.coverImageUrl!.startsWith('assets/')) {
      return Image.asset(property.coverImageUrl!,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _placeholder());
    }
    if (property.localImagePaths.isNotEmpty) {
      return Image.file(File(property.localImagePaths.first),
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _placeholder());
    }
    return _placeholder();
  }

  Widget _loadingPlaceholder() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF4BBEE6), Color(0xFF20A7DB)],
        ),
      ),
      child: const Center(
        child: CircularProgressIndicator(
            color: Colors.white54, strokeWidth: 2),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF4BBEE6), Color(0xFF20A7DB)],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(_typeIcon(property.propertyType),
              size: 36, color: Colors.white.withValues(alpha: 0.6)),
          const SizedBox(height: 6),
          Text(property.propertyType,
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 11,
                  letterSpacing: 0.5)),
        ],
      ),
    );
  }

  IconData _typeIcon(String type) {
    switch (type) {
      case 'flat':       return Icons.apartment_rounded;
      case 'plot':       return Icons.landscape_rounded;
      case 'commercial': return Icons.store_rounded;
      default:           return Icons.home_rounded;
    }
  }
}

class _PurposeBadge extends StatelessWidget {
  final String purpose;
  const _PurposeBadge({required this.purpose});

  @override
  Widget build(BuildContext context) {
    final isRent = purpose == 'rent';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: isRent ? AppColors.accent : AppColors.primary,
        borderRadius: BorderRadius.circular(7),
      ),
      child: Text(
        isRent ? 'For rent' : 'For sale',
        style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final IconData icon;
  final String label;
  const _Stat({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.textSecondary),
        const SizedBox(width: 4),
        Text(label,
            style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w400)),
      ],
    );
  }
}
