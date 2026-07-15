import 'dart:io';
import 'package:dio/dio.dart';
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
        title: 'Select City', items: dhaCities, current: _city);
    if (chosen != null) {
      setState(() { _city = chosen; _phase = null; _sector = null; });
    }
  }

  Future<void> _pickPhase() async {
    if (_city == null) return;
    final chosen = await _showPicker(
        title: 'Select Phase — $_city',
        items: getPhasesForCity(_city!),
        current: _phase);
    if (chosen != null) setState(() { _phase = chosen; _sector = null; });
  }

  Future<void> _pickSector() async {
    if (_city == null || _phase == null) return;
    final chosen = await _showPicker(
        title: 'Select Sector — $_phase',
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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Maximum 10 photos already added')));
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
      setState(() => _videoError =
          'Video exceeds 25 MB (${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB). '
          'Please pick a smaller file.');
      return;
    }
    setState(() => _pickedVideo = video);
  }

  void _removeVideo() => setState(() => _pickedVideo = null);

  // ── Submit ────────────────────────────────────────────────────────
  Future<void> _submit() async {
    setState(() => _errorMessage = null);
    if (!_formKey.currentState!.validate()) return;
    if (_city == null || _phase == null || _sector == null) {
      setState(() => _errorMessage = 'Please select City, Phase and Sector.');
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

        // Upload any newly added images
        for (int i = 0; i < _pickedImages.length; i++) {
          await repo.uploadImage(
              propertyId: widget.editProperty!.id,
              filePath: _pickedImages[i].path,
              isPrimary: false); // don't override the existing primary
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
                SnackBar(content: Text('Video: $e'),
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

        // Upload images (first one becomes the cover/primary)
        for (int i = 0; i < _pickedImages.length; i++) {
          await repo.uploadImage(
              propertyId: newId,
              filePath: _pickedImages[i].path,
              isPrimary: i == 0);
        }

        // Upload video if picked
        if (_pickedVideo != null) {
          try {
            await repo.uploadVideo(
                propertyId: newId, filePath: _pickedVideo!.path);
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Video: $e'),
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
              ? 'Listing updated successfully'
              : 'Property listed successfully'),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
        ));
        context.pop();
      }
    } on DioException catch (e) {
      String msg = 'Failed to save listing.';
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
                : 'Could not connect to server. Is it running?');
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
        title: Text(widget.isEditMode ? 'Edit listing' : 'Post a property'),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [

              // ── Photos (up to 10) ──────────────────────────────────
              const _SectionLabel('Photos (up to 10)'),
              _PhotoPicker(
                  images: _pickedImages,
                  existingUrls: widget.editProperty?.imageUrls ?? [],
                  onAdd: _pickImages,
                  onRemoveNew: (i) =>
                      setState(() => _pickedImages.removeAt(i))),
              const SizedBox(height: 16),

              // ── Video (1, max 25 MB) ───────────────────────────────
              const _SectionLabel('Video (1 video, max 25 MB)'),
              _VideoPickerTile(
                pickedVideo: _pickedVideo,
                existingVideoUrl: widget.editProperty?.videoUrl,
                error: _videoError,
                onPick: _pickVideo,
                onRemove: _removeVideo,
              ),
              const SizedBox(height: 24),

              // ── DHA Location ───────────────────────────────────────
              const _SectionLabel('DHA Location'),
              const Text(
                'Select the exact DHA location for your property.',
                style: TextStyle(
                    fontSize: 12, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 12),
              _LocationPickerTile(
                  step: '1', label: 'City', value: _city,
                  placeholder: 'Select city', enabled: true,
                  onTap: _pickCity),
              const SizedBox(height: 10),
              _LocationPickerTile(
                  step: '2', label: 'Phase', value: _phase,
                  placeholder: _city == null ? 'Select city first' : 'Select phase',
                  enabled: _city != null,
                  onTap: _city != null ? _pickPhase : null),
              const SizedBox(height: 10),
              _LocationPickerTile(
                  step: '3', label: 'Sector', value: _sector,
                  placeholder: _phase == null ? 'Select phase first' : 'Select sector',
                  enabled: _phase != null,
                  onTap: _phase != null ? _pickSector : null),
              const SizedBox(height: 24),

              // ── Basic info ─────────────────────────────────────────
              const _SectionLabel('Basic info'),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Title'),
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Title is required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionController,
                maxLines: 4,
                decoration: const InputDecoration(
                    labelText: 'Description (optional)'),
              ),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _propertyType,
                    decoration: const InputDecoration(
                        labelText: 'Property type'),
                    items: _propertyTypes
                        .map((t) => DropdownMenuItem(
                            value: t,
                            child: Text(
                                t[0].toUpperCase() + t.substring(1))))
                        .toList(),
                    onChanged: (v) => setState(() => _propertyType = v!),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _purpose,
                    decoration:
                        const InputDecoration(labelText: 'Purpose'),
                    items: const [
                      DropdownMenuItem(value: 'sale', child: Text('For sale')),
                      DropdownMenuItem(value: 'rent', child: Text('For rent')),
                    ],
                    onChanged: (v) => setState(() => _purpose = v!),
                  ),
                ),
              ]),
              const SizedBox(height: 24),

              // ── Price & size ───────────────────────────────────────
              const _SectionLabel('Price & size'),
              TextFormField(
                controller: _priceController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration:
                    const InputDecoration(labelText: 'Price (PKR)'),
                validator: (v) =>
                    (v == null || double.tryParse(v) == null)
                        ? 'Enter a valid price'
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
                        const InputDecoration(labelText: 'Area size'),
                    validator: (v) =>
                        (v == null || v.isEmpty) ? 'Required' : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _areaUnit,
                    decoration: const InputDecoration(labelText: 'Unit'),
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
                    decoration: const InputDecoration(
                        labelText: 'Bedrooms (optional)'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _bathsController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                        labelText: 'Bathrooms (optional)'),
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
                        ? 'Save changes'
                        : 'Post listing'),
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
                              : 'Existing video attached',
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
                        tooltip: 'Remove video',
                      ),
                    ],
                  )
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_circle_outline_rounded,
                          color: AppColors.textSecondary, size: 20),
                      SizedBox(width: 8),
                      Text('Add video (max 25 MB)',
                          style: TextStyle(
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
                          child: const Text('Cover',
                              style: TextStyle(
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
                decoration: const InputDecoration(
                  hintText: 'Search...',
                  prefixIcon: Icon(Icons.search_rounded, size: 20),
                  contentPadding: EdgeInsets.symmetric(vertical: 10),
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
