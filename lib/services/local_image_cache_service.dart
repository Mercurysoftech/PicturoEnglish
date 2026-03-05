import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:dio/dio.dart';

class LocalImageCacheService {
  static final Dio _dio = Dio();

  static Future<String> _getCacheDir() async {
    final dir = await getApplicationDocumentsDirectory();
    final cacheDir = Directory('${dir.path}/avatar_cache');
    if (!await cacheDir.exists()) {
      await cacheDir.create(recursive: true);
    }
    return cacheDir.path;
  }

  static Future<String> _getLocalFilePath(String imageUrl) async {
    final cacheDir = await _getCacheDir();
    final fileName = imageUrl.split('/').last;
    return '$cacheDir/$fileName';
  }

  static Future<File> getImageFile(String imageUrl) async {
    final filePath = await _getLocalFilePath(imageUrl);
    final file = File(filePath);

    if (await file.exists()) {
      return file;
    }

    try {
      final response = await _dio.get(
        imageUrl,
        options: Options(responseType: ResponseType.bytes),
      );
      await file.writeAsBytes(response.data);
      return file;
    } catch (e) {
      throw Exception('Failed to download image: $e');
    }
  }

  // Clear all cached avatars (optional)
  static Future<void> clearCache() async {
    final cacheDir = Directory(await _getCacheDir());
    if (await cacheDir.exists()) {
      await cacheDir.delete(recursive: true);
    }
  }
}
