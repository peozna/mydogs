import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../../../core/error/app_exception.dart';
import '../../../core/network/api_client.dart';

class LocalGalleryStorage {
  LocalGalleryStorage(this._dio);

  final Dio _dio;

  /// Downloads the image from [url] and saves it locally using [imageId] in the file name.
  ///
  /// Returns the absolute local file path on success.
  /// Throws [ImageDownloadException] if the download or file write fails.
  Future<String> saveImage(String imageId, String url) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      // Ensure the directory exists
      final dogsDir = Directory(p.join(directory.path, 'mydogs'));
      if (!await dogsDir.exists()) {
        await dogsDir.create(recursive: true);
      }

      final fileName = 'dog_$imageId.jpg';
      final localPath = p.join(dogsDir.path, fileName);

      // Download file bytes using Dio
      final response = await _dio.get<List<int>>(
        url,
        options: Options(responseType: ResponseType.bytes),
      );

      final bytes = response.data;
      if (bytes == null || bytes.isEmpty) {
        throw const ImageDownloadException();
      }

      // Write bytes to the file
      final file = File(localPath);
      await file.writeAsBytes(bytes, flush: true);

      return file.path;
    } on DioException catch (e) {
      throw ImageDownloadException(cause: e);
    } catch (e) {
      if (e is AppException) rethrow;
      throw StorageException(cause: e);
    }
  }

  /// Deletes the local image file at [path], if it exists.
  ///
  /// Throws [StorageException] if deletion fails.
  Future<void> deleteImage(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      throw StorageException(cause: e);
    }
  }
}

final localGalleryStorageProvider = Provider<LocalGalleryStorage>((ref) {
  final dio = ref.watch(dioProvider);
  return LocalGalleryStorage(dio);
});
