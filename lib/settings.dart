import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'i18n/i18n.dart';

/// Preferencias del jugador. Singleton sobre SharedPreferences; la app entera
/// escucha sus cambios (el idioma redibuja todo).
class AppSettings extends ChangeNotifier {
  AppSettings._();
  static final instance = AppSettings._();

  late SharedPreferences _prefs;

  bool sound = true;
  bool music = true;
  bool haptics = true;

  /// Recordatorio diario del jardín y, si se eligió, a qué hora (minutos desde
  /// la medianoche; sin elegir, la del balance).
  bool reminders = true;
  int? reminderMinutes;

  Future<void> load(Iterable<String> systemLocales) async {
    _prefs = await SharedPreferences.getInstance();
    sound = _prefs.getBool('sound') ?? true;
    music = _prefs.getBool('music') ?? true;
    haptics = _prefs.getBool('haptics') ?? true;
    reminders = _prefs.getBool('reminders') ?? true;
    reminderMinutes = _prefs.getInt('reminderMinutes');
    setLanguage(_prefs.getString('language') ?? systemLanguage(systemLocales));
  }

  void setSound(bool v) => _set('sound', sound = v);
  void setMusic(bool v) => _set('music', music = v);
  void setHaptics(bool v) => _set('haptics', haptics = v);
  void setReminders(bool v) => _set('reminders', reminders = v);

  void setReminderMinutes(int minutes) {
    reminderMinutes = minutes;
    _prefs.setInt('reminderMinutes', minutes);
    notifyListeners();
  }

  void setLang(String code) {
    setLanguage(code);
    _prefs.setString('language', currentLanguage);
    notifyListeners();
  }

  void _set(String key, bool v) {
    _prefs.setBool(key, v);
    notifyListeners();
  }
}
