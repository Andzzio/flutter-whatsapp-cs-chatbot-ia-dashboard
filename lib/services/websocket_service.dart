import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/status.dart' as status;

enum SocketStatus { connecting, connected, disconnected, error }

class WebSocketService {
  WebSocketChannel? _channel;
  final String _baseUrl;

  // Status Stream
  final _statusController = StreamController<SocketStatus>.broadcast();
  Stream<SocketStatus> get statusStream => _statusController.stream;

  // Message Stream
  final _messageController = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get messageStream => _messageController.stream;

  SocketStatus _currentStatus = SocketStatus.disconnected;
  SocketStatus get currentStatus => _currentStatus;

  Timer? _reconnectTimer;
  int _retryAttempts = 0;
  bool _isDisposed = false;

  WebSocketService(this._baseUrl);

  void connect() {
    if (_isDisposed) {
      return;
    }
    if (_currentStatus == SocketStatus.connected ||
        _currentStatus == SocketStatus.connecting) {
      return;
    }

    _updateStatus(SocketStatus.connecting);

    // Build URL: Replace http/https with ws/wss and ENSURE trailing slash
    String wsUrlStr = _baseUrl.replaceFirst('http', 'ws');
    if (!wsUrlStr.endsWith('/')) {
      wsUrlStr += '/';
    }
    // Specific path for routing
    if (!wsUrlStr.endsWith('/ws/dashboard/')) {
      // Assuming _baseUrl is root, append path
      wsUrlStr += 'ws/dashboard/';
    }

    final url = Uri.parse(wsUrlStr);

    debugPrint("🔌 WS Connecting to: $url");
    debugPrint("🔌 WS Origin: $_baseUrl");

    try {
      _channel = IOWebSocketChannel.connect(
        url,
        headers: {
          'Origin': _baseUrl, // Send original HTTP url as Origin
        },
      );

      // Esperar a que el stream esté listo para capturar errores iniciales
      _channel!.ready.catchError((e) {
        // Silenciar error crítico visual, manejarlo como desconexión lógica
        debugPrint("⚠️ WS Handshake Failed (using fallback): $e");
        _onDisconnect();
      });

      _channel!.stream.listen(
        (message) {
          _onConnected();
          try {
            final data = json.decode(message);
            _messageController.add(data);
          } catch (e) {
            debugPrint("⚠️ WS Parse Error: $e");
          }
        },
        onError: (error) {
          debugPrint("❌ WS Error: $error");
          _onDisconnect();
        },
        onDone: () {
          debugPrint("🚫 WS Closed");
          _onDisconnect();
        },
        cancelOnError: true,
      );
    } catch (e) {
      debugPrint("❌ WS Connection Failed: $e");
      _onDisconnect();
    }
  }

  void _onConnected() {
    if (_currentStatus != SocketStatus.connected) {
      debugPrint("✅ WS Connected");
      _updateStatus(SocketStatus.connected);
      _retryAttempts = 0; // Reset retries on success
      _reconnectTimer?.cancel();
    }
  }

  void _onDisconnect() {
    if (_currentStatus == SocketStatus.disconnected)
      return; // Already disconnected
    _updateStatus(SocketStatus.disconnected);
    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    if (_isDisposed) return;

    // Exponential Backoff with Jitter (1s, 2s, 4s, 8s... max 30s)
    final delaySeconds = min(30, pow(2, _retryAttempts).toInt());
    debugPrint(
      "⏳ WS Reconnecting in ${delaySeconds}s (Attempt ${_retryAttempts + 1})...",
    );

    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(Duration(seconds: delaySeconds), () {
      _retryAttempts++;
      connect();
    });
  }

  void _updateStatus(SocketStatus status) {
    _currentStatus = status;
    _statusController.add(status);
  }

  void disconnect() {
    _isDisposed = true;
    _reconnectTimer?.cancel();
    _channel?.sink.close(status.goingAway);
    _updateStatus(SocketStatus.disconnected);
  }

  void dispose() {
    disconnect();
    _statusController.close();
    _messageController.close();
  }
}
