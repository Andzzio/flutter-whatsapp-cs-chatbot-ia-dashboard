import 'dart:async';
import 'package:boty_flutter/models/contact.dart';
import 'package:boty_flutter/models/message.dart';
import 'package:boty_flutter/models/snippet.dart';
import 'package:boty_flutter/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
// Message import removed (duplicate)
import 'package:boty_flutter/services/notification_service.dart';
import 'dart:convert';

enum ChatFilter { all, unread, botActive, botInactive, needsAttention }

class ChatProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  final NotificationService _notificationService = NotificationService();

  List<Contact> _contacts = [];
  String _apiToken = "";
  Timer? _syncTimer;
  ChatFilter _filter = ChatFilter.all;

  // Notification State
  bool _areNotificationsEnabled = true;
  String? _currentActiveChatPhone;
  // Cache local de muteados para persistencia: Phone -> isMuted
  Map<String, bool> _mutedContacts = {};

  List<Contact> get contacts {
    switch (_filter) {
      case ChatFilter.unread:
        return _contacts.where((c) => c.unreadCount > 0).toList();
      case ChatFilter.botActive:
        return _contacts.where((c) => c.isBotActive).toList();
      case ChatFilter.botInactive:
        return _contacts.where((c) => !c.isBotActive).toList();
      case ChatFilter.needsAttention:
        return _contacts.where((c) => c.needsHumanAttention).toList();
      case ChatFilter.all:
        return _contacts;
    }
  }

  String get apiToken => _apiToken;
  ChatFilter get filter => _filter;
  bool get areNotificationsEnabled => _areNotificationsEnabled;

  void setFilter(ChatFilter filter) {
    _filter = filter;
    notifyListeners();
  }

  ChatProvider() {
    _loadToken();
    _initNotifications();
  }

  Future<void> _initNotifications() async {
    await _notificationService.initialize();
  }

  Future<void> _loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    _apiToken = prefs.getString('api_token') ?? "";
    _areNotificationsEnabled = prefs.getBool('notifications_enabled') ?? true;

    // Cargar muteados
    final mutedString = prefs.getString('muted_contacts') ?? "{}";
    try {
      final decoded = json.decode(mutedString) as Map<String, dynamic>;
      _mutedContacts = decoded.map(
        (key, value) => MapEntry(key, value as bool),
      );
    } catch (e) {
      _mutedContacts = {};
    }

    await _loadSnippets();
    await _loadCrmData();

    notifyListeners();
    if (_apiToken.isNotEmpty) {
      _startSyncLoop();
    }
  }

  Future<void> setToken(String token) async {
    _apiToken = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('api_token', token);
    notifyListeners();
    _startSyncLoop();
  }

  void _startSyncLoop() {
    _syncTimer?.cancel();

    _sync();
    _syncTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      _sync();
    });
  }

  void setActiveChat(String? phone) {
    _currentActiveChatPhone = phone;
    // Si entramos a un chat, limpiamos su notificación visual o badge si fuera necesario
    // notifyListeners(); // No estrictamente necesario si no cambia UI dependiente de esto globalmente
  }

  Future<void> toggleGlobalNotifications(bool enabled) async {
    _areNotificationsEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_enabled', enabled);
    notifyListeners();
  }

  Future<void> toggleContactMute(String phone) async {
    final iscurrentlyMuted = _mutedContacts[phone] ?? false;
    _mutedContacts[phone] = !iscurrentlyMuted;

    // Actualizar en la lista en memoria
    final index = _contacts.indexWhere((c) => c.phone == phone);
    if (index != -1) {
      _contacts[index].isMuted = _mutedContacts[phone]!;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('muted_contacts', json.encode(_mutedContacts));
    notifyListeners();
  }

  Future<void> _sync() async {
    if (_apiToken.isEmpty) return;
    try {
      final newContacts = await _apiService.syncContacts(_apiToken);

      // Procesar notificaciones y estados locales
      for (var newContact in newContacts) {
        // Aplicar estado 'Muted' persistido
        if (_mutedContacts.containsKey(newContact.phone)) {
          newContact.isMuted = _mutedContacts[newContact.phone]!;
        }

        // Aplicar datos CRM persistidos
        if (_crmData.containsKey(newContact.phone)) {
          final data = _crmData[newContact.phone]!;
          newContact.notes = data['notes'] ?? "";
          // Ensure proper casting for list of strings
          newContact.tags = (data['tags'] as List)
              .map((e) => e.toString())
              .toList();
        }

        // Detectar nuevos mensajes para notificar
        // Comparamos con el estado anterior (_contacts)
        final oldContactIndex = _contacts.indexWhere(
          (c) => c.phone == newContact.phone,
        );

        if (oldContactIndex != -1) {
          final oldContact = _contacts[oldContactIndex];
          // Si hay más mensajes que antes
          if (newContact.messages.length > oldContact.messages.length) {
            // Obtener los ultimos mensajes nuevos
            // Verificamos el último mensaje
            final lastMsg = newContact.messages.last;

            // Lógica de Notificación:
            // 1. Notificaciones globales activadas
            // 2. Contacto NO muteado
            // 3. Contacto NO es el chat activo actualmente
            // 4. Mensaje NO es enviado por mi (pendiente o no) -> Asumimos we want to notify received messages.
            //    Model Message: 'user' field usually contains the name or identifier.
            //    Si es 'me' o isPending es true (nuestro optimista), no notificar.
            //    Mejor check: !lastMsg.isPending && ... ?
            //    Si el API devuelve 'user': 'ClientName', entonces es entrante.
            //    Si devuelve 'user': 'me' (o como lo maneje el backend), es saliente.
            //    Asumiremos que si msg.isBot == false, es del usuario (recibido por el bot).
            //    Wait, Message model: isBot: json["is_bot"].
            //    Si 'is_bot' es true, es mensaje DEL SISTEMA/BOT (o saliente).
            //    Si 'is_bot' es false, es mensaje DEL USUARIO (entrante).
            //    Queremos notificar mensajes DEL USUARIO (entrante).

            if (_areNotificationsEnabled &&
                !newContact.isMuted &&
                newContact.phone != _currentActiveChatPhone &&
                !lastMsg.isBot && // Es mensaje del usuario (entrante)
                !lastMsg
                    .isPending // No es un mensaje optimista nuestro
                    ) {
              // Solo notificar si es realmente reciente (para evitar spam al inicio)
              // (Opcional, pero Sync trae todo el historial cada vez, así que detectar diferencia es clave)

              _notificationService.showUserMessageNotification(
                newContact,
                lastMsg,
              );
            }
          }
        }
      }

      _contacts = newContacts;
      notifyListeners();
    } catch (e) {
      debugPrint("Error en provider: $e");
    }
  }

  Future<void> refreshContacts() async {
    await _sync();
  }

  @override
  void dispose() {
    _syncTimer?.cancel();
    super.dispose();
  }

  Future<void> sendMessage(String phone, String text, {int? replyToId}) async {
    if (_apiToken.isEmpty) return;

    // Optimistic UI Update
    final index = _contacts.indexWhere((c) => c.phone == phone);
    if (index != -1) {
      final now = DateTime.now();
      final timeStr =
          "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";

      // Find replied message object for optimistic update
      ReplyInfo? replyInfo;
      if (replyToId != null) {
        try {
          final repliedMsg = _contacts[index].messages.firstWhere(
            (m) => m.id == replyToId,
          );
          replyInfo = ReplyInfo(
            id: repliedMsg.id ?? 0,
            text: repliedMsg.text,
            type: repliedMsg.type,
            senderName: repliedMsg.user, // Or appropriate sender name
            mediaId: repliedMsg.mediaId,
          );
        } catch (e) {
          // Message not found in local list (rare but possible)
        }
      }

      final pendingMessage = Message(
        user: "me",
        text: text,
        time: timeStr,
        isBot: true,
        isPending: true,
        type: 'text',
        replyTo: replyInfo,
      );

      _contacts[index].messages.add(pendingMessage);
      // Actualizar timestamp manualmente para el sort inmediato
      _contacts[index].lastActivity = DateTime.now();

      // Mover al inicio de la lista
      final contactToMove = _contacts.removeAt(index);
      _contacts.insert(0, contactToMove);

      notifyListeners();
    }

    try {
      final success = await _apiService.sendMessage(
        _apiToken,
        phone,
        text,
        replyToId: replyToId,
      );
      if (success) {
        _sync();
      } else {
        _sync();
      }
    } catch (e) {
      debugPrint("Error sending message: $e");
      _sync();
    }
  }

  Future<void> deleteMessage(String phone, int msgId) async {
    if (_apiToken.isEmpty) return;

    // Optimistic Update
    final index = _contacts.indexWhere((c) => c.phone == phone);
    if (index != -1) {
      _contacts[index].messages.removeWhere((m) => m.id == msgId);
      notifyListeners();
    }

    try {
      final success = await _apiService.deleteMessage(_apiToken, msgId);
      if (!success) {
        // Revertir si falla (necesitaríamos mantener una copia o resync)
        _sync(); // Resync para asegurar consistencia
      }
    } catch (e) {
      _sync();
    }
  }

  Future<void> toggleBot(String phone, bool isActive) async {
    if (_apiToken.isEmpty) return;
    final success = await _apiService.toggleBot(_apiToken, phone, isActive);
    if (success) {
      final index = _contacts.indexWhere((c) => c.phone == phone);
      if (index != -1) {
        _contacts[index].isBotActive = isActive;
        notifyListeners();
      }
    }
  }

  Future<void> markAsRead(String phone) async {
    if (_apiToken.isEmpty) return;

    // Optimistic update
    final index = _contacts.indexWhere((c) => c.phone == phone);
    if (index != -1) {
      _contacts[index].unreadCount = 0;
      notifyListeners();
    }

    await _apiService.markMessagesAsRead(_apiToken, phone);
    // No need to sync immediately as the optimistic update handles the UI
    // The next periodic sync will confirm the state
  }

  // --- CRM Logic (Notes & Tags) ---
  // Map: Phone -> { 'notes': String, 'tags': List<String> }
  Map<String, Map<String, dynamic>> _crmData = {};

  Future<void> _loadCrmData() async {
    final prefs = await SharedPreferences.getInstance();
    final String? crmJson = prefs.getString('crm_data');
    if (crmJson != null) {
      try {
        final decoded = json.decode(crmJson) as Map<String, dynamic>;
        _crmData = decoded.map((key, value) {
          return MapEntry(key, Map<String, dynamic>.from(value));
        });
      } catch (e) {
        debugPrint("Error loading CRM data: $e");
        _crmData = {};
      }
    }
  }

  Future<void> _saveCrmData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('crm_data', json.encode(_crmData));
  }

  Future<void> updateContactCrm(
    String phone, {
    String? notes,
    List<String>? tags,
  }) async {
    if (!_crmData.containsKey(phone)) {
      _crmData[phone] = {'notes': '', 'tags': []};
    }

    if (notes != null) _crmData[phone]!['notes'] = notes;
    if (tags != null) _crmData[phone]!['tags'] = tags;

    // Actualizar en memoria
    final index = _contacts.indexWhere((c) => c.phone == phone);
    if (index != -1) {
      if (notes != null) _contacts[index].notes = notes;
      if (tags != null) _contacts[index].tags = tags;
      notifyListeners();
    }

    await _saveCrmData();
  }

  // --- Snippets Logic ---
  List<Snippet> _snippets = [];
  List<Snippet> get snippets => _snippets;

  Future<void> _loadSnippets() async {
    final prefs = await SharedPreferences.getInstance();
    final String? snippetsJson = prefs.getString('snippets');
    if (snippetsJson != null) {
      try {
        final List<dynamic> decoded = json.decode(snippetsJson);
        _snippets = decoded.map((item) => Snippet.fromJson(item)).toList();
      } catch (e) {
        debugPrint("Error loading snippets: $e");
        _snippets = [];
      }
    } else {
      // Default snippets
      _snippets = [
        Snippet(
          shortcut: "/hola",
          content: "Hola, ¿en qué puedo ayudarte hoy? 🌸",
        ),
        Snippet(
          shortcut: "/envio",
          content: "Realizamos envíos a todo el país. 🚚",
        ),
        Snippet(
          shortcut: "/pago",
          content: "Aceptamos Yape, Plin y Transferencia. 💳",
        ),
      ];
      _saveSnippets();
    }
  }

  Future<void> _saveSnippets() async {
    final prefs = await SharedPreferences.getInstance();
    final String encoded = json.encode(
      _snippets.map((s) => s.toJson()).toList(),
    );
    await prefs.setString('snippets', encoded);
  }

  Future<void> addSnippet(Snippet snippet) async {
    _snippets.add(snippet);
    await _saveSnippets();
    notifyListeners();
  }

  Future<void> removeSnippet(String shortcut) async {
    _snippets.removeWhere((s) => s.shortcut == shortcut);
    await _saveSnippets();
    notifyListeners();
  }

  Future<void> updateSnippet(String oldShortcut, Snippet newSnippet) async {
    final index = _snippets.indexWhere((s) => s.shortcut == oldShortcut);
    if (index != -1) {
      _snippets[index] = newSnippet;
      await _saveSnippets();
      notifyListeners();
    }
  }
}
