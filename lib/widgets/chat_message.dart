import 'package:boty_flutter/widgets/audio_message.dart';
import 'package:boty_flutter/services/api_service.dart';
import 'package:boty_flutter/widgets/video_message.dart';
import 'package:boty_flutter/providers/chat_provider.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import '../models/message.dart';

class ChatMessage extends StatelessWidget {
  final Message message;
  const ChatMessage({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final alignment = message.isBot
        ? Alignment.centerLeft
        : Alignment.centerRight;
    final color = message.isBot ? Colors.grey[300] : Color(0xFFDCF8C6);
    final textColor = Colors.black;

    final token = Provider.of<ChatProvider>(context, listen: false).apiToken;

    return Align(
      alignment: alignment,
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        padding: EdgeInsets.all(12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width,
        ),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(12),
            topRight: Radius.circular(12),
            bottomLeft: message.isBot ? Radius.zero : Radius.circular(12),
            bottomRight: message.isBot ? Radius.circular(12) : Radius.zero,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (message.type == "image" && message.mediaId != null)
              Image.network(
                "${ApiService.baseUrl}/api/media/${message.mediaId}/",
                headers: {"Authorization": token},
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    width: 200,
                    height: 200,
                    color: Colors.grey[200],
                    child: Center(child: CircularProgressIndicator()),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 200,
                    height: 200,
                    color: Colors.grey[300],
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.broken_image, color: Colors.grey),
                        Text(
                          "Error cargando imagen",
                          style: TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  );
                },
              )
            else if (message.type == "audio" && message.mediaId != null)
              AudioMessage(mediaId: message.mediaId!)
            else if (message.type == "video" && message.mediaId != null)
              VideoMessage(mediaId: message.mediaId!)
            else
              Text(
                message.text,
                style: TextStyle(color: textColor, fontSize: 16),
              ),
            SizedBox(height: 4),
            Text(
              message.time,
              style: TextStyle(color: Colors.black54, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }
}
