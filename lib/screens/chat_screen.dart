import 'dart:io';
import 'package:boty_flutter/models/contact.dart';
import 'package:boty_flutter/models/message.dart';
import 'package:boty_flutter/models/snippet.dart';
import 'package:boty_flutter/providers/chat_provider.dart';
import 'package:boty_flutter/widgets/catalog_dialog.dart';
import 'package:boty_flutter/widgets/chat_message.dart';
import 'package:boty_flutter/widgets/crm_edit_dialog.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:boty_flutter/services/api_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:flutter/services.dart';

class ChatScreen extends StatefulWidget {
  final Contact contact;
  const ChatScreen({super.key, required this.contact});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  OverlayEntry? _overlayEntry;
  final LayerLink _layerLink = LayerLink();
  String _lastQuery = "";
  final Map<int, GlobalKey> _messageKeys = {};

  void _scrollToMessage(int messageId) {
    // Small delay to ensure frame is built if coming from outside
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final key = _messageKeys[messageId];
      if (key?.currentContext != null) {
        Scrollable.ensureVisible(
          key!.currentContext!,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          alignment: 0.5,
        );
      }
    });
  }

  Message? _replyToMessage;

  void _onSwipeToReply(Message message) {
    setState(() {
      _replyToMessage = message;
    });
    _focusNode.requestFocus();
  }

  void _cancelReply() {
    setState(() {
      _replyToMessage = null;
    });
  }

  Future<void> _sendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    Provider.of<ChatProvider>(
      context,
      listen: false,
    ).sendMessage(widget.contact.phone, text, replyToId: _replyToMessage?.id);

    _textController.clear();
    _cancelReply();
    _focusNode.requestFocus();
  }

  // ... (initState/dispose remain detailed above but skipping here for brevity in replacement if unchanged)
  // Logic to insert snippet overlay etc.

  // NOTE: Inserting the Reply Preview inside _buildInputArea
  Widget _buildInputArea(BuildContext context, Contact contact) {
    return Container(
      padding: const EdgeInsets.only(
        bottom: 24,
      ), // SafeArea handled by parent usually or padding.
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            offset: const Offset(0, -4),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_replyToMessage != null)
            Container(
              padding: const EdgeInsets.all(8),
              color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
              child: Row(
                children: [
                  const Icon(Icons.reply, size: 20, color: Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Respondiendo a ${_replyToMessage!.isBot ? 'Bot' : 'Cliente'}",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                        Text(
                          _replyToMessage!.text,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: _cancelReply,
                  ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: CompositedTransformTarget(
              link: _layerLink,
              child: Row(
                children: [
                  // ... (Icons and Input remain same)
                  IconButton(
                    icon: Icon(
                      Icons.attach_file_rounded,
                      color: Theme.of(context).hintColor,
                    ),
                    onPressed: _pickAndSendMedia,
                  ),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).scaffoldBackgroundColor,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Focus(
                        onKeyEvent: (node, event) {
                          final isDesktop =
                              Platform.isLinux ||
                              Platform.isWindows ||
                              Platform.isMacOS;
                          if (!isDesktop) return KeyEventResult.ignored;

                          if (event is KeyDownEvent &&
                              event.logicalKey == LogicalKeyboardKey.enter) {
                            if (HardwareKeyboard.instance.isShiftPressed)
                              return KeyEventResult.ignored;
                            _sendMessage();
                            return KeyEventResult.handled;
                          }
                          return KeyEventResult.ignored;
                        },
                        child: TextField(
                          controller: _textController,
                          focusNode: _focusNode,
                          textInputAction: TextInputAction.newline,
                          keyboardType: TextInputType.multiline,
                          maxLines: 4,
                          minLines: 1,
                          decoration: const InputDecoration(
                            hintText: "Escribe un mensaje...",
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: Icon(
                      Icons.shopping_bag_outlined,
                      color: Theme.of(context).primaryColor,
                    ),
                    tooltip: "Enviar producto del catálogo",
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => CatalogDialog(contact: contact),
                      );
                    },
                  ),
                  const SizedBox(width: 4),
                  Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.send_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                      onPressed: _sendMessage,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Update ListView Builder to wrap ChatMessage in Dismissible for Swipe Reply
  Widget _buildMessageList(Contact currentContact) {
    return ListView.builder(
      controller: _scrollController,
      reverse: true,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      itemCount: currentContact.messages.length,
      itemBuilder: (BuildContext context, int index) {
        final msg =
            currentContact.messages[currentContact.messages.length - 1 - index];
        final key = msg.id != null
            ? _messageKeys.putIfAbsent(msg.id!, () => GlobalKey())
            : null;

        return Dismissible(
          key: Key("msg_${msg.id}_${index}"), // Unique key
          direction: DismissDirection.startToEnd,
          confirmDismiss: (direction) async {
            _onSwipeToReply(msg);
            return false; // Don't actually dismiss
          },
          background: Container(
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.only(left: 20),
            color: Colors.transparent, // Or a subtle hint color
            child: Icon(Icons.reply, color: Theme.of(context).primaryColor),
          ),
          child: ChatMessage(
            key: key,
            message: msg,
            onReplyTap: _scrollToMessage,
          ),
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final chatProvider = Provider.of<ChatProvider>(context, listen: false);
      chatProvider.markAsRead(widget.contact.phone);
      chatProvider.setActiveChat(widget.contact.phone);
    });
    _textController.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    // Usamos el context con cuidado en dispose, pero para providers suele ser seguro si listen=false
    // Sin embargo, mejor hacerlo antes de super.dispose y try-catch por si acaso el widget fue desmontado de forma extraña,
    // o simplemente acceder al provider si tenemos referencia.
    // Una practica común es setear active chat a null.
    // Pero como no tenemos acceso facil a context en dispose de forma segura siempre...
    // Lo haremos en deactivate o simplemente confiamos en que al salir llamamos a setActiveChat(null) o al entrar a otro overwrite.
    // Mejor aún: deactivate es llamado cuando el widget se quita del tree.

    _removeSnippetOverlay();

    _textController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    // Intentar limpiar active chat si es posible, si no, confiamos en que salir de la pantalla lo hará
    // (Actually, no way to access context safely in dispose for Provider interactions typically without warnings).
    // Workaround: We can use a reference to provider saved in didChangeDependencies, but setActiveChat(null) is important.
    // Let's rely on WillPopScope or Navigator.pop callback... no, that's messy.
    // Let's use deactivate based on WidgetsBinding instance?
    // Let's just do it in deactivate().
    super.dispose();
  }

  @override
  void deactivate() {
    Provider.of<ChatProvider>(context, listen: false).setActiveChat(null);
    super.deactivate();
  }

  void _onTextChanged() {
    final text = _textController.text;
    if (text.startsWith("/") && text.length > 1) {
      _showSnippetOverlay(text);
    } else {
      _removeSnippetOverlay();
    }
  }

  void _showSnippetOverlay(String query) {
    // Si el query no cambió, evitando reconstrucciones innecesarias (ej. movimiento de cursor)
    if (_lastQuery == query && _overlayEntry != null) return;
    _lastQuery = query;

    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    final matches = chatProvider.snippets
        .where((s) => s.shortcut.startsWith(query))
        .toList();

    if (matches.isEmpty) {
      _removeSnippetOverlay();
      return;
    }

    if (_overlayEntry != null) {
      _overlayEntry!.remove();
    }

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        width: 300, // Fixed width or dynamic
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: const Offset(
            0,
            -150,
          ), // Move up. Should calculate based on list height ideally.
          // Better approach: Use Alignment.bottomLeft relative to input, but input grows.
          // Let's rely on offset for now or Alignment.
          // Alignment.bottomLeft of Follower aligns with Target's anchor.
          // We want the overlay ABOVE the input.
          // targetAnchor: Alignment.topLeft,
          // followerAnchor: Alignment.bottomLeft,
          targetAnchor: Alignment.topLeft,
          followerAnchor: Alignment.bottomLeft,

          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(12),
            color: Theme.of(context).cardColor,
            child: Container(
              constraints: const BoxConstraints(maxHeight: 200),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: matches.length,
                itemBuilder: (context, index) {
                  final snippet = matches[index];
                  return ListTile(
                    leading: const Icon(
                      Icons.flash_on,
                      size: 16,
                      color: Colors.orange,
                    ),
                    title: Text(
                      snippet.shortcut,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      snippet.content,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    onTap: () => _insertSnippet(snippet),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  void _removeSnippetOverlay() {
    if (_overlayEntry != null) {
      _overlayEntry!.remove();
      _overlayEntry = null;
    }
  }

  void _insertSnippet(Snippet snippet) {
    _textController.text = snippet.content;
    _textController.selection = TextSelection.fromPosition(
      TextPosition(offset: _textController.text.length),
    );
    _removeSnippetOverlay();
    _focusNode.requestFocus();
  }

  Future<void> _pickAndSendMedia() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: Icon(Icons.image, color: Theme.of(context).primaryColor),
              title: const Text('Imágenes (Galería)'),
              onTap: () => _pickFiles(FileType.image),
            ),
            ListTile(
              leading: Icon(
                Icons.videocam,
                color: Theme.of(context).primaryColor,
              ),
              title: const Text('Videos (Galería)'),
              onTap: () => _pickFiles(FileType.video),
            ),
            ListTile(
              leading: Icon(
                Icons.audiotrack,
                color: Theme.of(context).primaryColor,
              ),
              title: const Text('Audios (Archivos)'),
              onTap: () => _pickFiles(FileType.audio),
            ),
            ListTile(
              leading: Icon(
                Icons.attach_file,
                color: Theme.of(context).primaryColor,
              ),
              title: const Text('Cualquier Archivo'),
              onTap: () => _pickFiles(FileType.any),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickFiles(FileType type) async {
    Navigator.pop(context);
    List<File> filesToUpload = [];

    try {
      // Estrategia híbrida: ImagePicker para imágenes en Móvil (mejor UI), FilePicker para el resto
      bool isMobile = Platform.isAndroid || Platform.isIOS;

      if (isMobile && type == FileType.image) {
        final picker = ImagePicker();
        final List<XFile> images = await picker.pickMultiImage();
        if (images.isNotEmpty) {
          filesToUpload = images.map((x) => File(x.path)).toList();
        }
      } else {
        // Uso de FilePicker para Desktop y otros tipos en móvil (Videos/Audio multiple)
        FilePickerResult? result = await FilePicker.platform.pickFiles(
          type: type,
          allowMultiple: true,
        );
        if (result != null) {
          filesToUpload = result.paths
              .where((path) => path != null)
              .map((path) => File(path!))
              .toList();
        }
      }

      // Subir archivos seleccionados
      for (var file in filesToUpload) {
        // Determinar tipo string para backend basado en extensión si es 'any' o el tipo pasado
        String uploadType = _mapFileTypeToString(type, file.path);
        _uploadFile(file, uploadType);
      }
    } catch (e) {
      debugPrint("Error seleccionando archivos: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error al seleccionar archivos: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _mapFileTypeToString(FileType type, String path) {
    if (type == FileType.image) return 'image';
    if (type == FileType.video) return 'video';
    if (type == FileType.audio) return 'audio';

    // Inferencia simple por extensión para FileType.any
    final ext = path.split('.').last.toLowerCase();
    if (['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(ext)) return 'image';
    if (['mp4', 'mov', 'avi', 'mkv'].contains(ext)) return 'video';
    if (['mp3', 'wav', 'aac', 'ogg', 'm4a'].contains(ext)) return 'audio';
    return 'document'; // Fallback
  }

  Future<void> _uploadFile(File file, String type) async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text("Subiendo archivo..."),
        backgroundColor: Theme.of(context).primaryColor,
      ),
    );

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
        if (mounted) {
          Provider.of<ChatProvider>(context, listen: false).refreshContacts();
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Error al enviar"),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
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
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: AppBar(
            backgroundColor: Theme.of(context).colorScheme.surface,
            elevation: 1,
            shadowColor: Colors.black.withValues(alpha: 0.05),
            leading: IconButton(
              icon: Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Theme.of(context).iconTheme.color,
              ),
              onPressed: () => Navigator.pop(context),
            ),
            title: Row(
              children: [
                CircleAvatar(
                  backgroundColor: Theme.of(context).primaryColor,
                  child: Text(
                    currentContact.name[0].toUpperCase(),
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        currentContact.name,
                        style: TextStyle(
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        currentContact.phone,
                        style: TextStyle(
                          color: Theme.of(context).textTheme.bodySmall?.color,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.info_outline_rounded),
                color: Theme.of(context).primaryColor,
                tooltip: "Información del cliente (CRM)",
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) =>
                        CrmEditDialog(contact: currentContact),
                  );
                },
              ),
              IconButton(
                icon: Icon(
                  currentContact.isMuted
                      ? Icons.notifications_off_rounded
                      : Icons.notifications_active_rounded,
                  color: currentContact.isMuted
                      ? Colors.grey
                      : Theme.of(context).primaryColor,
                ),
                tooltip: currentContact.isMuted
                    ? "Activar notificaciones"
                    : "Silenciar notificaciones",
                onPressed: () {
                  provider.toggleContactMute(currentContact.phone);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        !currentContact
                                .isMuted // Valor invertido porque se acaba de cambiar
                            ? "Notificaciones activadas"
                            : "Contacto silenciado",
                      ),
                      duration: const Duration(seconds: 1),
                    ),
                  );
                },
              ),
              IconButton(
                icon: Icon(
                  Icons.copy_rounded,
                  color: Theme.of(context).primaryColor,
                ),
                tooltip: "Copiar número",
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: currentContact.phone));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Número copiado: ${currentContact.phone}"),
                      backgroundColor: Theme.of(context).primaryColor,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
              ),
              Container(
                margin: const EdgeInsets.only(right: 16, left: 8),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: currentContact.isBotActive
                      ? Colors.green.withValues(alpha: 0.1)
                      : Colors.grey.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: currentContact.isBotActive
                        ? Colors.green.withValues(alpha: 0.3)
                        : Colors.grey.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.smart_toy_rounded,
                      size: 16,
                      color: currentContact.isBotActive
                          ? Colors.green
                          : Colors.grey,
                    ),
                    const SizedBox(width: 4),
                    Switch(
                      value: currentContact.isBotActive,
                      activeColor: Colors.green,
                      activeTrackColor: Colors.green.withValues(alpha: 0.2),
                      inactiveThumbColor: Colors.grey,
                      inactiveTrackColor: Colors.grey.withValues(alpha: 0.2),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      onChanged: (value) {
                        provider.toggleBot(currentContact.phone, value);
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          body: Column(
            children: [
              Expanded(child: _buildMessageList(currentContact)),
              _buildInputArea(context, currentContact),
            ],
          ),
        );
      },
    );
  }
}
