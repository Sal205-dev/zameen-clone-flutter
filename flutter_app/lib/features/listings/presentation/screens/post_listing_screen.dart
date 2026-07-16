import 'dart:io';
import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/mock/dha_data.dart';
import '../../../../core/mock/mock_data.dart';
import '../../../../core/network/providers.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/property_api_repository.dart';
import '../../domain/property_model.dart';

/// Create or edit a property listing.
///
/// Pass [editProperty] to enter edit mode — all fields are pre-filled and
/// submit calls PATCH instead of POST. The title bar changes to "Edit listing".
class PostListingScreen extends ConsumerStatefulWidget {
  final PropertyModel? editProperty;
  const PostListingScreen({super.key, this.editProperty});

  bool get isEditMode => editProperty != null;

  @override
  ConsumerState<PostListingScreen> createState() => _PostListingScreenState();
}

class _PostListingScreenState extends ConsumerState<PostListingScreen> {
  final _formKey = GlobalKey<FormState>();

  final _titleController       = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController       = TextEditingController();
  final _areaSizeController    = TextEditingController();
  final _bedsController        = TextEditingController();
  final _bathsController       = TextEditingController();

  String? _city;
  String? _phase;
  String? _sector;

  String _propertyType = 'house';
  String _purpose      = 'sale';
  String _areaUnit     = 'marla';

  // New photos picked this session
  final List<XFile> _pickedImages = [];

  // Video picked this session (null if none)
  XFile? _pickedVideo;
  String? _videoError; // shown when size check fails

  bool    _submitting = false;
  String? _errorMessage;

  static const _propertyTypes = ['house', 'flat', 'plot', 'commercial'];
  static const _areaUnits     = ['marla', 'kanal', 'sqft', 'sqyd'];

