import 'package:boty_flutter/widgets/audio_message.dart';
import 'dart:convert';
import 'package:boty_flutter/widgets/full_screen_image.dart';
import 'package:boty_flutter/widgets/video_message.dart';
import 'package:boty_flutter/services/api_service.dart';
import 'package:boty_flutter/providers/chat_provider.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import '../models/message.dart';

class ChatMessage extends StatelessWidget {
  final Message message;
  final Function(int)? onReplyTap;
  const ChatMessage({super.key, required this.message, this.onReplyTap});

  @override
  Widget build(BuildContext context) {
    // Definir alineación y colores según el emisor
    final isBot = message.isBot;
    final alignment = isBot ? Alignment.centerLeft : Alignment.centerRight;

    // Obtener colores del tema
    final theme = Theme.of(context);
    final sentColor = theme.primaryColor.withValues(alpha: 0.2);
    final receivedColor = theme.colorScheme.surfaceContainerHighest;
    final bubbleColor = isBot ? receivedColor : sentColor;

    final textColor = theme.textTheme.bodyLarge?.color ?? Colors.black;
    final timeColor = theme.textTheme.bodySmall?.color ?? Colors.grey;

    final token = Provider.of<ChatProvider>(context, listen: false).apiToken;

    return Align(
      alignment: alignment,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
        padding: const EdgeInsets.all(12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: bubbleColor,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: isBot ? Radius.zero : const Radius.circular(16),
            bottomRight: isBot ? const Radius.circular(16) : Radius.zero,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (message.replyTo != null)
              GestureDetector(
                onTap: () {
                  if (onReplyTap != null) {
                    onReplyTap!(message.replyTo!.id);
                  }
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border(
                      left: BorderSide(color: theme.primaryColor, width: 4),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        message.replyTo!.senderName,
                        style: TextStyle(
                          color: theme.primaryColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          if (message.replyTo!.type == 'image' &&
                              message.replyTo!.mediaId != null)
                            Container(
                              width: 40,
                              height: 40,
                              margin: const EdgeInsets.only(right: 8),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(4),
                                color: Colors.grey[200],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: Image.network(
                                  "${ApiService.baseUrl}/api/media/${message.replyTo!.mediaId}",
                                  headers: {"Authorization": token},
                                  fit: BoxFit.cover,
                                  errorBuilder: (ctx, error, stackTrace) =>
                                      const Center(
                                        child: Icon(
                                          Icons.broken_image,
                                          size: 16,
                                          color: Colors.grey,
                                        ),
                                      ),
                                ),
                              ),
                            )
                          else if (message.replyTo!.type == 'image')
                            const Padding(
                              padding: EdgeInsets.only(right: 4),
                              child: Icon(
                                Icons.camera_alt,
                                size: 16,
                                color: Colors.grey,
                              ),
                            ),
                          Expanded(
                            child: Text(
                              message.replyTo!.type == 'image'
                                  ? (message.replyTo!.text.isNotEmpty
                                        ? message.replyTo!.text
                                        : "Foto")
                                  : message.replyTo!.text,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors
                                    .grey[800], // Color más oscuro para mejor contraste
                                height: 1.2,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            if (message.type == "image" && message.mediaId != null)
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => FullScreenImage(
                        imageUrl:
                            "${ApiService.baseUrl}/api/media/${message.mediaId}/",
                        headers: {"Authorization": token},
                        heroTag: "image_${message.mediaId}",
                      ),
                    ),
                  );
                },
                child: Hero(
                  tag: "image_${message.mediaId}",
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: 300,
                        maxHeight: 400,
                      ),
                      child: Image.network(
                        "${ApiService.baseUrl}/api/media/${message.mediaId}/",
                        headers: {"Authorization": token},
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            width: 200,
                            height: 200,
                            color: Colors.black12,
                            child: const Center(
                              child: CircularProgressIndicator(),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: 200,
                            height: 200,
                            color: Colors.grey[300],
                            child: const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.broken_image, color: Colors.grey),
                                Text("Error", style: TextStyle(fontSize: 12)),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              )
            else if (message.type == "audio" && message.mediaId != null)
              AudioMessage(mediaId: message.mediaId!)
            else if (message.type == "video" && message.mediaId != null)
              VideoMessage(mediaId: message.mediaId!)
            else if (message.type == "product" ||
                (message.type == "text" &&
                    message.text.contains("*Bot envió productos")))
              Builder(
                builder: (context) {
                  String? imageUrl;
                  String? price;

                  if (message.caption != null && message.caption!.isNotEmpty) {
                    try {
                      final data = jsonDecode(message.caption!);
                      imageUrl = data['image_url'];
                      price = data['price'];
                    } catch (e) {
                      // Caption no es JSON
                    }
                  }

                  return Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.pinkAccent.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(8),
                            image: imageUrl != null && imageUrl.isNotEmpty
                                ? DecorationImage(
                                    image: NetworkImage(imageUrl),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                          ),
                          child: imageUrl == null || imageUrl.isEmpty
                              ? const Icon(
                                  Icons.shopping_bag,
                                  color: Colors.pinkAccent,
                                )
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Flexible(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                message.text
                                    .replaceAll("*", "")
                                    .replaceAll(
                                      "Bot envió productos",
                                      "Producto Enviado",
                                    ),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                  fontSize: 14,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (price != null)
                                Text(
                                  price,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.green,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              Text(
                                "ID: ${message.mediaId ?? 'N/A'}",
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              )
            else if (message.type == "catalog_message" ||
                (message.type == "text" &&
                    message.text.contains("*Bot envió el catálogo*")))
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.purple.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.storefront_rounded, color: Colors.purple),
                    const SizedBox(width: 8),
                    const Text(
                      "Catálogo Completo Enviado",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              )
            else if (message.type == "product_list" ||
                (message.type == "text" &&
                    message.text.contains(
                      "*Bot envió una lista de productos*",
                    )))
              Builder(
                builder: (context) {
                  List<dynamic> sections = [];
                  if (message.caption != null && message.caption!.isNotEmpty) {
                    try {
                      sections = jsonDecode(message.caption!);
                    } catch (e) {
                      // Caption no es JSON válido o es texto plano antiguo
                    }
                  }

                  return Container(
                    padding: const EdgeInsets.all(12),
                    constraints: const BoxConstraints(maxWidth: 280),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.deepPurple.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.list_alt_rounded,
                              color: Colors.deepPurple,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              "Lista de Productos",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.deepPurple,
                              ),
                            ),
                          ],
                        ),
                        if (sections.isNotEmpty) ...[
                          const Divider(),
                          ...sections.expand<Widget>((section) {
                            final rows = section['product_items'] as List;
                            return rows.map<Widget>((item) {
                              String id = item['product_retailer_id'] ?? '';
                              String name = item['name'] ?? id;
                              String? imageUrl = item['image_url'];
                              String? price = item['price'];

                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 4.0,
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: Colors.grey[100],
                                        borderRadius: BorderRadius.circular(4),
                                        image:
                                            imageUrl != null &&
                                                imageUrl.isNotEmpty
                                            ? DecorationImage(
                                                image: NetworkImage(imageUrl),
                                                fit: BoxFit.cover,
                                              )
                                            : null,
                                      ),
                                      child:
                                          imageUrl == null || imageUrl.isEmpty
                                          ? const Icon(
                                              Icons.shopping_bag_outlined,
                                              size: 20,
                                              color: Colors.grey,
                                            )
                                          : null,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            name,
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          if (price != null)
                                            Text(
                                              price,
                                              style: const TextStyle(
                                                fontSize: 10,
                                                color: Colors.green,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            });
                          }),
                        ] else
                          const Text(
                            "Ver detalles en WhatsApp",
                            style: TextStyle(fontSize: 10, color: Colors.grey),
                          ),
                      ],
                    ),
                  );
                },
              )
            else if (message.type == "contact_message" ||
                (message.type == "text" &&
                    message.text.contains(
                      "*Bot envió el contacto registrado*",
                    )))
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.blueAccent.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.person_pin_circle_rounded,
                      color: Colors.blueAccent,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      "Contacto Enviado",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              )
            else if (message.type == "button_message" ||
                (message.type == "text" &&
                    message.text.contains("*Bot envió los botones")))
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.orange.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.touch_app_rounded, color: Colors.orange),
                    const SizedBox(width: 8),
                    const Flexible(
                      child: Text(
                        "Menú de Opciones Enviado",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              )
            else if (message.type == "image_message" ||
                (message.type == "text" &&
                    message.text.contains("*Bot envió una imagen*")))
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.teal.withValues(alpha: 0.2)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.image_rounded, color: Colors.teal),
                    const SizedBox(width: 8),
                    const Text(
                      "Imagen Enviada por Bot",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              )
            else
              Text(
                message.text,
                style: TextStyle(color: textColor, fontSize: 16),
              ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  message.time,
                  style: TextStyle(color: timeColor, fontSize: 10),
                ),
                if (message.isPending) ...[
                  const SizedBox(width: 4),
                  Icon(Icons.access_time_rounded, size: 10, color: timeColor),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
