import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import '../domain/property_filter.dart';
import '../domain/property_model.dart';
/// Handles all real network calls for properties.
/// Every method catches DioException and rethrows a clean String
/// so the UI can display a friendly message rather than a stack trace.
class PropertyApiRepository {
  final Dio _dio;
  PropertyApiRepository(this._dio);

  /// GET /api/properties/ — filtered by whatever DhaFilter specifies.
  /// When no filter is active the API returns all properties, newest first.
  /// Falls back to an empty list on network error so the app doesn't crash
  /// when the server is not running.
  Future<List<PropertyModel>> getProperties(DhaFilter filter) async {
    try {
      final response = await _dio.get(
        '/properties/',
        queryParameters: filter.toQueryParams(),
      );

      // Django returns a plain list (no pagination configured)
      final list = response.data as List;

      // If user picked category = 'property' (house/flat), filter client-side
      // since the API doesn't support OR queries for property_type
      final results = list
          .map((item) =>
              PropertyModel.fromApiJson(item as Map<String, dynamic>))
          .where((p) {
        if (filter.category == 'property') {
          return p.propertyType == 'house' || p.propertyType == 'flat';
        }
        return true;
      }).toList();

      return results;
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout) {
        // Server not running — return empty list silently
        return [];
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  /// GET /api/properties/my_listings/ — the logged-in agent's own listings.
  /// Requires a valid JWT — the DioClient attaches it automatically.
  /// GET /api/properties/<id>/ — full detail including description and amenities.
  /// Returns null if the property doesn't exist or the server is unreachable.
  Future<PropertyModel?> getPropertyById(int id) async {
    try {
      final response = await _dio.get('/properties/$id/');
      return PropertyModel.fromApiJson(
          response.data as Map<String, dynamic>);
    } on DioException catch (_) {
      return null;
    } catch (_) {
      return null;
    }
  }

  /// POST /api/property-images/ — uploads one photo for a listing.
  /// [isPrimary] marks the first image as the cover shown on cards and the
  /// detail screen header. Pass true only for the first image in the loop.
  ///
  /// Throws a clean error String on failure — the caller decides whether
  /// to surface it and whether to keep uploading the rest (the listing
  /// itself is already saved either way, so a failed photo isn't fatal,
  /// but the caller should tell the user about it instead of it vanishing
  /// silently).
  Future<void> uploadImage({
    required int propertyId,
    required String filePath,
    bool isPrimary = false,
  }) async {
    try {
      final formData = FormData.fromMap({
        'property':   propertyId,
        'image':      await MultipartFile.fromFile(filePath),
        'is_primary': isPrimary.toString(),
      });
      await _dio.post('/property-images/', data: formData);
    } on DioException catch (e) {
      final data = e.response?.data;
      if (data is Map) {
        for (final v in data.values) {
          if (v is List && v.isNotEmpty) throw v.first.toString();
          if (v is String) throw v;
        }
      }
      throw 'error_image_upload_failed'.tr();
    }
  }

  /// POST /api/property-videos/ — uploads the video file (max 25 MB).
  /// Only 1 video allowed per listing — enforced on the server.
  Future<String?> uploadVideo({
    required int propertyId,
    required String filePath,
  }) async {
    try {
      final formData = FormData.fromMap({
        'property': propertyId,
        'video':    await MultipartFile.fromFile(filePath),
      });
      final response =
          await _dio.post('/property-videos/', data: formData);
      return response.data['id']?.toString();
    } on DioException catch (e) {
      final data = e.response?.data;
      if (data is Map) {
        for (final v in data.values) {
          if (v is List && v.isNotEmpty) throw v.first.toString();
          if (v is String) throw v;
        }
      }
      throw 'error_video_upload_failed'.tr();
    }
  }

  /// PATCH /api/properties/<id>/ — edit an existing listing's text fields.
  Future<void> updateProperty({
    required int id,
    required String title,
    required String description,
    required String propertyType,
    required String purpose,
    required String city,
    required String phase,
    required String sector,
    required String price,
    required String areaSize,
    required String areaUnit,
    int? beds,
    int? baths,
  }) async {
    try {
      await _dio.patch('/properties/$id/', data: {
        'title':         title,
        'description':   description,
        'property_type': propertyType,
        'purpose':       purpose,
        'city':          city,
        'phase':         phase,
        'sector':        sector,
        'price':         price,
        'area_size':     areaSize,
        'area_unit':     areaUnit,
        if (beds  != null) 'beds':  beds,
        if (baths != null) 'baths': baths,
      });
    } on DioException catch (e) {
      throw _parseError(e);
    }
  }

  /// DELETE /api/properties/<id>/ — permanently removes the listing and
  /// all its images and video (Django cascade handles the related rows).
  Future<void> deleteProperty(int id) async {
    try {
      await _dio.delete('/properties/$id/');
    } on DioException catch (e) {
      throw _parseError(e);
    }
  }

  Future<List<PropertyModel>> getMyListings() async {
    try {
      final response = await _dio.get('/properties/my_listings/');
      final list = response.data as List;
      return list
          .map((item) =>
              PropertyModel.fromApiJson(item as Map<String, dynamic>))
          .toList();
    } on DioException catch (_) {
      return [];
    } catch (_) {
      return [];
    }
  }

  String _parseError(DioException e) {
    final data = e.response?.data;
    if (data is Map) {
      for (final v in data.values) {
        if (v is List && v.isNotEmpty) return v.first.toString();
        if (v is String) return v;
      }
      if (data.containsKey('detail')) return data['detail'].toString();
    }
    switch (e.response?.statusCode) {
      case 400: return 'error_invalid_details_short'.tr();
      case 401: return 'error_not_authorised'.tr();
      case 403: return 'error_cannot_modify_listing'.tr();
      case 404: return 'error_listing_not_found'.tr();
      default:  return 'error_connection_short'.tr();
    }
  }
}