  @override
  void initState() {
    super.initState();
    // Pre-fill fields when editing an existing listing
    final p = widget.editProperty;
    if (p != null) {
      _titleController.text       = p.title;
      _descriptionController.text = p.description;
      _priceController.text       = p.price.toStringAsFixed(0);
      _areaSizeController.text    = p.areaSize;
      _bedsController.text        = p.beds?.toString()  ?? '';
      _bathsController.text       = p.baths?.toString() ?? '';
      _city         = p.city;
      _phase        = p.phase;
      _sector       = p.sector;
      _propertyType = p.propertyType;
      _purpose      = p.purpose;
      _areaUnit     = p.areaUnit;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _areaSizeController.dispose();
    _bedsController.dispose();
    _bathsController.dispose();
    super.dispose();
  }

  // ── Location pickers ──────────────────────────────────────────────
  Future<void> _pickCity() async {
    final chosen = await _showPicker(
        title: 'filter_select_city'.tr(), items: dhaCities, current: _city);
    if (chosen != null) {
      setState(() { _city = chosen; _phase = null; _sector = null; });
    }
  }

  Future<void> _pickPhase() async {
    if (_city == null) return;
    final chosen = await _showPicker(
        title: 'select_phase_for'.tr(namedArgs: {'city': _city!}),
        items: getPhasesForCity(_city!),
        current: _phase);
    if (chosen != null) setState(() { _phase = chosen; _sector = null; });
  }

  Future<void> _pickSector() async {
    if (_city == null || _phase == null) return;
    final chosen = await _showPicker(
        title: 'select_sector_for'.tr(namedArgs: {'phase': _phase!}),
        items: getSectorsForPhase(_city!, _phase!),
        current: _sector);
    if (chosen != null) setState(() => _sector = chosen);
  }

  Future<String?> _showPicker(
      {required String title,
      required List<String> items,
      required String? current}) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          _PickerSheet(title: title, items: items, current: current),
    );
  }

  // ── Media pickers ─────────────────────────────────────────────────
  Future<void> _pickImages() async {
    final remaining = 10 - _pickedImages.length;
    if (remaining <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('max_photos_reached'.tr())));
      return;
    }
    final images = await ImagePicker().pickMultiImage(limit: remaining);
    setState(() => _pickedImages.addAll(images));
  }

  Future<void> _pickVideo() async {
    setState(() { _videoError = null; });
    final video = await ImagePicker().pickVideo(
      source: ImageSource.gallery,
    );
    if (video == null) return;

    // Check 25 MB limit before uploading
    final bytes = await File(video.path).length();
    if (bytes > 25 * 1024 * 1024) {
      setState(() => _videoError = 'video_exceeds_size'.tr(namedArgs: {
            'size': (bytes / (1024 * 1024)).toStringAsFixed(1),
          }));
      return;
    }
    setState(() => _pickedVideo = video);
  }

  void _removeVideo() => setState(() => _pickedVideo = null);

  String _propertyTypeLabel(String type) {
    switch (type) {
      case 'house':       return 'type_house'.tr();
      case 'flat':        return 'type_flat'.tr();
      case 'plot':        return 'type_plot'.tr();
      case 'commercial':  return 'type_commercial'.tr();
      default:            return type;
    }
  }

  // ── Submit ────────────────────────────────────────────────────────
  Future<void> _submit() async {
    setState(() => _errorMessage = null);
    if (!_formKey.currentState!.validate()) return;
    if (_city == null || _phase == null || _sector == null) {
      setState(() => _errorMessage = 'error_select_location'.tr());
      return;
    }
    if (_videoError != null) {
      setState(() => _errorMessage = _videoError);
      return;
    }

    setState(() => _submitting = true);
    try {
      final repo = PropertyApiRepository(ref.read(dioProvider));

      if (widget.isEditMode) {
        // ── Edit mode: PATCH existing listing ───────────────────────
        await repo.updateProperty(
          id:           widget.editProperty!.id,
          title:        _titleController.text.trim(),
          description:  _descriptionController.text.trim(),
          propertyType: _propertyType,
          purpose:      _purpose,
          city:         _city!,
          phase:        _phase!,
          sector:       _sector!,
          price:        _priceController.text.trim(),
          areaSize:     _areaSizeController.text.trim(),
          areaUnit:     _areaUnit,
          beds:  _bedsController.text.isEmpty  ? null : int.tryParse(_bedsController.text),
          baths: _bathsController.text.isEmpty ? null : int.tryParse(_bathsController.text),
        );

        // Upload any newly added images — keep going even if one fails,
        // but remember failures so they can be reported (not silently
        // dropped, unlike before).
        final imageErrors = <String>[];
        for (int i = 0; i < _pickedImages.length; i++) {
          try {
            await repo.uploadImage(
                propertyId: widget.editProperty!.id,
                filePath: _pickedImages[i].path,
                isPrimary: false); // don't override the existing primary
          } catch (e) {
            imageErrors.add('$e');
          }
        }
        if (imageErrors.isNotEmpty && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('images_partial_failure'.tr(namedArgs: {
                  'failed': '${imageErrors.length}',
                  'total': '${_pickedImages.length}',
                  'error': imageErrors.first,
                })),
                backgroundColor: AppColors.error,
                behavior: SnackBarBehavior.floating),
          );
        }

        // Upload new video if picked
        if (_pickedVideo != null) {
          try {
            await repo.uploadVideo(
                propertyId: widget.editProperty!.id,
                filePath: _pickedVideo!.path);
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('video_error_prefix'.tr(namedArgs: {'error': '$e'})),
                    backgroundColor: AppColors.error,
                    behavior: SnackBarBehavior.floating),
              );
            }
          }
        }
      } else {
        // ── Create mode: POST new listing ────────────────────────────
        final response = await ref.read(dioProvider).post('/properties/', data: {
          'title':         _titleController.text.trim(),
          'description':   _descriptionController.text.trim(),
          'property_type': _propertyType,
          'purpose':       _purpose,
          'city':          _city,
          'phase':         _phase,
          'sector':        _sector,
          'price':         _priceController.text.trim(),
          'area_size':     _areaSizeController.text.trim(),
          'area_unit':     _areaUnit,
          'beds':  _bedsController.text.isEmpty  ? null : int.tryParse(_bedsController.text),
          'baths': _bathsController.text.isEmpty ? null : int.tryParse(_bathsController.text),
          'amenities': {},
        });

        final newId = response.data['id'] as int;

        // Upload images (first one becomes the cover/primary) — keep
        // going even if one fails, but report failures instead of
        // silently dropping them.
        final imageErrors = <String>[];
        for (int i = 0; i < _pickedImages.length; i++) {
          try {
            await repo.uploadImage(
                propertyId: newId,
                filePath: _pickedImages[i].path,
                isPrimary: i == 0);
          } catch (e) {
            imageErrors.add('$e');
          }
        }
        if (imageErrors.isNotEmpty && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('images_partial_failure'.tr(namedArgs: {
                  'failed': '${imageErrors.length}',
                  'total': '${_pickedImages.length}',
                  'error': imageErrors.first,
                })),
                backgroundColor: AppColors.error,
                behavior: SnackBarBehavior.floating),
          );
        }

        // Upload video if picked
        if (_pickedVideo != null) {
          try {
            await repo.uploadVideo(
                propertyId: newId, filePath: _pickedVideo!.path);
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('video_error_prefix'.tr(namedArgs: {'error': '$e'})),
                    backgroundColor: AppColors.error,
                    behavior: SnackBarBehavior.floating),
              );
            }
          }
        }
      }

      // Refresh all feeds
      ref.invalidate(apiPropertiesProvider);
      ref.invalidate(myApiListingsProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(widget.isEditMode
              ? 'listing_updated_success'.tr()
              : 'listing_posted_success'.tr()),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
        ));
        context.pop();
      }
    } on DioException catch (e) {
      String msg = 'error_save_listing_failed'.tr();
      final data = e.response?.data;
      if (data is Map) {
        for (final v in data.values) {
          if (v is List && v.isNotEmpty) { msg = v.first.toString(); break; }
          if (v is String) { msg = v; break; }
        }
      }
      if (mounted) setState(() => _errorMessage = msg);
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage =
            e.toString().startsWith('Exception:')
                ? e.toString().replaceFirst('Exception: ', '')
                : 'error_connection'.tr());
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(widget.isEditMode
            ? 'title_edit_listing'.tr()
            : 'title_post_property'.tr()),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [

              // ── Photos (up to 10) ──────────────────────────────────
              _SectionLabel('section_photos'.tr()),
              _PhotoPicker(
                  images: _pickedImages,
                  existingUrls: widget.editProperty?.imageUrls ?? [],
                  onAdd: _pickImages,
                  onRemoveNew: (i) =>
                      setState(() => _pickedImages.removeAt(i))),
              const SizedBox(height: 16),

              // ── Video (1, max 25 MB) ───────────────────────────────
              _SectionLabel('section_video'.tr()),
              _VideoPickerTile(
                pickedVideo: _pickedVideo,
                existingVideoUrl: widget.editProperty?.videoUrl,
                error: _videoError,
                onPick: _pickVideo,
                onRemove: _removeVideo,
              ),
              const SizedBox(height: 24),

              // ── DHA Location ───────────────────────────────────────
              _SectionLabel('section_dha_location'.tr()),
              Text(
                'dha_location_hint'.tr(),
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 12),
              _LocationPickerTile(
                  step: '1', label: 'filter_city'.tr(), value: _city,
                  placeholder: 'placeholder_select_city'.tr(), enabled: true,
                  onTap: _pickCity),
              const SizedBox(height: 10),
              _LocationPickerTile(
                  step: '2', label: 'filter_phase'.tr(), value: _phase,
                  placeholder: _city == null
                      ? 'placeholder_select_city_first'.tr()
                      : 'placeholder_select_phase'.tr(),
                  enabled: _city != null,
                  onTap: _city != null ? _pickPhase : null),
              const SizedBox(height: 10),
              _LocationPickerTile(
                  step: '3', label: 'filter_sector'.tr(), value: _sector,
                  placeholder: _phase == null
                      ? 'placeholder_select_phase_first'.tr()
                      : 'placeholder_select_sector'.tr(),
                  enabled: _phase != null,
                  onTap: _phase != null ? _pickSector : null),
              const SizedBox(height: 24),

              // ── Basic info ─────────────────────────────────────────
              _SectionLabel('section_basic_info'.tr()),
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(labelText: 'field_title'.tr()),
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'error_title_required'.tr() : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionController,
                maxLines: 4,
                decoration: InputDecoration(
                    labelText: 'field_description_optional'.tr()),
              ),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _propertyType,
                    decoration: InputDecoration(
                        labelText: 'field_property_type'.tr()),
                    items: _propertyTypes
                        .map((t) => DropdownMenuItem(
                            value: t,
                            child: Text(_propertyTypeLabel(t))))
                        .toList(),
                    onChanged: (v) => setState(() => _propertyType = v!),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _purpose,
                    decoration:
                        InputDecoration(labelText: 'field_purpose'.tr()),
                    items: [
                      DropdownMenuItem(value: 'sale', child: Text('badge_for_sale'.tr())),
                      DropdownMenuItem(value: 'rent', child: Text('badge_for_rent'.tr())),
                    ],
                    onChanged: (v) => setState(() => _purpose = v!),
                  ),
                ),
              ]),
              const SizedBox(height: 24),

              // ── Price & size ───────────────────────────────────────
              _SectionLabel('section_price_size'.tr()),
              TextFormField(
                controller: _priceController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration:
                    InputDecoration(labelText: 'field_price_pkr'.tr()),
                validator: (v) =>
                    (v == null || double.tryParse(v) == null)
                        ? 'error_valid_price'.tr()
                        : null,
              ),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _areaSizeController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration:
                        InputDecoration(labelText: 'field_area_size'.tr()),
                    validator: (v) =>
                        (v == null || v.isEmpty) ? 'error_required'.tr() : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _areaUnit,
                    decoration: InputDecoration(labelText: 'field_unit'.tr()),
                    items: _areaUnits
                        .map((u) => DropdownMenuItem(
                            value: u, child: Text(u)))
                        .toList(),
                    onChanged: (v) => setState(() => _areaUnit = v!),
                  ),
                ),
              ]),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                  child: TextFormField(
                    controller: _bedsController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                        labelText: 'field_bedrooms_optional'.tr()),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _bathsController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                        labelText: 'field_bathrooms_optional'.tr()),
                  ),
                ),
              ]),
              const SizedBox(height: 24),

              // ── Error ──────────────────────────────────────────────
              if (_errorMessage != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.07),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: AppColors.error.withValues(alpha: 0.35)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.error_outline_rounded,
                          color: AppColors.error, size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(_errorMessage!,
                            style: const TextStyle(
                                color: AppColors.error,
                                fontSize: 13,
                                fontWeight: FontWeight.w500)),
                      ),
                    ],
                  ),
                ),

              // ── Submit ─────────────────────────────────────────────
              ElevatedButton(
                onPressed: _submitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(52)),
                child: _submitting
                    ? const SizedBox(
                        height: 20, width: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : Text(widget.isEditMode
                        ? 'btn_save_changes'.tr()
                        : 'btn_post_listing'.tr()),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Video picker tile ─────────────────────────────────────────────────
class _VideoPickerTile extends StatelessWidget {
  final XFile? pickedVideo;
  final String? existingVideoUrl;
  final String? error;
  final VoidCallback onPick;
  final VoidCallback onRemove;

  const _VideoPickerTile({
    required this.pickedVideo,
    required this.existingVideoUrl,
    required this.error,
    required this.onPick,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final hasVideo = pickedVideo != null || existingVideoUrl != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: hasVideo ? null : onPick,
          child: Container(
            height: 70,
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: error != null
                    ? AppColors.error
                    : hasVideo
                        ? AppColors.primary
                        : AppColors.divider,
              ),
            ),
            child: hasVideo
                ? Row(
                    children: [
                      const SizedBox(width: 16),
                      Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.primarySurface,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.videocam_rounded,
                            color: AppColors.primary, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          pickedVideo != null
                              ? pickedVideo!.name
                              : 'existing_video_attached'.tr(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: AppColors.primary),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded,
                            color: AppColors.error, size: 20),
                        onPressed: onRemove,
                        tooltip: 'tooltip_remove_video'.tr(),
                      ),
                    ],
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.add_circle_outline_rounded,
                          color: AppColors.textSecondary, size: 20),
                      const SizedBox(width: 8),
                      Text('add_video_hint'.tr(),
                          style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13)),
                    ],
                  ),
          ),
        ),
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 4),
            child: Text(error!,
                style: const TextStyle(
                    fontSize: 12, color: AppColors.error)),
          ),
      ],
    );
  }
}

