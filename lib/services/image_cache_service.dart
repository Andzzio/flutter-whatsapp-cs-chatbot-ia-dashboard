import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class ImageCacheService {
  static final ImageCacheService _instance = ImageCacheService._internal();

  factory ImageCacheService() {
    return _instance;
  }

  ImageCacheService._internal();

  Future<String> _localPath() async {
    final directory = await getApplicationDocumentsDirectory();
    final mediaDir = Directory(p.join(directory.path, 'boty_media'));
    if (!await mediaDir.exists()) {
      await mediaDir.create(recursive: true);
    }
    return mediaDir.path;
  }

  Future<File> _localFile(String mediaId) async {
    final path = await _localPath();
    return File(p.join(path, '$mediaId.jpg')); // Assuming JPG for simplicity
  }

  Future<bool> isImageCached(String mediaId) async {
    try {
      final file = await _localFile(mediaId);
      return await file.exists();
    } catch (e) {
      return false;
    }
  }

  Future<File?> getCachedImage(String mediaId) async {
    try {
      final file = await _localFile(mediaId);
      if (await file.exists()) {
        return file;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<File?> downloadImage(
    String url,
    String mediaId, {
    Map<String, String>? headers,
  }) async {
    try {
      final file = await _localFile(mediaId);
      final response = await http.get(Uri.parse(url), headers: headers);

      if (response.statusCode == 200) {
        await file.writeAsBytes(response.bodyBytes);
        return file;
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }
}
