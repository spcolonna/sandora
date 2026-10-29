import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../balance/balance.dart';
import '../i18n/i18n.dart';
import '../settings.dart';
import 'progress.dart';
import 'reminder_plan.dart';

/// Avisos locales: el recordatorio diario del jardín y la campana que cierra
/// una meditación con la app en segundo plano. Sin servidor: todo se programa
/// en el teléfono.
class Reminders {
  Reminders._();
  static final instance = Reminders._();

  final _plugin = FlutterLocalNotificationsPlugin();
  late SharedPreferences _prefs;
  late ReminderPlan rules;
  bool _ready = false;

  static const _meditationId = 1;
  static const _teaId = 2;
  static const _dailyFirstId = 100;

  /// Para probar: `--dart-define=SANDORA_REMINDER_MIN=1` manda el primer
  /// recordatorio dentro de un minuto.
  static const _testMinutes = int.fromEnvironment('SANDORA_REMINDER_MIN');

  /// El permiso se pide una sola vez, después de la primera partida.
  bool get asked => _prefs.getBool('reminders.asked') ?? false;

  Future<void> load(Balance balance) async {
    _prefs = await SharedPreferences.getInstance();
    rules = ReminderPlan(balance.section('reminders'));
    if (kIsWeb) return;
    try {
      tzdata.initializeTimeZones();
      final zone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(zone.identifier));
      await _plugin.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
          // No se pide permiso al abrir: se pide después de la primera partida.
          iOS: DarwinInitializationSettings(
            requestAlertPermission: false,
            requestBadgePermission: false,
            requestSoundPermission: false,
          ),
        ),
      );
      _ready = true;
    } catch (e) {
      debugPrint('Avisos no disponibles: $e');
    }
  }

  /// Pide el permiso de avisos (una vez) y, si lo dan, programa los del jardín.
  Future<void> askOnce() async {
    if (!_ready || asked) return;
    await _prefs.setBool('reminders.asked', true);
    await _plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()?.requestPermissions(
      alert: true,
      sound: true,
    );
    await _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    await reschedule();
  }

  /// Vuelve a programar los recordatorios de los próximos días (al abrir o
  /// retomar la app, y al cambiar la hora o apagarlos en Ajustes).
  Future<void> reschedule() async {
    if (!_ready) return;
    final days = rules.b.i('days');
    for (var i = 0; i < days; i++) {
      await _plugin.cancel(id: _dailyFirstId + i);
    }
    final s = AppSettings.instance;
    if (!s.reminders || !asked) {
      await _plugin.cancel(id: _teaId);
      return;
    }
    final p = Progress.instance;
    final now = DateTime.now();
    final plan = rules.plan(
      now: now,
      minuteOfDay: s.reminderMinutes ?? rules.defaultMinutes,
      streak: p.meditationStreak,
      tower: p.tower.isNotEmpty,
    );
    final title = p.gardenName ?? tr('reminder.title');
    for (final (i, r) in plan.indexed) {
      final at = i == 0 && _testMinutes > 0 ? now.add(const Duration(minutes: _testMinutes)) : r.at;
      await _plugin.zonedSchedule(
        id: _dailyFirstId + i,
        scheduledDate: tz.TZDateTime.from(at, tz.local),
        title: title,
        body: tr(r.key, r.args),
        notificationDetails: _details(channel: 'garden', name: tr('reminder.channel')),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    }
  }

  /// La campana del final, por si la app queda en segundo plano.
  Future<void> meditationStarted(DateTime startedAt, int minutes) async {
    if (!_ready) return;
    await _plugin.zonedSchedule(
      id: _meditationId,
      scheduledDate: tz.TZDateTime.from(startedAt.add(Duration(minutes: minutes)), tz.local),
      title: tr('meditation.title'),
      body: tr('reminder.meditationDone'),
      notificationDetails: _details(channel: 'meditation', name: tr('meditation.title'), bell: true),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  /// Avisa cuando la visita llega al té servido (si los avisos están
  /// encendidos). Servir otro té el mismo día no cambia la hora.
  Future<void> teaServed(DateTime arrives, String visitor) async {
    if (!_ready || !asked || !AppSettings.instance.reminders) return;
    if (!arrives.isAfter(DateTime.now())) return;
    await _plugin.zonedSchedule(
      id: _teaId,
      scheduledDate: tz.TZDateTime.from(arrives, tz.local),
      title: Progress.instance.gardenName ?? tr('reminder.title'),
      body: tr('reminder.tea.$visitor'),
      notificationDetails: _details(channel: 'garden', name: tr('reminder.channel')),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  Future<void> meditationEnded() async {
    if (_ready) await _plugin.cancel(id: _meditationId);
  }

  NotificationDetails _details({required String channel, required String name, bool bell = false}) {
    return NotificationDetails(
      android: AndroidNotificationDetails(
        channel,
        name,
        importance: bell ? Importance.high : Importance.defaultImportance,
        sound: bell ? const RawResourceAndroidNotificationSound('meditation_bell') : null,
      ),
      iOS: DarwinNotificationDetails(sound: bell ? 'meditation_bell.caf' : null),
    );
  }
}