// ── Photo picker ──────────────────────────────────────────────────────
class _PhotoPicker extends StatelessWidget {
  final List<XFile>  images;
  final List<String> existingUrls;
  final VoidCallback onAdd;
  final ValueChanged<int> onRemoveNew;

  const _PhotoPicker({
    required this.images,
    required this.existingUrls,
    required this.onAdd,
    required this.onRemoveNew,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 90,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          // Existing API images (read-only in edit mode)
          ...existingUrls.map((url) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(url,
                      width: 90, height: 90, fit: BoxFit.cover),
                ),
              )),
          // Newly picked images (can remove)
          ...images.asMap().entries.map((entry) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(File(entry.value.path),
                          width: 90, height: 90, fit: BoxFit.cover),
                    ),
                    Positioned(
                      top: 2, right: 2,
                      child: GestureDetector(
                        onTap: () => onRemoveNew(entry.key),
                        child: Container(
                          decoration: const BoxDecoration(
                              color: Colors.black54,
                              shape: BoxShape.circle),
                          child: const Icon(Icons.close_rounded,
                              color: Colors.white, size: 16),
                        ),
                      ),
                    ),
                    if (entry.key == 0 && existingUrls.isEmpty)
                      Positioned(
                        bottom: 4, left: 4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 5, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text('badge_cover'.tr(),
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 9)),
                        ),
                      ),
                  ],
                ),
              )),
          // Add button (hidden when limit reached)
          if (existingUrls.length + images.length < 10)
            GestureDetector(
              onTap: onAdd,
              child: Container(
                width: 90, height: 90,
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.divider),
                  borderRadius: BorderRadius.circular(8),
                  color: AppColors.surfaceVariant,
                ),
                child: const Icon(Icons.add_a_photo_outlined,
                    color: AppColors.textSecondary),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Location picker tile ──────────────────────────────────────────────
