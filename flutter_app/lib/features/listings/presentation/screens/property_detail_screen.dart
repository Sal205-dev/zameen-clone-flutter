import 'dart:io';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';
import '../../../../core/mock/mock_data.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/property_model.dart';

class PropertyDetailScreen extends ConsumerStatefulWidget {
  final int propertyId;
  const PropertyDetailScreen({super.key, required this.propertyId});

  @override
  ConsumerState<PropertyDetailScreen> createState() =>
      _PropertyDetailScreenState();
}

class _PropertyDetailScreenState
    extends ConsumerState<PropertyDetailScreen> {
  final _pageController = PageController();
  int _currentImageIndex = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Use the real API detail provider — fetches description, amenities,
    // agent info and images from Django, falls back to mock for seeded data.
    final propertyAsync =
        ref.watch(apiPropertyDetailProvider(widget.propertyId));
    final favoriteIds = ref.watch(favoritesProvider);

    return propertyAsync.when(
      loading: () => Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(backgroundColor: AppColors.primary,
            foregroundColor: Colors.white),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => Scaffold(
        appBar: AppBar(),
        body: Center(child: Text('error_property_not_found'.tr())),
      ),
      data: (property) {
        if (property == null) {
          return Scaffold(
            appBar: AppBar(),
            body: Center(child: Text('error_property_not_found'.tr())),
          );
        }
        final isFavorited = favoriteIds.contains(property.id);
        return _buildDetail(property, isFavorited);
      },
    );
  }

  Widget _buildDetail(PropertyModel property, bool isFavorited) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // ── Image header ─────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            leading: Padding(
              padding: const EdgeInsets.all(8),
              child: CircleAvatar(
                backgroundColor: Colors.black38,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_rounded,
                      color: Colors.white, size: 20),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.all(8),
                child: CircleAvatar(
                  backgroundColor: Colors.black38,
                  child: IconButton(
                    icon: Icon(
                      isFavorited
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      color: isFavorited
                          ? Colors.red.shade300
                          : Colors.white,
                      size: 20,
                    ),
                    onPressed: () => ref
                        .read(favoritesProvider.notifier)
                        .toggle(property.id),
                  ),
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.only(right: 8, top: 8, bottom: 8),
                child: CircleAvatar(
                  backgroundColor: Colors.black38,
                  child: IconButton(
                    icon: const Icon(Icons.share_outlined,
                        color: Colors.white, size: 20),
                    onPressed: () =>
                        ScaffoldMessenger.of(context).showSnackBar(
                      _snackBar('snackbar_share_mock'.tr()),
                    ),
                  ),
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: _buildImageCarousel(property),
            ),
          ),

          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Type + timestamp ───────────────────────────────
                Container(
                  color: AppColors.surface,
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                  child: Row(
                    children: [
                      Text(
                        'listing_type_for_purpose'.tr(namedArgs: {
                          'type': property.propertyTypeLabel,
                          'purpose': property.purpose == 'rent'
                              ? 'purpose_word_rent'.tr()
                              : 'purpose_word_sale'.tr(),
                        }),
                        style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary),
                      ),
                      const Spacer(),
                      Text('just_posted'.tr(),
                          style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary)),
                    ],
                  ),
                ),

                // ── Price + location ───────────────────────────────
                Container(
                  color: AppColors.surface,
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        property.formattedPrice,
                        style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                            letterSpacing: -0.5),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.location_on_rounded,
                              size: 15, color: AppColors.primary),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              '${property.sector}, ${property.phase}, ${property.city}',
                              style: const TextStyle(
                                  fontSize: 14,
                                  color: AppColors.textSecondary),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // ── Stats row (beds/baths/area) ──────────────
                      Row(
                        children: [
                          if (property.beds != null)
                            _GreenStat(
                                icon: Icons.bed_rounded,
                                label: 'stat_beds'.tr(namedArgs: {
                                  'count': '${property.beds}'
                                })),
                          if (property.baths != null) ...[
                            const SizedBox(width: 20),
                            _GreenStat(
                                icon: Icons.bathtub_rounded,
                                label: 'stat_baths'.tr(namedArgs: {
                                  'count': '${property.baths}'
                                })),
                          ],
                          const SizedBox(width: 20),
                          _GreenStat(
                              icon: Icons.straighten_rounded,
                              label:
                                  '${property.areaSize} ${property.areaUnit}'),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                // ── Description ────────────────────────────────────
                if (property.description.isNotEmpty)
                  Container(
                    color: AppColors.surface,
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          property.description,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                              height: 1.6),
                        ),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: () => _showFullDescription(
                              context, property.description),
                          child: Text('view_full_description'.tr(),
                              style: const TextStyle(
                                  color: Colors.blue,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500)),
                        ),
                      ],
                    ),
                  ),

                if (property.description.isNotEmpty)
                  const SizedBox(height: 10),

                // ── Features & Amenities ───────────────────────────
                if (property.amenities.isNotEmpty)
                  Container(
                    color: AppColors.surface,
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('features_amenities'.tr(),
                            style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary)),
                        const SizedBox(height: 14),
                        _AmenitiesGrid(amenities: property.amenities),
                      ],
                    ),
                  ),

                if (property.amenities.isNotEmpty)
                  const SizedBox(height: 10),

                // ── Video ──────────────────────────────────────────
                if (property.videoUrl != null) ...[
                  Container(
                    color: AppColors.surface,
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('property_video'.tr(),
                            style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary)),
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: _VideoPlayerWidget(
                              url: property.videoUrl!),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                ],

                // ── Agent card ─────────────────────────────────────
                Container(
                  color: AppColors.surface,
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        width: 48, height: 48,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [
                            AppColors.primaryLight,
                            AppColors.primary
                          ]),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Center(
                          child: Text(
                            property.agent.username.isNotEmpty
                                ? property.agent.username[0].toUpperCase()
                                : 'A',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              property.agent.agencyName.isNotEmpty
                                  ? property.agent.agencyName
                                  : property.agent.username,
                              style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600),
                            ),
                            if (property.agent.phone.isNotEmpty)
                              Text(property.agent.phone,
                                  style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 100),
              ],
            ),
          ),
        ],
      ),

      // ── Bottom action bar ─────────────────────────────────────────
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 24),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          boxShadow: [
            BoxShadow(
                color: Color(0x14000000),
                blurRadius: 16,
                offset: Offset(0, -4))
          ],
        ),
        child: Row(
          children: [
            _ActionButton(
              icon: Icons.chat_bubble_outline_rounded,
              color: AppColors.primary,
              onTap: () => ScaffoldMessenger.of(context)
                  .showSnackBar(_snackBar('snackbar_chat_opened_mock'.tr())),
            ),
            const SizedBox(width: 8),
            _ActionButton(
              icon: Icons.email_outlined,
              color: AppColors.primary,
              onTap: () => ScaffoldMessenger.of(context)
                  .showSnackBar(_snackBar('snackbar_email_opened_mock'.tr())),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: SizedBox(
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: () => ScaffoldMessenger.of(context)
                      .showSnackBar(_snackBar('snackbar_calling_agent_mock'.tr())),
                  icon: const Icon(Icons.call_rounded, size: 18),
                  label: Text('btn_call'.tr()),
                ),
              ),
            ),
            const SizedBox(width: 8),
            _ActionButton(
              icon: Icons.chat_rounded,
              color: const Color(0xFF25D366),
              onTap: () => ScaffoldMessenger.of(context)
                  .showSnackBar(_snackBar('snackbar_whatsapp_opened_mock'.tr())),
            ),
          ],
        ),
      ),
    );
  }

  // ── Image carousel with live page counter ──────────────────────────
  Widget _buildImageCarousel(PropertyModel property) {
    // Real API images — swipeable PageView with live "X/N" counter
    if (property.imageUrls.isNotEmpty) {
      return Stack(
        fit: StackFit.expand,
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: property.imageUrls.length,
            onPageChanged: (index) =>
                setState(() => _currentImageIndex = index),
            itemBuilder: (context, index) => Image.network(
              property.imageUrls[index],
              fit: BoxFit.cover,
              loadingBuilder: (context, child, progress) {
                if (progress == null) return child;
                return _imagePlaceholder(property.propertyType);
              },
              errorBuilder: (context, error, stack) =>
                  _imagePlaceholder(property.propertyType),
            ),
          ),
          // Live photo counter — updates as user swipes
          if (property.imageUrls.length > 1)
            Positioned(
              bottom: 12, right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(8)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.photo_library_outlined,
                        color: Colors.white, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      '${_currentImageIndex + 1} / ${property.imageUrls.length}',
                      style: const TextStyle(
                          color: Colors.white, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          // Dot indicators at bottom centre
          if (property.imageUrls.length > 1)
            Positioned(
              bottom: 12, left: 0, right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  property.imageUrls.length,
                  (i) => AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: i == _currentImageIndex ? 16 : 6,
                    height: 6,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      color: i == _currentImageIndex
                          ? Colors.white
                          : Colors.white38,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ),
            ),
        ],
      );
    }

    // Asset image (mock data)
    if (property.coverImageUrl != null &&
        property.coverImageUrl!.startsWith('assets/')) {
      return Image.asset(property.coverImageUrl!,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) =>
              _imagePlaceholder(property.propertyType));
    }

    // Local file (just posted, still uploading)
    if (property.localImagePaths.isNotEmpty) {
      return Image.file(File(property.localImagePaths.first),
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) =>
              _imagePlaceholder(property.propertyType));
    }

    return _imagePlaceholder(property.propertyType);
  }

  Widget _imagePlaceholder(String type) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1580A8), Color(0xFF4BBEE6)],
        ),
      ),
      child: Center(
        child: Icon(_typeIcon(type),
            size: 64, color: Colors.white.withValues(alpha: 0.3)),
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────
  IconData _typeIcon(String type) {
    switch (type) {
      case 'flat':       return Icons.apartment_rounded;
      case 'plot':       return Icons.landscape_rounded;
      case 'commercial': return Icons.store_rounded;
      default:           return Icons.home_rounded;
    }
  }

  SnackBar _snackBar(String message) => SnackBar(
        content: Text(message),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      );

  void _showFullDescription(BuildContext context, String description) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        maxChildSize: 0.9,
        minChildSize: 0.3,
        expand: false,
        builder: (context, scrollController) => ListView(
          controller: scrollController,
          padding: const EdgeInsets.all(20),
          children: [
            Center(
              child: Container(
                width: 36, height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                    color: AppColors.divider,
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            Text('description_title'.tr(),
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            Text(description,
                style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                    height: 1.7)),
          ],
        ),
      ),
    );
  }
}

