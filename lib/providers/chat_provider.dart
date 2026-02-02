import 'dart:async';
import 'package:boty_flutter/models/contact.dart';
import 'package:boty_flutter/models/message.dart';
import 'package:boty_flutter/models/snippet.dart';
import 'package:boty_flutter/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
// Message import removed (duplicate)
import 'package:boty_flutter/services/notification_service.dart';
import 'package:boty_flutter/services/websocket_service.dart';
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

  // Dashboard Cache
  Map<String, dynamic>? _dashboardStats;
  Map<String, dynamic>? get dashboardStats => _dashboardStats;

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

    // 1. INSTANT LOAD: Cargar caché de contactos y dashboard
    await _loadFromCache();

    await _loadSnippets();
    await _loadCrmData();

    notifyListeners();
    if (_apiToken.isNotEmpty) {
      _startSyncLoop();
      // Agregar carga inmediata de Dashboard para resolver "Demora mucho"
      fetchDashboardStats(forceRefresh: true);
    }
  }

  Future<void> _loadFromCache() async {
    final prefs = await SharedPreferences.getInstance();

    // Stats Cache
    final statsString = prefs.getString('cached_dashboard_stats');
    if (statsString != null) {
      try {
        _dashboardStats = json.decode(statsString);
      } catch (e) {
        debugPrint("Error loading stats cache: $e");
      }
    }

    // Contacts Cache - EMERGENCY CLEAR due to freeze report
    await prefs.remove('cached_contacts');
    debugPrint("Contacts Cache CLEARED to resolve UI Freeze.");

    // final contactsString = prefs.getString('cached_contacts');
    // if (contactsString != null) {
    //   try {
    //     final List<dynamic> jsonList = json.decode(contactsString);
    //     _contacts = jsonList.map((c) => Contact.fromJson(c)).toList();
    //     debugPrint("Loaded ${_contacts.length} contacts from local cache.");
    //   } catch (e) {
    //     debugPrint("Error loading contacts cache: $e");
    //   }
    // }
  }

  Future<void> _saveToCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      if (_dashboardStats != null) {
        await prefs.setString(
          'cached_dashboard_stats',
          json.encode(_dashboardStats),
        );
      }

      if (_contacts.isNotEmpty) {
        // Serializamos manual o toMap. Contact no tiene toMap/toJson publico facil,
        // pero podemos re-usar la estructura que vino de la API si la tuvieramos,
        // o mapearlo.
        // Por simplicidad para este sprint, serializaremos el estado actual.
        // Necesitamos implementar un toJson en Contact o construirlo aquí.
        // Haremos un builder simple aquí para no tocar Contact aun.
        final contactsJson = _contacts
            .map(
              (c) => {
                "name": c.name,
                "phone": c.phone,
                "is_bot_active": c.isBotActive,
                "unread_count": c.unreadCount,
                "needs_human_attention": c.needsHumanAttention,
                "last_activity": c.lastActivity?.toIso8601String(),
                "tags": c.tags,
                // Guardamos historial solo parcial (ultimos 10) para no explotar cache
                "history": c.messages
                    .take(10)
                    .map(
                      (m) => {
                        "id": m.id,
                        "text": m.text,
                        "is_bot": m.isBot,
                        "time": m.time,
                        "type": m.type,
                        "media_id": m.mediaId,
                        "caption": m.caption,
                        "is_read": true, // Asumimos leido al guardar? No.
                      },
                    )
                    .toList(),
              },
            )
            .toList();

        await prefs.setString('cached_contacts', json.encode(contactsJson));
      }
    } catch (e) {
      print("Error saving to cache: $e");
    }
  }

  Future<void> setToken(String token) async {
    _apiToken = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('api_token', token);
    notifyListeners();
    _startSyncLoop();
    // Fetch inicial al loguearse
    fetchDashboardStats(forceRefresh: true);
  }

  Future<void> logout() async {
    _syncTimer?.cancel();
    _dashboardTimer?.cancel(); // Cancel dashboard timer
    _apiToken = "";
    _contacts = [];
    _dashboardStats = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('api_token', "");
    notifyListeners();
  }

  Timer? _dashboardTimer;

  WebSocketService? _wsService;

  void _startSyncLoop() {
    _syncTimer?.cancel();
    _dashboardTimer?.cancel(); // Reset both
    // 1. Initial Sync (Moved down slightly or kept here)
    // _channel cleanup replacing with service cleanup
    _wsService?.disconnect();

    // 1. Initial Sync
    _sync();

    // 2. WebSocket DISABLED (User Request) - Fallback to Polling Only
    /*
    _wsService = WebSocketService(ApiService.baseUrl);
    _wsService!.connect();
    // ... listeners commented out ...
    */

    // 3. Polling Only Mode (Every 5 seconds for better response)
    _syncTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _sync();
    });

    // START Dashboard Sync (Cada 60s) para resolver "No se actualizan nunca"
    _dashboardTimer = Timer.periodic(const Duration(seconds: 60), (timer) {
      if (_apiToken.isNotEmpty) {
        fetchDashboardStats(forceRefresh: true);
      }
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

  bool _isLoadingMoreContacts = false;
  bool _hasMoreContacts = true;
  int _remoteOffset = 0;

  Future<void> loadMoreContacts() async {
    if (_isLoadingMoreContacts || !_hasMoreContacts || _apiToken.isEmpty) {
      return;
    }

    _isLoadingMoreContacts = true;
    notifyListeners(); // Optional: Show loading spinner at bottom

    try {
      final moreContacts = await _apiService.syncContacts(
        _apiToken,
        offset: _remoteOffset,
        limit: 20,
      );

      if (moreContacts.isEmpty) {
        _hasMoreContacts = false;
        _isLoadingMoreContacts = false;
        notifyListeners();
        return;
      }

      // Avanzamos offset
      _remoteOffset += moreContacts.length;

      // Filtrar duplicados
      final currentIds = _contacts.map((c) => c.phone).toSet();
      final uniqueNew = moreContacts
          .where((c) => !currentIds.contains(c.phone))
          .toList();

      if (uniqueNew.isNotEmpty) {
        _contacts.addAll(uniqueNew);
      } else {
        // Si todos eran duplicados, quizás deberíamos intentar buscar la siguiente página
        // pero por seguridad simple, dejémoslo así o marquemos hasMore false si vino menos del limit.
        if (moreContacts.length < 20) {
          _hasMoreContacts = false;
        }
      }

      notifyListeners();
    } catch (e) {
      debugPrint("Error loading more contacts: $e");
    } finally {
      _isLoadingMoreContacts = false;
    }
  }

  Future<void> _sync() async {
    if (_apiToken.isEmpty) return;
    try {
      // Sync SIEMPRE trae la página 0 (Top 20 más recientes)
      final latestContacts = await _apiService.syncContacts(
        _apiToken,
        limit: 20,
        offset: 0,
      );

      // Reiniciar punteros de paginación
      _remoteOffset = 20;
      _hasMoreContacts = true; // Asumimos que puede haber más

      // Estrategia de Fusión (Smart Merge):
      // 1. Actualizar existentes (si cambiaron)
      // 2. Insertar nuevos al inicio
      // 3. Mantener los "viejos" que ya habíamos cargado con loadMore

      // Mapa para acceso rápido por teléfono
      final contactMap = {for (var c in _contacts) c.phone: c};

      for (var newC in latestContacts) {
        // Procesar estados locales (Muted, Tags, Notes) antes de merge
        if (_mutedContacts.containsKey(newC.phone)) {
          newC.isMuted = _mutedContacts[newC.phone]!;
        }
        if (_crmData.containsKey(newC.phone)) {
          final data = _crmData[newC.phone]!;
          newC.notes = data['notes'] ?? "";
          newC.tags = (data['tags'] as List).map((e) => e.toString()).toList();
        }

        // Detección de notificación (comparando con versión en memoria)
        if (contactMap.containsKey(newC.phone)) {
          final oldC = contactMap[newC.phone]!;
          if (newC.messages.isNotEmpty &&
              newC.messages.length > oldC.messages.length) {
            // Verificamos el último mensaje
            // api.py devuelve "messages": reversed(recent_messages), así que el último es el más reciente.
            final lastM = newC.messages.last;

            if (_areNotificationsEnabled &&
                !newC.isMuted &&
                newC.phone != _currentActiveChatPhone &&
                !lastM.isBot) {
              _notificationService.showUserMessageNotification(newC, lastM);
            }
          }
        }

        // Actualizar/Insertar en mapa
        contactMap[newC.phone] = newC;
      }

      // Reconstruir lista:
      // Queremos que latestContacts aparezcan PRIMERO y en SU ORDEN (reciente).
      // El resto de contactos (que no vinieron en page 0) se agregan después.

      final mergedList = <Contact>[];
      final processedPhones = <String>{};

      // 1. Agregar los del sync (top 20 reales)
      for (var c in latestContacts) {
        mergedList.add(
          contactMap[c.phone]!,
        ); // Usamos la versión procesada del mapa
        processedPhones.add(c.phone);
      }

      // 2. Agregar el resto que ya teníamos cargado (paginación previa)
      for (var c in _contacts) {
        if (!processedPhones.contains(c.phone)) {
          mergedList.add(c);
        }
      }

      _contacts = mergedList;
      notifyListeners();
      _saveToCache();
    } catch (e) {
      print("Sync error: $e");
    }
  }

  Future<Map<String, dynamic>> fetchDashboardStats({
    bool forceRefresh = false,
  }) async {
    if (_dashboardStats != null && !forceRefresh) {
      return _dashboardStats!;
    }

    if (_apiToken.isEmpty) return {};

    try {
      final stats = await _apiService.getDashboardStats(_apiToken);
      if (stats.isNotEmpty) {
        _dashboardStats = stats;
        notifyListeners();
        // Cache the fresh stats
        _saveToCache();
      }
      return stats;
    } catch (e) {
      debugPrint("Error fetching dashboard stats: $e");
      notifyListeners(); // IMPORTANTE: Notificar para quitar spinners aunque falle
      return _dashboardStats ?? {};
    }
  }

  Future<void> refreshContacts() async {
    await _sync();
  }

  @override
  void dispose() {
    _syncTimer?.cancel();
    _wsService?.dispose();
    super.dispose();
  }

  /*
  void _handleNewMessage(Map<String, dynamic> msgData) {
    debugPrint(
      "🔥 WS Optimized Event: ${msgData['phone']} - ${msgData['text']}",
    );

    final phone = msgData['phone'];
    final contactIndex = _contacts.indexWhere((c) => c.phone == phone);

    if (contactIndex != -1) {
      // 1. UPDATE EXISTING CONTACT
      final msg = Message(
        user: "Client", // Or name
        text: msgData['text'] ?? "",
        time: DateTime.now().toLocal().toString().substring(11, 16),
        isBot: false, // msgData['type'] logic needed if bot sends it
        type: msgData['type'] ?? 'text',
      );

      _contacts[contactIndex].messages.add(msg);
      _contacts[contactIndex].lastActivity = DateTime.now();
      _contacts[contactIndex].unreadCount += 1; // Increment unread

      // Move to top
      final contact = _contacts.removeAt(contactIndex);
      _contacts.insert(0, contact);
      notifyListeners();

      // Notification
      if (_areNotificationsEnabled &&
          !contact.isMuted &&
          contact.phone != _currentActiveChatPhone) {
        _notificationService.showUserMessageNotification(contact, msg);
      }
    } else {
      // 2. NEW CONTACT (Not in list) -> Fallback to Sync
      debugPrint("⚠️ New contact via WS, running full sync.");
      _sync();
    }
  }
  */

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

  Future<bool> resetContactMemory(String phone) async {
    if (_apiToken.isEmpty) return false;

    // Call API
    final success = await _apiService.resetMemory(_apiToken, phone);

    if (success) {
      // Optimistic Update: Clear local messages
      final index = _contacts.indexWhere((c) => c.phone == phone);
      if (index != -1) {
        _contacts[index] = Contact(
          name: _contacts[index].name,
          phone: _contacts[index].phone,
          messages: [], // Clear messages
          isBotActive: _contacts[index].isBotActive,
          isMuted: _contacts[index].isMuted,
          notes: _contacts[index].notes,
          tags: _contacts[index].tags,
          needsHumanAttention: _contacts[index].needsHumanAttention,
          unreadCount: 0,
          lastActivity: DateTime.now(),
        );
        notifyListeners();
      }
    }
    return success;
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
          id: 1,
          shortcut: "/hola",
          content: "Hola, ¿en qué puedo ayudarte hoy? 🌸",
        ),
        Snippet(
          id: 2,
          shortcut: "/envio",
          content: "Realizamos envíos a todo el país. 🚚",
        ),
        Snippet(
          id: 3,
          shortcut: "/pago",
          content: "Aceptamos Yape, Plin y Transferencia. 💳",
        ),
      ];
      _saveSnippets();
    }
    // Always try to sync from backend after loading local
    if (_apiToken.isNotEmpty) {
      fetchSnippetsFromBackend();
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

  // Sync snippets from backend
  Future<void> fetchSnippetsFromBackend({bool forceRefresh = false}) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/api/snippets/'),
        headers: {'Authorization': _apiToken},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final snippetsList = data['snippets'] as List;
        _snippets = snippetsList.map((item) => Snippet.fromJson(item)).toList();
        await _saveSnippets();
        notifyListeners();
        debugPrint('✅ Snippets synced from backend: ${_snippets.length}');
      } else {
        debugPrint('⚠️ Failed to fetch snippets: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error fetching snippets from backend: $e');
    }
  }

  Future<void> loadMoreMessages(String phone) async {
    final contactIndex = _contacts.indexWhere((c) => c.phone == phone);
    if (contactIndex == -1) return;

    final contact = _contacts[contactIndex];
    if (contact.messages.isEmpty) return;

    final oldestMsgId = contact.messages.first.id;
    if (oldestMsgId == null) return;

    final newMessagesData = await _apiService.getChatHistory(
      _apiToken,
      phone,
      oldestMsgId,
    );
    if (newMessagesData.isEmpty) return;

    final newMessages = newMessagesData
        .map((m) => Message.fromJson(m))
        .toList();

    // newMessages came in correct order (Oldest -> Newer) but are OLDER than current list
    // So we prepend them: [...newMessages, ...existing]
    final updatedMessages = [...newMessages, ...contact.messages];

    _contacts[contactIndex] = Contact(
      name: contact.name,
      phone: contact.phone,
      messages: updatedMessages,
      isBotActive: contact.isBotActive,
      isMuted: contact.isMuted,
      notes: contact.notes,
      tags: contact.tags,
      needsHumanAttention: contact.needsHumanAttention,
      unreadCount: contact.unreadCount,
    );

    notifyListeners();
  }
}
