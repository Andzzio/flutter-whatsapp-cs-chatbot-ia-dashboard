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
import 'package:boty_flutter/widgets/order_bottom_sheet.dart';
import 'package:boty_flutter/widgets/order_drawer.dart';
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

  // Upload progress tracking
  int _uploadingCount = 0;
  int _uploadedCount = 0;
  int _totalToUpload = 0;
  final FocusNode _focusNode = FocusNode();

  OverlayEntry? _overlayEntry;
  final LayerLink _layerLink = LayerLink();
  final Map<int, GlobalKey> _messageKeys = {};
  bool _isBotToggling = false;

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
    return NotificationListener<ScrollNotification>(
      onNotification: (scrollInfo) {
        // With reverse: true, maxScrollExtent corresponds to the "top" of the visual list (oldest messages)
        // Check if we are close to the edge (e.g. 200 pixels away)
        if (scrollInfo.metrics.pixels >=
            scrollInfo.metrics.maxScrollExtent - 200) {
          // Debounce slightly or just call provider (provider should handle concurrency or just let it replace)
          // For simplicity in this iteration, we call it. A boolean _isLoadingMore could be added to state to prevent spam.
          // However, Provider call is async.
          // We'll trust the provider/API speed or add a simple check.
          // Actually, let's keep it simple.
          Provider.of<ChatProvider>(
            context,
            listen: false,
          ).loadMoreMessages(currentContact.phone);
        }
        return false;
      },
      child: ListView.builder(
        controller: _scrollController,
        reverse: true,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        itemCount:
            currentContact.messages.length +
            1, // +1 for loading indicator at top
        itemBuilder: (BuildContext context, int index) {
          // Extra item at the end (top visually) for spacing/spinner
          if (index == currentContact.messages.length) {
            return const SizedBox(
              height: 20,
            ); // Placeholder for potential spinner
          }

          final msg = currentContact
              .messages[currentContact.messages.length - 1 - index];
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
      ),
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
    // Mostrar overlay inmediatamente al escribir "/"
    if (text.startsWith("/")) {
      _showSnippetOverlay(text);
    } else {
      _removeSnippetOverlay();
    }
  }

  void _showSnippetOverlay(String query) {
    // Remover overlay existente SIEMPRE para reconstruir con datos filtrados
    if (_overlayEntry != null) {
      _overlayEntry!.remove();
      _overlayEntry = null;
    }

    final chatProvider = Provider.of<ChatProvider>(context, listen: false);

    // Quitar el "/" del query para comparar
    // Si query es "/hola", queryText será "hola"
    // Si query es "/", queryText será ""
    final queryText = query.substring(1).toLowerCase();

    // Si solo escribió "/", mostrar TODOS los snippets
    // Si escribió más (ej. "/e"), filtrar por los que empiezan con "e"
    final matches = queryText.isEmpty
        ? chatProvider
              .snippets // Mostrar todos si solo es "/"
        : chatProvider.snippets.where((s) {
            // Normalizar el shortcut del snippet (quitar "/" si lo tiene)
            final shortcut = s.shortcut.startsWith('/')
                ? s.shortcut.substring(1).toLowerCase()
                : s.shortcut.toLowerCase();
            return shortcut.startsWith(queryText);
          }).toList();

    if (matches.isEmpty) {
      return; // Ya removimos el overlay arriba
    }

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        width: MediaQuery.of(context).size.width - 32, // Ancho con padding
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          // El overlay debe aparecer ARRIBA del TextField
          // targetAnchor: bottom left del TextField
          // followerAnchor: bottom left del overlay (para que se alinee arriba)
          targetAnchor: Alignment.topLeft,
          followerAnchor: Alignment.bottomLeft,
          offset: const Offset(0, -8), // Pequeño gap entre overlay y input

          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(12),
            color: Theme.of(context).cardColor,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight:
                    MediaQuery.of(context).size.height *
                    0.4, // Máximo 40% de la pantalla
                minHeight: 50,
              ),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: matches.length,
                itemBuilder: (context, index) {
                  final snippet = matches[index];
                  return InkWell(
                    onTap: () => _insertSnippet(snippet),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.flash_on,
                            size: 18,
                            color: Colors.orange[600],
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  snippet.shortcut.startsWith('/')
                                      ? snippet.shortcut
                                      : '/${snippet.shortcut}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  snippet.content,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
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

      // Upload files with batch progress
      if (filesToUpload.isNotEmpty) {
        setState(() {
          _totalToUpload = filesToUpload.length;
          _uploadedCount = 0;
          _uploadingCount = 0;
        });

        for (var file in filesToUpload) {
          String uploadType = _mapFileTypeToString(type, file.path);
          _uploadFile(file, uploadType);
        }
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
    setState(() {
      _uploadingCount++;
    });

    // Show batch progress only once
    if (_uploadingCount == 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Subiendo $_totalToUpload archivo(s)..."),
          backgroundColor: Theme.of(context).primaryColor,
          duration: const Duration(seconds: 2),
        ),
      );
    }

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

      setState(() {
        _uploadedCount++;
      });

      if (response.statusCode == 200) {
        if (mounted) {
          Provider.of<ChatProvider>(context, listen: false).refreshContacts();

          // Show success when all done
          if (_uploadedCount == _totalToUpload) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text("✅ $_uploadedCount archivo(s) enviado(s)"),
                backgroundColor: Colors.green,
              ),
            );
          }
        }
      } else {
        if (mounted && _uploadedCount == _totalToUpload) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                "⚠️ $_uploadedCount/$_totalToUpload enviados (algunos fallaron)",
              ),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint("Upload error: $e");
      setState(() {
        _uploadedCount++;
      });

      if (mounted && _uploadedCount == _totalToUpload) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("❌ Error: $_uploadedCount/$_totalToUpload enviados"),
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

  String _getStateLabel(String state) {
    switch (state) {
      case 'initial':
        return 'Inicial';
      case 'browsing_catalog':
        return 'Viendo Catálogo';
      case 'product_selection':
        return 'Seleccionando';
      case 'confirm_cart':
        return 'Carrito';
      case 'collect_address':
        return 'Dirección';
      case 'select_payment':
        return 'Pago';
      case 'upload_proof':
        return 'Comprobante';
      case 'completed':
        return 'Completado';
      case 'locked_human':
        return 'HUMANO';
      default:
        return state;
    }
  }

  Color _getStateColor(String state) {
    if (state == 'locked_human') return Colors.red;
    if (state == 'completed') return Colors.green;
    if (state == 'initial') return Colors.grey;
    return Colors.blue;
  }

  bool _showDesktopDrawer = false;

  @override
  Widget build(BuildContext context) {
    return Consumer<ChatProvider>(
      builder: (context, provider, child) {
        final currentContact = provider.contacts.firstWhere(
          (c) => c.phone == widget.contact.phone,
          orElse: () => widget.contact,
        );

        final size = MediaQuery.of(context).size;
        final isDesktop = size.width > 900;

        // Auto-close drawer if screen becomes small
        if (!isDesktop && _showDesktopDrawer) {
          _showDesktopDrawer = false;
        }

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

                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 8.0,
                        runSpacing: 4.0,
                        children: [
                          Text(
                            currentContact.phone,
                            style: TextStyle(
                              color: Theme.of(
                                context,
                              ).textTheme.bodySmall?.color,
                              fontSize: 12,
                            ),
                          ),
                          if (currentContact.currentState != 'initial')
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 1,
                              ),
                              decoration: BoxDecoration(
                                color: _getStateColor(
                                  currentContact.currentState,
                                ).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                  color: _getStateColor(
                                    currentContact.currentState,
                                  ).withOpacity(0.5),
                                  width: 0.5,
                                ),
                              ),
                              child: Text(
                                _getStateLabel(
                                  currentContact.currentState,
                                ).toUpperCase(),
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: _getStateColor(
                                    currentContact.currentState,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              // Order Button
              IconButton(
                icon: Icon(
                  Icons.receipt_long,
                  color: _showDesktopDrawer
                      ? Colors.blueAccent
                      : Colors.grey[700],
                ),
                tooltip: "Crear Pedido (Mini-POS)",
                onPressed: () {
                  if (isDesktop) {
                    setState(() {
                      _showDesktopDrawer = !_showDesktopDrawer;
                    });
                  } else {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (ctx) =>
                          OrderBottomSheet(contactPhone: currentContact.phone),
                    );
                  }
                },
              ),
              // Bot Toggle
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                child: _isBotToggling
                    ? const Padding(
                        padding: EdgeInsets.all(12.0),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.green,
                            ),
                          ),
                        ),
                      )
                    : Switch(
                        value: currentContact.isBotActive,
                        activeColor: Colors.green,
                        activeTrackColor: Colors.green.withOpacity(0.2),
                        inactiveThumbColor: Colors.grey,
                        inactiveTrackColor: Colors.grey.withOpacity(0.2),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        onChanged: (value) async {
                          setState(() {
                            _isBotToggling = true;
                          });
                          await provider.toggleBot(currentContact.phone, value);
                          if (mounted) {
                            setState(() {
                              _isBotToggling = false;
                            });
                          }
                        },
                      ),
              ),
              // More Actions Menu
              PopupMenuButton<String>(
                icon: Icon(
                  Icons.more_vert_rounded,
                  color: Theme.of(context).primaryColor,
                ),
                onSelected: (value) {
                  if (value == 'crm') {
                    showDialog(
                      context: context,
                      builder: (context) =>
                          CrmEditDialog(contact: currentContact),
                    );
                  } else if (value == 'mute') {
                    provider.toggleContactMute(currentContact.phone);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          !currentContact.isMuted
                              ? "Notificaciones activadas"
                              : "Contacto silenciado",
                        ),
                        duration: const Duration(seconds: 1),
                      ),
                    );
                  } else if (value == 'copy') {
                    Clipboard.setData(
                      ClipboardData(text: currentContact.phone),
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          "Número copiado: ${currentContact.phone}",
                        ),
                        backgroundColor: Theme.of(context).primaryColor,
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  } else if (value == 'reset_memory' ||
                      value == 'reset_state') {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: Text(
                          value == 'reset_state'
                              ? "Reiniciar Estado"
                              : "Borrar Memoria",
                        ),
                        content: Text(
                          value == 'reset_state'
                              ? "Esto devolverá el bot al estado INICIAL si se quedó trabado. (También borra el historial temporal)."
                              : "Esto borrará TODO el historial de mensajes con este contacto.",
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text("Cancelar"),
                          ),
                          TextButton(
                            onPressed: () async {
                              Navigator.pop(ctx);
                              // We use the same API for now as it does both
                              final success = await provider.resetContactMemory(
                                currentContact.phone,
                              );
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      success
                                          ? "Estado Reiniciado Correctamente."
                                          : "Error al reiniciar.",
                                    ),
                                    backgroundColor: success
                                        ? Colors.green
                                        : Colors.red,
                                  ),
                                );
                              }
                            },
                            child: const Text(
                              "Confirmar",
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                },
                itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                  const PopupMenuItem<String>(
                    value: 'crm',
                    child: ListTile(
                      leading: Icon(Icons.info_outline_rounded),
                      title: Text('Ver Información (CRM)'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  PopupMenuItem<String>(
                    value: 'mute',
                    child: ListTile(
                      leading: Icon(
                        currentContact.isMuted
                            ? Icons.notifications_off_rounded
                            : Icons.notifications_active_rounded,
                      ),
                      title: Text(
                        currentContact.isMuted
                            ? 'Activar Notificaciones'
                            : 'Silenciar',
                      ),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  const PopupMenuItem<String>(
                    value: 'copy',
                    child: ListTile(
                      leading: Icon(Icons.copy_rounded),
                      title: Text('Copiar Número'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  const PopupMenuItem<String>(
                    value: 'reset_memory',
                    child: ListTile(
                      leading: Icon(
                        Icons.cleaning_services_rounded,
                        color: Colors.red,
                      ),
                      title: Text(
                        'Borrar Memoria (Reset)',
                        style: TextStyle(color: Colors.red),
                      ),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  const PopupMenuItem<String>(
                    value: 'reset_state',
                    child: ListTile(
                      leading: Icon(
                        Icons.settings_backup_restore_rounded,
                        color: Colors.orange,
                      ),
                      title: Text(
                        'Reiniciar Estado (Bot)',
                        style: TextStyle(color: Colors.orange),
                      ),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
            ],
          ),
          body: Row(
            children: [
              Expanded(
                flex: 6,
                child: Column(
                  children: [
                    Expanded(child: _buildMessageList(currentContact)),
                    _buildInputArea(context, currentContact),
                  ],
                ),
              ),
              if (isDesktop && _showDesktopDrawer)
                VerticalDivider(width: 1, color: Colors.grey[200]),
              if (isDesktop && _showDesktopDrawer)
                Expanded(
                  flex: 4,
                  child: OrderDrawer(contactPhone: currentContact.phone),
                ),
            ],
          ),
        );
      },
    );
  }
}