// ── Green stat chip ───────────────────────────────────────────────────
class _GreenStat extends StatelessWidget {
  final IconData icon;
  final String label;
  const _GreenStat({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: AppColors.primary, size: 18),
        const SizedBox(width: 5),
        Text(label,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary)),
      ],
    );
  }
}

// ── 2-column amenities grid ───────────────────────────────────────────
class _AmenitiesGrid extends StatelessWidget {
  final Map<String, String> amenities;
  const _AmenitiesGrid({required this.amenities});

  @override
  Widget build(BuildContext context) {
    final entries = amenities.entries.toList();
    final rowCount = (entries.length / 2).ceil();
    return Column(
      children: List.generate(rowCount, (rowIndex) {
        final left = entries[rowIndex * 2];
        final hasRight = (rowIndex * 2 + 1) < entries.length;
        final right = hasRight ? entries[rowIndex * 2 + 1] : null;
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            children: [
              Expanded(
                  child: _AmenityItem(
                      label: left.key, value: left.value)),
              const SizedBox(width: 12),
              Expanded(
                child: right != null
                    ? _AmenityItem(
                        label: right.key, value: right.value)
                    : const SizedBox(),
              ),
            ],
          ),
        );
      }),
    );
  }
}

class _AmenityItem extends StatelessWidget {
  final String label;
  final String value;
  const _AmenityItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.check_box_rounded,
            color: Colors.blue, size: 16),
        const SizedBox(width: 6),
        Expanded(
          child: Text('$label: $value',
              style: const TextStyle(
                  fontSize: 13, color: AppColors.textSecondary)),
        ),
      ],
    );
  }
}

