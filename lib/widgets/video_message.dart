import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:boty_flutter/services/api_service.dart';
import 'package:boty_flutter/providers/chat_provider.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';

class VideoMessage extends StatefulWidget {
  final String mediaId;
  const VideoMessage({super.key, required this.mediaId});

  @override
  State<VideoMessage> createState() => _VideoMessageState();
}

class _VideoMessageState extends State<VideoMessage> {
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;
  bool _isInitialized = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // No inicializamos el video aquí para evitar congelar la UI si hay muchos videos
  }

  Future<void> _initializeVideo() async {
    setState(() {
      _isLoading = true;
    });

    final token = Provider.of<ChatProvider>(context, listen: false).apiToken;
    try {
      _videoController = VideoPlayerController.networkUrl(
        Uri.parse("${ApiService.baseUrl}/api/media/${widget.mediaId}/"),
        httpHeaders: {"Authorization": token},
      );
      await _videoController!.initialize();
      _chewieController = ChewieController(
        videoPlayerController: _videoController!,
        autoPlay: true,
        looping: false,
        errorBuilder: (context, errorMessage) {
          return Center(
            child: Text(errorMessage, style: TextStyle(color: Colors.white)),
          );
        },
      );
      if (mounted) {
        setState(() {
          _isInitialized = true;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error inicializando video: $e");
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error cargando video")));
      }
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        height: 200,
        width: 200,
        color: Colors.black12,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_isInitialized && _chewieController != null) {
      return SizedBox(
        height: 200,
        width: 200,
        child: Chewie(controller: _chewieController!),
      );
    }

    return GestureDetector(
      onTap: _initializeVideo,
      child: Container(
        height: 200,
        width: 200,
        color: Colors.black87,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.play_circle_fill, color: Colors.white, size: 50),
              SizedBox(height: 8),
              Text("Ver Video", style: TextStyle(color: Colors.white)),
            ],
          ),
        ),
      ),
    );
  }
}
