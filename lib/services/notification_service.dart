import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:boty_flutter/models/contact.dart';
import 'package:boty_flutter/models/message.dart' as models;
import 'package:permission_handler/permission_handler.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const LinuxInitializationSettings initializationSettingsLinux =
        LinuxInitializationSettings(defaultActionName: 'Open notification');

    // Configuración básica para iOS (aunque el usuario usa Linux/Android principalmente)
    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings();

    const InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          linux: initializationSettingsLinux,
          iOS: initializationSettingsDarwin,
          macOS: initializationSettingsDarwin,
        );

    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse details) {
        // Aquí se podría manejar la navegación al chat al tocar la notificación
      },
    );

    await _requestPermissions();
  }

  Future<void> _requestPermissions() async {
    if (Platform.isAndroid) {
      final status = await Permission.notification.status;
      if (status.isDenied) {
        await Permission.notification.request();
      }
      /* 
      // Para Android 13+ especifico con el plugin si fuera necesario, 
      // pero permission_handler suele bastar.
      */
    } else if (Platform.isIOS || Platform.isMacOS) {
      await _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >()
          ?.requestPermissions(alert: true, badge: true, sound: true);
      await _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
            MacOSFlutterLocalNotificationsPlugin
          >()
          ?.requestPermissions(alert: true, badge: true, sound: true);
    }
  }

  Future<void> showUserMessageNotification(
    Contact contact,
    models.Message message,
  ) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
          'high_priority_messages', // Nuevo canal de alta prioridad
          'Mensajes Urgentes',
          channelDescription: 'Notificaciones de alta prioridad para mensajes',
          importance: Importance.max,
          priority: Priority.max, // Cambiado de high a max
          playSound: true,
          enableVibration: true,
          enableLights: true,
          showWhen: true,
          ticker: 'Nuevo mensaje', // Texto en barra de estado
          styleInformation: BigTextStyleInformation(''),
        );

    const LinuxNotificationDetails linuxPlatformChannelSpecifics =
        LinuxNotificationDetails(
          urgency: LinuxNotificationUrgency
              .critical, // Cambiado de normal a critical
        );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      linux: linuxPlatformChannelSpecifics,
    );

    // ID único basado en timestamp para que se acumulen
    int id = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    await _flutterLocalNotificationsPlugin.show(
      id,
      contact.name,
      message.text.isNotEmpty ? message.text : '📷 Imagen',
      platformChannelSpecifics,
      payload: contact.phone,
    );
  }
}