// ── Square icon action button ─────────────────────────────────────────
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _ActionButton(
      {required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 50, height: 50,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Icon(icon, color: color, size: 22),
      ),
    );
  }
}

// ── Inline video player ───────────────────────────────────────────────
class _VideoPlayerWidget extends StatefulWidget {
  final String url;
  const _VideoPlayerWidget({required this.url});

  @override
  State<_VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<_VideoPlayerWidget> {
  late VideoPlayerController _controller;
  bool _initialized = false;
  bool _hasError    = false;

  @override
  void initState() {
    super.initState();
    _controller =
        VideoPlayerController.networkUrl(Uri.parse(widget.url))
          ..initialize().then((_) {
            if (mounted) setState(() => _initialized = true);
          }).catchError((_) {
            if (mounted) setState(() => _hasError = true);
          });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _togglePlay() {
    setState(() {
      _controller.value.isPlaying
          ? _controller.pause()
          : _controller.play();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return Container(
        height: 180,
        color: Colors.black12,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.videocam_off_rounded,
                  color: AppColors.textHint, size: 36),
              const SizedBox(height: 8),
              Text('could_not_load_video'.tr(),
                  style: const TextStyle(color: AppColors.textSecondary)),
            ],
          ),
        ),
      );
    }

    if (!_initialized) {
      return Container(
        height: 180,
        color: Colors.black,
        child: const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    return GestureDetector(
      onTap: _togglePlay,
      child: Container(
        color: Colors.black,
        child: Stack(
          alignment: Alignment.center,
          children: [
            AspectRatio(
              aspectRatio: _controller.value.aspectRatio,
              child: VideoPlayer(_controller),
            ),
            // Play/pause overlay
            AnimatedOpacity(
              opacity: _controller.value.isPlaying ? 0.0 : 1.0,
              duration: const Duration(milliseconds: 300),
              child: Container(
                width: 56, height: 56,
                decoration: const BoxDecoration(
                    color: Colors.black45,
                    shape: BoxShape.circle),
                child: const Icon(Icons.play_arrow_rounded,
                    color: Colors.white, size: 32),
              ),
            ),
            // Progress bar at bottom
            Positioned(
              bottom: 0, left: 0, right: 0,
              child: VideoProgressIndicator(
                _controller,
                allowScrubbing: true,
                colors: const VideoProgressColors(
                  playedColor:     AppColors.primary,
                  bufferedColor:   Colors.white38,
                  backgroundColor: Colors.white12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
