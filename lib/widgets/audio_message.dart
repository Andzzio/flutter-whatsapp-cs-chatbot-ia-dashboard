import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:boty_flutter/services/api_service.dart';
import 'package:boty_flutter/providers/chat_provider.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class AudioMessage extends StatefulWidget {
  final String mediaId;
  const AudioMessage({super.key, required this.mediaId});

  @override
  State<AudioMessage> createState() => _AudioMessageState();
}

class _AudioMessageState extends State<AudioMessage> {
  final player = AudioPlayer();
  bool isPlaying = false;
  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    return isLoading
        ? SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : IconButton(
            icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow),
            onPressed: () async {
              if (isPlaying) {
                await player.pause();
                setState(() => isPlaying = false);
              } else {
                setState(() => isLoading = true);
                try {
                  // 1. Descargar el archivo con headers
                  final token = Provider.of<ChatProvider>(
                    context,
                    listen: false,
                  ).apiToken;
                  final url =
                      "${ApiService.baseUrl}/api/media/${widget.mediaId}/";
                  final response = await http.get(
                    Uri.parse(url),
                    headers: {"Authorization": token},
                  );

                  if (response.statusCode == 200) {
                    // 2. Guardar en temporal
                    final dir = await getTemporaryDirectory();
                    final file = File(
                      '${dir.path}/${widget.mediaId}.aac',
                    ); // Asumimos aac o mp3
                    await file.writeAsBytes(response.bodyBytes);

                    // 3. Reproducir archivo local
                    await player.play(DeviceFileSource(file.path));
                    setState(() => isPlaying = true);

                    // Escuchar cuando termine
                    player.onPlayerComplete.listen((event) {
                      if (mounted) setState(() => isPlaying = false);
                    });
                  } else {
                    debugPrint(
                      "Error descargando audio: ${response.statusCode}",
                    );
                  }
                } catch (e) {
                  debugPrint("Error reproduciendo audio: $e");
                } finally {
                  if (mounted) setState(() => isLoading = false);
                }
              }
            },
          );
  }

  @override
  void dispose() {
    player.dispose();
    super.dispose();
  }
}
