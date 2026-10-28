import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// Cihaz bildirimlerinin ince sarmalayıcısı. [initialize] çağrılmadıkça
/// (web, testler) hiçbir şey yapmaz; testler [instance]ı sahtesiyle değiştirir.
class NotificationService {
  static NotificationService instance = NotificationService();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _ready = false;

  static const _channelId = 'break_reminders';
  static const _silentChannelId = 'break_reminders_silent';

  /// Bildirime dokununca açılacak sekme (bildirimin payload'ı).
  static const openHome = 'home';
  static const openExercises = 'exercises';

  final _taps = StreamController<String>.broadcast();
  String? _launchPayload;

  /// Uygulama açıkken ya da arka plandayken dokunulan bildirimlerin payload'ı.
  Stream<String> get taps => _taps.stream;

  /// Uygulama bir bildirime dokunularak açıldıysa payload'ı; bir kez okunur.
  String? takeLaunchPayload() {
    final payload = _launchPayload;
    _launchPayload = null;
    return payload;
  }

  Future<void> initialize() async {
    // Web'de zamanlanmış bildirim yok; uygulama sadece sayaçla çalışır.
    if (kIsWeb) return;
    try {
      // Bildirimler kesin bir ana kurulduğu için saat dilimi önemli değil.
      tz.initializeTimeZones();
      await _plugin.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('ic_notification'),
          // İzin ilk açılışta değil, onboarding bitince istenir.
          iOS: DarwinInitializationSettings(
            requestAlertPermission: false,
            requestSoundPermission: false,
            requestBadgePermission: false,
          ),
        ),
        onDidReceiveNotificationResponse: (response) {
          if (response.payload case final payload?) _taps.add(payload);
        },
      );
      final launch = await _plugin.getNotificationAppLaunchDetails();
      if (launch?.didNotificationLaunchApp ?? false) {
        _launchPayload = launch!.notificationResponse?.payload;
      }
      _ready = true;
    } catch (e) {
      debugPrint('Bildirimler başlatılamadı: $e');
    }
  }

  /// Bildirim iznini ister; izin verildiyse (ya da gerekmiyorsa) true.
  Future<bool> requestPermission() async {
    if (!_ready) return true;
    try {
      final android = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      if (android != null) {
        return await android.requestNotificationsPermission() ?? false;
      }
      final ios = _plugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >();
      if (ios != null) {
        return await ios.requestPermissions(
              alert: true,
              badge: true,
              sound: true,
            ) ??
            false;
      }
    } catch (e) {
      debugPrint('Bildirim izni istenemedi: $e');
    }
    return true;
  }

  /// [at] anında tek seferlik bildirim kurar; aynı [id] öncekinin yerini alır.
  Future<void> scheduleAt({
    required int id,
    required DateTime at,
    required String title,
    required String body,
    required String payload,
    required bool sound,
  }) async {
    if (!_ready) return;
    try {
      await _plugin.zonedSchedule(
        id: id,
        scheduledDate: tz.TZDateTime.from(at, tz.UTC),
        title: title,
        body: body,
        payload: payload,
        notificationDetails: _details(sound),
        androidScheduleMode: await _scheduleMode(),
      );
    } catch (e) {
      debugPrint('Bildirim kurulamadı: $e');
    }
  }

  Future<void> cancel(int id) async {
    if (!_ready) return;
    try {
      await _plugin.cancel(id: id);
    } catch (e) {
      debugPrint('Bildirim iptal edilemedi: $e');
    }
  }

  Future<void> cancelAll() async {
    if (!_ready) return;
    try {
      await _plugin.cancelAll();
    } catch (e) {
      debugPrint('Bildirimler iptal edilemedi: $e');
    }
  }

  /// Kesin alarm izni (Android 14+ varsayılan kapalı) yoksa birkaç dakika
  /// gecikebilen zamanlamaya düşülür.
  Future<AndroidScheduleMode> _scheduleMode() async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    final exact = await android?.canScheduleExactNotifications() ?? false;
    return exact
        ? AndroidScheduleMode.exactAllowWhileIdle
        : AndroidScheduleMode.inexactAllowWhileIdle;
  }

  /// Android'de kanal sesi sonradan değişmediği için sesli ve sessiz iki
  /// ayrı kanal var.
  static NotificationDetails _details(bool sound) => NotificationDetails(
    android: sound
        ? const AndroidNotificationDetails(
            _channelId,
            'Hatırlatmalar',
            channelDescription: 'Mola, mesai ve günlük hedef anımsatıcıları',
            importance: Importance.high,
            priority: Priority.high,
          )
        : const AndroidNotificationDetails(
            _silentChannelId,
            'Sessiz hatırlatmalar',
            channelDescription: 'Sessiz ve titreşimsiz anımsatıcılar',
            importance: Importance.high,
            priority: Priority.high,
            playSound: false,
            enableVibration: false,
          ),
    iOS: DarwinNotificationDetails(presentSound: sound),
  );
}
