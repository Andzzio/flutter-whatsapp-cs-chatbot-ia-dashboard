import 'dart:io';
import 'package:boty_flutter/models/contact.dart';
import 'package:boty_flutter/providers/chat_provider.dart';
import 'package:boty_flutter/widgets/chat_message.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:boty_flutter/services/api_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

class ChatScreen extends StatefulWidget {
  final Contact contact;
  const ChatScreen({super.key, required this.contact});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _textController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Marcar como leídos al entrar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ChatProvider>(
        context,
        listen: false,
      ).markAsRead(widget.contact.phone);
    });
  }

  Future<void> _pickAndSendMedia() async {
    showModalBottomSheet(
      context: context,
      builder: (context) => Wrap(
        children: [
          ListTile(
            leading: Icon(Icons.image),
            title: Text('Imagen (Galería)'),
            onTap: () => _processMedia(ImageSource.gallery, 'image'),
          ),
          ListTile(
            leading: Icon(Icons.videocam),
            title: Text('Video (Galería)'),
            onTap: () => _processMedia(ImageSource.gallery, 'video'),
          ),
          ListTile(
            leading: Icon(Icons.audiotrack),
            title: Text('Audio (Archivos)'),
            onTap: () => _processFile('audio'),
          ),
        ],
      ),
    );
  }

  Future<void> _processMedia(ImageSource source, String type) async {
    Navigator.pop(context);
    final picker = ImagePicker();
    final XFile? file = await picker.pickImage(source: source);

    if (file != null) {
      _uploadFile(File(file.path), type);
    }
  }

  Future<void> _processFile(String type) async {
    Navigator.pop(context);
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.audio,
    );

    if (result != null) {
      _uploadFile(File(result.files.single.path!), type);
    }
  }

  Future<void> _uploadFile(File file, String type) async {
    // Mostrar indicador de carga
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text("Subiendo archivo...")));

    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse(
          "${ApiService.baseUrl}/api/contacts/${widget.contact.phone}/send-media/",
        ),
      );
      final token = Provider.of<ChatProvider>(context, listen: false).apiToken;
      request.headers['Authorization'] = token;
      request.fields['type'] = type;
      final mimeType = _getMimeType(file.path);
      request.files.add(
        await http.MultipartFile.fromPath(
          'file',
          file.path,
          contentType: mimeType,
        ),
      );

      var response = await request.send();
      if (response.statusCode == 200) {
        debugPrint("Archivo enviado con éxito");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Enviado con éxito"),
              backgroundColor: Colors.green,
            ),
          );
          Provider.of<ChatProvider>(context, listen: false).refreshContacts();
        }
      } else {
        debugPrint("Error al enviar archivo: ${response.statusCode}");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Error al enviar"),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint("Excepción al subir: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error de conexión"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  MediaType? _getMimeType(String path) {
    final ext = path.split('.').last.toLowerCase();
    switch (ext) {
      case 'jpg':
      case 'jpeg':
        return MediaType('image', 'jpeg');
      case 'png':
        return MediaType('image', 'png');
      case 'mp4':
        return MediaType('video', 'mp4');
      case 'mp3':
        return MediaType('audio', 'mpeg');
      case 'aac':
        return MediaType('audio', 'aac');
      case 'ogg':
        return MediaType('audio', 'ogg');
      case 'wav':
        return MediaType('audio', 'wav');
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ChatProvider>(
      builder: (context, provider, child) {
        final currentContact = provider.contacts.firstWhere(
          (c) => c.phone == widget.contact.phone,
          orElse: () => widget.contact,
        );

        return Scaffold(
          appBar: AppBar(
            title: Text(currentContact.name),
            backgroundColor: Colors.blueAccent,
            foregroundColor: Colors.white,
            actions: [
              Switch(
                value: currentContact.isBotActive,
                activeTrackColor: Colors.greenAccent,
                onChanged: (value) {
                  Provider.of<ChatProvider>(
                    context,
                    listen: false,
                  ).toggleBot(currentContact.phone, value);
                },
              ),
            ],
          ),
          body: Column(
            children: [
              Expanded(
                child: ListView.builder(
                  reverse: true,
                  itemCount: currentContact.messages.length,
                  itemBuilder: (BuildContext context, int index) {
                    final msg = currentContact
                        .messages[currentContact.messages.length - 1 - index];
                    return ChatMessage(message: msg);
                  },
                ),
              ),
              Container(
                padding: EdgeInsets.all(8),
                color: Colors.white,
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.attach_file, color: Colors.grey),
                      onPressed: _pickAndSendMedia,
                    ),
                    Expanded(
                      child: TextField(
                        controller: _textController,
                        decoration: InputDecoration(
                          hintText: "Escribe un mensaje...",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(20)),
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 8),
                    IconButton(
                      onPressed: () {
                        final text = _textController.text.trim();
                        if (text.isNotEmpty) {
                          Provider.of<ChatProvider>(
                            context,
                            listen: false,
                          ).sendMessage(currentContact.phone, text);
                        }
                        _textController.clear();
                      },
                      icon: Icon(Icons.send, color: Colors.blueAccent),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
