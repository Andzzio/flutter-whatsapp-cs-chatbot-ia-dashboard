import 'dart:io';
import 'package:flutter/material.dart';
import '../services/image_cache_service.dart';

class CachedImageBubble extends StatefulWidget {
  final String imageUrl;
  final String mediaId;
  final Map<String, String>? authHeaders;
  final void Function(File)? onTap;

  const CachedImageBubble({
    super.key,
    required this.imageUrl,
    required this.mediaId,
    this.authHeaders,
    this.onTap,
  });

  @override
  State<CachedImageBubble> createState() => _CachedImageBubbleState();
}

class _CachedImageBubbleState extends State<CachedImageBubble> {
  final ImageCacheService _cacheService = ImageCacheService();
  File? _imageFile;
  bool _isLoading = true;
  bool _isDownloading = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _checkCache();
  }

  Future<void> _checkCache() async {
    final file = await _cacheService.getCachedImage(widget.mediaId);
    if (mounted) {
      setState(() {
        _imageFile = file;
        _isLoading = false;
      });
    }
  }

  Future<void> _downloadImage() async {
    setState(() {
      _isDownloading = true;
      _hasError = false;
    });

    final file = await _cacheService.downloadImage(
      widget.imageUrl,
      widget.mediaId,
      headers: widget.authHeaders,
    );

    if (mounted) {
      setState(() {
        _imageFile = file;
        _isDownloading = false;
        _hasError = file == null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        width: 200,
        height: 200,
        color: Colors.grey[200],
        child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    // Estado: Imagen ya descargada (Mostrar imagen)
    if (_imageFile != null) {
      return GestureDetector(
        onTap: () {
          if (widget.onTap != null && _imageFile != null) {
            widget.onTap!(_imageFile!);
          }
        },
        child: Hero(
          tag: "image_${widget.mediaId}",
          child: Image.file(
            _imageFile!,
            width: 200,
            height: 200,
            fit: BoxFit.cover,
          ),
        ),
      );
    }

    // Estado: No descargada (Mostrar botón de descarga)
    return Container(
      width: 200,
      height: 200,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Icono de fondo sutil
          Icon(Icons.image_outlined, size: 60, color: Colors.grey[300]),

          // Contenido central interactivo
          if (_isDownloading)
            const CircularProgressIndicator(
              strokeWidth: 3,
              color: Colors.purple,
            )
          else
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_hasError)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 8.0),
                    child: Text(
                      "Error",
                      style: TextStyle(color: Colors.red, fontSize: 12),
                    ),
                  ),
                ElevatedButton.icon(
                  onPressed: _downloadImage,
                  icon: Icon(
                    _hasError ? Icons.refresh : Icons.download_rounded,
                    size: 20,
                  ),
                  label: Text(_hasError ? "Reintentar" : "Descargar"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.purple,
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
                if (!_hasError)
                  const Padding(
                    padding: EdgeInsets.only(top: 8.0),
                    child: Text(
                      "JPG • Toca para ver",
                      style: TextStyle(color: Colors.grey, fontSize: 11),
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}
