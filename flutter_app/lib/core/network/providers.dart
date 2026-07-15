import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dio_client.dart';
import 'token_storage.dart';

/// Single shared TokenStorage instance — every part of the app that needs
/// to read/write tokens goes through this one provider.
final tokenStorageProvider = Provider<TokenStorage>((_) => TokenStorage());

/// Single shared authenticated Dio instance — every repository uses this
/// instead of creating its own Dio, so the JWT interceptor applies everywhere.
final dioProvider = Provider<Dio>((ref) {
  final storage = ref.watch(tokenStorageProvider);
  return DioClient(storage).dio;
});
