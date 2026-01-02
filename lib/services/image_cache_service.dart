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
    void Function(double)? onProgress,
  }) async {
    final client = http.Client();
    try {
      final file = await _localFile(mediaId);
      final request = http.Request('GET', Uri.parse(url));
      if (headers != null) request.headers.addAll(headers);

      final response = await client.send(request);

      if (response.statusCode == 200) {
        final totalBytes = response.contentLength ?? 0;
        int receivedBytes = 0;

        final sink = file.openWrite();
        await response.stream.listen((chunk) {
          sink.add(chunk);
          receivedBytes += chunk.length;
          if (onProgress != null && totalBytes > 0) {
            onProgress(receivedBytes / totalBytes);
          }
        }).asFuture();

        await sink.flush();
        await sink.close();
        return file;
      }
      return null;
    } catch (e) {
      return null;
    } finally {
      client.close();
    }
  }
}