class _LocationPickerTile extends StatelessWidget {
  final String step, label;
  final String? value, placeholder;
  final bool enabled;
  final VoidCallback? onTap;

  const _LocationPickerTile({
    required this.step, required this.label,
    required this.value, required this.placeholder,
    required this.enabled, this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasValue = value != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: hasValue ? AppColors.primary : AppColors.divider,
            width: hasValue ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 26, height: 26,
              decoration: BoxDecoration(
                color: hasValue ? AppColors.primary : AppColors.divider,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: hasValue
                    ? const Icon(Icons.check_rounded,
                        color: Colors.white, size: 14)
                    : Text(step,
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: enabled
                                ? AppColors.textPrimary
                                : AppColors.textHint)),
              ),
            ),
            const SizedBox(width: 12),
            Text(label,
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w500)),
            const Spacer(),
            Text(
              value ?? placeholder!,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight:
                      hasValue ? FontWeight.w600 : FontWeight.w400,
                  color: hasValue
                      ? AppColors.primary
                      : AppColors.textHint),
            ),
            const SizedBox(width: 6),
            Icon(
              hasValue
                  ? Icons.arrow_drop_down_rounded
                  : Icons.chevron_right_rounded,
              size: 20,
              color: enabled ? AppColors.primary : AppColors.textHint,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Picker bottom sheet ───────────────────────────────────────────────
class _PickerSheet extends StatefulWidget {
  final String title;
  final List<String> items;
  final String? current;
  const _PickerSheet({required this.title, required this.items, required this.current});

  @override
  State<_PickerSheet> createState() => _PickerSheetState();
}

class _PickerSheetState extends State<_PickerSheet> {
  String _query = '';
  List<String> get _filtered => _query.isEmpty
      ? widget.items
      : widget.items
          .where((i) => i.toLowerCase().contains(_query.toLowerCase()))
          .toList();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.75),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36, height: 4,
            margin: const EdgeInsets.only(top: 12, bottom: 16),
            decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2)),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(widget.title,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w700)),
            ),
          ),
          if (widget.items.length > 6)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: TextField(
                autofocus: false,
                decoration: InputDecoration(
                  hintText: 'common_search_hint'.tr(),
                  prefixIcon: const Icon(Icons.search_rounded, size: 20),
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  isDense: true,
                  fillColor: AppColors.background,
                ),
                onChanged: (v) => setState(() => _query = v),
              ),
            ),
          Flexible(
            child: ListView.builder(
              padding: const EdgeInsets.only(bottom: 24),
              shrinkWrap: true,
              itemCount: _filtered.length,
              itemBuilder: (context, index) {
                final item = _filtered[index];
                final isSelected = item == widget.current;
                return Container(
                  color: isSelected ? AppColors.primarySurface : null,
                  child: ListTile(
                    dense: true,
                    title: Text(item,
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.w400,
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.textPrimary)),
                    trailing: isSelected
                        ? const Icon(Icons.check_circle_rounded,
                            color: AppColors.primary, size: 20)
                        : null,
                    onTap: () => Navigator.of(context).pop(item),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text,
            style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary)),
      );
}
